// Contains various modules for microcontroller 

//---------------------------------------------------------------------------
// Program counter adder
// Increments program counter by 1 to move to next instruction


module pc_adder
  (
    i_Adder,
	o_Adder
	);

  input [7:0] i_Adder;   // Given from Program Counter
  
  output [7:0] o_Adder;  // Outputs to second input of MUX_1
  

  assign o_Adder = i_Adder + 1; // increments by 1
  
endmodule


// MUX ---------------------------------------------------------------------------
// MUX 1
// Chooses which input will be used for PC, if it is a branch or not taken, selects the adder input
// otherwie the input is from the Instruction Register (IR)
//MUX 2
// Chooses second operand for ALU
// selects IR if high, otherwise selects the Data Registry (DR) from Data Memory(RAM)

module MUX
  (
    i_in0,
	i_in1,
	i_sel,
	o_out
	);
	
  input [7:0] i_in0; // Instruction Register (IR) for both 1 and 2
  
  input [7:0] i_in1; // pc_adder output for 1, (DR) for 2
  
  input i_sel;
  
  output [7:0] o_out; // input into program counter for 1, second pc_adder input for 2
  
assign o_out = ( i_sel == 1'b1 ) ? i_in0 : i_in1; // selects first input if high, otherwise it selects the second input

endmodule
  
// Note that assign is used, if we had a more complex multiplexer with more than 2 inputs or selects, then a case statement would be preferrable for readability
