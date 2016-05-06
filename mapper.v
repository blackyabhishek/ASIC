`timescale 1ns / 100ps
module mapper(x_in,mapped_x_in);
// synopsys template
input [8:0] x_in;
output [8:0] mapped_x_in;
reg [8:0] outp;
wire [8:0] not_x;
assign not_x = ~x_in;
assign mapped_x_in = outp;
always @(*)
begin
	if(x_in[8] == 1'b1)
	begin
		outp = {not_x[7:0],1'b0} + 1'b1;
	end
	else
	begin
		outp = {x_in[7:0],1'b0};
	end
end
endmodule
