`timescale 1ns / 1ps
module receive_uart_tx (
    input clk,
    input reset,
    output o_tx,
    input  logic       collision_detected,
    input  logic       collision_detected1,
    input  logic       collision_detected2,
    input  logic       collision_detected3,
    input  logic       collision_detected_ending,
    input  logic       poke_rst
);
    logic    tick;
    logic    [7:0] data;
    logic    start;
    
    UART_TX U_uart(
    .clk(clk),
    .rst(reset),
    .tick(tick),
    .start_trigger(start),
    .data_in(data),
    .o_tx(o_tx), 
    .o_tx_done()
);

    baud_tick_genp U_tick_gen(
    .clk(clk),
    .rst(reset),
    .baud_tick(tick)
);

    mux_collision_data U_MUX_data(
    .clk(clk),
    .reset(reset),
    .poke_rst(poke_rst),
    .collision_detected(collision_detected),
    .collision_detected1(collision_detected1),
    .collision_detected2(collision_detected2),
    .collision_detected3(collision_detected3),
    .collision_detected_ending(collision_detected_ending),
    .start(start),
    .data(data)
    );

endmodule


module UART_TX(
    input clk,
    input rst,
    input tick,
    input start_trigger,
    input [7:0] data_in,
    output o_tx, o_tx_done
);

    parameter IDLE = 0, SEND = 1, START = 2, D = 3,
              STOP = 4;


    reg tx_reg, tx_next, tx_done_reg, tx_done_next;
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    reg [3:0] state, next;  
    reg [3:0] tick_cnt_reg, tick_cnt_next ;


    // tx data in buffer
    reg[7:0] temp_data_reg, temp_data_next;

    assign o_tx = tx_reg;
    assign o_tx_done = tx_done_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= 0;
            tx_reg <= 1'b1; // 초기값
            tx_done_reg <= 0;
            bit_cnt_reg <= 0;
            tick_cnt_reg <= 0;
            temp_data_reg <=0;
        end
        else begin
            state <= next;
            tx_reg <= tx_next;
            tx_done_reg <= tx_done_next;
//            cnt_reg <= cnt_next;
            bit_cnt_reg <= bit_cnt_next;
            tick_cnt_reg <= tick_cnt_next;
            temp_data_reg <= temp_data_next;
        end
    end

    //next

    always @(*) begin
        next = state;
        tx_next = tx_reg;
        tx_done_next = tx_done_reg;
        bit_cnt_next = bit_cnt_reg;
        tick_cnt_next = tick_cnt_reg;
        temp_data_next = temp_data_reg;
 //       cnt_next = cnt_reg;
        case (state)
            IDLE : begin
                tx_next = 1'b1; // high
                tx_done_next = 1'b0; // 초기값
                tick_cnt_next = 4'h0; // 초기값
                if(start_trigger) begin 
                    next = START; // SEND;
                    // start trigger 순간 data를 buffring하기 위함.
                    temp_data_next = data_in;
                end
            end
            SEND : begin
                if(tick == 1'b1) begin
                    next = START;
                end
            end
            START : begin
                tx_done_next = 1'b1;
                tx_next = 1'b0; // 출력을 0으로 유지.
                if(tick == 1'b1) begin
                    if(tick_cnt_reg == 15) begin
                        next = D;
                        tick_cnt_next = 1'b0;
                        bit_cnt_next = 1'b0; // bit_cnt 초기화
                    end
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            D : begin 
                 tx_next = temp_data_reg[bit_cnt_reg];
   //             tx_next = data_in[bit_cnt_reg]; //UART LSB first
                if(tick) begin
                    if(tick_cnt_reg == 15) begin
                        tick_cnt_next = 0;
                        if(bit_cnt_reg == 7) begin
                            next = STOP;
                        end
                        else begin 
                            next = D;
                            bit_cnt_next = bit_cnt_reg + 1; // bit count 증가
                        end
                    end 
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
                /*
                if(tick == 1'b1) begin
                    tx_next = data_in[cnt_reg];
                    cnt_next = cnt_next + 1;
                    if(bit_cnt_next == 7) begin
                         next = STOP;
                         cnt_next = 0;
                    end
                end
                */
            end
            STOP : begin
                tx_next = 1'b1;
                if(tick == 1'b1) begin
                    if(tick_cnt_reg == 15) begin
                        next = IDLE;
                        tick_cnt_next = 1'b0;
                    end
                    else begin 
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
        endcase
    end


endmodule


module baud_tick_genp (
    input clk,
    input rst,
    output baud_tick
);

    parameter BAUD_RATE = 9600; //BAUD_RATE_19200 = 19200, ;
    localparam BAUD_COUNT = (100_000_000/BAUD_RATE)/16;
    reg [$clog2(BAUD_COUNT)-1:0] cnt_reg, cnt_next;
    reg tick_reg, tick_next;

    assign baud_tick = tick_reg;


    always @(posedge clk, posedge rst) begin

        if(rst) begin
            tick_reg <= 0;
            cnt_reg <= 0;
        end
        else begin
            cnt_reg <= cnt_next;
            tick_reg <= tick_next;
        end 
    end

    always @(*) begin
        cnt_next = cnt_reg;
        tick_next = tick_reg;
        if(cnt_reg == BAUD_COUNT-1) begin
            cnt_next = 0;
            tick_next = 1'b1; 
        end
        else begin
            cnt_next = cnt_reg + 1;
            tick_next = 1'b0;
        end
    end



endmodule

module mux_collision_data(
    input  logic       clk,
    input  logic       reset,
    input  logic       poke_rst,
    input  logic       collision_detected,
    input  logic       collision_detected1,
    input  logic       collision_detected2,
    input  logic       collision_detected3,
    input  logic       collision_detected_ending,
    output logic       start,
    output logic [7:0] data
);

    // 이전 collision_detected 값 저장용 레지스터들
    logic collision_detected_delay;
    logic collision_detected1_delay;
    logic collision_detected2_delay;
    logic collision_detected3_delay;
    logic collision_detected_ending_delay;
    logic poke_rst_delay;

    // 상승 엣지 발생 펄스
    logic pulse_detected;
    logic pulse_detected1;
    logic pulse_detected2;
    logic pulse_detected3;
    logic pulse_detected_ending;
    logic pulse_poke_rst;

    // num 신호 만들기 (엣지 기준 pulse로 생성)
    logic [5:0] num;

    logic [2:0] pulse_detected_cnt;
    logic [2:0] pulse_detected_ending_cnt;

    // 펄스 유지용 FF
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            pulse_detected_cnt        <= 0;
            pulse_detected_ending_cnt <= 0;
        end else begin
            // collision_detected 처리
            if (pulse_detected) begin
                pulse_detected_cnt <= 3'd2;
            end else if (pulse_detected_cnt != 0) begin
                pulse_detected_cnt <= pulse_detected_cnt - 1;
            end

            // collision_detected_ending 처리
            if (pulse_detected_ending) begin
                pulse_detected_ending_cnt <= 3'd2;
            end else if (pulse_detected_ending_cnt != 0) begin
                pulse_detected_ending_cnt <= pulse_detected_ending_cnt - 1;
            end
        end
    end

    // 최종 pulse 출력 (카운터가 0보다 크면 유지)
    logic pulse_detected_extended;
    logic pulse_detected_ending_extended;

    assign pulse_detected_extended        = (pulse_detected_cnt != 0);
    assign pulse_detected_ending_extended = (pulse_detected_ending_cnt != 0);


    // 이전 값 기억용 FF
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            collision_detected_delay        <= 0;
            collision_detected1_delay       <= 0;
            collision_detected2_delay       <= 0;
            collision_detected3_delay       <= 0;
            collision_detected_ending_delay <= 0;
            poke_rst_delay                  <= 0;
        end else begin
            collision_detected_delay        <= collision_detected;
            collision_detected1_delay       <= collision_detected1;
            collision_detected2_delay       <= collision_detected2;
            collision_detected3_delay       <= collision_detected3;
            collision_detected_ending_delay <= collision_detected_ending;
            poke_rst_delay                  <= poke_rst;
        end
    end

    // 엣지 검출
    assign pulse_detected        =  collision_detected        & ~collision_detected_delay;
    assign pulse_detected1       =  collision_detected1       & ~collision_detected1_delay;
    assign pulse_detected2       =  collision_detected2       & ~collision_detected2_delay;
    assign pulse_detected3       =  collision_detected3       & ~collision_detected3_delay;
    assign pulse_detected_ending =  collision_detected_ending & ~collision_detected_ending_delay;
    assign pulse_poke_rst        =  poke_rst                  & ~poke_rst_delay;

    // num 조합 (엣지 기준 pulse만 사용)
    assign num = {pulse_poke_rst, 
                  pulse_detected_ending_extended, 
                  pulse_detected3, 
                  pulse_detected2, 
                  pulse_detected1, 
                  pulse_detected_extended};

    always_comb begin
        start = 0;
        data = 0;
        case(num)
            6'b000001: begin start = 1; data = 8'h46; end
            6'b000010: begin start = 1; data = 8'h41; end
            6'b000100: begin start = 1; data = 8'h42; end
            6'b001000: begin start = 1; data = 8'h43; end
            6'b010000: begin start = 1; data = 8'h44; end
            6'b100000: begin start = 1; data = 8'h45; end
        endcase
    end

endmodule