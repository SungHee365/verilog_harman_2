`timescale 1ns / 1ps

module VGA_Controller(
    input logic clk,
    input logic rst,
    input logic [3:0] sw_red,
    input logic [3:0] sw_green,
    input logic [3:0] sw_blue,
    output logic h_sync,
    output logic v_sync,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port
    );


    VGA_Decoder U_VGA_DEC(
        .clk(clk),
        .rst(rst),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .DE(DE),
        .x_pixel(),
        .y_pixel()
    );

    vga_rgb_switch U_VGA_RGB_SW(
        .sw_red(sw_red),
        .sw_green(sw_green),
        .sw_blue(sw_blue),
        .DE(DE),
        .red_port(red_port),
        .green_port(green_port),
        .blue_port(blue_port)
        );



endmodule

module VGA_Decoder (
    input logic clk,
    input logic rst,
    output logic h_sync,
    output logic v_sync,
    output logic DE,
    output logic [9:0] x_pixel,
    output logic [9:0] y_pixel
);

    logic pclk;
    logic [9:0] h_cnt;
    logic [9:0] v_cnt;

    pixel_clk_gen U_Pix_Clk_Gen(
    .clk(clk),
    .rst(rst),
    .pclk(pclk)
);
    
    pixel_counter U_Pix_Counter(
    .pclk(pclk),
    .rst(rst),
    .h_cnt(h_cnt), // horizontor
    .v_cnt(v_cnt) // vertical
);

    vga_decoder U_VGA_Decoder(
    .h_cnt(h_cnt),
    .v_cnt(v_cnt),
    .h_sync(h_sync),
    .v_sync(v_sync),
    .x_pixel(x_pixel),
    .y_pixel(y_pixel),
    .DE(DE)
);

endmodule


module pixel_clk_gen (
    input logic clk,
    input logic rst,
    output logic pclk
);
    logic [1:0] p_cnt;

    always_ff @( posedge clk, posedge rst ) begin
        if(rst) begin
            p_cnt <= 0;
            pclk <=  1'b0;
        end
        else begin
            if(p_cnt == 3) begin
                p_cnt <= 0;
                pclk <= 1'b1;
            end
            else begin
                p_cnt <= p_cnt + 1;
                pclk <= 1'b0;
            end
        end
        
    end

endmodule

module pixel_counter (
    input logic pclk,
    input logic rst,
    output logic [9:0] h_cnt, // horizontor
    output logic [9:0] v_cnt // vertical
);
    localparam  H_MAX = 800, V_MAX = 525 ;
    
    always_ff @( posedge pclk, posedge rst ) begin : Horizontor_counter
        if(rst) begin
            h_cnt <= 0;
        end
        else begin
            if(h_cnt == H_MAX - 1) begin
                h_cnt <= 0;
            end
            else begin
                h_cnt <= h_cnt + 1;
            end
        end
    end

    always_ff @( posedge pclk, posedge rst ) begin : Vertical_counter
        if(rst) begin
            v_cnt <= 0;
        end
        else begin
            if (h_cnt == H_MAX - 1) begin
                if(v_cnt == V_MAX - 1) begin
                    v_cnt <= 0;
                end
                else begin
                    v_cnt = v_cnt + 1;
                end
            end
        end
    end


endmodule


module vga_decoder (
    input logic [9:0] h_cnt,
    input logic [9:0] v_cnt,
    output logic h_sync,
    output logic v_sync,
    output logic [9:0] x_pixel,
    output logic [9:0] y_pixel,
    output logic       DE
);
    
    localparam H_Visible_area = 640;
    localparam H_Front_porch = 16;
    localparam H_Sync_pulse =	96;
    localparam H_Back_porch =	48;
    localparam H_Whole_line =	800;


    localparam V_Visible_area = 480;
    localparam V_Front_porch = 10;
    localparam V_Sync_pulse =	2;
    localparam V_Back_porch =	33;
    localparam V_Whole_frame = 525;

    assign h_sync = !((h_cnt >= H_Visible_area + H_Front_porch) 
    && ( h_cnt < (H_Visible_area + H_Front_porch + H_Sync_pulse)));

    assign v_sync = !((v_cnt >= V_Visible_area + V_Front_porch) 
    && ( v_cnt < (V_Visible_area + V_Front_porch + V_Sync_pulse)));

    assign DE = (h_cnt < H_Visible_area) && (v_cnt < V_Visible_area);
    assign x_pixel = DE ? h_cnt : 10'bz;
    assign y_pixel = DE ? v_cnt : 10'bz;
endmodule