`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/01 16:28:40
// Design Name: 
// Module Name: tb_counter
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


module tb_counter();

    reg clk;
    reg rst;
    reg mode;
    wire [3:0]fndCom;
    wire [7:0]fndFont;

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        mode = 0;
        #10
        rst = 0;
        #100
        #100;
    end



top_counter_up_down dut(
    .clk(clk),
    .rst(rst),
    .mode(mode),
    .fndCom(fndCom),
    .fndFont(fndFont)
);



endmodule
