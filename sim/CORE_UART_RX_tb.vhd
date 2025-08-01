----------------------------------------------------------------------------------
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;


entity CORE_UART_RX_tb is
        generic(parity: integer range 0 to 1 := 1;     
                N: integer range 8 to 12 := 10;
                frequency: integer := 27000000;
                baud_frequency: integer := 9600
                );
end CORE_UART_RX_tb;


architecture CORE_UART_RX_tb_bh of CORE_UART_RX_tb is

component CORE_UART_RX is
    port(Rx_in, CLK, RESET: in std_logic;
         Flag, parity_flag: out std_logic;
         Reg_out: out std_logic_vector(N-(2+parity)-1 downto 0) --N-(2+parity)
         );
end component;

signal Rx_in, CLK: std_logic := '1';
signal RESET: std_logic := '0';
signal Flag, parity_flag: std_logic;
signal Reg_out: std_logic_vector(N-(2+parity)-1 downto 0);

begin

UART_RX_block: CORE_UART_RX port map(Rx_in => Rx_in, CLK => CLK, RESET => RESET, Flag => Flag, parity_flag => parity_flag, Reg_out => Reg_out);

--START:

process
begin
    wait for 1 ns;
    CLK <= NOT(CLK);
    wait for 37 ns;
end process;

process
begin
    RESET <= '0';
    wait for 54 us;
    RESET <= '1';
    wait for 74 us;


    --first frame

    Rx_in <= '0';   --start bit
    wait for 208 us;
    
    Rx_in <= '1';   --bit1
    wait for 208 us;
    Rx_in <= '0';   --bit2
    wait for 208 us;
    Rx_in <= '1';   --bit3
    wait for 208 us;
    Rx_in <= '0';   --bit4
    wait for 208 us;
    Rx_in <= '1';   --bit5
    wait for 208 us;
    Rx_in <= '0';   --bit6
    wait for 208 us;
    Rx_in <= '1';   --bit7
    wait for 208 us;
    
    Rx_in <= '1';   --parity bit
    wait for 208 us;
    Rx_in <= '1';   --stop bit
    wait for 104 us;
        
    --second frames
        
    Rx_in <= '0';   --start bit
    wait for 208 us;   
        
    Rx_in <= '1';   --bit1
    wait for 208 us;
    Rx_in <= '0';   --bit2
    wait for 208 us;
    Rx_in <= '0';   --bit3
    wait for 208 us;
    Rx_in <= '1';   --bit4
    wait for 208 us;
    Rx_in <= '1';   --bit5
    wait for 208 us;
    Rx_in <= '0';   --bit6
    wait for 208 us;
    Rx_in <= '1';   --bit7
    wait for 208 us;
    
    Rx_in <= '0';   --parity bit
    wait for 208 us;
    Rx_in <= '1';   --stop bit
    wait for 936 us;
    std.env.stop;
    
end process;


end CORE_UART_RX_tb_bh;


