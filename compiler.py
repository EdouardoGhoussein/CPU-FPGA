# Opcode mapping for instructions
opcode_map = {
    # Arithmetic/Logical Instructions (R-Type)
    "ADD": "0000",
    "SUB": "0001",
    "MUL": "0010",
    "AND": "0011",
    "OR": "0100",
    "XOR": "0101",
    "MOV": "0110",
    "NOT": "0111",
    "LSL": "1000",
    "LSR": "1009",
    "CMP": "0001",
    # Memory Access Instructions
    "LD": "0000",
    "ST": "1111",
    # Stack Operations
    "PUSH": "1110",
    "POP": "1100",
    # Branching Instructions
    "B": "0000",
    "BEQ": "0001",
    "BNE": "0010",
    "BLT": "0011",
    "BGT": "0100",
    "BLE": "0101",
    "BGE": "0110",
    # Special Instructions
    "NOP": "1111",
    # MMX Instructions
    "VDOT": "0010",
    "MATMUL": "0010",
}

# Instruction categories
instruction_categories = {
    "r_type": [
        "ADD",
        "SUB",
        "MUL",
        "AND",
        "OR",
        "XOR",
        "NOT",
        "LSL",
        "LSR",
    ],
    "r_type_move": ["MOV", "CMP"],
    "memory_access": ["LD", "ST"],
    "stack": ["PUSH", "POP"],
    "branching": ["B", "BEQ", "BNE", "BLT", "BGT", "BLE", "BGE"],
    "branch_link": ["BL", "BLEQ", "BLNE", "BLLT", "BLGT", "BLLE", "BLGE"],
    "branch_return": ["BX", "BXEQ", "BXNE", "BXLT", "BXGT", "BXLE", "BXGE"],
    "special": ["NOP"],
    "mmx_vector": [
        "VADD",
        "VSUB",
        "VMUL",
        "VAND",
        "VOR",
        "VXOR",
        "VNOT",
        "VLSL",
        "VLSR",
        "VDOT",
    ],
    "mmx_matrix": [
        "MADD",
        "MSUB",
        "MMUL",
        "MAND",
        "MOR",
        "MXOR",
        "MNOT",
        "MLSL",
        "MLSR",
        "MATMUL",
    ],
    "mmx_move": ["VMOV"],
}

# Expected number of parts for each instruction category
expected_parts = {
    "r_type": 4,
    "r_type_move": 3,
    "memory_access": 3,
    "stack": {"PUSH": 2, "POP": 3},
    "branching": 2,
    "branch_link": 2,
    "branch_return": 1,
    "special": 1,
    "mmx_vector": 4,
    "mmx_matrix": 4,
    "mmx_move": 3,
}


def inst_check_size(inst_parts):
    """Check if the instruction has the correct number of parts."""
    mnemonic = inst_parts[0]

    # Determine the category of the instruction
    for category, mnemonics in instruction_categories.items():
        if mnemonic in mnemonics:
            # Handle stack instructions separately
            if category == "stack":
                expected = expected_parts[category][mnemonic]
            else:
                expected = expected_parts[category]

            # Check if the number of parts matches
            if len(inst_parts) != expected:
                return False
            return True

    # If the mnemonic is not found in any category
    return False


# Opcode mapping and helper functions


def to_binary(value, bits=10):
    """Convert an integer to a binary string with a fixed number of bits.
    Negative numbers are represented in two's complement.
    """
    if value < 0:
        value = (1 << bits) + value
    return format(value, f"0{bits}b")


def parse_immediate(value_str):
    """Parse immediate value from string (supports hex, binary, decimal)."""
    try:
        if value_str.startswith("0X"):
            return int(value_str, 16)
        elif value_str.startswith("0B"):
            return int(value_str, 2)
        else:
            return int(value_str)
    except ValueError:
        return None


def validate_register(token, allowed_prefixes, max_num):
    """Validate register token (e.g., 'R3', 'V15')."""
    if len(token) < 2 or token[0] not in allowed_prefixes:
        return False
    try:
        num = int(token[1:])
        return 0 <= num <= max_num
    except ValueError:
        return False


