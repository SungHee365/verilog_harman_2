`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/04 18:12:24
// Design Name: 
// Module Name: tb_adder
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


module tb_adder();

    logic clk;
    logic rst;
    logic [7:0] outPort;

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        #10
        rst = 0;
    end

top_adder dut(
    .clk(clk),
    .rst(rst),
    .outPort(outPort)
    );

endmodule
