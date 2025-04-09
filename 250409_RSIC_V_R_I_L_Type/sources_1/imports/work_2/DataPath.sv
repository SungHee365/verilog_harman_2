`timescale 1ns / 1ps

`include "defines.sv"

module DataPath (
    input  logic        clk,
    input  logic        reset,
    // control unit side port
    input  logic        regFileWe,
    input  logic [ 3:0] aluControl,
    input  logic        aluSrcMuxSel,
    input  logic        RFWDSrcMuxSel,
    input  logic        shamt_signal,
    // instr memory side port
    input  logic [31:0] instrCode,
    output logic [31:0] instrMemAddr,
    // data memory side port
    output logic [31:0] dataAddr,
    output logic [31:0] dataWData,
    input  logic [31:0] dataRData
);
    logic [31:0] aluResult, RFData1, RFData2;
    logic [31:0] PCSrcData, PCOutData;
    logic [31:0] immExt, aluSrcMuxOut;
    logic [31:0] RFWDSrcMuxOut;

    assign instrMemAddr = PCOutData;
    assign dataAddr = aluResult;
    assign dataWData = RFData2;

    mux_2x1 U_RFWDSrcMux(
        .sel(RFWDSrcMuxSel),
        .x0(aluResult),
        .x1(dataRData),
        .y(RFWDSrcMuxOut)
    );


    RegisterFile U_RegFile (
        .clk(clk),
        .we(regFileWe),
        .RAddr1(instrCode[19:15]),
        .RAddr2(instrCode[24:20]),
        .WAddr(instrCode[11:7]),
        .WData(RFWDSrcMuxOut),
        .RData1(RFData1),
        .RData2(RFData2)
    );

    mux_2x1 U_ALUSrcMux(
        .sel(aluSrcMuxSel),
        .x0(RFData2),
        .x1(immExt),
        .y(aluSrcMuxOut)
    );


    alu U_ALU (
        .aluControl(aluControl),
        .a(RFData1),
        .b(aluSrcMuxOut),
        .result(aluResult)
    );
// signal 1 일떈 shamt가 아닐떈 immext가 나가야됨 


    extend U_ImmExtend(
        .shamt_signal(shamt_signal),
        .instrCode(instrCode),
        .immExt(immExt)
    );
    
    register U_PC (
        .clk(clk),
        .reset(reset),
        .d(PCSrcData),
        .q(PCOutData)
    );

    adder U_PC_Adder (
        .a(32'd4),
        .b(PCOutData),
        .y(PCSrcData)
    );



endmodule



module alu (
    input  logic [ 3:0] aluControl,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] result
);
    always_comb begin
        case (aluControl)
            `ADD:   result = a + b; 
            `SUB:   result = a - b; 
            `SLL:   result = a << b; 
            `SRL:   result = a >> b; 
            `SRA:   result = $signed(a) >>> $signed(b); 
            `SLT:   result = ($signed(a) < $signed(b)) ? 1 : 0; 
            `SLTU:   result = (a < b) ? 1 : 0; 
            `XOR:   result = a ^ b;
            `OR:   result = a | b;
            `AND:   result = a & b;
            default: result = 32'bx;
        endcase
    end
endmodule

module register (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] d,
    output logic [31:0] q
);
    always_ff @(posedge clk, posedge reset) begin
        if (reset) q <= 0;
        else q <= d;
    end
endmodule

module adder (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] y
);
    assign y = a + b;
endmodule

module RegisterFile (
    input  logic        clk,
    input  logic        we,
    input  logic [ 4:0] RAddr1,
    input  logic [ 4:0] RAddr2,
    input  logic [ 4:0] WAddr,
    input  logic [31:0] WData,
    output logic [31:0] RData1,
    output logic [31:0] RData2
);
    logic [31:0] RegFile[0:2**5-1];
    initial begin
        for (int i=0; i<32; i++) begin
            RegFile[i] = 10 + i;
        end
    end

    always_ff @(posedge clk) begin
        if (we) RegFile[WAddr] <= WData;
    end

    assign RData1 = (RAddr1 != 0) ? RegFile[RAddr1] : 32'b0;
    assign RData2 = (RAddr2 != 0) ? RegFile[RAddr2] : 32'b0;
endmodule

module mux_2x1 (
    input logic sel,
    input logic [31:0] x0,
    input logic [31:0] x1,
    output logic [31:0] y
);

always_comb begin
    case (sel)
        1'b0: y = x0;
        1'b1: y = x1; 
        default: y = 32'bx; 
    endcase
end

endmodule


module extend(
    input logic [31:0] instrCode,
    input logic        shamt_signal,
    output logic [31:0] immExt
);
    wire [7:0] opcode = instrCode[6:0];

    always_comb begin
        immExt = 32'bx;
        case (opcode)
            `OP_TYPE_R: immExt = 32'bx;
            `OP_TYPE_L: immExt = {{20{instrCode[31]}},instrCode[31:20]};
 //           `OP_TYPE_I: immExt = {{20{instrCode[31]}},instrCode[31:20]};
            `OP_TYPE_S: immExt = {{20{instrCode[31]}},instrCode[31:25],instrCode[11:7]};
            `OP_TYPE_I: begin
                if(shamt_signal) begin
                    immExt = {{27{instrCode[31]}},instrCode[24:20]};
                end
                else begin
                    immExt = {{20{instrCode[31]}},instrCode[31:20]};
                end
            end
            default: immExt = 32'bx;
        endcase
    end
endmodule

// mux 사용 0일떈 imm 1일떈 shamt가 나가는걸로

/*
module cut_bit(
    input logic [2:0] sel,
    input logic [31:0] x,
    output logic [31:0] y
);

    always_comb begin
        y = 32'bx;
        case (sel)
            3'b000: y = {{24{x[7]}}, x[7:0]};
            3'b001: y = {{16{x[15]}}, x[15:0]};
            3'b010: y = x;
            3'b100: y = {24'b0, x[7:0]};
            3'b110: y = {16'b0, x[15:0]};
            default: y = x; 
        endcase
        
    end


endmodule
*/
