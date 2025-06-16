`timescale 1ns / 1ps

module Collision_Detector (
    // Global Signals
    input  logic        clk_25MHz,
    input  logic        reset,
    // Object Signal(Object가 차지하는 영역)
    input  logic        collision_area,
    input  logic        collision_area1,
    input  logic        collision_area2,
    input  logic        collision_area3,
    input  logic        collision_area_ending,
    // Input RGB Port
    input  logic [ 3:0] red,
    input  logic [ 3:0] green,
    input  logic [ 3:0] blue,
    // Collision Signal
    output logic        collision_detected,
    output logic        collision_detected1,
    output logic        collision_detected2,
    output logic        collision_detected3,
    output logic        collision_detected_ending,

    input logic collision_en_start,
    input logic collision_en1,
    input logic collision_en2,
    input logic collision_en3,
    input logic collision_en_ending

);
    parameter pixel_cnt_threshold = 50;
//    logic [5:0] pixel_cnt;
    assign user_color = (red > 4'd10) && (red > green + 3) && (red > blue + 3);

    always_ff @(posedge clk_25MHz, posedge reset) begin
        if (reset) begin
            collision_detected  <= 0;
            collision_detected1 <= 0;
            collision_detected2 <= 0;
            collision_detected3 <= 0;
            collision_detected_ending <= 0;
     //       pixel_cnt           <= 0;
        end else begin
            if (collision_area && user_color && collision_en_start) begin
           //     pixel_cnt <= pixel_cnt + 1;
           //     if (pixel_cnt >= pixel_cnt_threshold) begin
                    collision_detected <= 1;
            //        pixel_cnt          <= 0;
           //     end
            end else begin
                collision_detected <= 0;
            end
            if (collision_area1 && user_color && collision_en1) begin
           //     pixel_cnt <= pixel_cnt + 1;
           //     if (pixel_cnt >= pixel_cnt_threshold) begin
                    collision_detected1 <= 1;
           //         pixel_cnt          <= 0;
           //     end
            end else begin
                collision_detected1 <= 0;
            end
            if (collision_area2 && user_color && collision_en2) begin
           //     pixel_cnt <= pixel_cnt + 1;
           //     if (pixel_cnt >= pixel_cnt_threshold) begin
                    collision_detected2 <= 1;
           //        pixel_cnt          <= 0;
            //    end
            end else begin
                collision_detected2 <= 0;
            end
            if (collision_area3 && user_color && collision_en3) begin
           //     pixel_cnt <= pixel_cnt + 1;
           //     if (pixel_cnt >= pixel_cnt_threshold) begin
                    collision_detected3 <= 1;
            //        pixel_cnt          <= 0;
            //    end
            end else begin
                collision_detected3 <= 0;
            end
            if (collision_area_ending && user_color && collision_en_ending) begin
           //     pixel_cnt <= pixel_cnt + 1;
           //     if (pixel_cnt >= pixel_cnt_threshold) begin
                    collision_detected_ending <= 1;
           //         pixel_cnt          <= 0;
           //     end
            end else begin
                collision_detected_ending <= 0;
            end
        end
    end
endmodule
