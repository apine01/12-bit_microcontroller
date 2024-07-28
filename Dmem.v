// data memory v1
// 16 entry data memory with 8 bits each entry (RAM)

module Dmem
  (
    i_clk,
	i_en,
	i_Wen,
	i_Addr,
	i_WriteData,
	o_ReadData
	);
	
  input i_clk; 
  
  input i_en;    // enables Data memory for the device. 1 means it will be read or written in, 0 means nothing is done
  
  input i_Wen;  // 1 means that the address specified will be written, specified by the input, 
                // 0 means the input is ignored and the specified address is read
  
  input [3:0] i_Addr; // Specifies which data entry will be read out, will be given from Instruction registry(IR) for current executions
  
  input [7:0] i_WriteData; // Input that will be written into the address, will be given from ALU output
  
  output [7:0] o_ReadData; // Output that will be read out and selected by a multiplier
  
  
//-----------------------------------------------------------------------------------------
//data memory

reg [7:0] data_m [15:0]; // data memory, can have a value of 0,1,2...15, each of those is 8 bits, example below
                          //   bits					unpacked value
						  // 0000000 					  0
						  // 0011010 					  1
						  // 1001010 					  2
						  // ...						  .
						  // ...						  .
						  // ...						  .
						  // 1000001 					  15

always @(posedge i_clk) begin 
  if (i_en && i_Wen)                 // writes into specified address of memory both both enable inputs are on
    data_m[i_Addr] <= i_WriteData; 
end 

  assign o_ReadData = (i_en == 1'b1)? data_m[i_Addr] : 8'b0000_0000;   // read data memory continously if the enable is on
                                                            // can happen simulatenously as it write to the data
endmodule
  