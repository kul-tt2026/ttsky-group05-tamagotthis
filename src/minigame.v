/*
 * The minigame module handles the food minigame.
 * It determines the position of the fish and checks if the cat has caught it.
 */
module minigame #(
    parameter SCREEN_WIDTH = 640,       // Width of the screen, positive x axis is to the right
    parameter SCREEN_HEIGHT = 480,      // Height of the screen, positive y axis is down
    parameter FISH_WIDTH = 16,          // Fish's width
    parameter CAT_WIDTH = 32,           // Cat's width
    parameter FISH_HEIGHT = 16,         // Fish's height
    parameter CAT_HEIGHT = 32,          // Cat's height
    parameter DEFAULT_X = 120,          // Default x position of the fish
    parameter DEFAULT_Y = 300,          // Default y position of the fish
    parameter BUFFER_DISTANCE = 50      // Determines how the fish's next position has to be from the current position
)(
    input rst_n, clk,                   // Global active-low reset and clock.
    input is_eating,                    // Signals that the food minigame is currently active.
    input reg [9:0] cat_pos_x,          // The x-position of the cat.
    input reg [9:0] cat_pos_y,          // The y-position of the cat.
    output reg [9:0] fish_pos_x,        // The x-position of the fish.
    output reg [9:0] fish_pos_y,        // The y-position of the fish.
    output fish_caught                  // Signals that a fish has been caught.
);

// note: is_eating is unused in the current implementation

localparam MIN_X = 0;
localparam MAX_X_FISH = SCREEN_WIDTH - FISH_WIDTH - 1;

localparam MIN_Y = 0;
localparam MAX_Y_FISH = SCREEN_HEIGHT - FISH_HEIGHT - 1;

reg [9:0] next_x, next_y;                                                           // always contain a valid next x and y position
reg [9:0] last_valid_x, last_valid_y;                                               // keep the most recent valid candidate values
wire [9:0] x, y;                                                                    // x and y coming out of lsfr, need to check if they're valid
wire no_overlap_fish;                                                               // tests whether there's no overlap and a buffer distance between the fish's current position and the next proposed position 
wire valid_x, valid_y;                                                              // signals whether the x / y from the lfsr are valid

wire [31:0] seed = 32'h8000_0001;                                                         // the starting seed doesn't really matter, as long as it's not all zeros
lfsr #(32,10) random_gen(.seed(seed), .clk(clk), .rst_n(rst_n), .x(x), .y(y));      // helper module to get pseudorandom x and y coordinates


/* verilator lint_off UNSIGNED */                                                   // turn off warning that says MIN_X <= x is always true since it's *currently* set to 0 and x is unsigned (so positive)
assign valid_x = (MIN_X <= x) && (x <= MAX_X_FISH);
assign valid_y = (MIN_Y <= y) && (y <= MAX_Y_FISH);
/* verilator lint_on UNSIGNED */                                                    // turn the warning back on


assign fish_caught = (cat_pos_x <= fish_pos_x) && (fish_pos_x <= cat_pos_x + (CAT_WIDTH - FISH_WIDTH))
                        && (cat_pos_y <= fish_pos_y) && (fish_pos_y <= cat_pos_y + (CAT_HEIGHT - FISH_HEIGHT));

assign no_overlap_fish = ( (x + FISH_WIDTH + BUFFER_DISTANCE <= fish_pos_x ) || (x >= fish_pos_x + FISH_WIDTH + BUFFER_DISTANCE) )              // constraints on x
                            && ( (y + FISH_HEIGHT + BUFFER_DISTANCE <= fish_pos_y ) || (y >= fish_pos_y + FISH_HEIGHT + BUFFER_DISTANCE) );     // constraints on y
// note: overflow shouldn't be a problem since we use 10 bit regs that can handle values up to 1023, while the valid positions are < 640

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // note: standard position of the fish shouldn't overlap with the cat, so that fish_caught automatically becomes 0 when resetting
        fish_pos_x <= DEFAULT_X;
        fish_pos_y <= DEFAULT_Y;
        last_valid_x <= DEFAULT_X;
        last_valid_y <= DEFAULT_Y;
    end else begin
        if (fish_caught) begin
            fish_pos_x <= next_x;
            fish_pos_y <= next_y;
        end

        if (no_overlap_fish) begin
            if (valid_x) last_valid_x <= x;
            if (valid_y) last_valid_y <= y;
        end
    end
end


always @(*) begin

    next_x = last_valid_x;
    next_y = last_valid_y;

    if (no_overlap_fish) begin
        if (valid_x) next_x = x;
        if (valid_y) next_y = y;
    end
end

endmodule

