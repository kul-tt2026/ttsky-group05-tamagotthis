
// Read Only Memory for 'cat_dead_eye'
module rom_cat_dead_eye(
                    input [9:0] addr,                         // Address to read out of, row-major.
                    output [0:0] value        // Value associated with the specified address.
                    );
    reg [0:0] mem[16:0];
    initial begin
        mem[0] = 1'd0;
        mem[1] = 1'd1;
        mem[2] = 1'd0;
        mem[3] = 1'd1;
        mem[4] = 1'd0;
        mem[5] = 1'd0;
        mem[6] = 1'd1;
        mem[7] = 1'd0;
        mem[8] = 1'd0;
        mem[9] = 1'd1;
        mem[10] = 1'd0;
        mem[11] = 1'd1;
        mem[12] = 1'd0;
        mem[13] = 1'd0;
        mem[14] = 1'd0;
        mem[15] = 1'd0;
    end

    assign value = mem[addr[4:0]];
endmodule
