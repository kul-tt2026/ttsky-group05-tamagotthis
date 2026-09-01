import os

HEX_INPUT_DIRECTORY = "../src/data/"
ROM_OUTPUT_DIRECTORY = "../src/"

ROM_TEMPLATE = """
// Read Only Memory for '$FILENAME'
module rom_$FILENAME(
                    input [9:0] addr,                         // Address to read out of, row-major.
                    output [$BIT_LENGTH_MINUS_ONE:0] value        // Value associated with the specified address.
                    );
    reg [$BIT_LENGTH_MINUS_ONE:0] mem[$MAX_ADDR_VAL:0];
    initial begin
$CONTENTS
    end

    assign value = mem[addr[$MAX_ADDR_BIT:0]];
endmodule
"""

for filename in os.listdir(HEX_INPUT_DIRECTORY):
    if '.hex' not in filename:
        continue

    rom_data = []
    # Read hex file.
    with open(HEX_INPUT_DIRECTORY + filename) as input_file:
        rom_data = [int(num) for num in input_file.read().split()]

    # Generate the text output for the ROM:
    pretty_filename = filename.replace(' ', '_').replace('.hex', '')
    bit_length = 1
    while 2**bit_length <= max(rom_data):
        bit_length += 1
    addr_bits_used = 1
    while 2**addr_bits_used <= len(rom_data):
        addr_bits_used += 1
    contents = '\n'.join([8 * " " + f"mem[{i}] = {bit_length}'d{rom_data[i]};" for i in range(len(rom_data))])
    final_text = ROM_TEMPLATE.replace('$FILENAME', pretty_filename) \
                             .replace('$BIT_LENGTH_MINUS_ONE', str(bit_length - 1)) \
                             .replace('$MAX_ADDR_VAL', str(len(rom_data))) \
                             .replace('$MAX_ADDR_BIT', str(addr_bits_used-1)) \
                             .replace('$CONTENTS', contents)
    
    # Save result.
    with open(ROM_OUTPUT_DIRECTORY + "rom_" + pretty_filename + ".v", "w+") as output_file:
        output_file.write(final_text)
