`timescale 1ns / 1ps


module fifo(
    input logic clk,
    input logic reset,
    // write side
    input logic [7:0] wdata,
    input logic        wr_en,
    output logic       full,
    // read side
    output logic [7:0] rdata,
    input  logic       rd_en,
    output logic       empty
);

    logic [3:0] wr_ptr,rd_ptr;

    fifo_ram U_reg(
        .clk(clk),
        //write side
        .wAddr(wr_ptr),
        .wdata(wdata),
        .wr_en(wr_en & ~full),
        // read side
        .rAddr(rd_ptr),
        .rdata(rdata)
    );    
    fifo_control_unit U_fifo_cu(.*);

endmodule


module fifo_ram(
    input logic        clk,
    input logic  [3:0] wAddr,
    input logic  [7:0] wdata,
    input logic        wr_en,
    input logic  [3:0] rAddr,
    output logic [7:0] rdata
);
    logic [7:0] mem[0:2**10-1];
    initial begin
        mem[0] = 120;
    end

    always_ff @( posedge clk ) begin
        if(wr_en) mem[wAddr] <= wdata;        
    end

    assign rdata = mem[rAddr];

endmodule

module fifo_control_unit(
    input logic clk,
    input logic reset,
    // write side
    output logic [3:0] wr_ptr,
    input logic        wr_en,
    output logic       full,
    // read side
    output logic [3:0] rd_ptr,
    input  logic       rd_en,
    output logic       empty
);
    localparam READ = 2'b01, WRITE = 2'b10, READ_WRITE = 2'b11;

    logic [3:0] rd_ptr_reg, rd_ptr_next;
    logic [3:0] wr_ptr_reg, wr_ptr_next;
    logic full_reg, full_next;
    logic empty_reg, empty_next;


    logic [1:0] fifo_state;

    assign fifo_state = {wr_en, rd_en};
    assign full = full_reg;
    assign empty = empty_reg;
    assign wr_ptr = wr_ptr_reg;
    assign rd_ptr = rd_ptr_reg;

    always_ff @( posedge clk, posedge reset ) begin 
        if(reset) begin
            wr_ptr_reg <= 0;
            rd_ptr_reg <= 0;
            full_reg <= 1'b0;
            empty_reg <= 1'b1;
        end
        else begin
            wr_ptr_reg <= wr_ptr_next;
            rd_ptr_reg <= rd_ptr_next;
            full_reg <= full_next;
            empty_reg <= empty_next;
        end
    end

    always_comb begin : fifo_comb
    wr_ptr_next = wr_ptr_reg;
    rd_ptr_next = rd_ptr_reg;
    empty_next = empty_reg;
    full_next = full_reg;
        case (fifo_state)
            READ: begin
                if(empty_reg == 1'b0) begin
                    full_next = 0;
                    rd_ptr_next = rd_ptr_reg + 1;
                    if(rd_ptr_next == wr_ptr_reg) begin
                        empty_next = 1'b1;
                    end
                end
            end
            WRITE: begin
                if(full_reg == 1'b0) begin
                    empty_next = 1'b0;
                    wr_ptr_next = wr_ptr_reg + 1;
                    if(wr_ptr_next == rd_ptr_reg) begin
                        full_next = 1'b1;
                    end
                end
            end
            READ_WRITE : begin
                if(empty_reg == 1'b1) begin
                    wr_ptr_next = wr_ptr_reg + 1;
                    empty_next = 1'b0;
                end 
                else if(full_reg == 1'b1) begin
                    rd_ptr_next = rd_ptr_reg + 1;
                    full_next = 1'b0;
                end
                else begin
                    wr_ptr_next = wr_ptr_reg + 1;
                    rd_ptr_next = rd_ptr_reg + 1;
                end
            end 
        endcase
    end

endmodule