`timescale 1ns / 100ps
module golomb_encoder(k,x_in,CWL,CW);
// synopsys template
parameter input_bits = 9;
parameter glimit = 16;
parameter code_word_length = 4;
input [(input_bits-1):0] x_in;
input [1:0] k;
output [(glimit-1):0] CW;
output [(code_word_length):0] CWL;
/// take care of code word leneght. It is actual length that is 1-16 (o not included ) so requires 5 bits

wire [(input_bits-1):0] quotient;
wire [(input_bits-1):0] for_remainder;
//wire [(input_bits-1):0] remainder;
wire [2:0] remainder;
reg [(code_word_length):0] CWL1;
reg [(glimit-1):0] CW1;
wire [(glimit-1):0] CW2;
assign quotient = x_in >> k;
//assign remainder = x_in[3:0] & (1<<(k+1) -1);
assign for_remainder = quotient << k;
assign remainder = for_remainder[2:0] ^ x_in[2:0];
// acheive the above with just one shifter  (Two shifters is a pain)

//assign CW = (CW1 << k) + remainder;
/// instead of adding, we could do an OR operation
//assign CW2 = (CW1 << k) | {13'b0000000000000,remainder};
assign CW2 = (remainder<<(quotient[2:0]+1'b1)) | CW1;
assign CW = (quotient > 9'b000000110) ? CW1:CW2; 
//assign CWL = CWL1;
assign CWL = (quotient > 9'b000000110) ? 5'b10000:(k+1'b1+ quotient[3:0]);
always @(*)
	begin
	case (quotient[8:0])
		9'b000000000 : CW1 = 16'b0000000000000000;
		9'b000000001 : CW1 = 16'b0000000000000001;
		9'b000000010 : CW1 = 16'b0000000000000011;
		9'b000000011 : CW1 = 16'b0000000000000111;
		9'b000000100 : CW1 = 16'b0000000000001111;
		9'b000000101 : CW1 = 16'b0000000000011111;
		9'b000000110 : CW1 = 16'b0000000000111111;
		//4'b0111 : CW1 = 16'b0000000011111110;
		///4'b1000 : CW1 = 16'b0000000111111110;
		default : CW1 = {x_in,7'b1111111}; 
	endcase
	//if (quotient > 9'b000000110)
///		begin
///		CWL1 = 5'b10000;
//		end
//	else
//		begin
//		CWL1 = k+1+quotient[3:0];
///		end
	end
endmodule
