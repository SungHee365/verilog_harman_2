`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/28 09:35:25
// Design Name: 
// Module Name: TIMER
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


module TIMER_Periph(

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
    output logic        PREADY
    // inport signals
);

    logic [1:0] TCR;
    logic [31:0] TCNT;
    logic [31:0] PSC;
    logic [31:0] ARR;

    APB_SlaveIntf_TIMER U_APB_Intf_TIMER (.*);
    TIMER U_TIMER(
    .clk(PCLK),
    .reset(PRESET),
    .en(TCR[0]),
    .clear(TCR[1]),
    .PSC(PSC),
    .ARR(ARR),
    .count(TCNT)
    );
endmodule

module APB_SlaveIntf_TIMER (
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
    output logic [1:0] TCR,
    input  logic [31:0] TCNT,
    output logic [31:0] PSC,
    output logic [31:0] ARR

);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;

    assign TCR = slv_reg0[1:0]; // [1] = clear, [0] = enble
    assign slv_reg1 = TCNT;
    assign PSC = slv_reg2; // 주파수 설정 100_000일시 1khz
    assign ARR = slv_reg3; // cnt 최대값 설정

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;
            //slv_reg1 <= 0;
             slv_reg2 <= 0;
             slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: slv_reg0 <= PWDATA;
                        2'd1: ;
                        2'd2: slv_reg2 <= PWDATA;
                        2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: PRDATA <= slv_reg1;
                        2'd2: PRDATA <= slv_reg2;
                        2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end

endmodule

module TIMER (
    input logic clk,
    input logic reset,
    input logic en,
    input logic clear,
    input logic[31:0] PSC,
    input logic[31:0] ARR,
    output logic [31:0] count
);

    logic tick;

    CLK_DIV  U_CLK_DIV(.*);


    counter  U_counter(.*);





endmodule


module CLK_DIV(
    input logic clk,
    input logic reset,
    input logic en,
    input logic clear,
    input logic [31:0] PSC,
    output logic tick
);


    logic [31:0] cnt_reg, cnt_next;
    logic tick_reg, tick_next;

    assign tick =  tick_reg;

    always_ff @( posedge clk, posedge reset ) begin
        if(reset) begin
            cnt_reg <= 0;
            tick_reg <= 0;
        end
        else begin
            cnt_reg <= cnt_next;
            tick_reg <= tick_next;
        end
    end


    always_comb begin
        cnt_next = cnt_reg;
        tick_next = tick_reg;
        if(clear) begin
            cnt_next = 0;
            tick_next = 0;
        end
        else if(en) begin
            if(cnt_reg == PSC) begin
                cnt_next = 0;
                tick_next = 1;
            end
            else begin
                cnt_next = cnt_reg + 1;
                tick_next = 0;
            end
        end
        else begin
            cnt_next = cnt_reg;
            tick_next = 0;
        end
    end


endmodule


module counter(
    input logic clk,
    input logic reset,
    input logic tick,
    input logic clear,
    input logic [31:0] ARR,
    output logic [31:0] count
);
 //   parameter COUNT = 32'hffff ;

    logic [31:0] cnt_reg, cnt_next;


    assign count = cnt_reg;

    always_ff @( posedge clk, posedge reset ) begin
        if(reset) begin
            cnt_reg <= 0;
        end
        else begin
            cnt_reg <= cnt_next;
        end
    end

    always_comb begin
        cnt_next = cnt_reg;
        if(clear) begin
            cnt_next = 0;
        end
        else if(cnt_reg == ARR) begin
            cnt_next = 0;
        end
        else begin
            cnt_next = cnt_reg + 1;
        end
    end

endmodule
