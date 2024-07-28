// Program memory
// 256 entry program memory, each entry is 12 bits

module Pmem
  (
    i_clk,
	i_en,
	i_Addr,
	i_Len,
	i_L_Addr,
	i_L_Instr,
	o_ReadInstr
	);
	
  input i_clk;
  
  input i_en;             // enables program memory for the device. 1 means it will be read, 0 means nothing is read out
  
  input [7:0] i_Addr;     // Specifies which data entry will be read out, given from program counter
  
  input i_Len;            // 1 means that the address will be loaded by the load Instruction port, the Instruction port will be 
                          // changed to that same value.
						  // 0 means that that the insruction load is ignored
  
  input [7:0] i_L_Addr;   // Specifies which Instruction will be loaded
  
  input [11:0] i_L_Instr; // Instruction that is loaded
  
  output [11:0] o_ReadInstr;  // Instruction that is read out, connected to IR
  
//-----------------------------------------------------------------------------------------------------------
// program memory

reg [11:0] prog_m [255:0];  // packed array is 12 bits, unpacked has 256 dimensions

always @(posedge i_clk) begin
  if (i_Len)
    prog_m[i_L_Addr] <= i_L_Instr;   // loads input instructions every clock cycle
end
   
  assign o_ReadInstr = ( i_en ) ? prog_m[i_Addr]: 12'b0000_0000_0000;   // reads out all the time
  
endmodule
	
	