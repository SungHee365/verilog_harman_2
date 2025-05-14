`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/21 10:46:11
// Design Name: 
// Module Name: TOP_UART_Stopwatch_Clock
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


module TOP_UART_Stopwatch_Clock(
    input clk,rst,
    input rx, // pc in rx
    output tx, // pc out tx
    // FIFO RX
    output RX_rd,
    output [7:0] RX_rdata,
    output RX_empty,
    // FIFO TX
    input TX_wr,
    input [7:0] TX_wdata,
    output TX_full
    );





wire w_tick;
wire w_rx_done, w_tx_done;
wire w_rd_full, w_empty_wr;
wire w_empty_start;
wire [7:0] w_rx_data, w_FIFO_data, w_tx_data;




UART_RX U_RX(
    .clk(clk),
    .rst(rst),
    .tick(w_tick),
    .rx(rx),
    .rx_done(w_rx_done),
    .rx_data(w_rx_data)
);



fifo U_FIFO_RX(
    .clk(clk),
    .reset(rst),   

    //write
    .wdata(w_rx_data),
    .wr_en(w_rx_done),
    .full(),

    //read
    .rd_en(RX_rd), // 수정
    .rdata(RX_rdata),
    .empty(RX_empty)
    );


fifo U_FIFO_TX(
    .clk(clk),
    .reset(rst),
    //write
    
    .wdata(TX_wdata),
    .wr_en(TX_wr),
    .full(TX_full),

    //read
    .rd_en(~w_tx_done), // 수정
    .rdata(w_tx_data),
    .empty(w_empty_start)
    );

UART_TX U_TX(
    .clk(clk),
    .rst(rst),
    .tick(w_tick),
    .start_trigger(~w_empty_start),
    .data_in(w_tx_data),
    .o_tx(tx), 
    .o_tx_done(w_tx_done)
);




baud_tick_genp U_BAUD_Tock_Gen(
    .clk(clk),
    .rst(rst),
    .baud_tick(w_tick)
);

endmodule
