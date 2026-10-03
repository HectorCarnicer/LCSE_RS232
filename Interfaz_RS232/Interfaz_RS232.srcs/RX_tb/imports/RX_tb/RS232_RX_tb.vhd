library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Testbench independiente del RECEPTOR RS232.
-- Genera directamente la senal serie LineRD_in (sin usar el TX) y comprueba
-- que Code_out/Valid_out/Store_out reconstruyen el byte enviado.
entity RS232_RX_tb is
end RS232_RX_tb;

architecture sim of RS232_RX_tb is

    constant Clk_period : time := 50 ns;             -- 20 MHz
    constant Bit_period : time := 173 * Clk_period;   -- ~115200 baudios

    signal Reset     : STD_LOGIC := '0';
    signal Clk       : STD_LOGIC := '0';
    signal LineRD_in : STD_LOGIC := '1';              -- linea en reposo = '1'
    signal Valid_out : STD_LOGIC;
    signal Code_out  : STD_LOGIC;
    signal Store_out : STD_LOGIC;

    signal received    : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal store_count : natural := 0;
    signal sim_done    : boolean := false;

begin

    -- Dispositivo bajo prueba
    UUT: entity work.RS232_RX
        port map (
            Reset     => Reset,
            Clk       => Clk,
            LineRD_in => LineRD_in,
            Valid_out => Valid_out,
            Code_out  => Code_out,
            Store_out => Store_out
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

    -- Monitor: reconstruye el byte con cada pulso de Valid_out (LSB primero)
    Monitor: process (Clk)
        variable idx : natural range 0 to 7 := 0;
        variable rx  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    begin
        if rising_edge(Clk) then
            if Valid_out = '1' then
                rx(idx) := Code_out;
                if idx = 7 then idx := 0; else idx := idx + 1; end if;
            end if;
            if Store_out = '1' then
                received    <= rx;
                store_count <= store_count + 1;
            end if;
        end if;
    end process Monitor;

    -- Estimulos
    Stimulus: process

        -- Envia una trama RS232: start (0), 8 datos LSB primero, stop (1 = ok, 0 = invalido)
        procedure send_byte (data : in STD_LOGIC_VECTOR(7 downto 0);
                             stop : in STD_LOGIC := '1') is
        begin
            LineRD_in <= '0';  wait for Bit_period;          -- start
            for i in 0 to 7 loop
                LineRD_in <= data(i);  wait for Bit_period;  -- datos
            end loop;
            LineRD_in <= stop; wait for Bit_period;          -- stop
            LineRD_in <= '1';                                -- reposo
        end procedure;

        -- Envia un byte y comprueba que se recibe correctamente
        procedure test_byte (data : in STD_LOGIC_VECTOR(7 downto 0)) is
            variable prev_count : natural;
        begin
            prev_count := store_count;
            send_byte(data);
            wait for 2 * Bit_period;
            assert store_count = prev_count + 1
                report "Store_out no se activo" severity error;
            assert received = data
                report "Byte incorrecto" severity error;
            if store_count = prev_count + 1 and received = data then
                report "OK: byte recibido correctamente";
            end if;
        end procedure;

        variable prev_count : natural;

    begin
        -- Reset
        Reset <= '0';
        wait for 5 * Clk_period;
        Reset <= '1';
        wait for 10 * Clk_period;

        -- Bytes de prueba
        test_byte(x"55");   -- 01010101
        test_byte(x"A3");   -- 10100011
        test_byte(x"00");
        test_byte(x"FF");

        -- Trama con bit de stop invalido -> Store_out NO debe activarse
        prev_count := store_count;
        send_byte(x"3C", stop => '0');
        wait for 3 * Bit_period;
        assert store_count = prev_count
            report "Store_out se activo con stop bit invalido" severity error;
        report "OK: trama con stop invalido rechazada";

        -- Tras el error, la FSM debe seguir funcionando
        test_byte(x"5A");

        report "Simulacion terminada (RS232_RX_tb)";
        sim_done <= true;
        wait;
    end process Stimulus;

end sim;
