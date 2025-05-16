`timescale 1ns / 1ps

module FSM_Slave_to_FND(
    // Slave signal
    input logic clk,
    input logic rst,
    input logic [7:0] data,
    input logic CS,
    input logic done,
    // fnd signal
    output logic [15:0] fnd_Data
    );

    typedef enum  { IDLE, L_BYTE, H_BYTE  } state_e;

    state_e state_reg, state_next;
    logic [15:0] fnddata_reg, fnddata_next;

    assign fnd_Data = fnddata_reg;

    always_ff @( posedge clk, posedge rst ) begin 
        if(rst) begin
            state_reg <= IDLE;
            fnddata_reg <= 1'b0;
        end
        else begin
            state_reg <= state_next;     
            fnddata_reg <= fnddata_next;
        end
    end

    always_comb begin
        state_next = state_reg;
        fnddata_next = fnddata_reg;
        case (state_reg)
            IDLE: begin
                fnddata_next = fnddata_reg;
                if(CS == 0) begin
                    state_next = L_BYTE;
                end
            end
            L_BYTE: begin
                if( (CS == 0) && (done == 1)) begin
                    fnddata_next[7:0] = data;
                    state_next = H_BYTE;
                end
            end
            H_BYTE: begin
                if((CS == 0) && (done == 1)) begin
                    fnddata_next[15:8] = data;
                    state_next = IDLE;
                end
            end
        endcase        
    end
endmodule

