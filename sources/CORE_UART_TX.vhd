----------------------------------------------------------------------------------
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;

entity CORE_UART_TX is
    generic(parity: integer range 0 to 1 := 1;     --<INSERT VALUE
            N: integer range 8 to 12 := 10; --from 5 to 9 data bits and 2 bits start/stop and parity bit --<INSERT VALUE
            frequency: integer := 27000000;        --<INSERT VALUE
            baud_frequency: integer := 9600        --<INSERT VALUE
            );
    port(Reg_in: in std_logic_vector(N-(2+parity)-1 downto 0);
         CLK, RESET, start: in std_logic;
         Rx_out, Flag: out std_logic
         );
end CORE_UART_TX;

architecture CORE_UART_TX_bh of CORE_UART_TX is

type UART_SM is (idle_bit, start_bit, data_bit, parity_stop_bit, restore);
signal current_state: UART_SM := idle_bit; 
signal Reg_data: std_logic_vector(N-(2+parity)-1 downto 0);
signal clk_count: integer range 0 to (frequency/baud_frequency)-1 := 0;
signal clk_per_bit: integer := (frequency/baud_frequency)-1;
signal bit_index: integer range 0 to N-(2+parity) := 0;
signal N_data: integer := N-(2+parity);
signal temp: integer range 0 to 1 := parity;


begin

Buffer_tx: process(current_state)                       --Reg_data is loaded each start_bit, so you can upload the next data from data_bit to idle
begin
    if(current_state = start_bit) then
        Reg_data <= Reg_in;
    end if;
end process;

SM_block: process(CLK, RESET)
variable parity_temp, a: integer := 0;
begin

    if(RESET = '0') then
        Rx_out <= '1';
        Flag <= '0';
        clk_count <= 0;
        
    elsif(rising_edge(CLK)) then
    
        case current_state is
            when idle_bit =>
                Flag <= '0';
                clk_count <= 0;
                Rx_out <= '1';
                if(start = '1') then
                    current_state <= start_bit;
                else
                    current_state <= idle_bit;
                end if;
            
            when start_bit =>
                Rx_out <= '0';
                if(clk_count = (clk_per_bit-1)) then
                    current_state <= data_bit;
                    clk_count <= 0;
                else
                    current_state <= start_bit;
                    clk_count <= clk_count + 1;
                end if;
            
            when data_bit =>
                Rx_out <= Reg_data(bit_index);
                if(clk_count = (clk_per_bit-1)) then
                    if(bit_index < N_data-1) then
                        bit_index <= bit_index + 1;
                    else
                        current_state <= parity_stop_bit;
                        bit_index <= 0;
                    end if;
                clk_count <= 0;
                    
                else
                    clk_count <= clk_count + 1;
                end if;
            
            when parity_stop_bit =>
                if(parity = 0) then                    --parity = 0 => no parity so stop_bit
                    Rx_out <= '1';                     --stop_bit;
                    Flag <= '1';
                    if(clk_count = clk_per_bit-3) then -- minus 3 because it is clk_per_bit-1 as usual, but it count 2 clk pulse (restore and next idle)
                                                       --to sincronise exactly clk_per_bit to the next frame
                        current_state <= restore;
                        clk_count <= 0;
                    else
                        clk_count <= clk_count + 1;
                    end if;
                elsif(temp = 1) then                 --parity = 1
                    for i in 0 to N-(2+parity)-1 loop       
                            if(Reg_in(i) = '1') then
                                parity_temp := parity_temp + 1;
                            end if;
                    end loop;
                    if(parity_temp mod 2 = 1) then --somma dei bit dispari
                        Rx_out <= '1';
                    else
                        Rx_out <= '0';
                    end if;
                    parity_temp := 0;
                    if(clk_count = clk_per_bit-1) then
                        temp <= 0;
                        clk_count <= 0;
                    else
                        clk_count <= clk_count + 1;
                    end if;
                else                                   --here it is temp = 0;
                                                       --EXIT PARITY = 0 so stop_bit
                    Rx_out <= '1';
                    if(clk_count = clk_per_bit-3) then
                        current_state <= restore;
                        clk_count <= 0;
                        Flag <= '1';                  
                                                       
                    else
                        clk_count <= clk_count + 1;
                    end if;
                end if;
                     
            when restore =>
                clk_count <= 0;
                current_state <= idle_bit;
                temp <= parity;                         --Important it is reset just here
                bit_index <= 0;
            
            when others =>
                current_state <= idle_bit;
            
        end case;
    
    end if;

end process;


end CORE_UART_TX_bh;

