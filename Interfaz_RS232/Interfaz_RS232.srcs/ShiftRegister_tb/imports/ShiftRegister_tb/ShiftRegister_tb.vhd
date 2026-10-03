----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.10.2020 15:11:52
-- Design Name: 
-- Module Name: ShiftRegister_tb - Behavioral
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

entity ShiftRegister_tb is
end ShiftRegister_tb;

architecture Behavioral of ShiftRegister_tb is

component ShiftRegister is
    port (
      Reset  : in  std_logic;
      Clk    : in  std_logic;
      Enable : in  std_logic;
      D      : in  std_logic;
      Q      : out std_logic_vector(7 downto 0));
end component;

signal Reset, Clk, Enable, D: std_logic;
signal Q: std_logic_vector(7 downto 0);

constant ClkPeriod: time := 10 ns;

constant Datain: std_logic_vector(9 downto 0) := "1001011001";

begin

Reset <= '1', '0' after 2*ClkPeriod, '1' after 17*ClkPeriod;

process
begin
    Clk <= '0';
    wait for ClkPeriod/2;
    Clk <= '1';
    wait for ClkPeriod/2;
end process;

--Enable <= '0', 
--          '1' after 10*ClkPeriod, '0' after 11*ClkPeriod,
--          '1' after 15*ClkPeriod, '0' after 16*ClkPeriod,
--          '1' after 20*ClkPeriod, '0' after 21*ClkPeriod,
--          '1' after 25*ClkPeriod, '0' after 26*ClkPeriod,
--          '1' after 30*ClkPeriod, '0' after 31*ClkPeriod,
--          '1' after 35*ClkPeriod, '0' after 36*ClkPeriod,
--          '1' after 40*ClkPeriod, '0' after 41*ClkPeriod,
--          '1' after 45*ClkPeriod, '0' after 46*ClkPeriod,
--          '1' after 50*ClkPeriod, '0' after 51*ClkPeriod,
--          '1' after 55*ClkPeriod, '0' after 56*ClkPeriod;     
          
--D <=      '0', 
--          '1' after 8*ClkPeriod,
--          '0' after 13*ClkPeriod,
--          '0' after 18*ClkPeriod,
--          '1' after 23*ClkPeriod,
--          '0' after 28*ClkPeriod,
--          '1' after 33*ClkPeriod,
--          '1' after 38*ClkPeriod,
--          '0' after 43*ClkPeriod,
--          '1' after 48*ClkPeriod,
--          '0' after 53*ClkPeriod;             
          
process
begin
    Enable <= '0';
    D <= '0';    
    wait until Reset = '1';
    wait until Reset = '0';
    wait for ClkPeriod;
    
    for i in 0 to Datain'high loop
        D <= Datain(i);
        wait for ClkPeriod;
        Enable <= '1';
        wait for ClkPeriod;
        Enable <= '0';
        wait for 3*ClkPeriod;
    end loop; 
    
    wait;      
end process;     

SR: ShiftRegister
    port map(
      Reset  => Reset,
      Clk    => Clk,
      Enable => Enable,
      D      => D,
      Q      => Q);


end Behavioral;
