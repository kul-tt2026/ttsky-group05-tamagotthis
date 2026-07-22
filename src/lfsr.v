/* This is a helper module for the minigame.
 * It uses a Linear Feedback Shift Register (LFSR) to generate a pseudorandom sequence of bits, from this sequence
 * the LSB's provide a pseudorandom x coordinate, the MSB's a pseudorandom y coordinate. Since x and y are taken
 * from the same sequence of bits, they aren't completely independent from each other (they're correlated), but 
 * this isn't a problem for our project.
 * A seed (start value) has to be provided, the same seed will always produce the same pseudorandom sequence.
 */
module lfsr #(
    parameter NB_INT = 32,              // Number of internal bits
    parameter NB_OUT = 10               // Determines the number of bits of outputs x and y
) 
( 
    input [NB_INT-1:0] seed,            // Determines the first output
    input clk, rst_n,                   // Global clock and active low reset
    output [NB_OUT-1:0] x,              // Outputted x coordinate
    output [NB_OUT-1:0] y               // Outputted y coordinate
);
  
    reg [NB_INT-1:0] bits;
    reg new_bit;
    
    assign new_bit = bits[NB_INT-1] ^ bits[NB_INT-3] ^ bits[NB_INT-7] ^ bits[NB_INT-8];

    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) bits <= seed;
        else bits <= {new_bit, bits[NB_INT-1:1]};
    end 

    assign x = bits[NB_OUT-1:0]; // 9:0
    assign y = bits[NB_INT-1:NB_INT-NB_OUT]; // 31:32-10 --> 31:22

endmodule


/* Note: if a 32 stage LFSR is used, it cycles throught 2^32 possible values.
 * When using a clock of 25 MHz (~ 2^24.6 cycles/s), it takes approximately 170 s to cycle through all the values.
 */
