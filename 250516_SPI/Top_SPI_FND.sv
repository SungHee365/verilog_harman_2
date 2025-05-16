`timescale 1ns / 1ps

module Top_SPI_FND(
    input clk,
    input rst,
    input btn,
    input [14:0] sw,
    output [3:0] fndCom,
    output [7:0] fndFont
    );

    logic ready;
    logic start;
    logic done;
    logic [13:0] fndata;
    logic [7:0] data;
    logic [7:0] stfdata;
    logic SCLK;
    logic MISO;
    logic MOSI;
    logic CS;

    Master U_Master(
        .*,
        .data(data)
    );


    SPI_Master U_SPI_Master(
        .*,
        .tx_data(data),
        .rx_data()
    );


    SPI_Slave U_SPI_Slave(
    // fsm signal
    .*,
    .data(stfdata)
    );

    FSM_Slave_to_FND U_FSM(
    .*,
    .data(stfdata),
    .fnd_Data(fndata)
    );

    fndController U_FND(
        .*,
        .reset(rst),
        .fndData(fndata),
        .fndDot()
    );

endmodule
