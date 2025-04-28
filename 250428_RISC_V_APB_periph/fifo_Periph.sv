`timescale 1ns / 1ps

module fifo_Periph(
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // inport signals
    input rx,
    output tx
);

    logic [7:0] FWD;
    logic [7:0] FRD;
    logic       wr_en,rd_en;
    logic       full,empty;

    APB_SlaveIntf_FIFO U_APB_Intf (.*);
    TOP_UART_Stopwatch_Clock U_UART(
    .clk(PCLK),
    .rst(PRESET),
    .rx(rx), // pc in rx
    .tx(tx), // pc out tx
    // FIFO RX
    .RX_rd(rd_en),
    .RX_rdata(FRD),
    .RX_empty(empty),
    // FIFO TX
    .TX_wr(wr_en),
    .TX_wdata(FWD),
    .TX_full(full)
    );

endmodule

module APB_SlaveIntf_FIFO (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // internal signals
    input  logic full, empty,
    input  logic [7:0] FRD,
    output logic [7:0] FWD, 
    output logic wr_en,rd_en
);

    typedef enum {IDLE, WRITE, READ  } state_e;
    state_e state,next;    


    logic [31:0] slv_reg0, slv_reg1, slv_reg2;  //, slv_reg3;
    logic [1:0] FSR; // 0 읽기쓰기 가능, 1일때 읽기만가능, 2일떄 쓰기만가능  3은 존제 x
    logic delayR, Rdelay;
    logic wr_en_reg, wr_en_next;
    logic rd_en_reg, rd_en_next;

    assign Rdelay = PSEL && PENABLE;
    assign wr_en = wr_en_reg;
    assign rd_en = rd_en_reg;

    assign FSR = {empty,full};
    assign FWD = slv_reg1[7:0];

    assign slv_reg0 = FSR;
    assign slv_reg2[7:0] = FRD;



    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
        //   slv_reg0 <= 0;
            slv_reg1 <= 0;
        //     slv_reg2 <= 0;
            // slv_reg3 <= 0;
            wr_en_reg <= 0;
            rd_en_reg <= 0;
            delayR <= 0;
            state <= IDLE;
        end else begin
            wr_en_reg <= wr_en_next;
            rd_en_reg <= rd_en_next;
            delayR <= Rdelay;
            state <= next;
            if (PSEL && PENABLE) begin
                PREADY <= delayR;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: ;
                        2'd1: slv_reg1 <= PWDATA ;
                        2'd2: ;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        //2'd1: PRDATA <= slv_reg1;
                        2'd2: PRDATA <= slv_reg2[7:0]; 
                        // 2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= delayR;
            end
        end
    end

    always_comb begin
        wr_en_next = 1'b0;
        rd_en_next = 1'b0;
        next = state;
        case(state)
            IDLE: begin
                if(PSEL && PENABLE && PWRITE && (PADDR[3:2] == 2'd1)) next = WRITE;
                if(PSEL && PENABLE && (PWRITE == 0) && (PADDR[3:2] == 2'd2)) next = READ;
            end
            WRITE: begin
                wr_en_next = 1'b1;
                next = IDLE;
            end
            READ:begin
                rd_en_next = 1'b1;
                next = IDLE;
            end
        endcase
    end




endmodule