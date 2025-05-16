`timescale 1ns / 1ps

module Master(
    input clk,
    input rst,
    input logic btn,
    input logic [14:0] sw,
    input logic ready,
    input logic done,
    output logic start,
    output logic [7:0] data
);

    typedef enum { IDLE, L_START,L_READY, H_START,H_READY  } state_e;
    state_e state_reg, state_next;
    logic [7:0] temp_data_reg, temp_data_next;

    assign data = temp_data_reg;

    always_ff @( posedge clk, posedge rst ) begin
        if(rst) begin
            state_reg <= IDLE;            
            temp_data_reg <= 0;
        end
        else begin
            state_reg <= state_next; 
            temp_data_reg <= temp_data_next;
        end
    end

    always_comb begin
        state_next = state_reg;
        temp_data_next = temp_data_reg;
        start = 0;
        case (state_reg)
            IDLE: begin
                if(btn) begin
                    state_next = L_START;
                    temp_data_next = sw[7:0];
                end
            end
            L_START: begin
                if(ready) begin
                    start = 1;
                    state_next = L_READY;
                end
            end
            L_READY: begin
                if(done) begin
                    state_next = H_START;
                    temp_data_next = sw[14:8];
                end
            end
            H_START:  begin
                if(ready) begin
                    start = 1;
                    state_next = H_READY;
                end
            end
            H_READY: begin
                if(done) begin
                    state_next = IDLE;
                end
            end
        endcase
    end

endmodule


module SPI_Master(
    input logic clk,
    input logic rst,
    // master in out
    input logic start,
    input logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic done,
    output logic ready,
    // slave out
    output logic SCLK,
    output logic MOSI,
    input logic MISO,
    output logic CS
    );

    typedef enum { IDLE, 
                   CP0, 
                   CP1 
    } state_e;

    logic [7:0] temp_tx_data_reg, temp_tx_data_next;
    logic [7:0] temp_rx_data_reg, temp_rx_data_next;
    logic tick_reg, tick_next;
    logic SCLK_reg,SCLK_next;
    logic [$clog2(50):0] clk_cnt_reg, clk_cnt_next;
    logic [3:0] bit_cnt_reg, bit_cnt_next;
    state_e state_reg, state_next;

    assign SCLK = SCLK_reg;
    assign MOSI = (~CS) ? temp_tx_data_reg[7] : 1'bz;
    assign rx_data = temp_rx_data_reg;

    always_ff @( posedge clk, posedge rst ) begin
        if(rst) begin
            state_reg <= IDLE;
            SCLK_reg <= 0;
            clk_cnt_reg <= 0;
            bit_cnt_reg <= 0;
            temp_tx_data_reg <= 0;
            temp_rx_data_reg <= 0;
        end
        else begin
            state_reg <= state_next;
            SCLK_reg <= SCLK_next;
            clk_cnt_reg <= clk_cnt_next;
            bit_cnt_reg <= bit_cnt_next;
            temp_tx_data_reg <= temp_tx_data_next;
            temp_rx_data_reg <= temp_rx_data_next;
        end        
    end

    always_comb begin
        state_next = state_reg;
        SCLK_next = SCLK_reg;
        clk_cnt_next = clk_cnt_reg;
        bit_cnt_next = bit_cnt_reg;
        temp_tx_data_next = temp_tx_data_reg;
        temp_rx_data_next = temp_rx_data_reg;
        done = 0;
        ready = 0;
        CS = 0;
        case (state_reg)
            IDLE: begin
                    done = 0;
                    ready = 1;
                    CS = 1;
                    if(start) begin
                        CS = 0;
                        state_next = CP0;
                        temp_tx_data_next = tx_data;
                    end
            end
            CP0: begin
                    SCLK_next = 0;
                    if(clk_cnt_reg == 49) begin
                        clk_cnt_next = 0;
                        temp_rx_data_next = {temp_rx_data_reg[6:0],MISO};
                        state_next = CP1;
                    end
                    else clk_cnt_next = clk_cnt_reg + 1;

            end 
            CP1: begin
                    SCLK_next = 1;
                    if(clk_cnt_reg == 49) begin
                        clk_cnt_next = 0;
                        if(bit_cnt_reg == 7) begin
                            done = 1;
                            bit_cnt_next = 0;
                            state_next = IDLE;
                        end
                        else begin
                            temp_tx_data_next = {temp_tx_data_reg[6:0],1'b0};
                            bit_cnt_next = bit_cnt_reg+1;
                            state_next = CP0;
                        end
                    end
                    else clk_cnt_next = clk_cnt_reg + 1;
            end  
        endcase
    end



endmodule
