`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/02 15:14:27
// Design Name: 
// Module Name: tb_uart
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


module tb_uart(

    );

    reg clk;
    reg rst;
    reg rx;
    wire tx;
    wire [3:0] fndCom;
    wire [7:0] fndFont;

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        rx = 1;
        #10
        rst = 0;
        #104170
        #104170
        rx = 0;
        #104170
        rx = 1;
        #104170
        rx = 1;
        #104170
        rx = 0;
        #104170
        rx = 0;
        #104170
        rx = 1;
        #104170
        rx = 0;
        #104170
        rx = 1;
        #104170
        rx = 0;
        #104170;
        rx = 1;
        
    end



top_counter_up_down DUT(
    .clk(clk),
    .rst(rst),
    .rx(rx),
    .tx(tx),
    .fndCom(fndCom),
    .fndFont(fndFont)
);

endmodule
