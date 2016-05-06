`timescale 1ns / 1ps

module Control_Unit(CLK,CLK_8,CLK,Reset,Clipped,Row,Column,YUV_turn,Valid_Sub_Sampler,Alternate,Active_1,Valid_1,Active_2,Valid_2,First_Pixel,Third_Pixel,New_Frame);
// synopsys template
input wire CLK_8,Reset,Clipped;
output wire CLK;
output reg [7:0] Row,Column;
output reg [1:0] YUV_turn;
output wire Valid_Sub_Sampler,Active_1,Valid_1,Active_2,Valid_2,First_Pixel,Third_Pixel,New_Frame;
output reg Alternate;

wire First_Row;
assign First_Row=(Row==8'd0)?1'b1:1'b0;
assign New_Frame=(First_Row & Column==8'd0)?1'b1:1'b0;
assign First_Pixel=(First_Row & Column==8'd75)?1'b1:1'b0;
assign Third_Pixel=(First_Row & Column==8'd77)?1'b1:1'b0;

reg [3:0] Counter;
reg [2:0] CLK_Divider;


assign CLK=CLK_Divider[2];

wire c0,c1,c2,c3,c6,c7,c8,c9;
assign c0=(Counter==4'd0)?1'b1:1'b0;
assign c1=(Counter==4'd1)?1'b1:1'b0;
assign c2=(Counter==4'd2)?1'b1:1'b0;
assign c3=(Counter==4'd3)?1'b1:1'b0;
//assign c4=(Counter==4'd4)?1'b1:1'b0;
//assign c5=(Counter==4'd5)?1'b1:1'b0;
assign c6=(Counter==4'd6)?1'b1:1'b0;
assign c7=(Counter==4'd7)?1'b1:1'b0;
assign c8=(Counter==4'd8)?1'b1:1'b0;
assign c9=(Counter==4'd9)?1'b1:1'b0;
//assign c10=(Counter==4'd10)?1'b1:1'b0;
//assign c11=(Counter==4'd11)?1'b1:1'b0;

always @(posedge CLK_8)
begin
	if(Reset)
	begin
		CLK_Divider<=3'b0;
	end
	else
	begin
		CLK_Divider<=CLK_Divider+1'b1;
	end
end

always @(posedge CLK)
begin
    if(Reset)
    begin
        Row<=8'b11111111;
        Column<=8'b11111110;
        Alternate<=1'b0;
    end
    else
    begin
        if(YUV_turn==2'b10)
        begin
            Alternate<=~Alternate;
            Column<=Column+1'b1;
            if(Column==8'b11111111)
            begin
                Row<=Row+1'b1;
            end
        end
    end
end

always @(posedge CLK)
begin
    if(Reset)
    begin
        YUV_turn<=2'b10;
    end
    else
    begin
        if(YUV_turn==2'b10)
        begin
            YUV_turn<=2'b00;
        end
        else
        begin
            YUV_turn<=YUV_turn+1'b1;
        end
    end
end

always @(posedge CLK)
begin
    if(Reset)
    begin
        Counter<=4'b0000;
    end
    else
    begin
        if(~Clipped)
        begin
                if(Counter==4'b1011)
                begin
                    Counter<=4'b0000;
                end
                else
                begin
                    Counter<=Counter+1'b1;
                end
        end
    end
end


assign Valid_Sub_Sampler=((~Third_Pixel | c6) & (c0 | c7 | c8 | c3 | c6 | c9))?1'b1:1'b0;
//assign Alternate=(~Pre_First_Pixel & (Counter==4'b0000 | Counter==4'b0001 | Counter==4'b0010 | Counter==4'b0110 | Counter==4'b0111 | Counter==4'b1000))?1'b1:1'b0;
assign Active_1=1'b1;
assign Valid_1=(c1 | c2 | c7 | c8)?1'b1:1'b0;
assign Active_2=Valid_1;
assign Valid_2=(c7 | c8)?1'b1:1'b0;//Valid_1;// & ~(Row==8'd0 & Column==8'd77);

endmodule
