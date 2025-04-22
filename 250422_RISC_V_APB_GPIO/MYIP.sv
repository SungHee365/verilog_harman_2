`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/22 12:00:53
// Design Name: 
// Module Name: MYIP
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


module FndController_Periph(
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // inport signals
    output logic [3:0] fndcomm,
    output logic [7:0] fndfont
);

    logic        fcr;
    logic [ 3:0] fmr;
    logic [ 3:0] fdr;
    logic [ 3:0] fnddata;

    APB_SlaveIntf_FND U_APB_Intf (.*);
    FndController U_FNDController(.*);
endmodule

module APB_SlaveIntf_FND (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // internal signals
    output logic        fcr,
    output  logic [ 3:0] fmr,
    output logic [ 3:0] fdr
);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2;//, slv_reg3;

    assign fcr = slv_reg0;
    assign fmr = slv_reg1[3:0];
    assign fdr = slv_reg2[3:0];

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;
            slv_reg1 <= 0;
            slv_reg2 <= 0;
        //    slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: slv_reg0 <= PWDATA;
                        2'd1: slv_reg1 <= PWDATA;                        
                        2'd2: slv_reg2 <= PWDATA;
                  //      2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: PRDATA <= slv_reg1;
                        2'd2: PRDATA <= slv_reg2;
                   //     2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end
endmodule

module FndController(
    input logic        fcr,
    input logic  [3:0] fmr,
    input logic  [3:0] fdr,
    output logic [3:0] fndcomm,
    output logic [7:0] fndfont
);

    assign fndcomm = fcr ? ~fmr : 4'b1111;

    always_comb begin
        case (fdr)
            4'h0: fndfont = 8'hc0; // 0
            4'h1: fndfont = 8'hF9; // 1
            4'h2: fndfont = 8'hA4; // 2
            4'h3: fndfont = 8'hB0; // 3
            4'h4: fndfont = 8'h99; // 4
            4'h5: fndfont = 8'h92; // 5
            4'h6: fndfont = 8'h82; // 6
            4'h7: fndfont = 8'hf8; // 7
            4'h8: fndfont = 8'h80; // 8
            4'h9: fndfont = 8'h90; // 9
            4'hA: fndfont = 8'h88; // A
            4'hB: fndfont = 8'h83; // B
            4'hC: fndfont = 8'hc6; // C
            4'hD: fndfont = 8'ha1; // D
            4'hE: fndfont = 8'h86; // 아무것도 x
            4'hF: fndfont = 8'h8e; // 
            default: fndfont = 8'hff;
        endcase
    end

endmodule