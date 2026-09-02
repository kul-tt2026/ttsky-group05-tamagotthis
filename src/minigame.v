/*
 * The minigame module handles the food minigame.
 * It determines the position of the fish and checks if the cat has caught it.
 */
module minigame #(
    parameter SCREEN_WIDTH = 640,       // Width of the screen, positive x axis is to the right
    parameter SCREEN_HEIGHT = 480,      // Height of the screen, positive y axis is down
    parameter FISH_WIDTH = 16*2,        // Fish's width
    parameter CAT_WIDTH = 23*2,         // Cat's width
    parameter FISH_HEIGHT = 10*2,       // Fish's height
    parameter CAT_HEIGHT = 25*2,        // Cat's height
    parameter DEFAULT_X = 120,          // Default x position of the fish
    parameter DEFAULT_Y = 300,          // Default y position of the fish
    parameter BUFFER_DISTANCE = 50      // Determines how the fish's next position has to be from the current position
)(
    input rst_n, clk, clk2,             // Global active-low reset and clock  + faster clock for lfsr (clk2)
    input is_eating,                    // Signals that the food minigame is currently active.
    input reg [9:0] cat_pos_x,          // The x-position of the cat.
    input reg [9:0] cat_pos_y,          // The y-position of the cat.
    output reg [9:0] fish_pos_x,        // The x-position of the fish.
    output reg [9:0] fish_pos_y,        // The y-position of the fish.
    output reg fish_caught              // Signals that a fish has been caught.
);

localparam MIN_X = 0;
localparam MAX_X_FISH = SCREEN_WIDTH - FISH_WIDTH - 1;

localparam MIN_Y = 0;
localparam MAX_Y_FISH = SCREEN_HEIGHT - FISH_HEIGHT - 1;
                            
reg [9:0] next_x, next_y;                                                               // always contain a valid next x and y position
reg [9:0] last_valid_x, last_valid_y;                                                   // keep the most recent valid candidate values
wire [9:0] x, y;                                                                        // x and y coming out of lsfr, need to check if they're valid
wire no_overlap_fish;                                                                   // tests whether there's no overlap and a buffer distance between the fish's current position and the next proposed position 
wire valid_x, valid_y;                                                                  // signals whether the x / y from the lfsr are valid
// wire fish_caught_now;                                                                // signals whether a fish was caught this clockcycle

// lfsr is a helper module to get pseudorandom x and y coordinates
wire [31:0] seed = 32'h8000_0001;                                                       

// x: 0 --> MAX_X_FISH (bv. 640 - 32 - 1 = 607) --> neem 10 bits
wire [8:0] x1, x2_full;
wire [6:0] x2 = x2_full[6:0];
lfsr32 #(9,1) random_x(.seed(seed), .clk(clk2), .rst_n(rst_n), .s1(x1), .s2(x2_full));
assign x = {1'b0, x1} + {3'b0, x2} >= MAX_X_FISH ? MAX_X_FISH : {1'b0, x1} + {3'b0, x2}; 

// y: 0 --> MAX_Y_FISH (bv. 480 - 32 - 1 = 447) --> 9 bits maar 10 maken voor consistentie
wire [12:0] y14_full, y23_full;
wire [7:0] y1 = y14_full[12:5];
wire [6:0] y2 = y23_full[12:6];
wire [5:0] y3 = y23_full[5:0];
wire [4:0] y4 = y14_full[4:0];
lfsr32 #(13,1) random_y(.seed(seed), .clk(clk2), .rst_n(rst_n), .s1(y14_full), .s2(y23_full));
assign y = {2'b0, y1} + {3'b0, y2} + {4'b0, y3} + {5'b0, y4} >= MAX_Y_FISH ? MAX_Y_FISH : {2'b0, y1} + {3'b0, y2} + {4'b0, y3} + {5'b0, y4};

assign valid_x = (MIN_X <= x) && (x <= MAX_X_FISH);
assign valid_y = (MIN_Y <= y) && (y <= MAX_Y_FISH);

// fish is caught when it overlaps completely with the cat
assign fish_caught = rst_n && (cat_pos_x <= fish_pos_x) && (fish_pos_x <= cat_pos_x + (CAT_WIDTH - FISH_WIDTH))
                       && (cat_pos_y <= fish_pos_y) && (fish_pos_y <= cat_pos_y + (CAT_HEIGHT - FISH_HEIGHT));

assign no_overlap_fish = ( (x + FISH_WIDTH + BUFFER_DISTANCE <= fish_pos_x ) || (x >= fish_pos_x + FISH_WIDTH + BUFFER_DISTANCE) )              // constraints on x
                            && ( (y + FISH_HEIGHT + BUFFER_DISTANCE <= fish_pos_y ) || (y >= fish_pos_y + FISH_HEIGHT + BUFFER_DISTANCE) );     // constraints on y


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // note: standard position of the fish shouldn't overlap with the cat, so that fish_caught automatically becomes 0 when resetting
        fish_pos_x <= DEFAULT_X;
        fish_pos_y <= DEFAULT_Y;
        
    end else begin
        
        if (fish_caught) begin
            fish_pos_x <= next_x;
            fish_pos_y <= next_y;
        end
    end
end

always @(posedge clk2 or negedge rst_n) begin
    if (!rst_n) begin
        // note: standard position of the fish shouldn't overlap with the cat, so that fish_caught automatically becomes 0 when resetting
        next_x <= DEFAULT_X;
        next_y <= DEFAULT_Y;
        
    end else if (no_overlap_fish & valid_x & valid_y) begin
        next_x <= x;
        next_y <= y;
    end

    
end

endmodule
