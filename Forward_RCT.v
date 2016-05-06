`timescale 1ns / 1ps

module Forward_RCT(YUV_turn,R,G,B,YUV);
// synopsys template
input wire[1:0] YUV_turn;
input wire[7:0] R;
input wire[7:0] G;
input wire[7:0] B;
output wire[8:0] YUV;

wire [9:0] R_10,G_10,B_10,G2_10;
assign R_10={2'b00,R[7:0]};
assign G_10={2'b00,G[7:0]};
assign G2_10={1'b0,G[7:0],1'b0};
assign B_10={2'b00,B[7:0]};

reg [9:0] answer;

assign YUV=(YUV_turn==2'b00)?{1'b0,answer[9:2]}:answer[8:0];
always @(*)
begin
    if(YUV_turn==2'b00)
    begin
        answer=R_10+G2_10+B_10;
    end
    else if(YUV_turn==2'b01)
    begin
        answer=R_10-G_10;
    end
    else
    begin
        answer=G_10-B_10;
    end
end

endmodule
