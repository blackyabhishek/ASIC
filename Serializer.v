`timescale 1ns / 1ps
module Serializer(CLK_8,Reset,CW,CWL,VC,OB,SCLK);
input wire CLK_8,Reset,VC;
input wire[15:0] CW;
input wire[4:0] CWL;

output wire SCLK;
output wire OB;

reg[5:0] Buffer_Occupancy;
reg[39:0] FIFO;
reg[2:0] Clock_Matcher;

wire [39:0] Barrel_Output;
wire[5:0] Shift;
wire[5:0] S;
wire[5:0] Push_Index;
wire Empty_Buffer,Input_Time,Valid_Input_Time;

assign Input_Time=(Clock_Matcher==3'b000)?(1'b1):(1'b0);
assign Empty_Buffer=(Buffer_Occupancy==6'b000000)?(1'b1):(1'b0);
assign Push_Index=Buffer_Occupancy-6'b000001;
assign S=(Empty_Buffer)?(Buffer_Occupancy):(Push_Index);
assign Shift=(Input_Time)?(S):(6'b000000);
assign Barrel_Output=CW<<<Shift;
assign Valid_Input_Time=VC & Input_Time;
assign OB=FIFO[0];
//assign SCLK=CLK_8 & ~Empty_Buffer;
assign SCLK = ~Empty_Buffer;
always @(posedge CLK_8)
begin
    if(Reset) begin
        Clock_Matcher<=3'b000;
    end else begin
        Clock_Matcher<=Clock_Matcher+1;
    end
end

genvar i;
generate
    for(i=0;i<40;i=i+1) begin : shift
        if(i<39) begin
            always @(posedge CLK_8) begin
                if(Reset) begin
                    FIFO[i]<=1'b0;
                end else begin
                    FIFO[i]<=(FIFO[i+1] | (Valid_Input_Time & Barrel_Output[i]));
                end
            end
        end else begin
            always @(posedge CLK_8) begin
                if(Reset) begin
                    FIFO[i]<=1'b0;
                end else begin
                    FIFO[i]<=(Valid_Input_Time & Barrel_Output[i]);
                end    
            end
        end
    end
endgenerate



always @(posedge CLK_8)
begin  
    if(Reset) begin
        Buffer_Occupancy<=6'b000000;
    end else if(Input_Time) begin
        if(VC) begin
            if(Empty_Buffer) begin
                Buffer_Occupancy<={1'b0,CWL};
            end else begin
                Buffer_Occupancy<=Push_Index+CWL;
            end
        end else begin
            if(Empty_Buffer) begin
               Buffer_Occupancy <= Buffer_Occupancy;
            end else begin
                Buffer_Occupancy<=Push_Index;
            end
        end
     end else begin
        if(Empty_Buffer) begin
            Buffer_Occupancy <= Buffer_Occupancy;
        end else begin
            Buffer_Occupancy<=Push_Index;
        end
     end
 end
        
endmodule
