`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/07 12:38:46
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
    output logic [3:0] raddr1,
    output logic [3:0] raddr2,
    output logic [3:0] waddr,
    output logic wEn,
    output logic outBuf,
    input logic le
    );

    typedef enum  {S0,S1,S2,S3,S4,S5,S6,S7,S8,S9,S10 } state_e;

    state_e state, next;

    always_ff @( posedge clk,posedge rst ) begin
        if(rst) state <= S0;
        else state <= next;
    end

    always_comb begin
        MuxSel = 0;
        waddr  = 0;
        wEn    = 0;
        raddr1  = 0;
        raddr2  = 0;
        outBuf = 0;
        next = S1;
        case (state)
            S0: begin
                    MuxSel = 1;
                    waddr  = 1;
                    wEn    = 1;
                    raddr1  = 1'bx;
                    raddr2  = 1'bx;
                    outBuf = 0;
                    next = S1;
            end
            S1: begin
                    MuxSel = 0;
                    waddr  = 2;
                    wEn    = 1;
                    raddr1  = 0;
                    raddr2  = 1;
                    outBuf = 0;
                    next = S2;
            end
            S2: begin
                    MuxSel = 0;
                    waddr  = 3;
                    wEn    = 1;
                    raddr1  = 0;
                    raddr2  = 2;
                    outBuf = 0;
                    next = S3;
            end
            S3: begin
                    MuxSel = 0;
                    waddr  = 2;
                    wEn    = 1;
                    raddr1  = 2;
                    raddr2  = 1;
                    outBuf = 0;
                    next = S4;  
            end
            S4: begin
                MuxSel = 0;
                waddr  = 1'bx;
                wEn    = 0;
                raddr1  = 2;
                raddr2  = 1;
                outBuf = 0;
                if(le) next = S5;
                else next = S6;
            end
            S5: begin
                    MuxSel = 0;
                    waddr  = 3;
                    wEn    = 1;
                    raddr1  = 2;
                    raddr2  = 3;
                    outBuf = 0;
                    next = S3;


            end
            S6: begin
                    MuxSel = 0;
                    waddr  = 1'bx;
                    wEn    = 0;
                    raddr1  = 0;
                    raddr2  = 3;
                    outBuf = 1;
                    next = S6;
            end
        endcase
    end

endmodule
