`timescale 1ns / 1ps

module top_counter_up_down (
    input        clk,
    input        rst,
    input        rx,
    output       tx,
    output [3:0] fndCom,
    output [7:0] fndFont
);
    wire [13:0] fndData;
    wire [3:0] fndDot;

    wire mode,en,clear;

    wire w_start_trigger;
    wire [7:0] w_rx_data, w_tx_data;
    wire w_rx_done, w_tx_done;

    counter_up_down U_Counter (
        .clk  (clk),
        .rst(rst),
        .en(en),
        .mode(mode),
        .clear(clear),
        .count(fndData),
        .dot_data(fndDot)
    );


    top_uart_rx U_uart_rx(
    .clk(clk),
    .rst(rst),
    .rx(rx),
    .rx_data(w_rx_data),
    .rx_done(w_rx_done)
);

    top_uart_tx U_uart_tx(
    .clk(clk),
    .rst(rst),
    .start_trigger(w_start_trigger),
    .data(w_tx_data),
    .tx(tx),
    .tx_done(w_tx_done),
    .tx_busy(w_tx_busy)
);

    fndController U_FndController (
        .clk(clk),
        .reset(rst),
        .fndDot(fndDot),
        .fndData(fndData),
        .fndCom(fndCom),
        .fndFont(fndFont)
    );



    counter_cu U_counter_cu(
    .clk    (clk),
    .rst    (rst),
    .rx_data(w_rx_data),
    .rx_done(w_rx_done),
    .tx_done(w_tx_done),
    .tx_busy(w_tx_busy),
    .start_trigger(w_start_trigger),
    .tx_data(w_tx_data),
    .mode   (mode),
    .en     (en),
    .clear  (clear)
);

endmodule

module comp_dot(
    input [13:0] count,
    output [3:0] dot_data
);

    assign dot_data = ((count%10)<5) ? 4'b1101 : 4'b1111;

endmodule


module counter_up_down (
    input         clk,
    input         reset,
    input         mode,
    input         en,
    input         clear,
    output [13:0] count,
    output [3:0]  dot_data
);
    wire tick;

    clk_div_10hz U_Clk_Div_10Hz (
        .clk  (clk),
        .reset(reset),
        .clear(clear),
        .en   (en),
        .tick (tick)
    );

    counter U_Counter_Up_Down (
        .clk  (clk),
        .reset(reset),
        .tick (tick),
        .mode (mode),
        .en   (en),
        .clear(clear),
        .count(count)
    );

comp_dot U_comp_dot(
    .count(count),
    .dot_data(dot_data)
);
      

endmodule


module counter (
    input         clk,
    input         reset,
    input         tick,
    input         mode,
    input         en,
    input         clear,
    output [13:0] count
);
    reg [$clog2(10000)-1:0] counter;

    assign count = counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
        end 
        else begin
            if(clear) begin
                counter <= 0;
            end
            else begin
                if(en) begin
                    if (mode == 1'b0) begin
                        if (tick) begin
                            if (counter == 9999) begin
                                counter <= 0;
                            end else begin
                                counter <= counter + 1;
                            end
                        end
                    end else begin
                        if (tick) begin
                            if (counter == 0) begin
                                counter <= 9999;
                            end else begin
                                counter <= counter - 1;
                            end
                        end
                    end
                end
            end
        end
    end
endmodule

module clk_div_10hz (
    input  wire clk,
    input  wire reset,
    input       clear,
    input       en,
    output reg  tick
);
    reg [$clog2(10_000_000)-1:0] div_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            div_counter <= 0;
            tick <= 1'b0;
        end 
        else begin
            if(en == 1) begin
                if (div_counter == 10_000_000 - 1) begin
                    div_counter <= 0;
                    tick <= 1'b1;
                end else begin
                    div_counter <= div_counter + 1;
                    tick <= 1'b0;
                end
            end
            if(clear == 1) begin
                div_counter <= 0;
                tick <= 1'b0;
            end
        end
    end
endmodule

module counter_cu(
    input clk,rst,
    input [7:0] rx_data,
    input rx_done,
    input tx_done,
    input tx_busy,
    output start_trigger,
    output [7:0] tx_data,
    output en,
    output clear,
    output mode
);
    localparam STOP = 0, RUN = 1, CLEAR = 2;

    reg [2:0] state,next;

    reg r_mode,r_clear,r_run_stop;
    reg n_mode,n_clear,n_run_stop;


    assign mode = r_mode;
    assign en = r_run_stop;
    assign clear = r_clear;

    assign start_trigger = (tx_busy == 1'b0) ? rx_done : 1'b0;
    assign tx_data = rx_data;

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            state <= 0;
            r_clear <= 0;
            r_run_stop <= 0;
            r_mode <= 0;
        end
        else begin
            state <= next;
            r_clear <= n_clear;
            r_run_stop <= n_run_stop;
            r_mode <= n_mode;
        end
    end

    always @(*) begin
        next = state;
        n_clear = r_clear;
        n_run_stop = r_run_stop;
        n_mode = r_mode;
        case (state)
           STOP : begin 
                    n_run_stop = 0; 
                    n_clear = 0;
                    if(rx_done) begin
                        if(rx_data == 8'h52 ) begin
                            next = RUN;
                        end
                        else if(rx_data == 8'h43) begin
                            next = CLEAR;
                        end
                        else if(rx_data == 8'h4D) begin
                            if(rx_done) begin
                            n_mode = ~r_mode;
                            end
                        end
                        else begin
                            next = STOP;
                        end
                    end
            end
           RUN : begin 
                    n_run_stop = 1; 
                    if(rx_done) begin
                        if(rx_data == 8'h53) begin
                            next = STOP;
                        end
                        if(rx_data == 8'h4D) begin
                            n_mode = ~r_mode;
                        end
                        if(rx_data == 8'h43) begin
                            next = CLEAR;
                        end
                    end
           end
           CLEAR : begin  
                    n_clear = 1;
                    next = STOP;
           end
        endcase
    end

endmodule
