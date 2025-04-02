`timescale 1ns / 1ps


module fndController(
    input clk,
    input rst,
    input tick_1ms,
    input [13:0] fndData,
    output [7:0] fndfont,
    output [3:0] fndCom

    );

    wire tick;
    wire [2:0] digit_sel;
    wire [3:0] digit_1, digit_10, digit_100, digit_1000, digit;
    wire [3:0] w_dot;

clk_div_1khz U_clkdiv_1khz(
    .clk(clk),
    .rst(rst),
    .tick(tick)
);

counter_2bit U_counter_2bit(
    .clk(clk),
    .rst(rst),
    .tick(tick),
    .count(digit_sel)
);


decoder_3x8 U_Decoder_3x8(
    .x(digit_sel),
    .y(fndCom)
);

digitSplitter U_Digit_Splitter(
    .fndData(fndData),
    .digit_1(digit_1),
    .digit_10(digit_10),
    .digit_100(digit_100),
    .digit_1000(digit_1000)
);

mux_8X1 U_Mux_8x1(
    .sel(digit_sel),
    .x_0(digit_1),
    .x_1(digit_10),
    .x_2(digit_100),
    .x_3(digit_1000),
    .x_4(4'hE),
    .x_5(w_dot),
    .x_6(4'hE),
    .x_7(4'hE),
    .y(digit)
);

BCDtoSEG_decoder U_BCD_to_SEG(
    .bcd(digit),
    .seg(fndfont)
);

dot_blink U_dot_blink(
    .clk(clk),
  //  .digit_1(digit_1),
    .tick_1ms(tick_1ms),
    .rst(rst),
    .dot(w_dot)
);

    
endmodule


module clk_div_1khz(
    input           clk,
    input           rst,
    output reg      tick
);
    reg [$clog2(100_000)-1 : 0] div_counter;

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            div_counter <= 0;
            tick <= 1'b0;
        end
        else begin
            if(div_counter == 100_000-1) begin
                div_counter <= 0;
                tick <= 1'b1;
            end
            else begin
                div_counter <= div_counter + 1;
                tick <= 1'b0;
            end
        end
    end
endmodule


module counter_2bit(
    input           clk,
    input           rst,
    input           tick,
    output reg [2:0]    count
);
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            count <= 0;
        end
        else begin
            if(tick) begin
                if(count==7) begin
                    count <= 0;
                end
                else begin
                    count <= count + 1;
                end
            end
        end
    end
endmodule

module decoder_3x8(
    input [2:0] x,
    output reg [3:0] y
);
    always @(*) begin
        y = 4'b1111;
        case (x)
           0 : y = 4'b1110;
           1 : y = 4'b1101;
           2 : y = 4'b1011;
           3 : y = 4'b0111;
           4 : y = 4'b1110;
           5 : y = 4'b1101;
           6 : y = 4'b1011;
           7 : y = 4'b0111;
        endcase
    end

endmodule

module digitSplitter (
    input [13:0] fndData,
    output [3:0] digit_1,
    output [3:0] digit_10,
    output [3:0] digit_100,
    output [3:0] digit_1000
);
   assign digit_1 = fndData % 10;
   assign digit_10 = fndData / 10 % 10;
   assign digit_100 = fndData / 100 % 10;
   assign digit_1000 = fndData / 1000 % 10; 
endmodule

module mux_8X1 (
    input [2:0] sel,
    input [3:0] x_0,
    input [3:0] x_1,
    input [3:0] x_2,
    input [3:0] x_3,
    input [3:0] x_4,
    input [3:0] x_5,
    input [3:0] x_6,
    input [3:0] x_7,
    output reg [3:0] y
);

    always @(*) begin
        y = 4'b1111;
       case (sel)
        0: y = x_0;
        1: y = x_1;
        2: y = x_2;
        3: y = x_3;
        4: y = x_4;
        5: y = x_5;
        6: y = x_6;
        7: y = x_7;
       endcase 
    end

endmodule

module BCDtoSEG_decoder (
    input [3:0] bcd,
    output reg [7:0] seg
);

    always @(bcd) begin
        case (bcd)
            4'h0: seg = 8'hc0; // 0
            4'h1: seg = 8'hF9; // 1
            4'h2: seg = 8'hA4; // 2
            4'h3: seg = 8'hB0; // 3
            4'h4: seg = 8'h99; // 4
            4'h5: seg = 8'h92; // 5
            4'h6: seg = 8'h82; // 6
            4'h7: seg = 8'hf8; // 7
            4'h8: seg = 8'h80; // 8
            4'h9: seg = 8'h90; // 9
            4'hA: seg = 8'h88; // A
            4'hB: seg = 8'h83; // B
            4'hC: seg = 8'hc6; // C
            4'hD: seg = 8'ha1; // D
            4'hE: seg = 8'hff; // 아무것도 x
            4'hF: seg = 8'h7f; // 
            default: seg = 8'hff;
        endcase
    end
endmodule

/*
module dot_blink(
    input clk,
    input [3:0]digit_1,
    input rst,
    output [3:0] dot
);
    reg dot_cnt;

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            dot_cnt <= 0;
        end
        else begin
            if(digit_1 <= 5) begin
                dot_cnt <= 1'b0;
            end
            else begin
                dot_cnt <= 1'b1;
            end
        end    
    end

    assign dot = (dot_cnt == 1) ?  4'hF : 4'hE;
endmodule
*/
// 위의 경우 스위치를 왔다갔다하면 0.5초마다 점멸이 불가능
// 따라서 아래의 경우로 대체 
// 0.1초 마다 생기는 틱을 가져와서 5번 카운트한후 5번되면 dot의 상태가 바뀜

module dot_blink(
    input clk,
    input tick_1ms,
    input rst,
    output [3:0] dot
);
    reg dot_cnt;
    reg [3:0] count;

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            dot_cnt <= 0;
        end
        else begin
            if(tick_1ms) begin
                if(count == 5) begin
                    dot_cnt <= ~dot_cnt;
                    count <= 0 ; 
                end
                else begin
                    count <= count + 1;
                end
            end
        end    
    end

    assign dot = (dot_cnt == 1) ?  4'hF : 4'hE;
endmodule