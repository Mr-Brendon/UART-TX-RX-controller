----------------------------------------------------------------------------------
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity testbench is
    generic(parity: integer range 0 to 1 := 1;
            N: integer range 8 to 12 := 10;
            frequency: integer := 27000000;
            baud_frequency: integer := 9600
            );
end testbench;

architecture test of testbench is

component CORE_UART_TX is
    port(Reg_in: in std_logic_vector(N-(2+parity)-1 downto 0);
         CLK, RESET, start: in std_logic;
         Rx_out, Flag, buffer_stored: out std_logic
         );
end component;

signal Reg_in: std_logic_vector(N-(2+parity)-1 downto 0);
signal CLK, RESET, start: std_logic := '0';
signal Rx_out, Flag: std_logic;

begin

comp: CORE_UART_TX port map(Reg_in => Reg_in, CLK => CLK, RESET => RESET, Rx_out => Rx_out, Flag => Flag, start => start);


process
begin
    wait for 1 ns;
    CLK <= not(CLK);
    wait for 1 ns;
end process;

process
begin
    start <= '0';
    RESET <= '0';
    wait for 9 ns;
    RESET <= '1';
    Reg_in <= "1010111";
    wait for 1 ns;
    start <= '1';
    wait for 50ns;
    Reg_in <= "1010101";
    wait for 163 us;
    Reg_in <= "1100100";
    wait for 3 ms;
    std.env.stop;
end process;





end test;
