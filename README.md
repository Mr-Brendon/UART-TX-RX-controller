UART TX RX controller which converts UART data in parallel data and vice versa.
In UART_FPGA_sources there is a simple constraint to upload the controller in an GOWIN FPGA, with an onboard clock of 27MHz.
The controller perform a transmission and a reception of: one start bit, from 5 to 9 data bits, one optional even parity bit and a stop bit.

For RX, Flag pinout rises up when the data bits are transmitted and uploaded to Reg_out.  
parity_flag rises up when there is a parity mismatch.  
Pay attention Reg_out and parity_flag are setted with previous values until Flag rises up again.
