`timescale 1ns / 1ps

module debounce_edge_detect #(
    parameter int unsigned CLK_FREQ_HZ    = 50_000_000,
    parameter int unsigned STABLE_TIME_MS = 10
) (
    input  logic clk,
    input  logic rst_n,
    input  logic sig_in,
    output logic sig_debounced,
    output logic edge_rise,
    output logic edge_fall
);

    // TODO:
    // 1. Implement a 2-stage synchronizer on the sig_in input.
    // 2. Calculate the required cycle count: CYCLES = (CLK_FREQ_HZ * STABLE_TIME_MS) / 1000.
    // 3. Implement a counter measuring the stability interval.
    // 4. Update sig_debounced with the stable input state.
    // 5. Generate 1-clock-cycle pulses for edge_rise and edge_fall.

    localparam int unsigned CYCLES = (CLK_FREQ_HZ * STABLE_TIME_MS) / 1000;
    localparam int unsigned CTR_W = $clog2(CYCLES); //19
    
    logic sig_sync_1, sig_sync_2;
    logic [CTR_W-1:0] stable_ctr = 0;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            stable_ctr <= '0;
            sig_sync_1 <= 1'b0;
            sig_sync_2 <= 1'b0;

            sig_debounced <= 1'b0;
            edge_rise <= 1'b0;
            edge_fall <= 1'b0;
        end else begin
            edge_rise <= 1'b0;
            edge_fall <= 1'b0;


            if(sig_sync_2 == sig_debounced) stable_ctr <= '0; 
            else if(stable_ctr ==  CTR_W'(CYCLES - 1)) begin
                edge_rise <= sig_sync_2;
                edge_fall <= ~sig_sync_2;
                sig_debounced <= sig_sync_2;
                stable_ctr <= '0;    
            end else begin
                stable_ctr <= stable_ctr + 1'b1;
            end

            sig_sync_2 <= sig_sync_1;
            sig_sync_1 <= sig_in;      
        end 
    end


    // edge_fal <= ev ? (sig_debounced && !sig_sync_2) : 0;    

endmodule
