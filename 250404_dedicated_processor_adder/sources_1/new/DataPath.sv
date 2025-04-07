`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/04 17:23:33
// Design Name: 
// Module Name: ControllerUnit
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
    input logic MuxSel_2,
    input logic En,
    input logic En_2,
    output logic lt,
    input logic OutBuf,
    output logic [7:0] outPort
    );

    logic [7:0] w_sum;
    logic [7:0] w_q;
    logic [7:0] w_q_2;
    logic [7:0] w_d;
    logic [7:0] w_d_2;
    logic [7:0] w_outPort;


    assign outPort = (OutBuf) ? w_q_2 : 1'bz;

mux U_mux(
    .MuxSel(MuxSel),
    .A(w_sum),
    .d(w_d)
);

registor U_register(
    .En(En),
    .clk(clk),
    .rst(rst),
    .d(w_d),
    .q(w_q)
);

adder U_adder(
    .A(w_q),
    .B(1),
    .sum(w_sum)
);

mux U_mux_2(
    .MuxSel(MuxSel_2),
    .A(w_outPort),
    .d(w_d_2)
);

registor U_register_2(
    .En(En_2),
    .clk(clk),
    .rst(rst),
    .d(w_d_2),
    .q(w_q_2)
);

adder U_adder_2(
    .A(w_q_2),
    .B(w_q),
    .sum(w_outPort)
);


comparator U_comparator(
    .A(w_q),
    .B(10),
    .lt(lt)
);

endmodule


module mux (
    input logic MuxSel,
    input logic [7:0] A,
    output logic [7:0] d
);

    assign d = (MuxSel) ? A : 0;
    
endmodule

module registor(
    input logic En,
    input logic clk,
    input logic rst,
    input logic [7:0] d,
    output logic [7:0] q
);

    always_ff @( posedge clk, posedge rst ) begin
        if(rst) begin
            q <= 0;
        end
        else begin 
            if(En) q<=d;
        end
    end

endmodule

module adder(
    input logic [7:0] A,
    input logic [7:0] B,
    output logic [7:0] sum
);
    assign sum = A + B;

endmodule

module comparator(
    input logic [7:0] A,
    input logic [7:0] B,
    output logic lt
);

    assign lt = A < B;

endmodule