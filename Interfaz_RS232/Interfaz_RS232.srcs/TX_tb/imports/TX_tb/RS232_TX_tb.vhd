library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Testbench independiente del TRANSMISOR RS232.
-- Muestrea directamente la linea TX y reconstruye la trama (start, 8 datos LSB
-- primero, stop), sin depender del receptor. Tambien comprueba EOT.
entity RS232_TX_tb is
end RS232_TX_tb;

architecture sim of RS232_TX_tb is

    constant Clk_period : time := 50 ns;             -- 20 MHz
    constant Bit_period : time := 173 * Clk_period;   -- ~115200 baudios

    signal Reset : STD_LOGIC := '0';
    signal Clk   : STD_LOGIC := '0';
    signal Start : STD_LOGIC := '0';
    signal Data  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal EOT   : STD_LOGIC;
    signal TX    : STD_LOGIC;

    signal sim_done : boolean := false;

begin

    -- Dispositivo bajo prueba
    UUT: entity work.RS232_TX
        port map (
            Reset => Reset,
            Clk   => Clk,
            Start => Start,
            Data  => Data,
            EOT   => EOT,
            TX    => TX
        );

    -- Reloj
    Clk_gen: process
    begin
        while not sim_done loop
            Clk <= '0'; wait for Clk_period / 2;
            Clk <= '1'; wait for Clk_period / 2;
        end loop;
        wait;
    end process;

    -- Estimulos
    Stimulus: process

        -- Comprueba que TX se mantiene en un valor fijo durante todo un bit,
        -- muestreando a mitad de periodo para evitar los flancos de cambio.
        procedure check_bit (expected : in STD_LOGIC; lbl : in string) is
        begin
            wait for Bit_period / 2;
            assert TX = expected
                report "Fallo en " & lbl & ": TX = " & std_logic'image(TX) &
                       ", se esperaba " & std_logic'image(expected)
                severity error;
            wait for Bit_period / 2;
        end procedure;

        -- Lanza una transmision y comprueba trama completa + EOT
        procedure test_byte (d : in STD_LOGIC_VECTOR(7 downto 0)) is
        begin
            assert EOT = '1'
                report "EOT deberia estar a '1' (libre) antes de transmitir" severity error;
            assert TX = '1'
                report "TX deberia estar en reposo ('1') antes de transmitir" severity error;

            -- Lanzamos Start sincronizado con el reloj
            wait until falling_edge(Clk);
            Data  <= d;
            Start <= '1';
            wait until falling_edge(Clk);
            Start <= '0';

            assert EOT = '0'
                report "EOT deberia bajar a '0' nada mas empezar" severity error;

            -- Bit de start
            check_bit('0', "bit de start");

            -- 8 bits de datos, LSB primero
            for i in 0 to 7 loop
                check_bit(d(i), "bit de datos " & integer'image(i));
            end loop;

            -- Bit de stop
            check_bit('1', "bit de stop");

            wait for 2 * Clk_period;
            assert EOT = '1'
                report "EOT deberia volver a '1' al terminar la trama" severity error;

            --report "OK: byte 0x" & to_hstring(d) & " transmitido correctamente";
        end procedure;

    begin
        Reset <= '0';
        wait for 5 * Clk_period;
        Reset <= '1';
        wait for 10 * Clk_period;

        assert TX = '1'  report "TX deberia estar en reposo tras el reset"  severity error;
        assert EOT = '1' report "EOT deberia estar a '1' tras el reset"     severity error;

        -- Bytes de prueba
        test_byte(x"55");   -- 01010101
        test_byte(x"A3");   -- 10100011
        test_byte(x"00");
        test_byte(x"FF");
        test_byte(x"81");   -- 10000001 (bits extremos)

        -- Dos transmisiones seguidas, para comprobar que no se pierde ningun bit
        -- entre una trama y la siguiente
        test_byte(x"3C");
        test_byte(x"C3");

        report "Simulacion terminada (RS232_TX_tb)";
        sim_done <= true;
        wait;
    end process Stimulus;

end sim;
