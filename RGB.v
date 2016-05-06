`timescale 1ns / 1ps

module RGB(CLK,Reset,Pixel,RGB_turn,Alternate,R,G,B);
// synopsys template
input wire CLK,Reset,Alternate;
input wire [1:0] RGB_turn;
input wire [7:0] Pixel;
output wire [7:0] R,G,B;

reg [7:0] R_1,G_1,B_1,R_2,G_2,B_2;

assign R=(Alternate)?R_1:R_2;
assign G=(Alternate)?G_1:G_2;
assign B=(Alternate)?B_1:B_2;

always @(posedge CLK)
begin
    if(Reset)
    begin
        R_1<=8'b00000000;
        G_1<=8'b00000000;
        B_1<=8'b00000000;
        R_2<=8'b00000000;
        G_2<=8'b00000000;
        B_2<=8'b00000000;
    end
    else
    begin
        if(Alternate)
        begin
            if(RGB_turn==2'b00)
            begin
                R_2<=Pixel;
            end
            else if(RGB_turn==2'b01)
            begin
                G_2<=Pixel;
            end
            else
            begin
                B_2<=Pixel;
            end
        end
        else
        begin
            if(RGB_turn==2'b00)
            begin
                R_1<=Pixel;
            end
            else if(RGB_turn==2'b01)
            begin
                G_1<=Pixel;
            end
            else
            begin
                B_1<=Pixel;
            end
        end
    end
end

endmodule
