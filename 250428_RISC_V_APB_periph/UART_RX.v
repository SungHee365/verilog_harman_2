`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/21 10:43:41
// Design Name: 
// Module Name: UART_RX
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module UART_RX(
    input clk,
    input rst,
    input tick,
    input rx,
    output rx_done,
    output [7:0] rx_data
);

    localparam IDLE = 0, START = 1, DATA = 2, STOP =3;

    reg rx_done_reg, rx_done_next;
    reg [1:0] state,next;
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    reg [4:0] tick_cnt_reg, tick_cnt_next;
    reg [7:0] rx_data_reg, rx_data_next;

    assign rx_done = rx_done_reg;
    assign rx_data = rx_data_reg;

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            state           <= 0;
            rx_done_reg     <= 0;
            bit_cnt_reg     <= 0;
            tick_cnt_reg    <= 0;
            rx_data_reg     <= 0;
        end
        else begin
            state           <= next;
            rx_done_reg     <= rx_done_next;
            bit_cnt_reg     <= bit_cnt_next;
            tick_cnt_reg    <= tick_cnt_next;
            rx_data_reg     <= rx_data_next;
        end
    end


    always @(*) begin
        next = state;
        tick_cnt_next = tick_cnt_reg;
        bit_cnt_next = bit_cnt_reg;
        rx_done_next = 1'b0;
        rx_data_next = rx_data_reg;
        case (state)
            IDLE: begin
                tick_cnt_next = 0;
                bit_cnt_next = 0;
                rx_done_next = 1'b0;
                if(rx==1'b0) begin
                    next = START;
                end
            end
            START: begin
                if(tick == 1'b1) begin
                    if(tick_cnt_reg == 7) begin
                        next = DATA;
                        tick_cnt_next = 0;
                    end
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            DATA: begin
                if(tick == 1'b1) begin
                    if(tick_cnt_reg == 15 ) begin
                        //read data
                        rx_data_next [bit_cnt_reg] = rx;
                        if(bit_cnt_reg == 7) begin
                            next = STOP;
                            bit_cnt_next = 0;
                            tick_cnt_next = 0; // tick cnt 초기화
                        end
                        else begin
                            next = DATA;
                            bit_cnt_next = bit_cnt_reg + 1;
                            tick_cnt_next = 0;
                        end
                    end
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            STOP: begin
                if(tick) begin
                    if(tick_cnt_reg == 23) begin
                        rx_done_next = 1'b1;
                        next = IDLE;
                    end
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end  
        endcase
        
    end
        

    
endmodule

module baud_tick_genp (
    input clk,
    input rst,
    output baud_tick
);

    parameter BAUD_RATE = 9600; //BAUD_RATE_19200 = 19200, ;
    localparam BAUD_COUNT = (100_000_000/BAUD_RATE)/16;
    reg [$clog2(BAUD_COUNT)-1:0] cnt_reg, cnt_next;
    reg tick_reg, tick_next;

    assign baud_tick = tick_reg;


    always @(posedge clk, posedge rst) begin

        if(rst) begin
            tick_reg <= 0;
            cnt_reg <= 0;
        end
        else begin
            cnt_reg <= cnt_next;
            tick_reg <= tick_next;
        end 
    end

    always @(*) begin
        cnt_next = cnt_reg;
        tick_next = tick_reg;
        if(cnt_reg == BAUD_COUNT-1) begin
            cnt_next = 0;
            tick_next = 1'b1; 
        end
        else begin
            cnt_next = cnt_reg + 1;
            tick_next = 1'b0;
        end
    end



endmodule