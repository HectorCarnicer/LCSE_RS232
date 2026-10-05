----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/15/2026 06:41:08 PM
-- Design Name: 
-- Module Name: RS232_RX - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity RS232_RX is
 port(
    Reset: in STD_LOGIC;
    Clk: in STD_LOGIC;
    LineRD_in: in STD_LOGIC;
    Valid_out: out STD_LOGIC;
    Code_out: out STD_LOGIC;
    Store_out: out STD_LOGIC
 );
end RS232_RX;

architecture Behavioral of RS232_RX is
    
    -- Estados
    type state_t is (Idle, StartBit, RcvData, StopBit);
    signal current_state, next_state: state_t := Idle;
    
    -- Constantes: Número de ciclos de reloj para llegara a T_bit y T_halfbit a 115200 baudios
    constant T_bit: natural := 173;
    constant T_halfbit: natural := T_bit/ 2;
    
    -- Variables
    signal BitCounter: natural range 0 to T_bit := 0;
    signal DataCount: natural range 0 to 7 := 0;
    
    -- Señales para sincronizar
    signal s_LineRD_in: STD_LOGIC := '0';
    signal s_Store_out: STD_LOGIC := '0';
    signal s_Valid_out: STD_LOGIC := '0';
    signal s_Code_out:  STD_LOGIC := '0';
    
    --Flags combinacionales
    signal clear_counter : STD_LOGIC;
    signal clear_data    : STD_LOGIC;
    signal inc_data      : STD_LOGIC;
begin

Sequential: process (Clk, Reset)
begin    
    --Reset asíncrono
    if Reset = '0' then
        current_state <= Idle;
        BitCounter <= 0;
        DataCount <= 0;
        s_LineRD_in <= '1';
    elsif rising_edge(Clk) then
        s_LineRD_in <= LineRD_in;
        current_state <= next_state;
        
        -- Contador de ciclos de reloj
        if clear_counter = '1' then
            BitCounter <= 0;
        else
            BitCounter <= BitCounter + 1;
        end if;

        -- Contador de bits de datos
        if clear_data = '1' then
            DataCount <= 0;
        elsif inc_data = '1' then
            DataCount <= DataCount + 1;
        end if;
    end if;
end process Sequential;

Logic_FSM: process (current_state, s_LineRD_in, BitCounter, DataCount)
begin
    
    --Valores predeterminados
    next_state <= current_state;
    clear_counter <= '0';
    clear_data <= '0';
    inc_data <= '0';
    s_Valid_out <= '0';
    s_Store_out <= '0';
    s_Code_out <= s_LineRD_in;
    
    -- FSM
    case current_state is
    
            when Idle =>
            
                clear_counter <= '1';
                clear_data <= '1';
                if s_LineRD_in = '0' then
                    next_state <= StartBit;
                end if;
                
            when StartBit =>
                if BitCounter = T_halfbit - 1 then
                    clear_counter <= '1';
                    if s_LineRD_in = '0' then
                        next_state <= RcvData;  
                    else
                        next_state <= Idle;      
                    end if;
                end if;
                
            when RcvData =>
                if BitCounter = T_bit - 1 then
                    clear_counter <= '1';
                    s_Valid_out <= '1';       
                    if DataCount = 7 then
                        next_state <= StopBit;
                    else
                        inc_data <= '1';
                    end if;
                end if;
                
            when StopBit =>
                if BitCounter = T_bit - 1 then
                    clear_counter <= '1';
                    if s_LineRD_in = '1' then
                        s_Store_out <= '1';        
                    end if;
                    next_state <= Idle;
                end if;
                
    end case;        
end process Logic_FSM;

Code_out <= s_Code_out;
Valid_out <= s_Valid_out;
Store_out <= s_Store_out;


end Behavioral;
