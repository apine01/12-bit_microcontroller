// Control unit for micro controller
// M,I,S type

module control_unit
  (
    i_InstrR,
	i_Stage,
	i_SR,
	PC_en, Acc_en, SR_en, IR_en, DR_en, 
	Pmem_en, Pmem_Len, Dmem_en, Dmem_Wen, 
	ALU_en, ALU_mode, 
	MUX1_sel, MUX2_sel
	);
	
  input [11:0] i_InstrR;  // M type - 0010_0000_0000 - 0011_1111_1111 ALU instructions
                          // I type - 0001_0000_0000 - 0001_1111_1111 unconditional jump
						  //        - 0100_0000_0000 - 0111_1111_1111 conditional jump 
                          //        - 1000_0000_0000 - 1111_1111_1111 ALU instructions
						  // S type - 0000_0000_0000 - 0000_1111_1111 special instructions

  
  input [1:0] i_Stage;   // Four stages
                         // LOAD (initial state - 00): load program to program memory, 1 cycle per instruction loaded
						 // FETCH (first cycle - 01): fetch current instruction from program memory
						 // DECODE (second cycle - 10): decode instruction to generate control logic, read data memory for operand
						 // EXECUTE (third cycle - 11): execute instruction

  input [3:0] i_SR;     // status register that holds ALU flags
  
  output reg PC_en, Acc_en, SR_en, IR_en, DR_en, Pmem_en, Pmem_Len, Dmem_en, Dmem_Wen, ALU_en, MUX1_sel, MUX2_sel;
  
  output reg [3:0] ALU_mode;
  
//-----------------------------------------------------------------------------------------------------------------------------------------------
// to set dont care bits, use AND conditional
// Example for M type, 4'b001x condition can be written as <i_InstrR && 4'b1110 == 4'b0010>
// Put 0 on bits that dont matter for deciding the instruction type

  parameter  M_type = 4'b0010;
  
  parameter I_type0 = 4'b0001, I_type1 = 4'b0100, I_type2 = 4'b1000;
  
  parameter  S_type = 4'b0000;
  
  parameter LOAD = 2'b00, FETCH = 2'b01, DECODE = 2'b10, EXECUTE = 2'b11;

//-------------------------------------------------------------------------------------------------------------------------
  
always @(*) begin
    // values stay 0 until an if statement changes them, no else statement, since it wont do them simultenously
	// makes it cleaner and easier to write stages
    PC_en    = 1'b0;
	Acc_en   = 1'b0;
	SR_en    = 1'b0;
	IR_en    = 1'b0;
	DR_en    = 1'b0;
	Pmem_en  = 1'b0;
	Pmem_Len = 1'b0;
	Dmem_en  = 1'b0;
	Dmem_Wen = 1'b0;
	ALU_en   = 1'b0;
	ALU_mode = 4'b0000;
	MUX1_sel = 1'b0;
	MUX2_sel = 1'b0;
	
  // S type, 0000 -----------------------------------------------
  
  // S type fetch
  if ( i_InstrR[11:8] == S_type && i_Stage == FETCH ) begin
	IR_en    = 1'b1;
	Pmem_en  = 1'b1;
  end
  
  // S type decode 
  // Doesnt need to do anything

  // S type execute
  if ( i_InstrR[11:8] == S_type && i_Stage == EXECUTE ) begin
    PC_en    = 1'b1;
    MUX1_sel = 1'b1;
  end
  
  // I type unconditional jump, 0001 -----------------------------------------------------
  
  // I type unconditional jump fetch 
  if ( i_InstrR[11:8] == I_type0 && i_Stage == FETCH) begin
	IR_en    = 1'b1;
	Pmem_en  = 1'b1;
  end
  
  // I type unconditional jump decode 
  // Doesnt need to do anything

  // I type unconditional jump execute  
  if ( i_InstrR[11:8] == I_type0 && i_Stage == EXECUTE)
	PC_en    = 1'b1;
  
  // M type, 0010 -----------------------------------------------------
  
  // M type fetch 
  if ( i_InstrR[11:8] && 4'b1110 == M_type && i_Stage == FETCH) begin
    IR_en   = 1'b1;
	Pmem_en = 1'b1;
  end
  
  // M type decode
  if ( i_InstrR[11:8] && 4'b1110 == M_type && i_Stage == DECODE) begin
    DR_en   = 1'b1;
	Dmem_en = 1'b1;
  end
  
  // M type execute 
  if ( i_InstrR[11:8] && 4'b1110 == M_type && i_Stage == EXECUTE) begin
    PC_en    = 1'b1;
	Acc_en   = i_InstrR[8];
	SR_en    = 1'b1;
	Dmem_en  = ~i_InstrR[8];
	Dmem_Wen = ~i_InstrR[8];
	ALU_en   = 1'b1;
	ALU_mode = i_InstrR[7:0];
	MUX1_sel = 1'b1;
	MUX2_sel = 1'b1;
  end

  // I type conditional jump, 0100 -----------------------------------------------------
  
  // I type conditional jump fetch
  if ( i_InstrR[11:8] && 4'b1100 == I_type1 && i_Stage == FETCH) begin
    IR_en   = 1'b1;
	Pmem_en = 1'b1;
  end
  
  // I type conditional jump decode
  // Does not need to do anything
  
  // I type conditional jump execute
  if ( i_InstrR[11:8] && 4'b1100 == I_type1 && i_Stage == FETCH) begin
    PC_en    = 1'b1;
	MUX1_sel = i_SR[i_InstrR[9:8]];
  end
  
  // I type ALU instructions, 1000 -----------------------------------------------------
  
  // I type ALU fetch
  if ( i_InstrR[11:8] && 4'b1000 == I_type2 && i_Stage == FETCH) begin
    IR_en   = 1'b1;
	Pmem_en = 1'b1;
  end

  // I type ALU decode
  // doesnt need to do anything

  // I type ALU execute 
  if ( i_InstrR[11:8] && 4'b1000 == I_type2 && i_Stage == FETCH) begin
    PC_en    = 1'b1;
	Acc_en   = 1'b1;
	SR_en    = 1'b1;
	ALU_en   = 1'b1;
	ALU_mode = {1'b0,i_InstrR[10:8]};
	MUX1_sel = 1'b1;
  end
  
  // Loading state 
  
  if (i_Stage == LOAD) begin
    Pmem_Len = 1'b1;
	Pmem_en  = 1'b1;
  end
end
endmodule