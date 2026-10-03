------------------------------------------------------
-- Autor: Juan Antonio López Martín
-- Departamento de Ingeniería Electrónica 
------------------------------------------------------ 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity nexys_RS232top is
  port (
    
	-- Puertos PMOD de usuario (x4)
	JA 				: inout STD_LOGIC_VECTOR(2 downto 1);    
	
    --Interfaz USB-RS232
--    UART_TXD_IN     : in  STD_LOGIC;
--    UART_RXD_OUT    : out  STD_LOGIC;
--    UART_CTS        : in  STD_LOGIC;
--    UART_RTS        : in  STD_LOGIC;


---------------------------------------------------------------------------------------
	
	-- Displays 7 segmentos (x8)
    CA                 : out  STD_LOGIC;    
    CB                 : out  STD_LOGIC;    
    CC                 : out  STD_LOGIC;    
    CD                 : out  STD_LOGIC;    
    CE                 : out  STD_LOGIC;    
    CF                 : out  STD_LOGIC;    
    CG                 : out  STD_LOGIC;    
    DP                 : out  STD_LOGIC;    
    AN                 : out  STD_LOGIC_VECTOR(7 downto 0);    

-- Botones de usuario (x5)
    BTNC             : in  STD_LOGIC;    
    BTNU             : in  STD_LOGIC;    
--    BTNL             : in  STD_LOGIC;    
--    BTNR             : in  STD_LOGIC;    
--    BTND             : in  STD_LOGIC;    

-- Interruptores (x16)
    SW                 : in   STD_LOGIC_VECTOR(15 downto 0);    
-- LEDs (x16)
    LED                : out  STD_LOGIC_VECTOR(15 downto 0);   

-- Reloj de la FPGA
    CLK100MHZ        : in   STD_LOGIC

	 );  
end nexys_RS232top;


architecture a_behavior of nexys_RS232top is

-- declaración de componentes 
    component clk_wiz_0
        port (
          reset     : in  std_logic;
          clk_in1   : in  std_logic;
          clk_out1  : out  std_logic;
          locked    : out std_logic);
    end component;

    component RS232top is
      port (
        Reset     : in  std_logic;   -- Low-level asynchronous reset
        Clk       : in  std_logic;   -- System clock (20MHz), rising edge 
	
        Data_in   : in  std_logic_vector(7 downto 0);  -- Parallel TX byte 
        Valid_D   : in  std_logic;   -- Handshake signal from guest, active low 
        Ack_in    : out std_logic;   -- Data ack, low when it has been stored
        TX_RDY    : out std_logic;   -- System ready to transmit
        TD        : out std_logic;   -- RS232 Transmission line
	
        RD        : in  std_logic;   -- RS232 Reception line
        Data_out  : out std_logic_vector(7 downto 0);  -- Parallel RX byte
        Data_read : in  std_logic;   -- Send RX data to guest 
        Full      : out std_logic;   -- Internal RX memory full 
        Empty     : out std_logic);  -- Internal RX memory empty
    end component;


-- declaración de señales 
    signal reset, reset_p : std_logic;
    signal clk : std_logic;
    signal clk1, clk2, clk3, clk4, clk5, clk6, clk7 : std_logic;
    --signal s_SW : std_logic_vector(15 downto 0);
 
    signal contador : UNSIGNED(31 downto 0); 
    signal flag : std_logic;

-- signals for UUT (RS_232top) 
    signal Data_in   : std_logic_vector(7 downto 0);  -- Parallel TX byte 
    signal Valid_D   : std_logic;   -- Handshake signal from guest, active low 
    signal Ack_in    : std_logic;   -- Data ack, low when it has been stored
    signal TX_RDY    : std_logic;   -- System ready to transmit
    signal TD        : std_logic;   -- RS232 Transmission line
	
    signal RD        : std_logic;   -- RS232 Reception line
    signal Data_out  : std_logic_vector(7 downto 0);  -- Parallel RX byte
    signal Data_read : std_logic;   -- Send RX data to guest 
    signal Full      : std_logic;   -- Internal RX memory full 
    signal Empty     : std_logic;  -- Internal RX memory empty
    
begin

-- Reset
     reset <= SW(15);

-- Datos de entrada y salida
     LED(7 downto 0) <= Data_out;
     Data_in <= SW(7 downto 0);

-- Visualización de las señales de salida y estado del sistema
     LED(9 downto 8) <= "00";
     LED(10) <= Ack_in;
     LED(11) <= TX_RDY;
     LED(12) <= '0';
     LED(13) <= Full;
     LED(14) <= Empty;
     LED(15) <= reset;

-- Señales de petición de envío y recepción de datos (entrada) 
     Valid_D <= NOT (BTNC);
     Data_read <= BTNU; 
    -- Data_read <= BTNU;  -- ACTIVA A NIVEL BAJO!
  
-- realimentación lineas TD => RD  (necesita un cable entre los pines 1 y 2 del pmodJA)
     JA(1) <= TD;   -- OUTPUT PORT
     JA(2) <= 'Z';   -- OUTPUT PORT
     RD <= JA(2);   -- INPUT PORT

-- conexión de las lineas TD y RD PC mediante el puerto microUSB (puerto serie RS232)
--     UART_RXD_OUT <= TD;
--     RD <= UART_TXD_IN;


    CA <= '1';
    CB <= '1';
    CC <= '1';
    CD <= '1';
    CE <= '1';
    CF <= '1';
    CG <= '1';
    DP <= contador(24);
    AN <= "00000000";

  reset_p <= not reset;
-- instanciación de componentes 
    clk_20MHz : clk_wiz_0 PORT MAP(
        reset => reset_p,
        clk_in1 => CLK100MHz,
        clk_out1 => clk,
        locked => open);

    UUT : RS232top PORT MAP(
        Reset      => reset, 
        Clk        => clk,
        Data_in    => Data_in,
        Valid_D    => Valid_D,
        Ack_in     => Ack_in,
        TX_RDY     => TX_RDY,
        TD         => TD,
        RD         => RD,
        Data_out   => Data_out,
        Data_read  => Data_read,
        Full       => Full, 
        Empty      => Empty);


    process(reset, clk)
    begin
      if reset='0' then
        contador <= (others => '0');
        flag <= '0';
      elsif clk'event and clk='1' then
          contador <= contador + 1;
          if contador >= 100000000 then
            contador <= (others => '0');
            flag <= not flag;
          end if; 
      end if;
    end process;      
    
                   
-- otros procesos
   -- (...)

end a_behavior;
