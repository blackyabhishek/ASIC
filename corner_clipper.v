`timescale 1ns / 1ps
module corner_clipper(row_number,col_number,clipped);
// synopsys template
parameter bits = 8;
input [(bits-1):0] row_number;
input [(bits-1):0] col_number;
output clipped;
/// if clipped = 1 then, remove the pixel
wire [bits:0] addition;
wire signed [bits:0] subtraction;
wire comp1,comp2,comp3,comp4,comp5,comp6;
assign addition = {1'b0,row_number} + {1'b0,col_number};
assign subtraction = {1'b0,col_number} - {1'b0,row_number};
assign comp1 = (addition < 75) ? 1'b1:1'b0;
assign comp2 = (addition > 435) ? 1'b1:1'b0;
assign comp3 = (subtraction > 180) ? 1'b1:1'b0;
assign comp4 = (subtraction < -180) ? 1'b1:1'b0;
//assign comp5 = (addition == 75) ? 1'b1:1'b0;
//assign comp6 = (subtraction == -180) ? 1'b1:1'b0;
//assign comp7 = (row_number < 180 && row_number> 75 && col_number==0) ? 1'b1:1'b0;
assign clipped = comp1 | comp2 | comp3 | comp4;
//assign seed_pixel = comp5 | comp6 | comp7;
endmodule
