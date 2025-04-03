`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/02 16:47:26
// Design Name: 
// Module Name: uart_tx
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
module top_uart_tx(
    input clk,
    input rst,
    input start_trigger,
    input [7:0] data,
    output tx,
    output tx_done,
    output tx_busy
);

    wire w_tick;

uart_tx U_uart_tx(
    .clk(clk),
    .rst(rst),
    .tick(w_tick),
    .start_trigger(start_trigger),
    .data(data),
    .tx(tx),
    .tx_done(tx_done),
    .tx_busy(tx_busy)
    );


tick_genv U_tick_genv(
    .clk(clk),
    .rst(rst),
    .tick(w_tick)
);

endmodule

module uart_tx(
    input clk,
    input rst,
    input tick,
    input start_trigger,
    input [7:0] data,
    output tx,
    output tx_done,
    output tx_busy
    );


    reg done_reg,done_next;
    reg busy_reg,busy_next;
    reg tx_reg, tx_next;
    reg [2:0] state,next;
    reg [3:0] tick_cnt_reg, tick_cnt_next; 
    reg [4:0] data_cnt_reg, data_cnt_next;

    parameter IDLE = 0, START = 1, D = 2, STOP = 3;

    assign tx_busy = busy_reg;
    assign tx_done = done_reg;
    assign tx = tx_reg;

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            state <= 0;
            tick_cnt_reg <= 0;
            data_cnt_reg <= 0;
            tx_reg <= 1;
            done_reg <= 0;
            busy_reg <= 0;
        end
        else begin
            state <= next;
            tick_cnt_reg <= tick_cnt_next;
            data_cnt_reg <= data_cnt_next;
            tx_reg <= tx_next;
            done_reg <= done_next;
            busy_reg <= busy_next;
        end
    end

    always @(*) begin
        next = state;
        tick_cnt_next = tick_cnt_reg;
        data_cnt_next = data_cnt_reg;
        done_next = 1'b0;
        busy_next = busy_reg;
        tx_next = tx_reg;
        case (state)
           IDLE :begin
                done_next = 1'b0;
                if(start_trigger) begin 
                    next = START;
                    busy_next = 1'b1;
                end
           end
           START : if(tick) begin
                    tx_next = 1'b0;
                    if(tick_cnt_reg == 15) begin
                        tick_cnt_next = 0;
                        next = D;
                    end
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
           end
           D     : if(tick) begin
                    tx_next = data[data_cnt_reg];
                    if(data_cnt_reg == 8) begin
                        data_cnt_next = 0;
                        next = STOP;
                    end
                    else begin
                        if(tick_cnt_reg == 15) begin
                            tick_cnt_next = 0;
                            data_cnt_next = data_cnt_reg + 1;
                        end
                        else begin
                            tick_cnt_next = tick_cnt_reg + 1;
                        end
                    end
           end
           STOP   : begin
                    if(tick) begin
                        if(tick_cnt_reg == 7) begin
                            tick_cnt_next = 0;
                            done_next = 1'b1;
                            busy_next = 1'b0;
                            next = IDLE;
                            tx_next = 1'b1;
                        end
                        else begin
                            tick_cnt_next = tick_cnt_reg + 1;
                        end
                    end
           end 
        endcase
    end



endmodule
