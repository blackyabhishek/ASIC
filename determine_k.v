`timescale 1ns / 100ps
module determine_k(A,N2,k);
// synopsys template
input [11:0] A;
input [2:0] N2;
output [1:0] k;
reg [1:0] outp;
///wire signed [11:0] temp;
wire [11:0] temp;
wire [3:0] lead1A;
wire [2:0] lead1N;
reg [3:0] leadA;
reg [2:0] leadN;
///wire signed [3:0] difference;
wire [3:0] difference;
wire [11:0] shifted_N;
wire [3:0] N;
assign N={N2,1'b0};
assign lead1A = leadA;
assign lead1N = leadN;
assign difference = lead1A-{1'b0,lead1N};
// above statement is dicy, look into it 
assign shifted_N = N << difference[1:0];
assign temp = A - shifted_N;
assign k = outp;

always @(*)
begin
case (1'b1)
A[11] : leadA = 11;
A[10] :  leadA = 10;
A[9] :  leadA = 9;
A[8] :  leadA = 8;
A[7] :  leadA = 7;
A[6] :	leadA = 6;
A[5] :	leadA = 5;
A[4] :	leadA = 4;
A[3] :	leadA = 3;
A[2] :	leadA = 2;
A[1] :	leadA = 1;
A[0] :	leadA = 0;
default : leadA = 0;
endcase
end
always @(*)
begin
case (1'b1)
N[3] : leadN = 3'd3;
N[2] : leadN = 3'd2;
N[1] : leadN = 3'd1;
N[0] : leadN = 3'd0;
default : leadN = 0;
endcase
end

always @ (*)
begin
	if(difference[3] == 1'b1)
	begin
		outp = 2'b00;
	end
	else if (difference >= 4'b0011)
	begin
		outp = 2'b11;
	end
	else
	begin
		
		if(temp[11] ==  1'b0 && temp != 12'b000000000000)
			outp = difference[1:0] +1;
		else
			outp = difference[1:0];
			
	end
	
end
endmodule
