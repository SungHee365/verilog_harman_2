`timescale 1ns / 1ps

module ram (
    input  logic        clk,
    input  logic        we,
    input  logic [31:0] addr,
    input  logic [31:0] wData,
    output logic [31:0] rData
);
    logic [31:0] mem[0:9];

    initial begin
        //rom[x]=32'b imm12      _ rs1 _f3 _ rd  _ opcode; // L-Type
        mem[4] = 32'hffffffff;
    end

    always_ff @( posedge clk ) begin
        if (we) mem[addr[31:0]] <= wData;
    end

    assign rData = mem[addr[31:0]];
endmodule
