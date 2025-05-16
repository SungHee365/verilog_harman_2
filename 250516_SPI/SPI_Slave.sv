`timescale 1ns / 1ps

module SPI_Slave(
    // Master signal
    input logic SCLK,
    input logic rst,
    input logic MOSI,
    output logic MISO,
    input logic CS,
    // fsm signal
    output logic [7:0] data,
    input done
    );

    logic [7:0] temp_data;

    assign MISO = (~CS) ? temp_data[7] : 1'bz;
    assign data = temp_data;

    always_ff @( posedge SCLK, posedge rst ) begin 
        if(rst) begin
            temp_data <= 1'b0;
        end
        else begin
            temp_data <= {temp_data[6:0],MOSI};
        end
    end

endmodule
