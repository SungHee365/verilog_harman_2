`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/02 14:11:38
// Design Name: 
// Module Name: uart_rx
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


module top_uart_rx(
    input clk,
    input rst,
    input rx,
    output [7:0] rx_data,
    output rx_done
);

    wire w_tick;

uart_rx U_uart_rx(
    .clk(clk),
    .rst(rst),
    .tick(w_tick),
    .rx(rx),
    .rx_done(rx_done),
    .rx_data(rx_data)
    );


tick_genv U_tick_genv(
    .clk(clk),
    .rst(rst),
    .tick(w_tick)
);



endmodule


module uart_rx(
    input clk,
    input rst,
    input tick,
    input rx,
    output rx_done,
    output [7:0] rx_data
    );

    parameter IDLE = 0, START = 1, D = 2, STOP = 3 ;

    reg [1:0] state, next;
    reg [$clog2(23)-1:0] tick_cnt_reg, tick_cnt_next;
    reg [3:0] data_cnt_reg, data_cnt_next;
    reg done_reg, done_next;
    reg [7:0] data_reg, data_next;


    assign rx_done = done_reg;
    assign rx_data = data_reg;

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            state <= 0;
            tick_cnt_reg <= 0;
            data_cnt_reg <= 0;
            done_reg <= 0;
            data_reg <= 0;
        end
        else begin
            state <= next;
            tick_cnt_reg <= tick_cnt_next;
            data_cnt_reg <= data_cnt_next;
            done_reg <= done_next;
            data_reg <= data_next;
        end
    end

    always @(*) begin
        next = state;
        tick_cnt_next = tick_cnt_reg;
        data_cnt_next = data_cnt_reg;
        done_next = 1'b0;
        data_next = data_reg;
        case (state)
           IDLE : begin
                if(rx==1'b0) begin
                    next = START;
                    done_next = 1'b0;
                end
           end
           START : begin
                    if(tick==1'b1) begin
                        if(tick_cnt_reg == 7) begin
                            tick_cnt_next = 0;
                            next = D;
                        end
                        else begin
                            tick_cnt_next = tick_cnt_reg + 1;
                        end
                    end
           end
           D :  begin
                    if(tick==1'b1) begin
                        if(data_cnt_reg == 8) begin
                            next = STOP;
                            data_cnt_next = 0;
                        end
                        else begin
                            if(tick_cnt_reg == 15) begin
                                tick_cnt_next = 0;
                                data_cnt_next = data_cnt_reg + 1;
                                data_next[data_cnt_reg] = rx;
                            end
                            else begin
                                tick_cnt_next = tick_cnt_reg + 1;
                            end
                        end
                    end
           end
           STOP : begin
                    if(tick==1'b1) begin
                        if(tick_cnt_reg == 7) begin
                            tick_cnt_next = 0;
                            next = IDLE;
                            done_next = 1'b1;
                        end
                        else begin
                            tick_cnt_next = tick_cnt_reg + 1;
                        end
                    end
           end 
        endcase
    end









endmodule


module tick_genv(
    input clk,
    input rst,
    output tick
);

    parameter TICK = 100_000_000/9600/16 ;

    reg [$clog2(TICK)-1: 0] cnt_reg, cnt_next;
    reg tick_reg, tick_next;

    assign tick = tick_reg;

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            cnt_reg <= 0;
            tick_reg <= 0;
        end
        else begin
            cnt_reg <= cnt_next;
            tick_reg <= tick_next;
        end
    end

    always @(*) begin
        cnt_next = cnt_reg;
        tick_next = 1'b0;
        if(cnt_reg == TICK-1) begin
            cnt_next = 0;
            tick_next = 1'b1;
        end
        else begin
            cnt_next = cnt_reg + 1;
            tick_next = 0;
        end
    end

endmodule
