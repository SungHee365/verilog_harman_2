`timescale 1ns / 1ps

module rom (
    input  logic [31:0] addr,
    output logic [31:0] data
);
    logic [31:0] rom[0:15];

    initial begin
        //rom[x]=32'b fucn7 _ rs2 _ rs1 _f3 _ rd  _opcode; // R-Type
        rom[0] = 32'b0000000_00001_00010_000_00100_0110011; // add x4, x2, x1 x4에 23값
        rom[1] = 32'b0100000_00001_00010_000_00101_0110011; // sub x5, x2, x1 x5에 1값
        //rom[x] = 32'b imm7 _ rs2_ rs1 _ f3_ imm5 _ opcode; // S-Type
        rom[2] = 32'b0000000_00010_00000_010_01000_0100011; // sw x2, 8(x0); ram x2에 12값
        //rom[x] = 32'b imm12     _ rs1  _f3 _ rd  _ opcode; // L-Type        
        rom[3] = 32'b0000000_01000_00000_010_00100_0000011; // lw x4, 8(x0); x4에 12값
        //rom[x] = 32'b imm12     _ rs1  _f3 _ rd  _ opcode; // I-Type nomal
        rom[4] = 32'b0000000_00010_00100_000_00100_0010011; // x4에 14값       
        //rom[x] = 32'b imm7_shamt_ rs1 _f3 _ rd  _ opcode; // I-Type shift
        rom[5] = 32'b0000000_00010_00101_001_00101_0010011; // x5에 4값
    end
    assign data = rom[addr[31:2]];
endmodule
