`default_nettype none

module palette_battery (
    input wire [2:0] battery_level,
    input  wire [2:0] color_index,
    output reg [5:0] rrggbb
);

  localparam BLACK = 6'b000000;
  localparam GRAY = 6'b010101;
  localparam GREEN = 6'b001100;
  localparam YELLOW = 6'b111100;
  localparam RED = 6'b110000;
  localparam BLUE = 6'b010111;

  reg [5:0] main_color;

  always @(*) begin
    main_color = (battery_level >= 6) ? GREEN :
                 (battery_level >= 3) ? YELLOW :
                 (battery_level >= 1) ? RED : GRAY;

    case (color_index)
      3'd0: rrggbb = BLACK;
      3'd1: rrggbb = (battery_level == 7) ? GREEN : GRAY;
      3'd2: rrggbb = (battery_level >= 5) ? main_color : GRAY;
      3'd3: rrggbb = (battery_level >= 4) ? main_color : GRAY;
      3'd4: rrggbb = (battery_level >= 2) ? main_color : GRAY;
      3'd5: rrggbb = (battery_level >= 1) ? main_color : GRAY;

      default: rrggbb = BLUE;   // set to blue to easily spot mistakes
    endcase
  end

endmodule