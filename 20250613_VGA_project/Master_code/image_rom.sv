`timescale 1ns / 1ps

module image_rom_Candy_normal (
    input logic clk,
    input  logic [16:0] addr,
    output logic [15:0] data
);
    logic [15:0] rom[0:50*50-1];

    initial begin
        $readmemh("Candy_normal.mem", rom);
    end
/*
    always_ff @(posedge clk) begin
        data <= rom[addr];
    end
*/

    assign data  = rom[addr];
endmodule


module image_rom_Candy_special (
    input logic clk,
    input  logic [16:0] addr,
    output logic [15:0] data
);
    logic [15:0] rom[0:50*50-1];

    initial begin
        $readmemh("Candy_special.mem", rom);
    end

    always_ff @(posedge clk) begin
        data <= rom[addr];
    end 
endmodule

module image_rom_pokemon_bread (
    input logic clk,
    input  logic [16:0] addr,
    output logic [15:0] data
);
    logic [15:0] rom[0:50*50-1];

    initial begin
        $readmemh("pokemon_bread.mem", rom);
    end
/*
    always_ff @(posedge clk) begin
        data <= rom[addr];
    end 
    */
    assign data  = rom[addr];
endmodule

module image_rom_start (
    input logic clk,
    input  logic [16:0] addr,
    output logic [15:0] data
);
    logic [15:0] rom[0:130*130-1];

    initial begin
        $readmemh("monster_ball.mem", rom);
    end
/*
    always_ff @(posedge clk) begin
        data <= rom[addr];
    end
    */
    assign data  = rom[addr];
endmodule

module image_rom_end (
    input logic clk,
    input  logic [16:0] addr,
    output logic [15:0] data
);
    logic [15:0] rom[0:150*90-1];

    initial begin
        $readmemh("retry.mem", rom);
    end
/*
    always_ff @(posedge clk) begin
        data <= rom[addr];
    end
    */
    assign data  = rom[addr];
endmodule

