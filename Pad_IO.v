`timescale 1ns / 1ps

module Pad_IO(Pad_CLK_8,Pad_RESET,Pad_Pixel,Pad_OB,Pad_SCLK);

input wire Pad_CLK_8,Pad_RESET;
input wire[7:0] Pad_Pixel;
output wire Pad_OB,Pad_SCLK;

wire Reset,CLK_8,OB,SCLK;
wire [7:0] Pixel;

XMHA IN_CLK_8(CLK_8,Pad_CLK_8,1'b0,1'b0,1'b0);

XMHA IN_Reset(Reset,Pad_Reset,1'b0,1'b0,1'b0);

XMHA IN_Pixel_0(Pixel[0],Pad_Pixel[0],1'b0,1'b0,1'b0);
XMHA IN_Pixel_1(Pixel[1],Pad_Pixel[1],1'b0,1'b0,1'b0);
XMHA IN_Pixel_2(Pixel[2],Pad_Pixel[2],1'b0,1'b0,1'b0);
XMHA IN_Pixel_3(Pixel[3],Pad_Pixel[3],1'b0,1'b0,1'b0);
XMHA IN_Pixel_4(Pixel[4],Pad_Pixel[4],1'b0,1'b0,1'b0);
XMHA IN_Pixel_5(Pixel[5],Pad_Pixel[5],1'b0,1'b0,1'b0);
XMHA IN_Pixel_6(Pixel[6],Pad_Pixel[6],1'b0,1'b0,1'b0);
XMHA IN_Pixel_7(Pixel[7],Pad_Pixel[7],1'b0,1'b0,1'b0);


YA28SHA OUT_OB(Pad_OB,OB,1'b0,1'b0,1'b0,1'b0);

YA28SHA OUT_SCLK(Pad_SCLK,SCLK,1'b0,1'b0,1'b0,1'b0);

Compressor Comp(CLK_8,Reset,RGB,OB,SCLK);


endmodule