# Enhanced compile_line with detailed validation
def compile_line(inst, line_num):
    inst = inst.upper().strip()
    if not inst:
        return None  # Skip empty lines

    inst_parts = inst.split()
    if not inst_parts:
        return None

    mnemonic = inst_parts[0]
    error_prefix = f"Line {line_num}: {inst} -"

    # Size check
    if not inst_check_size(inst_parts):
        raise ValueError(f"{error_prefix} Invalid number of operands")

    # Get opcode and continue compilation
    try:
        opcode_key = list(mnemonic)
        if opcode_key[0] == "B" and len(opcode_key) > 1:
            opcode_key[1] = opcode_key[1].replace("L", "").replace("X", "")
        elif opcode_key[0] == "V" and mnemonic != "VDOT":
            opcode_key[0] = opcode_key[0].replace("V", "")
        elif opcode_key[0] == "M" and mnemonic not in ["MATMUL", "MOV"]:
            opcode_key[0] = opcode_key[0].replace("M", "")
        opcode_key = "".join(opcode_key)

        opcode = opcode_map[opcode_key]
    except KeyError:
        raise KeyError(f"{error_prefix} Invalid instruction mnemonic {opcode_key}")

    # Operand validation
    try:
        if mnemonic in instruction_categories["r_type"]:
            if not (
                validate_register(inst_parts[1], ["R"], 7)
                and validate_register(inst_parts[2], ["R"], 7)
            ):
                raise ValueError("Invalid register(s)")

            # Third operand can be register or immediate
            third = inst_parts[3]
            if not (
                validate_register(third, ["R"], 7)
                or (
                    parse_immediate(third) is not None
                    and -(2**13) <= parse_immediate(third) < 2**14
                )
            ):
                raise ValueError("Third operand must be R register or 10-bit immediate")
            immediate = "1" if "R" not in third else "0"
            last_part = (
                to_binary(int(third[1:]), 3) + 11 * "0"
                if immediate == "0"
                else to_binary(parse_immediate(third), 14)
            )
            return (
                "000"
                + immediate
                + "0100"
                + opcode
                + to_binary(int(inst_parts[1][1:]), 3)
                + to_binary(int(inst_parts[2][1:]), 3)
                + last_part
            )
        elif mnemonic == "NOP":
            return "00000000" + opcode + 20 * "0"
        elif mnemonic == "CMP":
            if not (validate_register(inst_parts[1], ["R"], 7)):
                raise ValueError("Invalid register(s) for CMP")

            src = inst_parts[2]
            if not (
                validate_register(src, ["R"], 7)
                or (
                    parse_immediate(src) is not None
                    and -(2**15) <= parse_immediate(src) < 2**16
                )
            ):
                raise ValueError("Source must be R register or 16-bit immediate")
            immediate = "1" if "R" not in src else "0"
            last_part = (
                "000" + to_binary(int(src[1:])) + 11 * "0"
                if immediate == "0"
                else to_binary(parse_immediate(src), 14)
            )
            return (
                "000"
                + immediate
                + "0000"
                + opcode
                + "000"
                + to_binary(int(inst_parts[1][1:]), 3)
                + last_part
            )
        elif mnemonic == "MOV":
            if not validate_register(inst_parts[1], ["R"], 7):
                raise ValueError("Invalid destination register")

            src = inst_parts[2]
            if not (
                validate_register(src, ["R"], 7)
                or (
                    parse_immediate(src) is not None
                    and -(2**15) <= parse_immediate(src) < 2**16
                )
            ):
                raise ValueError("Source must be R register or 16-bit immediate")
            immediate = "1" if "R" not in src else "0"
            last_part = (
                "000" + to_binary(int(src[1:]), 3) + 11 * "0"
                if immediate == "0"
                else "0" + to_binary(parse_immediate(src), 16)
            )
            return (
                "000"
                + immediate
                + "0100"
                + opcode
                + to_binary(int(inst_parts[1][1:]), 3)
                + last_part
            )
        elif mnemonic in ["LD", "ST"]:
            if not validate_register(inst_parts[1], ["R"], 7):
                raise ValueError("Invalid base register")

            # Second operand can be register or address
            addr = inst_parts[2]
            if not (
                validate_register(addr, ["R"], 7) or parse_immediate(addr) is not None
            ):
                raise ValueError("Address must be register or immediate")

            immediate = "1" if "R" not in addr else "0"
            last_part = (
                "000" + to_binary(int(addr[1:])) + 11 * "0"
                if immediate == "0"
                else 6 * "0" + to_binary(parse_immediate(addr), 8)
            )
            if mnemonic == "LD":
                return (
                    "000"
                    + immediate
                    + "0101"
                    + opcode
                    + to_binary(int(inst_parts[1][1:]), 3)
                    + "000"
                    + last_part
                )
            else:
                return (
                    "000"
                    + immediate
                    + "0001"
                    + opcode
                    + "000"
                    + to_binary(int(inst_parts[1][1:]), 3)
                    + last_part
                )
        elif mnemonic in (
            instruction_categories["branching"]
            + instruction_categories["branch_link"]
            + instruction_categories["branch_return"]
        ):
            immediate = (
                "1" if mnemonic in instruction_categories["branch_return"] else "0"
            )

            if immediate == "1":
                inst_parts.append("0")  # Add a dummy value for the second operand

            if not (
                parse_immediate(inst_parts[1]) is not None
                and -(2**7) <= parse_immediate(inst_parts[1]) < 2**8
            ):
                raise ValueError("Branch offset must be 8-bit immediate")
            write = "1" if mnemonic in instruction_categories["branch_link"] else "0"
            return (
                f"000{immediate}0{write}10"
                + opcode
                + "111"
                + "0" * 9
                + to_binary(parse_immediate(inst_parts[1]), 8)
            )
        elif mnemonic == "PUSH":
            if not validate_register(inst_parts[1], ["R"], 7):
                raise ValueError("Invalid register for PUSH")

            return (
                "00000000"
                + opcode
                + "000"
                + "000"
                + to_binary(int(inst_parts[1][1:]), 3)
                + 11 * "0"
            )

        elif mnemonic == "POP":
            if not validate_register(inst_parts[1], ["R"], 7):
                raise ValueError("Invalid register for POP")
            if not (
                parse_immediate(inst_parts[2]) is not None
                and 0 <= parse_immediate(inst_parts[2]) < 2**5
            ):
                raise ValueError("POP offset must be 5-bit immediate")
            return (
                "00000100"
                + opcode
                + to_binary(int(inst_parts[1][1:]), 3)
                + "000000"
                + to_binary(parse_immediate(inst_parts[2]), 11)
            )

        elif mnemonic in instruction_categories["mmx_vector"]:
            start = 1
            if mnemonic == "VDOT":
                start = 2
                if not validate_register(inst_parts[1], ["R"], 7):
                    raise ValueError(
                        "Invalid register (R0-R7 required) for VDOT destination"
                    )
            for reg in inst_parts[start:]:
                if not validate_register(reg, ["V"], 15):
                    raise ValueError("Invalid vector register (V0-V15 required)")

            TAlu = "1" if mnemonic == "VDOT" else "0"
            return (
                f"1{TAlu}000100"
                + opcode
                + to_binary(int(inst_parts[1][1:]), 4)
                + to_binary(int(inst_parts[2][1:]), 4)
                + to_binary(int(inst_parts[3][1:]), 4)
                + 8 * "0"
            )

        elif mnemonic in instruction_categories["mmx_matrix"]:
            for reg in inst_parts[1:]:
                if not validate_register(reg, ["M"], 4):
                    raise ValueError("Invalid matrix register (M0-M4 required)")

            TAlu = "1" if mnemonic == "MATMUL" else "0"
            return (
                f"1{TAlu}000110"
                + opcode
                + to_binary(int(inst_parts[1][1:]) * 3, 4)
                + to_binary(int(inst_parts[2][1:]) * 3, 4)
                + to_binary(int(inst_parts[3][1:]) * 3, 4)
                + 8 * "0"
            )

        elif mnemonic == "VMOV":
            if not validate_register(inst_parts[1], ["V"], 15):
                raise ValueError("Invalid vector register")

            values = inst_parts[2].split(",")
            if not all(
                parse_immediate(v) is not None
                and -(2**15) <= parse_immediate(v) < 2**16
                for v in values
            ) or validate_register(inst_parts[2], ["V"], 15):
                raise ValueError("Invalid 16-bit immediate values")
            immediate = "1" if "V" not in inst_parts[2] else "0"
            if immediate == "1":
                return (
                    "10010100"
                    + opcode
                    + to_binary(int(inst_parts[1][1:]), 4)
                    + to_binary(parse_immediate(values[0]), 16)
                    + "\n"
                    + to_binary(parse_immediate(values[1]), 16)
                    + to_binary(parse_immediate(values[2]), 16)
                )
            else:
                return (
                    "10000100"
                    + opcode
                    + to_binary(int(inst_parts[1][1:]), 4)
                    + "0000"
                    + to_binary(int(inst_parts[2][1:]), 4)
                    + 8 * "0"
                )

        # Add similar validation blocks for other categories...

    except ValueError as e:
        raise ValueError(f"{error_prefix} {str(e)}") from e

    # ... rest of compilation logic
    return opcode


if __name__ == "__main__":
    binary = []
    with open("inst") as file:
        num = 0
        for line in file:
            binary.append(compile_line(line, num))
            num += 1

    with open("binary", "w") as file:
        file.write("\n".join(binary))
