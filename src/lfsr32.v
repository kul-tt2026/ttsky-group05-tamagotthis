/* This is a helper module for the minigame.
 * 
 * It uses a Linear Feedback Shift Register (LFSR) to generate a pseudorandom sequence of bits, based on 32 internal bits
 * This module can be used to output one or two random signals, depending on the parameter TWO_OUTPUTS. 
 * Make sure that 32 >= 2*NB_OUT is you want two outputs.

 * If only one output is needed, it takes NB_INT bits from the internal NB_OUT bits, starting from the LSB's.
 * If two outputs are needed, s1 takes NB_INT LSB's, s2 takes NB_INT MSB's.
 * Since s1 and s2 are taken from the same sequence of bits, they aren't completely independent from each other (they're correlated), 
 * but this isn't a problem for our project.

 * A seed (start value) is given through the SEED parameter, the same seed will always produce the same pseudorandom sequence.
 */
module lfsr32 #(
    parameter NB_OUT = 10,              // Determines the number of bits of outputs s1 (and s2)
    parameter TWO_OUTPUTS = 1,          // Set it to 1 to get two outputs, otherwise only one output is provided
    parameter [31:0] SEED = 32'h8000_0001 // Start value of the internal bits, must not be all zeros.
                                        // A parameter (not a port): an async reset value must be a constant,
                                        // otherwise yosys can't map the flops and emits latches.
) 
( 
    input clk, rst_n,                   // Global clock and active low reset
    output reg [NB_OUT-1:0] s1,         // Outputted s1 value
    output reg [NB_OUT-1:0] s2          // Outputted s2 value (set to all zero's if only one output is needed)
);
  
    reg [31:0] bits;
    wire new_bit;

    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin 
            bits <= SEED;
            s1 <= 0;
            s2 <= 0;
        end else begin

            // bits <= {new_bit, bits[31:1]};
            bits <= {bits[0], bits[31:1]} ^ (bits[0] * 32'h00000057);
            if (TWO_OUTPUTS == 1) begin
                s1 <= bits[NB_OUT-1:0];   // 9:0
                s2 <= bits[31:32-NB_OUT]; // 31:32-10 --> 31:22
            end else begin
                s1 <= bits[NB_OUT-1:0];
                s2 <= 0;
            end
        end 
    end 

endmodule
