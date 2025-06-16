`timescale 1ns / 1ps

module OV7670_VGA_Display (
    // global signals
    input logic clk,
    input logic reset,
    input logic poke_rst,

    // OV7670 camera signals
    input  logic       ov7670_pclk,
    output logic       ov7670_xclk,
    input  logic       ov7670_href,
    input  logic       ov7670_v_sync,
    input  logic [7:0] ov7670_data,

    // VGA output signals
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port,

    //output collsion

    // SCCB
    input logic start_btn,
    output logic SCL,
    output logic SDA,

    //
    output collision_detected,
    output collision_detected1,
    output collision_detected2,
    output collision_detected3,
    output collision_detected_ending,
    output o_poke_rst
    // uart
//    output logic tx
);

    // Object Area
    logic   collision_area, collision_area1, collision_area2, collision_area3, collision_area_ending;
//    logic   collision_detected, collision_detected1, collision_detected2, collision_detected3, collision_detected_ending;
    logic collision_en_start;
    logic collision_en1;
    logic collision_en2;
    logic collision_en3;
    logic collision_en_ending;

    // Framebuffer connections
    logic        we;
    logic [16:0] wAddr;
    logic [15:0] wData;
    logic [16:0] rAddr;
    logic [15:0] rData;
    logic        oe;
    logic [3:0]  red_data, green_data, blue_data;

    // VGA controller output
    logic [ 9:0] x_pixel;
    logic [ 9:0] y_pixel;
    logic        DE;

    // clock for write/read
    logic w_rclk, rclk;

    // uart
    logic tick;
    logic [7:0] data;
    logic start;

    // Game Timer
    logic start_trigger;
    logic [9:0] pixel_timer;
    logic end_trigger;

    assign o_poke_rst = poke_rst;
    // OV7670 pixel clock generator
    pixel_clk_gen U_OV7670_Clk_Gen (
        .clk  (clk),
        .reset(reset),
        .pclk (ov7670_xclk)
    );

    SCCB_intf U_SCCB(
        .clk(clk),
        .reset(reset),
        .start_btn(start_btn),
        .SCL(SCL),
        .SDA(SDA)
    );

    // VGA timing generator
    VGA_Controller U_VGA_Controller (
        .clk    (clk),
        .reset  (reset),
        .rclk   (w_rclk),
        .h_sync (h_sync),
        .v_sync (v_sync),
        .DE     (DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel)
    );


    game_timer U_GAME_TIMER(
        .clk(clk),
        .reset(reset),
        .start_trigger(start_trigger),
        .data(data),
        .pixel_timer(pixel_timer),
        .end_trigger(end_trigger)
    );


    // QVGA memory controller
    QVGA_Mem U_QVGA_MEM_Controller (
        .clk              (clk),
        .reset            (reset),
        .x_pixel          (x_pixel),
        .y_pixel          (y_pixel),
        .DE               (DE),
        .collision_trigger(collision_detected),
        .collision_trigger1(collision_detected1),
        .collision_trigger2(collision_detected2),
        .collision_trigger3(collision_detected3),
        .collision_trigger_ending(collision_detected_ending),
 
        .d_en (oe),
        .rAddr(rAddr),
        .rData(rData),

        .red_port  (red_data),
        .green_port(green_data),
        .blue_port (blue_data),
        .collision_area      (collision_area),
        .collision_area1(collision_area1),
        .collision_area2(collision_area2),
        .collision_area3(collision_area3),
        .collision_area_ending(collision_area_ending),
        .upscale(1'b0),

        .start_trigger(start_trigger),
        .end_trigger(end_trigger),
        .pixel_timer(pixel_timer),

        .collision_en_start(collision_en_start),
        .collision_en1(collision_en1),
        .collision_en2(collision_en2),
        .collision_en3(collision_en3),
        .collision_en_ending(collision_en_ending)

    );

    Chroma_Key U_Chroma_KEY (
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .DE(DE),
        .rData({red_data, green_data, blue_data}),
        .red_port(red_port),
        .green_port(green_port),
        .blue_port(blue_port)
    );

    // OV7670 → Memory 변환
    OV_7670_MemController U_OV7670_MemController (
        .pclk       (ov7670_pclk),
        .reset      (reset),
        .href       (ov7670_href),
        .v_sync     (ov7670_v_sync),
        .ov7670_data(ov7670_data),
        .we         (we),
        .wAddr      (wAddr),
        .wData      (wData)
    );

    // Dual-port framebuffer
    framebuffer U_FrameBuffer (
        // write side
        .wclk (ov7670_pclk),
        .we   (we),
        .wAddr(wAddr),
        .wData(wData),

        // read side
        .rclk (clk),
        .oe   (oe),
        .rAddr(rAddr),
        .rData(rData)
    );

    Collision_Detector U_Collision_Detector (
        // Global Signals
        .clk_25MHz         (ov7670_pclk),
        .reset             (reset),
        // Object Signal(Object가 차지하는 영역)
        .collision_area       (collision_area),
        .collision_area1       (collision_area1),
        .collision_area2       (collision_area2),
        .collision_area3       (collision_area3),
        .collision_area_ending       (collision_area_ending),
        // Input RGB Port
        .red               (rData[15:12]),
        .green             (rData[10:7]),
        .blue              (rData[4:1]),
        // Collision Signal
        .collision_detected(collision_detected),
        .collision_detected1(collision_detected1),
        .collision_detected2(collision_detected2),
        .collision_detected3(collision_detected3),
        .collision_detected_ending(collision_detected_ending),

        .collision_en_start(collision_en_start),
        .collision_en1(collision_en1),
        .collision_en2(collision_en2),
        .collision_en3(collision_en3),
        .collision_en_ending(collision_en_ending)
    );
/*
    UART_TX U_uart(
    .clk(clk),
    .rst(reset),
    .tick(tick),
    .start_trigger(start),
    .data_in(data),
    .o_tx(tx), 
    .o_tx_done()
);

    baud_tick_genp U_tick_gen(
    .clk(clk),
    .rst(reset),
    .baud_tick(tick)
);
*/
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
    assign num = {pulse_poke_rst,pulse_detected_ending, pulse_detected3, pulse_detected2, pulse_detected1, pulse_detected};


    always_comb begin
        start = 0;
        data = 0;
        case(num)
            6'b000001: begin start = 1; data = 8'h40; end
            6'b000010: begin start = 1; data = 8'h41; end
            6'b000100: begin start = 1; data = 8'h42; end
            6'b001000: begin start = 1; data = 8'h43; end
            6'b010000: begin start = 1; data = 8'h44; end
            6'b100000: begin start = 1; data = 8'h45; end
        endcase
    end

endmodule
