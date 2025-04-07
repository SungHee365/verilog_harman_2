`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/07 12:38:46
// Design Name: 
// Module Name: top_DedicatedProcessor
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


module top_DedicatedProcessor(
    input clk,
    input rst,
    output [7:0] outport
    );

    logic MuxSel;
    logic [3:0] raddr1;
    logic [3:0] raddr2;
    logic [3:0] waddr;
    logic wEn;
    logic outBuf;
    logic le;

ControllerUnit U_cu(.*);

DataPath U_dp(.*);


endmodule
