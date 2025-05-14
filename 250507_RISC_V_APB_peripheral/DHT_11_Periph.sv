`timescale 1ns / 1ps
  
module DHT_11_Periph(
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
    inout  logic        dht_io
);  

    logic dht_start;
    logic [15:0] humidity;
    logic [15:0] temperature;

    APB_SlaveIntf_DHT11 U_APB_Intf (.*);
    DHT11 U_DHT_IP (
    .*,
    .clk(PCLK),
    .rst(PRESET)
    );
endmodule

module APB_SlaveIntf_DHT11 (
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
    output logic       dht_start,
    input  logic [15:0] humidity,
    input  logic [15:0] temperature

); 
    logic [31:0] slv_reg0, slv_reg1, slv_reg2;  //, slv_reg3;

    assign dht_start = slv_reg0[0];
    assign slv_reg1[7:0] = humidity[15:8]; // humidity
    assign slv_reg2[7:0] = temperature[15:8]; // humidity

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;
            //slv_reg1 <= 0;
            // slv_reg2 <= 0;
            // slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: slv_reg0 <= PWDATA;
                        2'd1: ;
                        // 2'd2: slv_reg2 <= PWDATA;
                        // 2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        //2'd0: PRDATA <= slv_reg0;
                        2'd1: PRDATA <= slv_reg1;
                        2'd2: PRDATA <= slv_reg2;
                        // 2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end

endmodule
