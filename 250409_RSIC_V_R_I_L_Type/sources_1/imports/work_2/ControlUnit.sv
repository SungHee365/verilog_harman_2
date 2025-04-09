`timescale 1ns / 1ps

`include "defines.sv"

module ControlUnit (
    input  logic [31:0] instrCode,
    output logic        regFileWe,
    output logic [ 3:0] aluControl,
    output logic        aluSrcMuxSel,
    output logic        dataWe,
    output logic        RFWDSrcMuxSel,
    output logic        shamt_signal
);
    wire [6:0] opcode = instrCode[6:0];
    wire [3:0] operators = {instrCode[30], instrCode[14:12]};  // {func7[5], func3}


// op코드 i타입 이면서 이거 적용

    logic [4:0] signals;
    assign {regFileWe, aluSrcMuxSel, dataWe, RFWDSrcMuxSel, shamt_signal} = signals;

    always_comb begin
        signals = 5'b0;
        case (opcode)
        // {regFileWe, aluSrcMuxSel, dataWe,RFWDSrcMuxSel, shamt_signal} = signals;
            `OP_TYPE_R : signals = 5'b1_0_0_0_0;  // R-Type
            `OP_TYPE_L : signals = 5'b1_1_0_1_0;  // L-Type;
            `OP_TYPE_S : signals = 5'b0_1_1_0_0;  // sw 만 구현
            `OP_TYPE_I : begin
                if(operators == 4'bx001 || operators == 4'bx101)
                signals = 5'b1_1_0_0_1; 
                else // 
                signals = 5'b1_1_0_0_0; 
            end
        endcase
    end

    always_comb begin
        aluControl = 4'bx;
        case (opcode)
            `OP_TYPE_R : aluControl = operators;
            `OP_TYPE_L : aluControl = `ADD;
            `OP_TYPE_S : aluControl = `ADD;
            `OP_TYPE_I : aluControl = operators;
        endcase
    end


endmodule

