library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RS232_TX is
    Port(
        Reset : in  std_logic;                    -- Reset asíncrono, activo a nivel bajo
        Clk   : in  std_logic;                    -- Reloj del sistema (20 MHz)
        Start : in  std_logic;                    -- Comienzo de transmisión, activo alto
        Data  : in  std_logic_vector(7 downto 0); -- Byte a transmitir
        EOT   : out std_logic;                    -- Fin de transmisión / TX_RDY, activo alto
        TX    : out std_logic                     -- Línea serie RS232
    );
end RS232_TX;

architecture Behavioral of RS232_TX is

    type FSM_state is (Idle, StartBit, SendBit, StopBit);
    signal CurrentState, NextState : FSM_state;

    -- Con f = 20 MHz y 115200 bps: 20e6 / 115200 = 173.61 ciclos (cuenta 0 a 172)
    constant PulseEndOfCount : integer := 172; 

    signal Pulse_width : integer range 0 to PulseEndOfCount := 0;
    signal Pulse_width_next : integer range 0 to PulseEndOfCount := 0;
    
    signal Data_count  : integer range 0 to 7 := 0;
    signal Data_count_next  : integer range 0 to 7 := 0;
    
    --signal Data_reg    : std_logic_vector(7 downto 0);

    --signal Pulse_reset: std_logic:= '1';
    --signal Data_count_reset: std_logic:= '1';
    --signal Data_count_inc: std_logic := '1';
    --signal Data_load: std_logic := '1';
begin

Sequential: process (Reset, Clk)
begin
    if Reset = '0' then
        CurrentState <= Idle;
        Pulse_width <= 0;
        Data_count <= 0;
    elsif rising_edge(Clk) then
        CurrentState <= NextState;
        Pulse_width <= Pulse_width_next;
        Data_count <= Data_count_next;
        
--        if Pulse_reset = '1' then
--            Pulse_width <= 0;
--        else
--            Pulse_width <= Pulse_width + 1;
--        end if;

--        if Data_count_reset = '1' then
--            Data_count <= 7;
--        elsif Data_count_inc = '1' then
--            Data_count <= Data_count - 1;
--        end if;

--        if Data_load = '1' then
--            Data_reg <= Data;
--        end if;
        
    end if;
end process Sequential;


Logic: process (CurrentState, Start, Pulse_width, Data_count)
begin 
    --Valores predeterminados
    NextState <= CurrentState;
    Pulse_width_next <= Pulse_width;
    Data_count_next <= Data_count;
    
    case CurrentState is
        when Idle =>
            --Pulse_reset <= '1';
            Pulse_width_next <= 0;
            --Data_count_reset <= '1';
            Data_count_next <= 0;
            
            if Start = '1' then
                NextState <= StartBit;
                --Pulse_reset <= '0';
                --Data_count_reset <= '0';
            end if;
        when StartBit =>
            --Pulse_reset <= '0';
            Pulse_width_next <= Pulse_width + 1;
            Data_count_next <= 0;
            
            --Data_count_inc <= '0';
            if Pulse_width = PulseEndOfCount then
                NextState <= SendBit;
                Pulse_width_next <= 0;
            end if;
        when SendBit =>
            --Data_count_reset <= '0'; 
            --Pulse_reset <= '0';
            --Data_load <= '0';
            Pulse_width_next <= Pulse_width + 1;
            if Pulse_width = PulseEndOfCount then
                --Pulse_reset <= '1';
                Pulse_width_next <= 0;
                if Data_Count = 7 then
                    NextState <= StopBit;      
                else
                    --Data_count_inc <= '1';
                    Data_count_next <= Data_count + 1;     
                end if;
            end if;
        when StopBit => 
            --Data_count_reset <= '1';
            
            --Pulse_reset <= '0';
            --Data_load <= '0';
            --Data_count_inc <= '0';
            Pulse_width_next <= Pulse_width + 1;
            if Pulse_width = PulseEndOfCount then
                NextState <= Idle;
                --Pulse_reset <= '1';
                Pulse_width_next <= 0;
                Data_count_next <= 0; 
            end if;
     end case;
end process Logic;

Output: process (CurrentState, Data_count, Data)
begin
    --Valores predeterminados
    TX <= '0';
    EOT <= '0';
    case CurrentState is
            when Idle =>
                TX <= '1';
                EOT <= '1';
            when StartBit =>
                TX <= '0';
                EOT <= '0';
            when SendBit =>
                TX <= Data(Data_count);
                EOT <= '0';
            when StopBit => 
                TX <= '1';
                EOT <= '0';
     end case;
end process Output;

end architecture;