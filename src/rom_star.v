// Read Only Memory for star
module rom_star(
    input [9:0] addr,                           // Address to read out of, row-major.
    output [1:0] value                          // Value associated with the specified address.
);
    reg [1:0] mem[24:0];
    initial begin
        mem[0]  = 2'd0;
        mem[1]  = 2'd0;
        mem[2]  = 2'd1;
        mem[3]  = 2'd0;
        mem[4]  = 2'd0;
        mem[5]  = 2'd0;
        mem[6]  = 2'd1;
        mem[7]  = 2'd1;
        mem[8]  = 2'd1;
        mem[9]  = 2'd0;
        mem[10] = 2'd1;
        mem[11] = 2'd1;
        mem[12] = 2'd2;
        mem[13] = 2'd1;
        mem[14] = 2'd1;
        mem[15] = 2'd0;
        mem[16] = 2'd1;
        mem[17] = 2'd1;
        mem[18] = 2'd1;
        mem[19] = 2'd0;
        mem[20] = 2'd0;
        mem[21] = 2'd0;
        mem[22] = 2'd1;
        mem[23] = 2'd0;
        mem[24] = 2'd0;
    end

    assign value = mem[addr[4:0]];
endmodule
