----------------------------------------------------------------------------------
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--use UNISIM.VComponents.all;

--BAUD RATE commonly used: 4800, 9600, 19.2K, 57.6K e 115.2K
--parity bit is just eaven
--frequency >> baud_frequency 


--Reciver:
entity CORE_UART_RX is
    generic(parity: integer range 0 to 1 := 1;     --<INSERT VALUE
            N: integer range 7 to 12 := 10; --from 5 to 9 data bits and 2 bits: start/stop and parity bit --<INSERT VALUE
            frequency: integer := 27000000;        --<INSERT VALUE
            baud_frequency: integer := 9600        --<INSERT VALUE
            );
    port(Rx_in, CLK, RESET: in std_logic;
         Flag, parity_flag: out std_logic;
         Reg_out: out std_logic_vector(N-(2+parity)-1 downto 0) --N-(2+parity) is the value of bits: - start, stop and eventualy parity
         );
end CORE_UART_RX;


architecture CORE_UART_RX_bh of CORE_UART_RX is

type UART_SM is (idle_bit, start_bit, data_bit, parity_stop_bit, restore);
signal current_state: UART_SM := idle_bit;
signal Rx_data: std_logic;
signal buffer_reg: std_logic_vector(N-(2+parity)-1 downto 0) := (others => '0');
signal N_data: integer := N-(2+parity);
signal bit_index: integer range 0 to N-(2+parity) := 0;
signal clk_frequency: integer := frequency;
signal baud_rate: integer := baud_frequency;  
signal clk_per_bit: integer := clk_frequency/baud_rate;
signal clk_count: integer range 0 to (frequency/baud_frequency)-1 := 0;
signal temp: integer range 0 to 1 := parity;



begin

Sample: Rx_data <= Rx_in;

SM_block: process(CLK, RESET)
variable a, parity_temp: integer := 0;
begin

    if(RESET = '0') then
        current_state <= idle_bit;
        Flag <= '0';
        Reg_out <= (others => '0');
        clk_count <= 0;
        bit_index <= 0;
        buffer_reg <= (others => '0');
        temp <= parity;
        a := 0;
        
    elsif(rising_edge(CLK)) then
        case current_state is
            when idle_bit =>
                Flag <= '0';
                clk_count <= 0;
                
                if(Rx_data = '1') then
                    current_state <= idle_bit;
                else
                    current_state <= start_bit;
                end if;
                
            when start_bit =>
                Flag <= '0';
                
                if(clk_count = ((clk_per_bit-1)/2)) then
                    current_state <= data_bit;
                    clk_count <= 0;
                else
                    current_state <= start_bit;
                    clk_count <= clk_count + 1;
                end if;
                
            when data_bit =>
                Flag <= '0';
                clk_count <= clk_count + 1;
                
                if(clk_count = clk_per_bit-1) then
                    if(bit_index < N_data-1) then      
                        current_state <= data_bit;
                        clk_count <= 0;
                        buffer_reg(bit_index) <= Rx_data;
                        bit_index <= bit_index + 1;
                    else
                        buffer_reg(bit_index) <= Rx_data;
                        current_state <= parity_stop_bit;
                        clk_count <= 0;
                        bit_index <= 0;
                    end if;
                else
                    current_state <= data_bit;
                    clk_count <= clk_count + 1;
                    
                end if;
                
            when parity_stop_bit => --doppio perche potrebbe non esserci il parity bit
                if(parity = 0) then                           ---------if parity = 0 it is the stop_bit state
                    if(clk_count = clk_per_bit-1) then
                        current_state <= restore;
                        Flag <= '1';
                        clk_count <= 0;
                        Reg_out <= buffer_reg;
                    else
                        current_state <= parity_stop_bit;
                        Flag <= '0';
                        clk_count <= clk_count + 1;
                    end if;
                elsif(temp = 1) then                         ---------parity = 1, temp = 1 is parity state
                    if(clk_count = clk_per_bit-1) then
                        temp <= 0;                            
                        current_state <= parity_stop_bit;
                        clk_count <= 0;
                        
                        if(Rx_data = '1') then
                            a := 1;
                        else
                            a := 0;
                        end if;
                        
                        parity_temp := a;          
                        a := 0;
                        for i in 0 to N-(2+parity)-1 loop
                            if (buffer_reg(i) = '1') then
                                a := 1;
                            else
                                a := 0;
                            end if;
                        parity_temp := parity_temp + a;
                        end loop;
                        
                        a := 0; --resettiamo a
                        
                        if(parity_temp mod 2 = 1) then
                            parity_flag <= '1';
                        else
                            parity_flag <= '0';
                        end if;
                        
                    else
                        Flag <= '0';
                        clk_count <= clk_count + 1;
                    end if;
                else                                        ----------temp = 0 is stop_bit state
                    if(clk_count = clk_per_bit-1) then
                        current_state <= restore;
                        Flag <= '1';
                        clk_count <= 0;
                        Reg_out <= buffer_reg;
                    else
                        current_state <= parity_stop_bit;
                        Flag <= '0';
                        clk_count <= clk_count + 1;
                    end if;
                end if;
                
            when restore =>
                current_state <= idle_bit;
                buffer_reg <= (others => '0');
                Flag <= '0';
                clk_count <= 0;
                temp <= parity;
                bit_index <= 0;
                parity_temp := 0;
            when others =>
                current_state <= idle_bit;
            
        end case;
    end if;
end process;



end CORE_UART_RX_bh;
