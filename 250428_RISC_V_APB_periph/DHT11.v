`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/26 11:41:40
// Design Name: 
// Module Name: DHT11
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


module DHT11(
    input clk,
    input rst,
    input dht_start,
    inout dht_io,
    output[15:0] dht_data
    );

    wire w_tick_10us;

    assign dht_data = {humidity,temparature};

tick_genp_10us U_tick_genp(
    .clk(clk),
    .rst(rst),
    .tick_10us(w_tick_10us)
);


dnt11_ctrl U_dnt11_ctrl(
    .clk(clk),
    .rst(rst),
    .tick_10us(w_tick_10us),
    .btn(dht_start),
    .humidity(humidity),
    .temperature(temparature),
    .dht_io(dht_io)
);


    
endmodule


module dnt11_ctrl(
    input clk,
    input rst,
    input tick_10us,
    input btn,
    output [7:0] humidity,
    output [7:0] temperature,
    output dht_io

);
    parameter START_CNT = 2000, WAIT_CNT = 3, SYNC_CNT = 8,
              DATA_decision = 4,
              STOP_CNT = 5,  TIME_OUT = 3000 ;

    localparam IDLE = 0, START = 1, WAIT = 2, SYNC_LOW = 3,
               SYNC_HIGH = 4, DATA_SYNC = 5, DATA = 6, DATA0 = 7, DATA1 = 8, STOP = 9 ;

    reg [3:0] state,next;
    reg [$clog2(1800)-1:0] tick_cnt_reg, tick_cnt_next;
    reg [$clog2(40)-1:0] data_cnt_reg, data_cnt_next;
    reg [39:0] data_reg, data_next;
    reg io_oe_reg, io_oe_next;
    reg io_out_reg, io_out_next;
    
    wire led_ind;

    assign dht_io = (io_oe_reg) ? io_out_reg : 1'bz;


    assign humidity = data_reg[39:32];
    assign temperature = data_reg [23:16];
    assign led_ind = (data_reg[7:0] == data_reg[39:32] + data_reg[31:24] + data_reg[23:16] + data_reg[15:8]) ? 1'b1 : 1'b0;



    always @(posedge clk, posedge rst) begin
        if(rst) begin
            state <= 0;
            tick_cnt_reg <= 0;
            io_out_reg <= 1'b1;
            io_oe_reg <= 0;
            data_cnt_reg <= 0;
            data_reg <= 0;
        end
        else begin
            state <= next;
            tick_cnt_reg <= tick_cnt_next;
            io_out_reg <= io_out_next;
            io_oe_reg <= io_oe_next;
            data_cnt_reg <= data_cnt_next;
            data_reg <= data_next;
        end
        
    end

    always @(*) begin
        next = state;
        tick_cnt_next = tick_cnt_reg;
        io_out_next = io_out_reg;
        io_oe_next = io_oe_reg;
        data_cnt_next = data_cnt_reg;
        data_next = data_reg;
        case (state)
           IDLE : begin
                    io_out_next = 1'b1;
                    io_oe_next = 1'b1;
                    if(btn) begin 
                        next = START;
                        tick_cnt_next = 0;
                    end
           end
           START : begin  //1
                    io_out_next = 1'b0;
                    if(tick_10us == 1'b1) begin
                        if(tick_cnt_reg == START_CNT-1) begin
                             next = WAIT;
                             tick_cnt_next = 0;
                        end
                        else begin
                             tick_cnt_next = tick_cnt_reg + 1;
                        end
                    end
                end
           WAIT : begin // 2
                    io_out_next = 1'b1;
                    if(tick_10us == 1'b1) begin
                             if(tick_cnt_reg == WAIT_CNT-1) begin
                                io_oe_next = 1'b0;
                                next = SYNC_LOW;
                                tick_cnt_next = 0;
                             end
                             else begin
                                 tick_cnt_next = tick_cnt_reg + 1;
                             end
                    end
                end
           SYNC_LOW :  begin // 3
                    if(tick_10us == 1'b1) begin
                        if(tick_cnt_reg == 2) begin
                        if(dht_io == 1) begin
                            next = SYNC_HIGH;
                            tick_cnt_next = 0;
                        end
                        end
                        else begin
                            tick_cnt_next = tick_cnt_reg + 1;
                            next = SYNC_LOW;
                        end
                    end
           end
           SYNC_HIGH : begin // 4
                    if(tick_10us == 1'b1) begin
                        if(tick_cnt_reg == 2) begin
                            if(dht_io == 0) begin
                                next = DATA_SYNC;
                                tick_cnt_next = 0;
                            end
                            end
                            else begin
                                tick_cnt_next = tick_cnt_reg + 1;
                                next = SYNC_HIGH;
                            end
                    end
            end
           DATA_SYNC : begin // 5
                    if(tick_10us == 1'b1) begin
                        if(tick_cnt_reg == 2) begin
                            if(dht_io == 1) begin
                                next = DATA;
                                tick_cnt_next = 0;
                            end
                        end
                        else begin
                                next = DATA_SYNC;
                                tick_cnt_next = tick_cnt_reg + 1;
                        end
                    end
           end
           DATA : begin // 6
                    if(dht_io == 0) begin
                        if(tick_cnt_reg <= DATA_decision-1) begin
                            next = DATA0;
                        end
                        else begin
                            next = DATA1;
                        end
                    end
                    else begin
                        if(tick_10us) begin
                            tick_cnt_next = tick_cnt_reg + 1;
                        end
                    end
           end 

           DATA0 : begin // 7
                    data_next = {data_reg[38:0],1'b0};
                    tick_cnt_next = 0;
                    if(data_cnt_reg == 40-1) begin
                    next = STOP;
                    end
                    else begin 
                    next = DATA_SYNC;
                    data_cnt_next = data_cnt_reg +1;
                    end
           end
           DATA1 : begin //8
                    data_next = {data_reg[38:0],1'b1};
                    tick_cnt_next = 0;
                    if(data_cnt_reg == 40-1) begin
                    next = STOP;
                    end
                    else begin 
                    next = DATA_SYNC;
                    data_cnt_next = data_cnt_reg +1;
                    end
           end

           STOP : begin // 9
                    data_cnt_next = 0;
                    if(tick_cnt_reg == STOP_CNT-1) begin
                        next = IDLE;
                        tick_cnt_next = 0;
                        io_out_next = 1'b1;
                        io_oe_next = 1'b1;
                    end
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
           end
        endcase
        
    end





endmodule


module tick_genp_10us(
    input clk,
    input rst,
    output tick_10us
);

    reg [$clog2(1000)-1:0] cnt_reg, cnt_next;
    reg tick_reg, tick_next;

    assign tick_10us = tick_reg;


    always @(posedge clk, posedge rst) begin
        if(rst) begin
            cnt_reg <= 0;
            tick_reg <= 0;
        end
        else begin
            cnt_reg <= cnt_next;
            tick_reg <= tick_next;
        end
    end

    always @(*) begin
        cnt_next = cnt_reg;
        tick_next = 0;
        if(cnt_reg == 1000-1) begin
            cnt_next = 0;
            tick_next = 1;
        end
        else begin
            cnt_next = cnt_reg + 1;
            tick_next = 0;
        end
        
    end


endmodule