`timescale 1ns / 100ps
module adaptive_golomb(clk,reset,x_in,yuvselector,valid,CWL,CW);
// synopsys template
input [8:0] x_in;
input [1:0] yuvselector;
input valid;
input reset;
input clk;
output [15:0] CW;
output [4:0] CWL;
/// for now assume Y = 0, U = 1, V = 2.
/// Assume X_in is in 2's complement format
reg [11:0] ACY;
reg [11:0] ACU;
reg [11:0] ACV;
reg [2:0] NY;
reg [2:0] NU;
wire [8:0] mapped_x_in;
wire [1:0] k;

reg [11:0] A_in;
reg [2:0] N_in; 
mapper mapper1(x_in,mapped_x_in);
determine_k kfinder(A_in,N_in,k);
golomb_encoder golomb_comb(k,mapped_x_in,CWL,CW);
always @(*)
begin
	case(yuvselector)
	2'b00 : 
	begin
		A_in = ACY;
		N_in = NY;
	end
	2'b01 :
	begin
		A_in = ACU;
		N_in = NU;
	end
	2'b10 :
	begin
		A_in = ACV;
		N_in = NU;
	end
	2'b11 :
	begin
		A_in = ACY;
		N_in = NY;
	end
	endcase
end
always @(posedge clk)
begin
	if(reset)
		begin
			ACY <= 0;
			ACU <= 0;
			ACV <= 0;
			NY <=0;
			NU <=0;
		end
	else
		begin
			if(valid)
			begin
				case (yuvselector)
				2'b00 : 
				begin	
					if (NY == 3'b111)
					begin
						NY <= 3'b011;
						ACY <= {1'b0,ACY[11:1]};
						
					end
					else
					begin
						ACY <= ACY + mapped_x_in;
						NY <= NY + 1'b1;
					end	
				end
				
				2'b01 : 
				begin
					if (NU == 3'b111)
					begin
						///NU <= 3'b011;
						ACU <= {1'b0,ACU[11:1]};	
					end
					else
					begin
						ACU <= ACU + mapped_x_in;
						///NU <= NU + 1;
					end
				end

				2'b10 :
				begin
					if (NU == 3'b111)
					begin
						NU <= 3'b011;
						ACV <= {1'b0,ACV[11:1]};	
					end
					else
					begin
						ACV <= ACV + mapped_x_in;
						NU <= NU + 1'b1;
					end	
				end
				endcase
			end
		end
end
		
endmodule
