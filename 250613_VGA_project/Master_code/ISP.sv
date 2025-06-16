`timescale 1ns / 1ps

module ImageSignalProcessor (
    input  logic        clk,

    // background
    input  logic        bg_en,
    input  logic [15:0] bg_data,

    // object
    input  logic        obj_en_start,
    input  logic [15:0] obj_data_start,
    input  logic        obj1_en,
    input  logic [15:0] obj1_data,
    input  logic        obj2_en,
    input  logic [15:0] obj2_data,
    input  logic        obj3_en,
    input  logic [15:0] obj3_data,
    input  logic        obj_en_ending,
    input  logic [15:0] obj_data_ending,


    // timer
    input  logic        timer_area,
    input  logic        timer_left,

    // output
    output logic [3:0]  red_port,
    output logic [3:0]  green_port,
    output logic [3:0]  blue_port
);

    logic [15:0] selected_data;
    logic        active_en = obj_en_start | obj1_en | obj2_en | obj3_en | obj_en_ending | bg_en;

    assign selected_data =  timer_left      ? 16'hffff          :
                            timer_area      ? 16'h001f          : 
                            obj_en_start    ? obj_data_start    : 
                            obj1_en         ? obj1_data         : 
                            obj2_en         ? obj2_data         : 
                            obj3_en         ? obj3_data         : 
                            obj_en_ending   ? obj_data_ending   :
                            bg_data;

    assign red_port   = active_en ? selected_data[15:12] : 4'd0;
    assign green_port = active_en ? selected_data[10:7]  : 4'd0;
    assign blue_port  = active_en ? selected_data[4:1]   : 4'd0;

endmodule
