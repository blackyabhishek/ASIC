`timescale 1ns / 1ps
module dpcm(clk,reset,x_in,yuvselector,valid,x_out);
// synopsys template
parameter input_bits = 8;
input [(input_bits-1):0] x_in;
input [1:0] yuvselector;
input valid;
input reset;
input clk;
output [input_bits:0] x_out;
reg [(input_bits-1):0] y_prev,u_prev,v_prev;
reg [(input_bits-1):0] selected;
assign x_out = {x_in[input_bits-1],x_in} - {selected[input_bits-1],selected};
always @(*)
begin
	case(yuvselector)
		2'b00 : selected = y_prev;
		2'b01 : selected = u_prev;
		2'b10 : selected = v_prev;
	default : selected = v_prev;
	endcase
end
always @(posedge clk)
begin
	if(reset)
	begin
		y_prev <=0;
		u_prev <=0;
		v_prev <=0;
	end
	else
	begin
		if(valid)
		begin
			case(yuvselector)
			2'b00 : y_prev <= x_in;
			2'b01 : u_prev <= x_in;
			2'b10 : v_prev <= x_in;
			endcase
		end
	end
end
endmodule
