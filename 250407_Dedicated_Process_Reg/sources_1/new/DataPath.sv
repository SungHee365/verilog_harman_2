`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/07 12:38:46
// Design Name: 
// Module Name: DataPath
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module DataPath(
    input logic clk,
    input logic rst,
    input logic MuxSel,
    input logic [3:0] raddr1,
    input logic [3:0] raddr2,
    input logic [3:0] waddr,
    input logic wEn,
    input logic outBuf,
    output logic le,
    output logic [7:0] outport
    );


    logic [7:0] adderResult, MuxData, rData1, rData2;

    assign outport = outBuf ? rData2 : 8'bz;


mux_2x1 U_mux(
    .sel(MuxSel), 
    .x0(adderResult),    
    .x1(1),
    .y(MuxData)
);

RegFile U_Reg(
    .clk(clk),
    .readAddr1(raddr1),
    .readAddr2(raddr2),
    .writeAddr(waddr),
    .writeEn(wEn),
    .wData(MuxData),
    .rData1(rData1),
    .rData2(rData2)
);

adder U_adder(
    .a(rData1),
    .b(rData2),
    .sum(adderResult)
);

comparator U_Comp(
    .a(rData1),
    .b(8'd10),
    .le(le)
);


endmodule



module mux_2x1(
    input logic sel, 
    input logic [7:0] x0,    
    input logic [7:0] x1,
    output logic [7:0] y    
);

    always_comb begin : mux
        y = 8'b0;
        case (sel)
            1'b0: y = x0;
            1'b1: y = x1;
        endcase
    end

endmodule

module RegFile (
    input logic clk,
    input logic [2:0] readAddr1,
    input logic [2:0] readAddr2,
    input logic [2:0] writeAddr,
    input logic writeEn,
    input logic [7:0] wData,
    output logic [7:0] rData1,
    output logic [7:0] rData2
);
    logic [7:0] mem [0:7];

    always_ff @( posedge clk ) begin
        if(writeEn) mem[writeAddr] <= wData;
    end

    assign rData1 = (readAddr1 == 3'b0) ? 8'b0 : mem[readAddr1];
    assign rData2 = (readAddr2 == 3'b0) ? 8'b0 : mem[readAddr2];

endmodule

module adder(
    input logic [7:0] a,
    input logic [7:0] b,
    output logic [7:0] sum
);

    assign sum = a + b;

endmodule

module comparator(
    input logic [7:0] a,
    input logic [7:0] b,
    output logic le
);

assign le = a <= b;

endmodule