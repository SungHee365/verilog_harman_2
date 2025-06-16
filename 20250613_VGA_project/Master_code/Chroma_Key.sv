`timescale 1ns / 1ps

module Chroma_Key(
    input   logic   [9:0]   x_pixel,
    input   logic   [9:0]   y_pixel,
    input   logic   DE,
    input   logic   [11:0]  rData,
    output  logic   [3:0]   red_port,
    output  logic   [3:0]   green_port,
    output  logic   [3:0]   blue_port
    );

    logic   chroma_target;
    logic   [3:0]   red_data, green_data, blue_data;
    logic   [11:0]  background_Data;
    
    assign  red_data = rData[11:8];
    assign  green_data = rData[7:4];
    assign  blue_data = rData[3:0];

    assign  chroma_target = 
            (green_data > 5) &&                
            (green_data > red_data + 3) &&      
            (green_data > blue_data + 3);   

    assign  {red_port, green_port, blue_port} = chroma_target ?
            background_Data : rData;

    ImageRom_BG U_BG_ROM(
        .x_pixel(x_pixel>>1),
        .y_pixel(y_pixel>>1),
        .DE(DE),
        .background_Data(background_Data)
    );


endmodule

module ImageRom_BG (
    input   logic   [9:0]   x_pixel,
    input   logic   [9:0]   y_pixel,
    input   logic   DE,
    output  logic   [11:0]  background_Data
);
    logic   [16:0]  image_addr;
    logic   [15:0]  image_data;     // RGB565 => 16'b rrrrr_gggggg_bbbbb -> RGB444 (상위 4bit만 사용)

    assign  image_addr =  320*y_pixel + x_pixel;
    assign  background_Data = DE ? {image_data[15:12], image_data[10:7], image_data[4:1]} : {4'b0, 4'b0, 4'b0};

    image_rom_BG U_ROM(
        .addr(image_addr),
        .data(image_data)
    );
    
endmodule

module image_rom_BG(
    input   logic   [16:0]  addr,
    output  logic   [15:0]  data
    );

    logic   [16:0]  rom[0:320*240-1];
    initial begin
        $readmemh("background.mem", rom);
    end

    assign  data = rom[addr];
endmodule