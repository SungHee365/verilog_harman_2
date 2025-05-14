`timescale 1ns / 1ps
 
 
module HCSR04_Periph (
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
    // export signals
    input echo,
    output start_trigger
);
  
    logic  trigger;
    logic [8:0] distance;

    APB_SlaveIntf_HCSR04 U_APB_Intf (.*);
    HCSR04 U_GPOHCSR04_IP (.*);
endmodule

module APB_SlaveIntf_HCSR04 (
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
    output logic trigger,
    input logic [8:0] distance
);
    logic [31:0] slv_reg0, slv_reg1; //, slv_reg2, slv_reg3;

    assign trigger = slv_reg0[0];
    assign slv_reg1 = distance;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;
            //slv_reg1 <= 0;
            // slv_reg2 <= 0;
            // slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: slv_reg0 <= PWDATA;
                        //2'd1: slv_reg1 <= PWDATA;
                        // 2'd2: slv_reg2 <= PWDATA;
                        // 2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: PRDATA <= slv_reg1;
                        // 2'd2: PRDATA <= slv_reg2;
                        // 2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end

endmodule

module HCSR04 (
    // global signal
    input  logic PCLK,
    input  logic PRESET,
    input  logic trigger,
    input  logic echo,
    output logic [8:0] distance,
    output logic start_trigger
);

    logic tick_1us, time_done;

Ultrasonic_dp U_hcsr04_dp(
    .clk(PCLK),
    .rst(PRESET),
    .tick_1us(tick_1us),
    .btn(trigger),
    .echo(echo),
    .start_trigger(start_trigger),
    .time_done(time_done)
);

tick_genp_1Mhz U_hcsr04_tick(
    .clk(PCLK),
    .rst(PRESET),
    .tick_1us(tick_1us)
);

dist_calculator U_hcsr04_dist(
    .clk(PCLK),
    .rst(PRESET),
    .tick(tick_1us),
    .echo(echo),
    .time_done(time_done),
    .dist_cm(distance)
);

endmodule


module Ultrasonic_dp(
    input logic clk,
    input logic rst,
    input logic tick_1us,
    input logic btn,
    input logic echo,
    output logic start_trigger,
    output logic time_done
);

    parameter IDLE = 0, START = 1, WAIT = 2, DATA = 3;

    logic time_next, time_reg;
    logic [3:0] cnt_next, cnt_reg;
    logic [1:0] state,next;
    logic start_next, start_reg;


    assign start_trigger = start_reg;
    assign time_done = time_reg;

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            cnt_reg <= 0;
            start_reg <= 0;
            state <= 0;
            time_reg <= 0;
        end
        else begin
            cnt_reg <= cnt_next;
            start_reg <= start_next;
            state <= next;
            time_reg <= time_next;
        end
    end

    always @(*) begin
        cnt_next = cnt_reg;
        start_next = start_reg;
        next = state;
        time_next = time_reg;
        case (state)
           IDLE : begin  time_next = 0;
                    if(btn) begin 
                     next = START;
                    end
           end
           START : if(tick_1us == 1) begin
                    if(cnt_reg == 9) begin
                        start_next = 0;
                        cnt_next = 0;
                        next = WAIT;
                    end
                    else begin
                        cnt_next = cnt_reg + 1;
                        start_next = 1;
                        next = START;
                    end
           end
           WAIT : if(tick_1us == 1) begin
            if(echo == 1) begin
                next = DATA;
            end
            else begin
                next = WAIT;
            end
           end
           DATA : if(tick_1us == 1) begin
            if(echo == 0) begin
                next = IDLE;
                time_next = 1;
            end
            else begin
                next = DATA;
            end
           end
        endcase
        
    end


endmodule



module tick_genp_1Mhz(
    input  logic clk,
    input  logic rst,
    output logic tick_1us
);


    logic [$clog2(100)-1:0] cnt_next, cnt_reg;
    logic tick_next, tick_reg;


    assign tick_1us = tick_reg;

    always @(posedge clk, posedge rst) begin
        if(rst) begin 
            cnt_reg <= 0;
            tick_reg <=0;
        end
        else begin
            cnt_reg <= cnt_next;
            tick_reg <= tick_next;
        end
    end

    always @(*) begin
        cnt_next = cnt_reg;
        tick_next = tick_reg;
        if(cnt_reg == 100-1) begin
            cnt_next = 0;
            tick_next = 1;
        end
        else begin
            cnt_next = cnt_reg +1;
            tick_next = 0;
        end 
    end

endmodule

module dist_calculator(
    input   logic       clk,
    input   logic       rst,
    input   logic       tick,
    input   logic       echo,
    input   logic       time_done,
    output  logic [8:0] dist_cm
);

    reg [15:0]cnt_reg,cnt_next;
    reg [15:0]time_reg, time_next;
    reg [8:0] dist_reg;

    always @( posedge clk, posedge rst) begin
        if(rst) begin
            cnt_reg <= 0;
            time_reg <= 0;
        end
        else begin
            cnt_reg <= cnt_next;
            time_reg <= time_next;
        end
    end


    always @(*) begin
        cnt_next = cnt_reg;
        time_next = time_reg;
        if(time_done == 1) begin
            cnt_next = 0;
            time_next = cnt_reg;
        end
        if(tick == 1'b1) begin
            if(echo == 1) begin
                cnt_next = cnt_reg + 1;
            end
        end
    end


// 타이밍 바이올레이션으로 인하여 /58 대신 쉬프트연산
// (time_reg >> 6) + (time_reg >> 9) 오차율 대략 1.95%
//(time_reg >> 6) + (time_reg >> 9) - (time_reg >> 12); 오차율 대략 0.54%
    assign dist_cm = (time_reg >> 6) + (time_reg >> 9) - (time_reg >> 12);


endmodule