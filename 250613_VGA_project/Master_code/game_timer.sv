`timescale 1ns / 1ps

module game_timer(
    input   logic   clk,
    input   logic   reset,
    input   logic   [7:0] data,
    input   logic   start_trigger,
    output  logic   [9:0]   pixel_timer,
    output  logic   end_trigger
    );

    logic   [23:0]  pixel_timer_counter_reg, pixel_timer_counter_next;
    logic   [9:0]   pixel_timer_reg, pixel_timer_next;
    logic           end_reg, end_next;
    logic [7:0] data_delay;
    logic data_rise;
    logic data_q;

    assign  pixel_timer = pixel_timer_reg;
    assign  end_trigger = end_reg;
    assign data_rise = (data == 8'h42) && (data_delay != 8'h42);

    typedef enum bit[1:0] { IDLE, GAME} state_e;

    state_e state, state_next;

    always_ff @( posedge clk, posedge reset ) begin
        if(reset)   begin
            state <= IDLE;
            pixel_timer_counter_reg <= 0;
            pixel_timer_reg <= 0;
            end_reg <= 0;
            data_delay <= 0;
            data_q <= 0;
        end
        else    begin
            state <= state_next;
            pixel_timer_counter_reg <= pixel_timer_counter_next;
            pixel_timer_reg <= pixel_timer_next;
            end_reg <= end_next;
            data_q <= data;
            data_delay <= data_q;
        end
    end

    always_comb begin
        state_next = state;
        pixel_timer_counter_next = pixel_timer_counter_reg;
        pixel_timer_next = pixel_timer_reg;
        end_next = end_reg;
        case (state)
            IDLE: begin
                end_next = 1'b0;
                pixel_timer_counter_next = 0;
                pixel_timer_next = 0;
                if(start_trigger)   begin
                    state_next = GAME;
                end    
            end
            GAME:   begin
                if(data_rise) begin
                    if(pixel_timer_reg < 20) begin
                        pixel_timer_next = 0;
                    end
                    else begin
                        pixel_timer_next = pixel_timer_reg - 20;
                    end
                end
                else if(pixel_timer_counter_reg == 10_000_000 - 1)  begin
                    pixel_timer_counter_next = 0;
                    if(pixel_timer_reg >= 200 - 1)   begin
                        state_next = IDLE;
                        end_next = 1'b1;
                    end
                    else begin
                        pixel_timer_next = pixel_timer_reg + 1;
                    end
                end
                else    begin
                    pixel_timer_counter_next = pixel_timer_counter_reg + 1;
                end

            end
        endcase
    end
endmodule
