`timescale 1ns / 1ps

module Quantizer(YUV,YUV_Quantized);
// synopsys template
input wire [8:0] YUV;
output wire [5:0] YUV_Quantized;
wire [6:0] YUV_Round;
assign YUV_Round = YUV[8:2]+1'b1;
assign YUV_Quantized=(YUV_Round==7'b1000000)?6'b011111:YUV_Round[6:1];

endmodule
