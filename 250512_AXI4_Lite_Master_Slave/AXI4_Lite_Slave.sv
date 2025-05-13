`timescale 1ns / 1ps
module AXI4_Lite_Slave(
    // Gloval Signals
    input   logic       ACLK,
    input   logic       ARESETn,
    // WRITE Transaction, AW Channel
    input   logic [ 3:0] AWADDR,
    input   logic        AWVALID,
    output  logic        AWREADY,
    // WRITE Transaction, W Channel
    input   logic [31:0] WDATA,
    input   logic        WVALID,
    output  logic        WREADY,
    // WRITE Transaction, B Channel
    output  logic [ 1:0] BRESP,
    output  logic        BVALID,
    input   logic        BREADY,
    // READ Transaction, AR Channel
    input   logic [ 3:0] ARADDR,
    input   logic        ARVALID,
    output  logic        ARREADY,
    // READ Transaction, R Channel
    output  logic [31:0] RDATA,
    output  logic        RVALID,
    input   logic        RREADY
);

    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;
    logic [ 3:0] aw_addr_next, aw_addr_reg;
    logic [ 3:0] ar_addr_next, ar_addr_reg;

    // WRITE Transaction, AW Channel transfer
    typedef enum  {
        AW_IDLE_S, 
        AW_READY_S
    } aw_state_e;

    aw_state_e aw_state_reg, aw_state_next;

    always_ff @( posedge ACLK ) begin
        if(!ARESETn) begin
            aw_state_reg <= AW_IDLE_S;
            aw_addr_reg <= 0;
        end
        else begin
            aw_state_reg <= aw_state_next;
            aw_addr_reg <= aw_addr_next;
        end
    end

    always_comb begin
        aw_state_next = aw_state_reg;
        AWREADY = 1'b0;
        aw_addr_next = aw_addr_reg;
        case (aw_state_reg)
            AW_IDLE_S: begin
                AWREADY = 1'b0;
                if (AWVALID) begin
                    aw_state_next = AW_READY_S; 
                    aw_addr_next = AWADDR;
                end
            end 
            AW_READY_S:  begin
                AWREADY = 1'b1;
                aw_addr_next = AWADDR;
                aw_state_next = AW_IDLE_S;
            end
        endcase
    end

    // WRITE Transaction, W Channel transfer
    typedef enum  {
        W_IDLE_S, 
        W_READY_S
    } w_state_e;

    w_state_e w_state_reg, w_state_next;

    always_ff @( posedge ACLK ) begin
        if(!ARESETn) begin
            w_state_reg <= W_IDLE_S;
        end
        else begin
            w_state_reg <= w_state_next;
        end
    end

    always_comb begin
        w_state_next = w_state_reg;
        WREADY = 1'b0;
        case (w_state_reg)
            W_IDLE_S: begin
                WREADY = 1'b0;
                if(AWVALID) w_state_next = W_READY_S;
            end
            W_READY_S: begin
                WREADY = 1'b1;
                if(WVALID) begin
                    w_state_next = W_IDLE_S;
                    case (aw_addr_reg[3:2])
                        2'd0: slv_reg0 = WDATA;
                        2'd1: slv_reg1 = WDATA;
                        2'd2: slv_reg2 = WDATA;
                        2'd3: slv_reg3 = WDATA;
                    endcase 
                end
            end
        endcase
    end

    // WRITE Transaction, B Channel transfer
    typedef enum  {
        B_IDLE_S, 
        B_VALID_S
    } b_state_e;

    b_state_e b_state_reg, b_state_next;

    always_ff @( posedge ACLK ) begin
        if(!ARESETn) begin
            b_state_reg <= B_IDLE_S;
        end
        else begin
            b_state_reg <= b_state_next;
        end
    end

    always_comb begin
        b_state_next = b_state_reg;
        BRESP = 2'b00;
        BVALID = 1'b0;
        case (b_state_reg)
            B_IDLE_S: begin
               BVALID = 1'b0 ;
               if(WVALID && WREADY) b_state_next = B_VALID_S;
            end
            B_VALID_S: begin
               BRESP = 2'b00; // ok
               BVALID = 1'b1; 
               if(BREADY) b_state_next = B_IDLE_S;
            end 
        endcase
    end

    // READ Transaction, AR Channel transfer
    typedef enum  {
        AR_IDLE_S, 
        AR_READY_S
    } ar_state_e;

    ar_state_e ar_state_reg, ar_state_next;

    always_ff @( posedge ACLK ) begin
        if(!ARESETn) begin
            ar_state_reg <= AR_IDLE_S;
            ar_addr_reg <= 0;
        end
        else begin
            ar_state_reg <= ar_state_next;
            ar_addr_reg <= ar_addr_next;
        end
    end

    always_comb begin
        ar_state_next = ar_state_reg;
        ARREADY = 1'b0;
        ar_addr_next = ar_addr_reg;
        case (ar_state_reg)
            AR_IDLE_S: begin
                ARREADY = 1'b0;
                if (ARVALID) begin
                    ar_state_next = AR_READY_S; 
                    ar_addr_next = ARADDR;
                end
            end 
            AR_READY_S:  begin
                ARREADY = 1'b1;
                ar_addr_next = ARADDR;
                ar_state_next = AR_IDLE_S;
            end
        endcase
    end

    // READ Transaction, R Channel transfer
    typedef enum  {
        R_IDLE_S, 
        R_VALID_S
    } r_state_e;

    r_state_e r_state_reg, r_state_next;

    always_ff @( posedge ACLK ) begin
        if(!ARESETn) begin
            r_state_reg <= R_IDLE_S;
        end
        else begin
            r_state_reg <= r_state_next;
        end
    end

    always_comb begin
        r_state_next = r_state_reg;
        RVALID = 1'b0;
        case (r_state_reg)
            R_IDLE_S: begin
                RVALID = 1'b0;
                if((ARVALID && ARREADY) == 1) r_state_next = R_VALID_S;
            end 
            R_VALID_S: begin
                RVALID = 1'b1;
                case(ar_addr_reg[3:2])
                    2'd0: RDATA = slv_reg0;
                    2'd1: RDATA = slv_reg1;
                    2'd2: RDATA = slv_reg2;
                    2'd3: RDATA = slv_reg3;
                endcase
                if(RREADY == 1'b1)
                r_state_next = R_IDLE_S;
            end
        endcase
    end

endmodule
