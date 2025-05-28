`timescale 1ns / 1ps

module vga_rgb_switch(
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic DE,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port
    );

    logic [11:0] RGB;

    localparam WHITE = 12'hfff , BLACK = 12'h000, BLACK1 = 12'h111, BLACK2 = 12'h222 ,GRAY = 12'hbbb, YELLOW = 12'hff0, SKYBLUE = 12'h0ff, 
               LIGHT_GREEN = 12'h0f3, PINK = 12'hc0c, PURPLE = 12'h325, RED = 12'hf00, BLUE = 12'h00f, DARK_BLUE = 12'h009  ;

    assign {red_port, green_port, blue_port} = RGB;


    always_comb begin
        RGB = 0;
        if(DE) begin
            if(x_pixel <= 91 && y_pixel <= 300) begin // white
            RGB = GRAY; //red_port = 4'b1011; green_port = 4'b1011; blue_port = 4'b1011;                
            end
            else if(x_pixel <= 183 && y_pixel <= 300) begin // yellow
            RGB = YELLOW;//red_port = 4'b1111; green_port = 4'b1111; blue_port = 4'b0000;                
            end
            else if(x_pixel <= 274 && y_pixel <= 300) begin // skyblue
            RGB = SKYBLUE; //red_port = 4'b0000; green_port = 4'b1111; blue_port = 4'b1111;   
            end
            else if(x_pixel <= 366 && y_pixel <= 300) begin // green
            RGB = LIGHT_GREEN; //red_port = 4'b0000; green_port = 4'b1111; blue_port = 4'b0011;   
            end
            else if(x_pixel <= 457 && y_pixel <= 300) begin // purple
            RGB = PINK; //red_port = 4'b1111; green_port = 4'b0000; blue_port = 4'b1111;   
            end
            else if(x_pixel <= 549 && y_pixel <= 300) begin // red
            RGB = RED; //red_port = 4'b1111; green_port = 4'b0000; blue_port = 4'b0000;   
            end
            else if(x_pixel <= 639 && y_pixel <= 300) begin // blue
            RGB = BLUE; //red_port = 4'b0000; green_port = 4'b0000; blue_port = 4'b1111;   
            end

            else if(x_pixel <= 91 && y_pixel <= 360) begin // blue
            RGB = BLUE; //red_port = 4'b0000; green_port = 4'b0000; blue_port = 4'b1111;                
            end
            else if(x_pixel <= 183 && y_pixel <= 360) begin // black
            RGB = BLACK; //red_port = 4'b0000; green_port = 4'b0000; blue_port = 4'b0000;                
            end
            else if(x_pixel <= 274 && y_pixel <= 360) begin // purple
            RGB = PINK; //red_port = 4'b1111; green_port = 4'b0000; blue_port = 4'b1111;   
            end
            else if(x_pixel <= 366 && y_pixel <= 360) begin // black
            RGB = BLACK; //red_port = 4'b0000; green_port = 4'b0000; blue_port = 4'b0000;   
            end
            else if(x_pixel <= 457 && y_pixel <= 360) begin // skyblue
            RGB = SKYBLUE; //red_port = 4'b0000; green_port = 4'b1111; blue_port = 4'b1111;   
            end
            else if(x_pixel <= 549 && y_pixel <= 360) begin // black
            RGB = BLACK;  //red_port = 4'b0000; green_port = 4'b0000; blue_port = 4'b0000;   
            end
            else if(x_pixel <= 639 && y_pixel <= 360) begin // white
            RGB = GRAY;  //red_port = 4'b1011; green_port = 4'b1011; blue_port = 4'b1011;   
            end

            else if(x_pixel <= 114 && y_pixel <= 479) begin // dark blue
            RGB = DARK_BLUE; //red_port = 4'b0000; green_port = 4'b0000; blue_port = 4'b0111;                
            end
            else if(x_pixel <= 228 && y_pixel <= 479) begin // white
            RGB = WHITE;  //red_port = 4'b1111; green_port = 4'b1111; blue_port = 4'b1111;                
            end
            else if(x_pixel <= 342 && y_pixel <= 479) begin // purple
            RGB = PURPLE;  //red_port = 4'b0111; green_port = 4'b0001; blue_port = 4'b1111;   
            end
            else if(x_pixel <= 457 && y_pixel <= 479) begin // black
            RGB = BLACK1;  //red_port = 4'b0000; green_port = 4'b0000; blue_port = 4'b0000;   
            end
            else if(x_pixel <= 487 && y_pixel <= 479) begin // black
            RGB = BLACK;  //red_port = 4'b0000; green_port = 4'b0000; blue_port = 4'b0000;   
            end
            else if(x_pixel <= 518 && y_pixel <= 479) begin // black
            RGB = BLACK1;  //red_port = 4'b0000; green_port = 4'b0000; blue_port = 4'b0000;   
            end
            else if(x_pixel <= 550 && y_pixel <= 479) begin // black
            RGB = BLACK2;  //red_port = 4'b0000; green_port = 4'b0000; blue_port = 4'b0000;   
            end
            else if(x_pixel <= 639 && y_pixel <= 479) begin // black
            RGB = BLACK;  //red_port = 4'b0000; green_port = 4'b0000; blue_port = 4'b0000;   
            end
        end
    end

endmodule

