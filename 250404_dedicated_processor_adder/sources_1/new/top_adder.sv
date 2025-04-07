`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/04 17:23:33
// Design Name: 
// Module Name: ControllerUnit
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


module top_adder(
    input logic clk,
    input logic rst,
    output logic [7:0] outPort
    );

    logic MuxSel,En,lt,OutBuf ,MuxSel_2, En_2;

    ControllerUnit U_cu(
    .clk(clk),
    .rst(rst),
    .MuxSel(MuxSel),
    .MuxSel_2(MuxSel_2),
    .En(En),
    .En_2(En_2),
    .lt(lt),
    .OutBuf(OutBuf)
    );


    DataPath U_dp(
    .clk(clk),
    .rst(rst),
    .MuxSel(MuxSel),
    .MuxSel_2(MuxSel_2),
    .En(En),
    .En_2(En_2),
    .lt(lt),
    .OutBuf(OutBuf),
    .outPort(outPort)
    );
endmodule