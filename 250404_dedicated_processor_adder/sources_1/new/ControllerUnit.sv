`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/04 17:46:50
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


module ControllerUnit(
    input logic clk,
    input logic rst,
    output logic MuxSel,
    output logic MuxSel_2,
    output logic En,
    output logic En_2,
    input logic lt,
    output logic OutBuf
    );

    localparam S0 = 0 , S1 = 1, S2 = 2, S3 = 3, S4 = 4, S5 = 5, S6 = 6;

    logic [3:0] state, next;

    always_ff @( posedge clk, posedge rst ) begin
        if(rst) begin
            state <= 0;
        end
        else begin
            state <= next;
        end
    end


    always_comb begin
        next = state;
        case (state)
           S0 : begin
                MuxSel = 0;
                MuxSel_2 = 0;
                En = 1;
                En_2 = 0;
                OutBuf = 0;
                next = S1;
           end
           S1 : begin
                MuxSel = 0;
                MuxSel_2 = 0;
                En = 0;
                En_2 = 0;
                OutBuf = 0;
                next = S2;
           end
           S2 : begin
                MuxSel = 0;
                MuxSel_2 = 0;
                En = 0;
                En_2 = 1;
                OutBuf = 0;
                next = S3;
           end 
           S3 : begin
                MuxSel = 0;
                MuxSel_2 = 0;
                En = 0;
                En_2 = 0;
                OutBuf = 0;
                if(lt) begin
                    next = S4;
                end
                else begin
                    next = S6;
                end
           end 
           S4 : begin 
                MuxSel = 1;
                MuxSel_2 = 0;
                En = 1;
                En_2 = 0;
                OutBuf = 0;
                next = S5;
           end
           S5 : begin 
                MuxSel = 0;
                MuxSel_2 = 1;
                En = 0;
                En_2 = 1;
                OutBuf = 0;
                next = S3;
           end
            S6 : begin 
                MuxSel = 0;
                MuxSel_2 = 0;
                En = 0;
                En_2 = 0;
                OutBuf = 1;
                next = S6;
            end
        endcase

    end


endmodule
