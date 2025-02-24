import pyperclip


def generate_vhdl_rom_data(binary_file, inst_file):
    # Read binary instructions from the binary file
    with open(binary_file, "r") as file:
        binary_instructions = file.readlines()

    # Read comments from the inst file
    with open(inst_file, "r") as file:
        comments = file.readlines()

    vhdl_code = "    -- Initialize ROM with binary instructions\n"

    # Iterate over the binary instructions and comments
    for idx, (bin_inst, comment) in enumerate(zip(binary_instructions, comments)):
        bin_inst = (
            bin_inst.strip()
        )  # Remove any leading/trailing spaces or newline characters
        comment = (
            comment.strip()
        )  # Remove any leading/trailing spaces or newline characters

        if bin_inst:  # Only process non-empty binary instructions
            # Add data initialization for ROM (to store the instruction at the proper index)
            vhdl_code += f'    Data_Rom({idx}) <= "{bin_inst}"; -- {comment}\n'

    # Copy the generated VHDL code to the clipboard

    return vhdl_code


# Example usage
if __name__ == "__main__":
    vhdl_code = generate_vhdl_rom_data("binary_testing", "inst")
    pyperclip.copy(vhdl_code)
    print(vhdl_code)
    print("\nThe VHDL code has been copied to the clipboard!")
