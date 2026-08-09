module state_dood (
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire [9:0] pix_x,
    input wire [9:0] pix_y,
    output wire [1:0] R,
    output wire [1:0] G,
    output wire [1:0] B
);

localparam [9:0] KAT_LEFT= 192 ;
localparam [9:0] KAT_TOP = 112;

wire [9:0] x= (pix_x - KAT_LEFT) >>3;
wire [9:0] y= (pix_y - KAT_TOP) >>3;
wire in_sprite = (x[9:5] == 0 && y[9:5] == 0);

wire [1:0] pixel_value_rom;
bitmap_rom_kat rom1 (
    .x(x[4:0]),
    .y(y[4:0]),
    .pixel(pixel_value_rom)

);

  // --- Stap 1: gebied dat de originele ogen bevat, wissen naar achtergrond ---
wire is_oog_gebied =
    ((y[4:0] == 5'd13 || y[4:0] == 5'd16) &&
     (x[4:0] == 5'd12 || x[4:0] == 5'd13 || x[4:0] == 5'd21 || x[4:0] == 5'd22)) ||
    ((y[4:0] == 5'd14 || y[4:0] == 5'd15) &&
     (x[4:0] == 5'd11 || x[4:0] == 5'd12 || x[4:0] == 5'd13 || x[4:0] == 5'd14 ||
      x[4:0] == 5'd20 || x[4:0] == 5'd21 || x[4:0] == 5'd22 || x[4:0] == 5'd23));

// --- Stap 2: klein kruisje (X) tekenen op specifieke pixels ---
wire is_kruis_pixel =
    (y[4:0] == 5'd13 && (x[4:0] == 5'd12 || x[4:0] == 5'd14|| x[4:0] == 5'd22 || x[4:0] == 5'd20)) ||
    (y[4:0] == 5'd14 &&  (x[4:0] == 5'd13 || x[4:0]== 5'd21)) ||
    (y[4:0] == 5'd15 && (x[4:0] == 5'd12 || x[4:0] == 5'd14 || x[4:0] == 5'd22 || x[4:0] == 5'd20));

// --- Combineren: kruis heeft voorrang op oog-gebied, oog-gebied op ROM ---
wire [1:0] pixel_value = is_kruis_pixel ? 2'b01 :               // zwart kruisje
                          is_oog_gebied ? 2'b11 :                // achtergrondkleur
                          pixel_value_rom;                       // normale sprite

wire [5:0] color ;
palette_kat palette_inst(
    .color_index(pixel_value),
    .rrggbb(color)
);

assign R = (enable && in_sprite) ? color[5:4] : 2'b00;
assign G = (enable && in_sprite) ? color[3:2] : 2'b00;
assign B = (enable && in_sprite) ? color[1:0] : 2'b00;

endmodule
