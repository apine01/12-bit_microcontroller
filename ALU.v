//  Arithmetic Logic Unit (ALU)
// select input width
module ALU
  #(parameter DATA_WIDTH = 8)
  (
  ALU_sel,
  ALU_en,
  i_A,
  i_B,
  ALU_out,
  ALU_cout,
  ALU_overflow,
  ALU_zero,
  ALU_signed
  );
  
  input [3:0] ALU_sel;  // selects which operation will be done on A and B
  
  input ALU_en;         // enables ALU
  
  input [DATA_WIDTH-1:0] i_A;
 
  
  input [DATA_WIDTH-1:0] i_B;
  
  output reg [DATA_WIDTH-1:0] ALU_out;  // output after arithmetic has been done
  
  output ALU_cout;                      // carry out if computation exceeds limits
  
  output ALU_overflow;                  // overflows when operation leaks into signed bit
    
  output ALU_zero;                      // outputs if all zeros
  
  output ALU_signed;                    // Sgned bit
  
  // some wire connections
  wire [DATA_WIDTH-1:0] A;
   assign A = i_A;  // easy readbility 
  wire [DATA_WIDTH-1:0] B;
   assign B = i_B;  // easy readbility 
   
// failsafe, carry out
  wire [DATA_WIDTH:0] flag; 
  assign flag = {1'b0,i_A} + {1'b0,i_B};
  assign ALU_cout = flag[DATA_WIDTH];     // sends out flag when MSB is used
  
//----------------------------------------------------------------------------------------------

always @(*) begin
  if (ALU_en == 1'b1) begin
    case(ALU_sel)
      4'b0000 :              // addition
        ALU_out = A + B;
      4'b0001 :              // increment A
        ALU_out = A + 1;
      4'b0010 :              // increment A
        ALU_out = B + 1;
      4'b0011 :              // subtraction 
        ALU_out = A - B;
      4'b0100 :              // decrement A
        ALU_out =  A - 1;
      4'b0101 :              // decrement B
        ALU_out = B - 1;
      4'b0110 :              // multiplication  
        ALU_out = A * B;
      4'b0111 :              // division 
        ALU_out = A / B;
      4'b1000 :              // AND 
        ALU_out = A & B;
      4'b1001 :              // NAND
        ALU_out = ~(A & B);
      4'b1010 :              // OR
        ALU_out = A | B; 
      4'b1011 :              // NOR
         ALU_out = ~(A | B);
      4'b1100 :              // XOR
        ALU_out = A ^ B;
      4'b1101 :              // XNOR
        ALU_out = ~(A ^ B);
      4'b1110 :              // transfer A
        ALU_out = A;
      4'b1111 :              // transfer B  
        ALU_out = B;        
      default : 
        ALU_out = A + B;   // default value
    endcase
  end
  
  else 
    ALU_out = 0;
end  
  
  assign ALU_overflow = ( ALU_out[7] == (A[7] && B[7]) ) ? 1'b0 : 1'b1;
  
  assign ALU_zero = (ALU_out) ? 1'b0 : 1'b1;
  
  assign ALU_signed = ALU_out[7]; 

endmodule 