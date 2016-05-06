`timescale 1ns / 1ps

module Compressor(CLK_8,RESET,Pixel,OB,SCLK);
//module Compressor(CLK,RESET,Pixel,VC,CWL,CW);
input wire RESET,CLK_8;
input wire [7:0] Pixel;
output wire OB,SCLK;

wire [15:0] CW;
wire [4:0] CWL;
//output wire [15:0] CW;
//output wire [4:0] CWL;
//output wire VC;
wire VC;
wire Valid_Sub_Sampler;
wire Clipped,New_Frame;
assign VC=Valid_Sub_Sampler & ~Clipped;

wire CLK;
wire [7:0] Row_Number,Column_Number;
wire [1:0] YUV_Turn;
wire Alternate,Active_1,Valid_1,Active_2,Valid_2,First_Pixel,Third_Pixel;
Control_Unit CU(CLK,CLK_8,RESET,Clipped,Row_Number,Column_Number,YUV_Turn,Valid_Sub_Sampler,Alternate,Active_1,Valid_1,Active_2,Valid_2,First_Pixel,Third_Pixel,New_Frame);

wire RESET2;
assign RESET2=RESET | New_Frame;

corner_clipper Clipper(Row_Number,Column_Number,Clipped);

wire [7:0] R,G,B;
RGB RGB_Pixel_Storage(CLK,RESET2,Pixel,YUV_Turn,Alternate,R,G,B);

wire [8:0] YUV;
Forward_RCT RGB_TO_YUV(YUV_Turn,R,G,B,YUV);

wire [5:0] YUV_Quantized;
Quantizer Qua(YUV,YUV_Quantized);
wire yo;
assign yo = 1'b1;
wire [6:0] S_n_1;
DWT DWT_Level_1(CLK,RESET2,Clipped,First_Pixel,yo,Valid_1,YUV_Turn,YUV_Quantized,S_n_1);

wire [7:0] S_n_2;
DWT #(7) DWT_Level_2(CLK,RESET2,Clipped,Third_Pixel,Active_2,Valid_2,YUV_Turn,S_n_1,S_n_2);

wire [7:0] DPCM_In;
wire [8:0] DPCM_Out;
assign DPCM_In=(YUV_Turn==2'b00)?{YUV_Quantized[5],YUV_Quantized[5],YUV_Quantized}:S_n_2;
dpcm DPCM_calculate(CLK,RESET2,DPCM_In,YUV_Turn,VC,DPCM_Out);


adaptive_golomb Encoder(CLK,RESET2,DPCM_Out,YUV_Turn,VC,CWL,CW);
Serializer Ser(CLK_8,RESET,CW,CWL,VC,OB,SCLK);

endmodule
