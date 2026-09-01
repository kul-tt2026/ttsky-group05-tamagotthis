
// Read Only Memory for 'cat_raised_ear'
module rom_cat_raised_ear(
                    input [9:0] addr,                         // Address to read out of, row-major.
                    output [1:0] value        // Value associated with the specified address.
                    );
    reg [1:0] mem[48:0];
    initial begin
        mem[0] = 2'd0;
        mem[1] = 2'd1;
        mem[2] = 2'd1;
        mem[3] = 2'd0;
        mem[4] = 2'd0;
        mem[5] = 2'd0;
        mem[6] = 2'd1;
        mem[7] = 2'd3;
        mem[8] = 2'd3;
        mem[9] = 2'd1;
        mem[10] = 2'd1;
        mem[11] = 2'd0;
        mem[12] = 2'd1;
        mem[13] = 2'd3;
        mem[14] = 2'd3;
        mem[15] = 2'd3;
        mem[16] = 2'd3;
        mem[17] = 2'd1;
        mem[18] = 2'd1;
        mem[19] = 2'd3;
        mem[20] = 2'd3;
        mem[21] = 2'd3;
        mem[22] = 2'd3;
        mem[23] = 2'd3;
        mem[24] = 2'd0;
        mem[25] = 2'd1;
        mem[26] = 2'd3;
        mem[27] = 2'd3;
        mem[28] = 2'd3;
        mem[29] = 2'd3;
        mem[30] = 2'd0;
        mem[31] = 2'd1;
        mem[32] = 2'd3;
        mem[33] = 2'd3;
        mem[34] = 2'd3;
        mem[35] = 2'd3;
        mem[36] = 2'd0;
        mem[37] = 2'd0;
        mem[38] = 2'd1;
        mem[39] = 2'd3;
        mem[40] = 2'd3;
        mem[41] = 2'd3;
        mem[42] = 2'd0;
        mem[43] = 2'd0;
        mem[44] = 2'd0;
        mem[45] = 2'd1;
        mem[46] = 2'd3;
        mem[47] = 2'd3;
    end

    assign value = mem[addr[5:0]];
endmodule
