// Microcontroller
// 12 bit instructions, 3 instruction types (inputs) -> (result stored)
// M type - accumulator, data memory -> accumulator, data memory
// I type - accumulator, encoded instruction -> accumulator 
// S type - no inputs -> no operation, move on to next instruction

`include "Microcontroller_mods.v"
`include "Pmem.v"
`include "Dmem.v"
`include "control_unit.v"
`include "ALU.v"

// The IR, PC, Control Logic, DR, Accumulator and SR will be made here
module Microcontroller
  (
    i_clk,
	i_reset
	);

  input i_clk;
  
  input i_reset;
  
  // regs
  
  reg [11:0] r_program_data [16:0];   // Our txt file has 17 lines of 8 bit numbers
  
  reg [11:0] r_IR_out = 12'b0;      // Instruction register output
  reg        r_IR_clr;              // clears instruction register
  
  reg [7:0] r_DR_out = 8'b0;       // Data register output
  reg       r_DR_clr;              // clears data register
  
  reg [3:0] r_SR_out = 4'b0;       // Status register, updates every clock
  reg       r_SR_clr;              // clears status register
  
  reg [7:0] r_PC_out = 8'b0;       // Program counter output
  reg       r_PC_clr;              // clears Program counter
  
  
  reg [7:0] r_Acc_result = 8'b0;              // Accumalator with ALU result
  reg [7:0] r_Acc_operand = 8'b0;             // holds operand from ALU
  reg       r_Acc_clr;                        // clears accumalator

  reg [1:0] r_Current_Stage = 2'b0;           // stage in current clock cycle
  reg [1:0] r_Next_Stage;                     // stage for next clock cycle
  
  
  reg [7:0]  r_load_Addr = 8'b0;             // address of instruction to be loaded
  
  reg             r_done = 1'b0;             // checks if loading is done, high if it is
  
  wire [11:0] w_load_Instr;                 // instruction that is laoded
  
  // wires
  wire [7:0] w_PCadder_out;                  // first input of MUX1
  
  wire [7:0] w_MUX2_out;                    // MUX2 output
  
  wire [7:0] w_PC_in;                       // program counter input
  
  wire [11:0] w_Pmem_out;                   // program memory output
  
  wire [7:0] w_ALU_out;                     // ALU arithematic output
  
  wire [7:0] w_Dmem_read;                   // data memory read output     
  
  wire w_PC_en, w_Acc_en, w_SR_en, w_IR_en, w_DR_en, w_Pmem_en, w_Pmem_Len, w_Dmem_en, w_Dmem_Wen, w_ALU_en, w_MUX1_sel, w_MUX2_sel; // wire enables for control unit
  
  wire [3:0] w_ALU_mode;
  
  wire [3:0] w_SR_in;  // Updates to be made to status register
  
  
  parameter LOAD = 2'b00, FETCH = 2'b01, DECODE = 2'b10, EXECUTE = 2'b11;       // all stages

  
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////





//-------------------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------	
// Load section
//-----------------------------------------------------------------------------------------------------------------	
//-------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------- 

// read desired memory file

initial $readmemb("C:/Users/alanp/txt_files/pmemdata.dat", r_program_data, 0, 9);    // 10 addresses
 
assign w_load_Instr = r_program_data[r_load_Addr]; 

// Loading addresses when the loading pmem enable is on
always @(posedge i_clk) begin
  if (w_Pmem_Len == 1'b1 && r_load_Addr<9)    // increments address to be loaded if program memory load is enabled and the address has not exceeded its maximum
    r_load_Addr <= r_load_Addr + 1;  
   
  else if (r_load_Addr == 8'd9) begin        // once maximum address is reached, it resets it to 0 and sets the done register to high
    r_load_Addr <= 8'b0;          
	r_done      <= 1'b1;
  end
  
  else if (i_reset == 1'b1) begin                   // when reseted, the address to be loaded and the done register are set to 0 
    r_done      <= 1'b0;
	r_load_Addr <= 8'b0;
  end
  
  else                                    // if not done loading, the done register is low, does not change stages unitl it is high
    r_done <= 1'b0;
end


// Cycles through stages 
always @(posedge i_clk) begin
  if (i_reset == 1'b1)
    r_Current_Stage <= LOAD;
  else 
    r_Current_Stage <= r_Next_Stage;
end 
	
	
  
// State machine to cycle through stages
always @(*) begin // always sets clears to 0 unless load is done
  r_IR_clr  <= 1'b0;
  
  r_SR_clr  <= 1'b0;
  
  r_Acc_clr <= 1'b0;
  
  r_PC_clr  <= 1'b0;
  
  r_DR_clr  <= 1'b0;
  
  case(r_Current_Stage)
    LOAD : begin 
	  if (r_done == 1'b1) begin
	  
        r_IR_clr <= 1'b1;
  
        r_SR_clr <= 1'b1;
  
        r_Acc_clr <= 1'b1;
  
        r_PC_clr <= 1'b1;
  
        r_DR_clr <= 1'b1;
	  
	    r_Next_Stage <= FETCH;
	  end
	 
	  else 
	    r_Next_Stage <= LOAD;
	end
	
	FETCH :
	  r_Next_Stage <= DECODE;
	
	DECODE :
	  r_Next_Stage <= EXECUTE;
	
	EXECUTE : 
	  r_Next_Stage <= FETCH;
  endcase
end



//-------------------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------	
// Fetch section
//-----------------------------------------------------------------------------------------------------------------	
//-------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------- 

	
//-----------------------------------------------------------------------
// Multiplexer 1
//---------------{{{{{{{{{{{ 						
MUX  mux1
  (
    .i_in0(w_PCadder_out),  // program counter adder is second input
	.i_in1(r_IR_out[7:0]),   // instruction register output is first input
	.i_sel(w_MUX1_sel),      // selects adder output if high, else it selects IR
	.o_out(w_PC_in)          // output will be the input to the program counter, NOT the adder
	);
//--------------------------}}}}}}}}}}}


//-----------------------------------------------------------------------	
// Program counter adder
//---------------{{{{{{{{{{{ 						
pc_adder adder0
  (
    .i_Adder(r_PC_out),     // adder input is program counter input
	.o_Adder(w_PCadder_out)      // will be input to MUX1
	);
//--------------------------}}}}}}}}}}}

	
//-----------------------------------------------------------------------
// Program counter
//---------------{{{{{{{{{{{ 						
always @(posedge i_clk) begin    // if enabled, the program counter gets updated, cleared once the clear port is high. reset takes priority
  if (i_reset == 1'b1)
    r_PC_out <= 8'b0;
  
  else begin 
    if (w_PC_en == 1'b1)        
      r_PC_out <= w_PC_in;
    else if (r_PC_clr == 1'b1)
      r_PC_out <= 8'b0;
  end
end 
//--------------------------}}}}}}}}}}}


//-----------------------------------------------------------------------	
// Program memory
//---------------{{{{{{{{{{{ 						
Pmem pmem0
  (
    .i_clk(i_clk),
	.i_en(w_Pmem_en),        // enable for program memory
	.i_Addr(r_PC_out),       // program memory input address is the program counter output
	.i_Len(w_Pmem_Len),      // enable for porgram memory laoding
	.i_L_Addr(r_load_Addr),  // address to be loaded from instruction
	.i_L_Instr(w_load_Instr), // instruction to be loaded
	.o_ReadInstr(w_Pmem_out)  // output of program memory, will be input to instruction register
	);
//--------------------------}}}}}}}}}}}
	

//-----------------------------------------------------------------------
// Instructions Register (IR)
//---------------{{{{{{{{{{{ 						
always @(posedge i_clk) begin  // if enabled, takes program memory output as its value, set to 0 when the clear is high
  if (w_IR_en == 1'b1)
    r_IR_out <= w_Pmem_out;    // will be connected to control unit input, the first 8 bits to first input of both multiplexers, and the first 4 bits to data memory address
  else if (r_IR_clr == 1'b1)
    r_IR_out <= 12'b0;
end 
//--------------------------}}}}}}}}}}}







//-------------------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------	
// Decode section
//-----------------------------------------------------------------------------------------------------------------	
//-------------------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------

//-----------------------------------------------------------------------
// Control unit
//---------------{{{{{{{{{{{ 						
control_unit cu0                 // all enables, ALU mode, and multiplexer selects
  (
    .i_InstrR(r_IR_out),
	.i_Stage(r_Current_Stage),
	.i_SR(r_SR_out),
	.PC_en(w_PC_en), 
	.Acc_en(w_Acc_en), 
	.SR_en(w_SR_en), 
	.IR_en(w_IR_en), 
	.DR_en(w_DR_en), 
	.Pmem_en(w_Pmem_en),
    .Pmem_Len(w_Pmem_Len),	
	.Dmem_en(w_Dmem_en), 
	.Dmem_Wen(w_Dmem_Wen), 
	.ALU_en(w_ALU_en), 
	.ALU_mode(w_ALU_mode),    // chooses which operation will be done
	.MUX1_sel(w_MUX1_sel), 
	.MUX2_sel(w_MUX2_sel)
	);
	
//--------------------------}}}}}}}}}}}


//-----------------------------------------------------------------------
// Data memory
//---------------{{{{{{{{{{{ 						
Dmem dmem0
  (
    .i_clk(i_clk),
	.i_en(w_Dmem_en),        // enable for data memory
	.i_Wen(w_Dmem_Wen),      // write enable for data memory
	.i_Addr(r_IR_out[3:0]),  // address to be written or read
	.i_WriteData(w_ALU_out), // data that will be written in address
	.o_ReadData(w_Dmem_read) // data read from selected address for datat memory
	);
//--------------------------}}}}}}}}}}}
	
	
//-----------------------------------------------------------------------
// Data Register (DR)
//---------------{{{{{{{{{{{ 						
always @(posedge i_clk) begin // if enabled, data register will hold the read output of datat memory until it is cleared
  if (w_DR_en == 1'b1)
    r_DR_out <= w_Dmem_read;
  else if (r_DR_clr == 1'b1)
    r_DR_out <= 12'b0;       // data register output will be second input of MUX2
end 
//--------------------------}}}}}}}}}}}






//-------------------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------	
// Execute section
//-----------------------------------------------------------------------------------------------------------------	
//-------------------------------------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------------

//-----------------------------------------------------------------------
// Multiplexer 2
//---------------{{{{{{{{{{{ 						
MUX mux2
  (
    .i_in0(r_DR_out),           // first input is data register output
	.i_in1(r_IR_out[7:0]),      // second 8 bits of instruction register    
	.i_sel(w_MUX2_sel),         // selects DR if high, else it selects IR
	.o_out(w_MUX2_out)            
	);
//--------------------------}}}}}}}}}}}


//-----------------------------------------------------------------------
// ALU
//---------------{{{{{{{{{{{ 						
ALU alu0
  (
  .ALU_sel(w_ALU_mode),      // selects which operation will be done
  .ALU_en(w_ALU_en),         // enable for ALU
  .i_A(r_Acc_operand),       // first operand is output of Accumalator which holds the value
  .i_B(w_MUX2_out),          // second operand is output selected by MUX2
  .ALU_out(w_ALU_out),       
  .ALU_cout(w_SR_in[2]),     // carry bit
  .ALU_overflow(w_SR_in[0]), // overflow flag
  .ALU_zero(w_SR_in[3]),     // zero flag
  .ALU_signed(w_SR_in[1])    // sign bit
  );
//--------------------------}}}}}}}}}}}


//-----------------------------------------------------------------------
// Accumulator (Acc)
//---------------{{{{{{{{{{{ 						
always @(posedge i_clk) begin
  if (i_reset == 1'b1)            // reset take priority again
    r_Acc_operand <= 8'b0;
	
  else begin
    if (w_Acc_en == 1'b1)          // if enabled, stores ALU value, unless it is cleared
      r_Acc_operand <= w_ALU_out;
	
    else if (r_Acc_clr == 1'b1)
      r_Acc_operand <= 8'b0;
  end
end
//--------------------------}}}}}}}}}}}


//-----------------------------------------------------------------------
// Status Register (SR)
//---------------{{{{{{{{{{{ 						
always @(posedge i_clk) begin // if enabled, stores flag values outputted from ALU, set to 0 when cleared.
  if (i_reset == 1'b1)
    r_SR_out <= 4'b0;

  else begin
    if (w_SR_en == 1'b1) 
      r_SR_out <= w_SR_in;
    else if (r_SR_clr)
      r_SR_out <= 4'b0;
  end
end
//--------------------------}}}}}}}}}}}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

endmodule