`timescale 1ns / 1ps
      
module MCU (
    input  logic       clk,
    input  logic       reset,
    output logic [7:0] GPOA,
    input  logic [7:0] GPIB,
    inout  logic  [7:0] GPIOC, // led
    inout  logic  [7:0] GPIOD,  // switch    
    output logic [3:0] fndCom,
    output logic [7:0] fndFont,
    //uart
    input  logic       rx,
    output logic       tx,
    //HCSR04
    input  logic       echo,
    output logic       start_trigger,
    //dht11
    inout  logic dht_io
);
    // global signals
    logic        PCLK;
    logic        PRESET;
    // APB Interface Signals
    logic        PWRITE;
    logic        PENABLE;
    logic [31:0] PADDR;
    logic [31:0] PWDATA;
    logic        PSEL_RAM;
    logic        PSEL_GPO;
    logic        PSEL_GPI;
    logic        PSEL_GPIOC;
    logic        PSEL_GPIOD;
    logic        PSEL_FND;
    logic        PSEL_TIMER;
    logic        PSEL_UART;
    logic        PSEL_HCSR04;
    logic        PSEL_DHT11;
    logic [31:0] PRDATA_RAM;
    logic [31:0] PRDATA_GPO;
    logic [31:0] PRDATA_GPI;
    logic [31:0] PRDATA_GPIOC;
    logic [31:0] PRDATA_GPIOD;
    logic [31:0] PRDATA_FND;
    logic [31:0] PRDATA_TIMER;
    logic [31:0] PRDATA_UART;
    logic [31:0] PRDATA_HCSR04;
    logic [31:0] PRDATA_DHT11;
    logic        PREADY_RAM;
    logic        PREADY_GPO;
    logic        PREADY_GPI;
    logic        PREADY_GPIOC;
    logic        PREADY_GPIOD;
    logic        PREADY_FND;
    logic        PREADY_TIMER;
    logic        PREADY_UART;
    logic        PREADY_HCSR04;
    logic        PREADY_DHT11;

    // CPU - APB_Master Signals
    // Internal Interface Signals
    logic        transfer;  // trigger signal
    logic        ready;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic        write;  // 1:write, 0:read
    logic        dataWe;
    logic [31:0] dataAddr;
    logic [31:0] dataWData;
    logic [31:0] dataRData;

    // ROM Signals
    logic [31:0] instrCode;
    logic [31:0] instrMemAddr;
    
    // my ip
    logic [3:0] fndData;

    assign PCLK = clk;
    assign PRESET = reset;
    assign addr = dataAddr;
    assign wdata = dataWData;
    assign dataRData = rdata;
    assign write = dataWe;

    rom U_ROM (
        .addr(instrMemAddr),
        .data(instrCode)
    );

    RV32I_Core U_Core (.*);

    APB_Master U_APB_Master (
        .*,
        .PSEL0  (PSEL_RAM),
        .PSEL1  (PSEL_GPO),
        .PSEL2  (PSEL_GPI),
        .PSEL3  (PSEL_GPIOC),
        .PSEL4  (PSEL_GPIOD),
        .PSEL5  (PSEL_FND),
        .PSEL6  (PSEL_TIMER),
        .PSEL7  (PSEL_UART),
        .PSEL8  (PSEL_HCSR04),
        .PSEL9  (PSEL_DHT11),
        .PRDATA0(PRDATA_RAM),
        .PRDATA1(PRDATA_GPO),
        .PRDATA2(PRDATA_GPI),
        .PRDATA3(PRDATA_GPIOC),
        .PRDATA4(PRDATA_GPIOD),
        .PRDATA5(PRDATA_FND),
        .PRDATA6(PRDATA_TIMER),
        .PRDATA7(PRDATA_UART),
        .PRDATA8(PRDATA_HCSR04),
        .PRDATA9(PRDATA_DHT11),
        .PREADY0(PREADY_RAM),
        .PREADY1(PREADY_GPO),
        .PREADY2(PREADY_GPI),
        .PREADY3(PREADY_GPIOC),
        .PREADY4(PREADY_GPIOD),
        .PREADY5(PREADY_FND),
        .PREADY6(PREADY_TIMER),
        .PREADY7(PREADY_UART),
        .PREADY8(PREADY_HCSR04),
        .PREADY9(PREADY_DHT11)
    );

    ram U_RAM (
        .*,
        .PSEL  (PSEL_RAM),
        .PRDATA(PRDATA_RAM),
        .PREADY(PREADY_RAM)
    );

    GPO_Periph U_GPOA (
        .*,
        .PSEL   (PSEL_GPO),
        .PRDATA (PRDATA_GPO),
        .PREADY (PREADY_GPO),
        // export signals
        .outPort(GPOA)
    );

    GPI_Periph U_GPIB (
        .*,
        .PSEL  (PSEL_GPI),
        .PRDATA(PRDATA_GPI),
        .PREADY(PREADY_GPI),
        // inport signals
        .inPort(GPIB)
    );

    GPIO_Periph U_GPIOC (
        .*,
        .PSEL  (PSEL_GPIOC),
        .PRDATA(PRDATA_GPIOC),
        .PREADY(PREADY_GPIOC),
        .inoutPort(GPIOC)
    );

    GPIO_Periph U_GPIOD (
        .*,
        .PSEL  (PSEL_GPIOD),
        .PRDATA(PRDATA_GPIOD),
        .PREADY(PREADY_GPIOD),
        .inoutPort(GPIOD)
    );

    FndController_Periph U_FndControl(
        .*,
        .PSEL(PSEL_FND),
        .PRDATA(PRDATA_FND),
        .PREADY(PREADY_FND)
    );


    TIMER_Periph U_TIMER(
        .*,
        .PSEL(PSEL_TIMER),
        .PRDATA(PRDATA_TIMER),
        .PREADY(PREADY_TIMER)
    // inport signals
);

    fifo_Periph U_UART(
    .*,
    .PSEL(PSEL_UART),
    .PRDATA(PRDATA_UART),
    .PREADY(PREADY_UART)
);

    HCSR04_Periph U_HCSR04(
    .*,
    .PSEL(PSEL_HCSR04),
    .PRDATA(PRDATA_HCSR04),
    .PREADY(PREADY_HCSR04)
);

    DHT_11_Periph U_DHT11(
    .*,
    .PSEL(PSEL_DHT11),
    .PRDATA(PRDATA_DHT11),
    .PREADY(PREADY_DHT11)
);


endmodule