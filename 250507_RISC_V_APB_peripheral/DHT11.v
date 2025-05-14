
module DHT11 (
    input clk,
    input rst,
    input dht_start,
    inout dht_io,



    output [15:0] humidity,
    output [15:0] temperature

);

    wire tick_1us;

    dht11_controller U_1 (
        .clk(clk),
        .rst(rst),
        .tick_1us(tick_1us),
        .btn_start(dht_start),

        .dht_io(dht_io),


        .led(),
        .humidity(humidity),
        .temperature(temperature)

    );
    tick_1us U_2 (
        .clk(clk),
        .rst(rst),
        .tick_1us(tick_1us)
    );



endmodule


module tick_1us (
    input  clk,
    input  rst,
    output tick_1us
);
    parameter COUNT = 100;
    reg tick_reg, tick_next;
    reg [$clog2(COUNT)-1 : 0] count_reg, count_next;

    assign tick_1us = tick_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            tick_reg  <= 0;
            count_reg <= 0;
        end else begin
            tick_reg  <= tick_next;
            count_reg <= count_next;
        end

    end

    always @(*) begin
        tick_next  = 0;
        count_next = 0;
        if (count_reg == COUNT - 1) begin
            count_next = 0;
            tick_next  = 1;
        end else begin
            count_next = count_reg + 1;
            tick_next  = 0;
        end
    end
endmodule

module dht11_controller (
    input clk,
    input rst,
    input tick_1us,
    input btn_start,

    inout dht_io,



    output [15:0] humidity,
    output [15:0] temperature,

    output [9:0] led

);


    //fsm

    parameter IDLE = 0, START = 1, WAIT = 2, SYNC_LOW = 3, SYNC_HIGH = 4, 
                DATA_SYNC = 5, DATA_DC = 6, STOP_RX = 7, STOP_TX= 8;

    reg [3:0] state, next;
    reg dht_io_reg, dht_io_next;
    reg [$clog2(20000)-1:0] tick_count_reg, tick_count_next;

    reg io_oe_reg, io_oe_next;  //inout on/off

    reg [39:0] data_reg, data_next;
    reg [5:0] bit_count_reg, bit_count_next;
    reg led_reg, led_next;  //확인용
    wire [7:0] check_sum;
    reg led_check_sum;


    //data 
    assign humidity = data_reg[39:24];
    assign temperature = data_reg[23:8];
    assign check_sum = data_reg[7:0];

    assign led[8] = (check_sum == humidity[15:8] + humidity[7:0] + temperature[15:8] + temperature[7:0]);

    assign led[0] = (state == IDLE);
    assign led[1] = (state == START);
    assign led[2] = (state == WAIT);
    assign led[3] = (state == SYNC_LOW);
    assign led[4] = (state == SYNC_HIGH);
    assign led[5] = (state == DATA_SYNC);
    assign led[6] = (state == DATA_DC);
    assign led[7] = (state == STOP_RX);



    //assign led[8] = io_oe_reg;
    //out 3state on/off
    assign dht_io = (io_oe_reg) ? dht_io_reg : 1'bz;
    //io_oe_reg 1 -> 출력모드
    //io_oe_reg 0 -> 입력모드
reg dht_io_sync1, dht_io_sync2;

always @(posedge clk) begin
    dht_io_sync1 <= dht_io;
    dht_io_sync2 <= dht_io_sync1;
end

wire dht_io_rising  = (dht_io_sync2 == 0 && dht_io_sync1 == 1);
wire dht_io_falling = (dht_io_sync2 == 1 && dht_io_sync1 == 0);


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state          <= IDLE;
            dht_io_reg     <= 1;  //풀업 IDLE일때 high 로 내보내기
            tick_count_reg <= 0;
            led_reg        <= 0;
            io_oe_reg      <= 0;
            bit_count_reg  <= 0;
            data_reg       <= 0;
        end else begin
            state          <= next;
            dht_io_reg     <= dht_io_next;
            tick_count_reg <= tick_count_next;
            led_reg        <= led_next;
            io_oe_reg      <= io_oe_next;
            bit_count_reg  <= bit_count_next;
            data_reg       <= data_next;

        end
    end

    always @(*) begin
        next            = state;
        dht_io_next     = dht_io_reg;
        tick_count_next = tick_count_reg;
        led_next        = led_reg;
        io_oe_next      = io_oe_reg;
        bit_count_next  = bit_count_reg;
        data_next       = data_reg;

        case (state)
            IDLE: begin
                led_next    = 0;
                io_oe_next  = 1;
                dht_io_next = 1;

                if (btn_start) begin
                    next = START;
                    tick_count_next = 0;   // 상태 바뀌면 카운트 값 초기화
                end 
            end
            START: begin
                io_oe_next  = 1;
                dht_io_next = 0;
          

                if (tick_1us) begin
                    if (tick_count_reg == 18000-1) begin
                        next = WAIT;
                        tick_count_next = 0;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            WAIT: begin
                io_oe_next  = 1;
                dht_io_next = 1;
                if (tick_1us) begin
                    if (tick_count_reg == 29) begin
                        next = SYNC_LOW;
                        //dht_io_next = 0;  //
                        tick_count_next = 0;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end

            end
            SYNC_LOW: begin
                io_oe_next = 0;
                if (dht_io_rising ) begin //dht_io == 1) begin
                    next = SYNC_HIGH;
                end 


            end
            SYNC_HIGH: begin
                io_oe_next = 0;
                if (dht_io_falling) begin
                    next = DATA_SYNC;
                end

            end
            DATA_SYNC: begin
                io_oe_next = 0;
                if (dht_io_rising) begin
                    next = DATA_DC;
                    
                end


            end
            DATA_DC: begin
                io_oe_next = 0;



                if (dht_io_falling) begin
                    bit_count_next = bit_count_reg + 1;
                    if (bit_count_reg == 39) begin
                        tick_count_next = 0;
                        next = STOP_RX;
                        bit_count_next = 0;
                        data_next = {
                            data_reg[38:0], (tick_count_reg < 40) ? 1'b0 : 1'b1
                        };
                    end else begin
                        next = DATA_SYNC;
                        tick_count_next = 0;
                        data_next = {
                            data_reg[38:0], (tick_count_reg < 40) ? 1'b0 : 1'b1
                        };
                    end
                end else if (tick_1us) begin
                    tick_count_next = tick_count_reg + 1;
                end
                

             

            end

            STOP_RX: begin
               
                io_oe_next = 0;
                if (tick_1us) begin 

                    if (tick_count_reg == 50) begin
                        tick_count_next = 0;
                        next = IDLE;
                        io_oe_next = 1;
                        dht_io_next = 1;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end

                end
            end
          
        endcase
    end
endmodule
