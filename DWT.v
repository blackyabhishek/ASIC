`timescale 1ns / 1ps

module DWT(Input_CLK,Reset,Clipped,First_Pixel,Active,Valid,YUV_turn,X_n,S_n);
// synopsys template
parameter SIZE=6;

input wire Input_CLK,Reset,Clipped,Active,Valid,First_Pixel;
input wire [1:0] YUV_turn;
input wire [SIZE-1:0] X_n;
output wire [SIZE:0] S_n;

wire [SIZE:0] D_n;
reg [SIZE-1:0] U_X_n_1,U_X_n_2,V_X_n_1,V_X_n_2;
reg [SIZE:0] U_D_n_1,V_D_n_1;
wire [SIZE-1:0] X_n_1,X_n_2;
wire [SIZE:0] D_n_1;

wire temp=~Clipped & Active;

assign X_n_1=(YUV_turn==2'b01)?U_X_n_1:V_X_n_1;
assign X_n_2=(YUV_turn==2'b01)?U_X_n_2:V_X_n_2;
assign D_n_1=(YUV_turn==2'b01)?U_D_n_1:V_D_n_1;

always @(posedge Input_CLK)
begin
    if(Reset)
    begin
        U_X_n_1<=0;
        U_X_n_2<=0;
        U_D_n_1<=0;
        V_X_n_1<=0;
        V_X_n_2<=0;
        V_D_n_1<=0;
    end
    else
    begin
        if(temp & YUV_turn==2'b01)
        begin
            U_X_n_2<=U_X_n_1;
            U_X_n_1<=X_n;
            if(Valid & ~First_Pixel)
            begin
                U_D_n_1<=D_n;
            end
        end
        if(temp & YUV_turn==2'b10)
        begin
            V_X_n_2<=V_X_n_1;
            V_X_n_1<=X_n;
            if(Valid & ~First_Pixel)
            begin
                V_D_n_1<=D_n;
            end
        end
    end
end

wire [SIZE:0] D_temp;
wire [SIZE-1:0] D_temp_2;
wire [SIZE+1:0] S_temp;
wire [SIZE-1:0] S_temp_4;

assign D_temp={X_n[SIZE-1],X_n}+{X_n_2[SIZE-1],X_n_2};
assign D_temp_2=D_temp[SIZE:1];
assign D_n={X_n_1[SIZE-1],X_n_1}-{D_temp_2[SIZE-1],D_temp_2};
assign S_temp={D_n[SIZE],D_n}+{D_n_1[SIZE],D_n_1}+2'b10;
assign S_temp_4=S_temp[SIZE+1:2];
assign S_n={X_n_2[SIZE-1],X_n_2}+{S_temp_4[SIZE-1],S_temp_4};

endmodule
