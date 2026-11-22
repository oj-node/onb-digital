`timescale 1ns / 1ps

module uart_tx #(
    parameter int unsigned CLK_FREQ_HZ = 50_000_000,
    parameter int unsigned BAUD_RATE   = 115_200
) (
    input  logic       clk,
    input  logic       rst_n,

    // Data handshake
    input  logic [7:0] tx_data,
    input  logic       tx_valid,
    output logic       tx_ready,

    // Physical line
    output logic       txd
);

    // TODO:
    // 1. Implement a clock prescaler generating bit clock ticks:
    //    CLKS_PER_BIT = (CLK_FREQ_HZ + BAUD_RATE/2) / BAUD_RATE.
    // 2. Build the state machine (FSM): IDLE, START, DATA, STOP.
    // 3. Transmit data bits in 8N1 format (LSB first).
    // 4. Manage the tx_ready flag to support back-to-back continuous transmission.

    localparam int unsigned CLKS_PER_BIT = (CLK_FREQ_HZ + BAUD_RATE/2) / BAUD_RATE;
    enum logic [1:0]{
        IDLE = 0, 
        START = 1, 
        DATA = 2, 
        STOP =3} state = IDLE;
    
    logic [2:0] bit_ctr = '0;
    logic [7:0] tx_data_reg;
    logic [$clog2(CLKS_PER_BIT)-1:0] clk_ctr = '0;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= IDLE;
            bit_ctr <= '0;
            clk_ctr <= '0;
            tx_data_reg <= '0;
            txd <= 1'b1;

        end else begin
            if (clk_ctr == CLKS_PER_BIT - 1) clk_ctr <= '0;
            else clk_ctr <= clk_ctr + 1;

            case(state)
                IDLE : begin
                    if(tx_valid && tx_ready) begin
                        txd <= 0;
                        state <= START;
                        clk_ctr <= '0;
                        tx_data_reg <= tx_data;        
                    end
                end

                START : begin
                    if (clk_ctr == CLKS_PER_BIT - 1) begin
                        state <= DATA;
                        bit_ctr <= '0;
                        txd <= tx_data_reg[0];
                    end
                end
                DATA : begin
                    if (clk_ctr == CLKS_PER_BIT - 1) begin
                        if (bit_ctr == 7) begin
                            state <= STOP;
                            txd <= 1'b1;
                        end else begin
                            txd <= tx_data_reg[bit_ctr + 1];
                            bit_ctr <= bit_ctr + 1'b1;
                        end
                    end
                end

                STOP : begin
                    if (clk_ctr == CLKS_PER_BIT - 1) begin
                        if (tx_valid) begin
                            tx_data_reg <= tx_data;
                            txd <= 1'b0;
                            state <= START;
                        end else begin
                            state <= IDLE;
                        end
                    end
                end
            endcase
        end
    end

    assign tx_ready = (state == IDLE) || (state == STOP && clk_ctr == CLKS_PER_BIT - 1);


endmodule
