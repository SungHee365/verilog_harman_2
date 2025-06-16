`timescale 1ns / 1ps

module QVGA_Mem(
    input logic       clk,
    input logic       reset,
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic       DE,
    input logic       collision_trigger, // 임시 충돌 감지 signal
    input logic       collision_trigger1,
    input logic       collision_trigger2,
    input logic       collision_trigger3,
    input logic       collision_trigger_ending,

    output logic        d_en,
    output logic [16:0] rAddr,
    input  logic [15:0] rData,

    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port,

    input logic upscale,

    // timer
    output logic start_trigger,
    input logic end_trigger,
    input logic [9:0] pixel_timer,

    output logic collision_area,
    output logic collision_area1,
    output logic collision_area2,
    output logic collision_area3,
    output logic collision_area_ending,

    output logic collision_en_start,
    output logic collision_en1,
    output logic collision_en2,
    output logic collision_en3,
    output logic collision_en_ending

    );

    localparam RESP_DELAY1 = 100_000_000; // 1초
    localparam RESP_DELAY3 = 300_000_000; // 1초
    localparam RESP_DELAY5 = 500_000_000; // 1초
        // VGA background
    logic display_en_small, display_en_big;
    logic [16:0] rAddr_small, rAddr_big;

    logic [29:0] obj1_respawn_counter_reg, obj1_respawn_counter_next;
    logic [29:0] obj2_respawn_counter_reg, obj2_respawn_counter_next;
    logic [29:0] obj3_respawn_counter_reg, obj3_respawn_counter_next;
    logic [29:0] obj1_clock;
    logic [29:0] obj2_clock;
    logic [29:0] obj3_clock;

    assign display_en_small = (x_pixel < 320 && y_pixel < 240);
    assign rAddr_small = display_en_small ? (y_pixel * 320 + x_pixel) : 17'd0;

    assign display_en_big = (x_pixel < 640 && y_pixel < 480);
    assign rAddr_big = display_en_big ? ((y_pixel >> 1) * 320 + (x_pixel >> 1)) : 17'd0;

    assign rAddr = upscale ? rAddr_small : rAddr_big;
    assign d_en = upscale ? display_en_small : display_en_big;

    // random 위치
    logic [9:0] x_offset, y_offset;
    logic [9:0] counter;
    logic [9:0] rnd_x1, rnd_y1;
    logic [9:0] rnd_x2, rnd_y2;
    logic [9:0] rnd_x3, rnd_y3;


    always_ff @(posedge clk) begin
        counter <= counter + 1;
        rnd_x1   <= counter ^ 10'h2A3;
        rnd_y1   <= counter + 10'h1F5;
        rnd_x2   <= counter ^ 10'h1C7; 
        rnd_y2   <= counter + 10'h12D; 
        rnd_x3   <= counter ^ 10'h3D9; 
        rnd_y3   <= counter + 10'h0B6; 
    end


    // 임시 충돌 감지 signal 생성기
        // 임시 충돌 감지 signal 생성기
    logic trigger_d, trigger_rise;
    logic trigger_d1, trigger_rise1;
    logic trigger_d2, trigger_rise2;
    logic trigger_d3, trigger_rise3;
    logic trigger_d_ending, trigger_rise_ending;

always_ff @(posedge clk, posedge reset) begin
    if (reset) begin
        trigger_d        <= 1'b0;
        trigger_d1       <= 1'b0;
        trigger_d2       <= 1'b0;
        trigger_d3       <= 1'b0;
        trigger_d_ending <= 1'b0;
    end
    else begin
        trigger_d        <= collision_trigger;
        trigger_d1       <= collision_trigger1;
        trigger_d2       <= collision_trigger2;
        trigger_d3       <= collision_trigger3;
        trigger_d_ending <= collision_trigger_ending;
    end
end

    assign trigger_rise =   (collision_trigger == 1 && trigger_d == 0);
    assign trigger_rise1 = (collision_trigger1 == 1 && trigger_d1 == 0);
    assign trigger_rise2 = (collision_trigger2 == 1 && trigger_d2 == 0);
    assign trigger_rise3 = (collision_trigger3 == 1 && trigger_d3 == 0);
    assign trigger_rise_ending = (collision_trigger_ending == 1 && trigger_d_ending == 0);

    // state
    typedef enum bit[1:0] { IDLE, GAME, ENDING} state_e;
    state_e state, state_next;

    // 
    logic [15:0]    obj1_data, obj2_data, obj3_data, obj_data_start, obj_data_end;
    logic           obj1_area, obj2_area, obj3_area, obj_area_start, obj_area_ending;
    logic           obj_en_start_reg, obj_en_start_next, obj1_en_reg, obj1_en_next, obj2_en_reg, obj2_en_next, obj3_en_reg, obj3_en_next, obj_en_ending_reg, obj_en_ending_next;
    logic [16:0]    object1_addr, object2_addr, object3_addr, object_addr_start, object_addr_ending;
    logic [9:0]     x_offset1_reg, y_offset1_reg, x_offset1_next, y_offset1_next;
    logic [9:0]     x_offset2_reg, y_offset2_reg, x_offset2_next, y_offset2_next;
    logic [9:0]     x_offset3_reg, y_offset3_reg, x_offset3_next, y_offset3_next;
    logic           start_trigger_reg, start_trigger_next;
    logic           timer_area, timer_left_area;

    assign  start_trigger = start_trigger_reg;

    assign collision_en_start = obj_en_start_reg;
    assign collision_en1 = obj1_en_reg;
    assign collision_en2 = obj2_en_reg;
    assign collision_en3 = obj3_en_reg;
    assign collision_en_ending = obj_en_ending_reg;

    // FSM


always_ff @(posedge clk) begin
    if (obj_area_start) begin
        object_addr_start <= ((y_pixel - 175) << 7) + ((y_pixel - 175) << 1) + (x_pixel - 255);
    end 
    else begin
        object_addr_start <= 17'b0;
    end

    if (obj1_area) begin
        object1_addr <= (((y_pixel - y_offset1_reg) << 5) + ((y_pixel - y_offset1_reg) << 4) + ((y_pixel - y_offset1_reg) << 1)) + (x_pixel - x_offset1_reg);
    end
    else begin
        object1_addr <= 17'b0;
    end

    if (obj2_area) begin
        object2_addr <= (((y_pixel - y_offset2_reg) << 5) + ((y_pixel - y_offset2_reg) << 4) + ((y_pixel - y_offset2_reg) << 1)) + (x_pixel - x_offset2_reg);
    end
    else begin
        object2_addr <= 17'b0;
    end

    if (obj3_area) begin
        object3_addr <= (((y_pixel - y_offset3_reg) << 5) + ((y_pixel - y_offset3_reg) << 4) + ((y_pixel - y_offset3_reg) << 1)) + (x_pixel - x_offset3_reg);
    end
    else begin
        object3_addr <= 17'b0;
    end

    if (obj_area_ending) begin
        object_addr_ending <= (((y_pixel - 400) << 6) + ((y_pixel - 400) << 5) + ((y_pixel - 400) << 2) ) + (x_pixel - 520);
    end
    else begin
        object_addr_ending <= 17'b0;
    end

end



    always_ff @(posedge clk, posedge reset)   begin
        if(reset)   begin
            state <= IDLE;
            x_offset1_reg <= 0;
            y_offset1_reg <= 120;
            x_offset2_reg <= 220;
            y_offset2_reg <= 120;
            x_offset3_reg <= 420;
            y_offset3_reg <= 120;
            obj_en_start_reg <= 0;
            obj1_en_reg   <= 0;
            obj2_en_reg   <= 0;
            obj3_en_reg   <= 0;
            obj_en_ending_reg <= 0;
            start_trigger_reg <= 0;
            obj1_respawn_counter_reg <= 0;
            obj2_respawn_counter_reg <= 0;
            obj3_respawn_counter_reg <= 0;
        end
        else        begin
            state <= state_next;
            x_offset1_reg <= x_offset1_next;
            y_offset1_reg <= y_offset1_next;
            x_offset2_reg <= x_offset2_next;
            y_offset2_reg <= y_offset2_next;
            x_offset3_reg <= x_offset3_next;
            y_offset3_reg <= y_offset3_next;
            obj_en_start_reg <= obj_en_start_next;
            obj1_en_reg   <= obj1_en_next;
            obj2_en_reg   <= obj2_en_next;
            obj3_en_reg   <= obj3_en_next;
            obj_en_ending_reg <= obj_en_ending_next;
            start_trigger_reg <= start_trigger_next;
            obj1_respawn_counter_reg <= obj1_respawn_counter_next;
            obj2_respawn_counter_reg <= obj2_respawn_counter_next;
            obj3_respawn_counter_reg <= obj3_respawn_counter_next;
        end
    end

    always_ff @( posedge clk, posedge reset ) begin
        if(reset) begin
            obj1_clock <= 0;
            obj2_clock <= 0;
            obj3_clock <= 0;
        end
        else begin
            if(obj1_en_reg) begin
                if(obj1_clock == RESP_DELAY3) begin
                    obj1_clock = 0;
                end
                else begin
                    obj1_clock = obj1_clock + 1;
                end
            end
            else begin
                obj1_clock = 0;
            end
            if(obj2_en_reg) begin
                if(obj2_clock == RESP_DELAY3) begin
                    obj2_clock = 0;
                end
                else begin
                    obj2_clock = obj2_clock + 1;
                end
            end
            else begin
                obj2_clock = 0;
            end
            if(obj3_en_reg) begin
                if(obj3_clock == RESP_DELAY3) begin
                    obj3_clock = 0;
                end
                else begin
                    obj3_clock = obj3_clock + 1;
                end
            end
            else begin
                obj3_clock = 0;
            end
        end
    end

    always_comb begin
        state_next = state;
        x_offset1_next = x_offset1_reg;
        y_offset1_next = y_offset1_reg;
        x_offset2_next = x_offset2_reg;
        y_offset2_next = y_offset2_reg;
        x_offset3_next = x_offset3_reg;
        y_offset3_next = y_offset3_reg;
        obj_en_start_next = 1'b0;
        obj1_en_next   = obj1_en_reg;
        obj2_en_next   = obj2_en_reg;
        obj3_en_next   = obj3_en_reg;
        obj1_area = 1'b0;
        obj2_area = 1'b0;
        obj3_area = 1'b0;
        obj_area_start = 1'b0;
        obj_area_ending = 1'b0;
        obj_en_ending_next = 1'b0;
        start_trigger_next = 1'b0;
        object_addr_start = obj_area_start ? (y_pixel - 175)*130 + (x_pixel - 255) : 17'b0;
        timer_area = 1'b0;
        timer_left_area = 1'b0;
        obj1_respawn_counter_next = obj1_respawn_counter_reg;
        obj2_respawn_counter_next = obj2_respawn_counter_reg;
        obj3_respawn_counter_next = obj3_respawn_counter_reg;
        case (state)
            IDLE: begin
                obj_en_start_next = 1'b1;
                obj_area_start = (x_pixel >= 255 && x_pixel < 385) && (y_pixel >= 175 && y_pixel < 305);
                if(trigger_rise)   begin
                    state_next = GAME;
                    start_trigger_next = 1'b1;
                    x_offset1_next = rnd_x1 % (170);
                    y_offset1_next = rnd_y1 % (310) + 120;
                    x_offset2_next = rnd_x2 % (150) + 220;
                    y_offset2_next = rnd_y2 % (30) + 120;
                    x_offset3_next = rnd_x3 % (170) + 420;
                    y_offset3_next = rnd_y3 % (310) + 120;
                    obj1_en_next   = 1'b1;
                    obj2_en_next   = 1'b1;
                    obj3_en_next   = 1'b1;
                end
            end
            GAME: begin
                // timer
                timer_area = (x_pixel >= 20 && x_pixel < 620) && (y_pixel >= 20 && y_pixel < 60);
                timer_left_area = timer_area && (x_pixel < (pixel_timer<<1) + pixel_timer + 20);
                // object_left
                obj1_area =    (x_pixel >= x_offset1_reg && x_pixel < x_offset1_reg + 50) &&
                               (y_pixel >= y_offset1_reg && y_pixel < y_offset1_reg + 50);
                object1_addr = obj1_area ? ((y_pixel - y_offset1_reg) * 50 + x_pixel - x_offset1_reg) : 17'd0;
                // object_center
                obj2_area =    (x_pixel >= x_offset2_reg && x_pixel < x_offset2_reg + 50) &&
                               (y_pixel >= y_offset2_reg && y_pixel < y_offset2_reg + 50);
                object2_addr = obj2_area ? ((y_pixel - y_offset2_reg) * 50 + x_pixel - x_offset2_reg) : 17'd0;
                // object_right
                obj3_area =    (x_pixel >= x_offset3_reg && x_pixel < x_offset3_reg + 50) &&
                               (y_pixel >= y_offset3_reg && y_pixel < y_offset3_reg + 50);
                object3_addr = obj3_area ? ((y_pixel - y_offset3_reg) * 50 + x_pixel - x_offset3_reg) : 17'd0;

                if(trigger_rise1 || obj1_clock == RESP_DELAY3)  obj1_en_next = 1'b0;
                if(trigger_rise2 || obj2_clock == RESP_DELAY3)  obj2_en_next = 1'b0;
                if(trigger_rise3 || obj3_clock == RESP_DELAY3)  obj3_en_next = 1'b0;

                if(obj1_en_reg == 0 ) begin
                    if( obj1_respawn_counter_reg == RESP_DELAY1) begin
                        x_offset1_next = rnd_x1 % (590);
                        y_offset1_next = rnd_y1 % (310) + 120;
                        obj1_en_next   = 1'b1;
                        obj1_respawn_counter_next = 0;
                    end
                    else begin
                        obj1_respawn_counter_next = obj1_respawn_counter_reg + 1;
                    end
                end
                else begin
                    obj1_respawn_counter_next = 0;
                end

                if(obj2_en_reg == 0 ) begin
                    if( obj2_respawn_counter_reg == RESP_DELAY3) begin
                        x_offset2_next = rnd_x2 % (590);
                        y_offset2_next = rnd_y2 % (310) + 120;
                        obj2_en_next   = 1'b1;
                        obj2_respawn_counter_next = 0;
                    end
                    else begin
                        obj2_respawn_counter_next = obj2_respawn_counter_reg + 1;
                    end
                end
                else begin
                    obj2_respawn_counter_next = 0;
                end

                if(obj3_en_reg == 0 ) begin
                    if( obj3_respawn_counter_reg == RESP_DELAY5) begin
                        x_offset3_next = rnd_x3 % (590);
                        y_offset3_next = rnd_y3 % (310) + 120;
                        obj3_en_next   = 1'b1;
                        obj3_respawn_counter_next = 0;
                    end
                    else begin
                        obj3_respawn_counter_next = obj3_respawn_counter_reg + 1;
                    end                    
                end
                else begin
                    obj3_respawn_counter_next = 0;
                end


                if(end_trigger)  begin
                    state_next = ENDING;
                end
            end
            ENDING: begin
                obj_en_ending_next = 1'b1;
                obj_area_ending = (x_pixel >= 520 && x_pixel < 620) && (y_pixel >= 400 && y_pixel < 460);
                object_addr_ending = obj_area_ending ? (y_pixel - 400)*150 + (x_pixel - 520) : 17'b0;
                if(trigger_rise_ending)    begin
                    state_next = IDLE;
                    start_trigger_next = 1'b1;

                end
            end
        endcase
    end

    assign  collision_area  = obj_area_start;
    assign  collision_area1 = obj1_area;
    assign  collision_area2 = obj2_area;
    assign  collision_area3 = obj3_area;
    assign  collision_area_ending = obj_area_ending;

    image_rom_Candy_normal U_ROM_1 (
        .clk(clk),
        .addr(object1_addr),
        .data(obj1_data)
    );

    image_rom_pokemon_bread U_ROM_2 (
        .clk(clk),
        .addr(object2_addr),
        .data(obj2_data)  
    );

    image_rom_Candy_special U_ROM_3 (
        .clk(clk),
        .addr(object3_addr),
        .data(obj3_data)  
    );
    

    image_rom_start U_ROM_Start (
        .clk(clk),
        .addr(object_addr_start),
        .data(obj_data_start)  
    );

    image_rom_end U_ROM_End (
        .clk(clk),
        .addr(object_addr_ending),
        .data(obj_data_end)  
    );

    ImageSignalProcessor U_ISP (
        .clk       (clk),
        .bg_en     (d_en),
        .bg_data   (rData),
        .timer_area(timer_area),
        .timer_left(timer_left_area),
        .obj_en_start(obj_area_start && obj_data_start != 16'hfffe && obj_en_start_reg),
        .obj_data_start(obj_data_start),
        .obj1_en    (obj1_area && obj1_data != 16'hfffe && obj1_en_reg),
        .obj1_data  (obj1_data),
        .obj2_en    (obj2_area && obj2_data != 16'hfffe && obj2_en_reg),
        .obj2_data  (obj2_data),
        .obj3_en    (obj3_area && obj3_data != 16'hfffe && obj3_en_reg),
        .obj3_data  (obj3_data),
        .obj_en_ending(obj_area_ending && obj_data_ending != 16'hfffe && obj_en_ending_reg),
        .obj_data_ending(obj_data_end),
        .red_port  (red_port),
        .green_port(green_port),
        .blue_port (blue_port)
    );
endmodule


