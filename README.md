# Instruction Set for RISC Processor

## Version Information

### V5 - The Final Version

The current instruction set architecture (ISA) described in this document corresponds to version V5, which is the final and stable version. The compiler is specifically designed to work with V5, ensuring compatibility and optimal performance. Any previous versions are deprecated and not supported by the compiler. It is crucial to use V5 for all development and deployment activities to ensure proper functionality and support.

## Visualizing Data in RAM and Matrix Register

You can visualize any data stored in RAM and the Matrix register using the switches on the DE10 board. Follow these instructions to access and display the data:

### Accessing RAM Data

1. **Toggle Switch 9 to Up (1)**: This sets the mode to access RAM.
2. **Use Switches 7 to 0**: These switches represent the address lines. Set the address by toggling these switches to the desired address value.

### Accessing Matrix/Vector Register Data

1. **Toggle Switch 9 to Down (0)**: This sets the mode to access the Matrix/Vector register.
2. **Use Switches 3 to 0**: These switches represent the row selection. Set the row by toggling these switches to the desired row number.
3. **Use Switches 5 and 4**: These switches represent the column selection. Set the column by toggling these switches to the desired column number.

By following these steps, you can easily visualize and debug the data stored in RAM and the Matrix/Vector register using the DE10 board switches.

# Improvement Points:

- **Optimize `pc_out`**: Integrate the ALU to perform addition operations, eliminating the need for a separate addition block.

- **Link memory and the matrix register**: Establish a direct connection between memory and the matrix register to improve operation efficiency.

- **Link the matrix register to general-purpose registers**: Ensure a smooth connection between the matrix register and general-purpose registers for easier data transfer.

- **Add more computation functionalities**: Implement operations like scalar-vector multiplication, matrix-scalar multiplication, and matrix-vector multiplication to enhance computational capabilities.

- **Introduce a post-decoder pipeline stage**: Add a pipeline stage after the decoder to improve throughput and system performance.

- **Integrate the vector product in one clock cycle**: If possible, optimize the vector product calculation to occur in a single clock cycle, reducing processing time.

- **Integrate multitasking to utilize the idle ALU**: Optimize processor efficiency by leveraging the unused ALU during idle periods for multitasking operations.

## Deploying Code to FPGA Target

To deploy the compiled code to the FPGA target, follow these steps:

1. **Compile the Instructions**: Ensure that your instruction set is compiled into a binary format.

2. **Run `binaryToROM.py`**: Execute the `binaryToROM.py` script. This script converts the compiled binary instructions into a format suitable for the FPGA ROM.

3. **Copy to Clipboard**: The script automatically copies the formatted code to your clipboard.

4. **Paste into `ROM.vhd`**: Open your `ROM.vhd` file and paste the copied code into the appropriate section.

By following these steps, your code will be ready to run on the FPGA target.

## Register Usage for Vector and Matrix Instructions

### Vector Instructions

For vector instructions, you need to use vector registers denoted by `V`. These registers range from `V0` to `V15`. For example, to add two vectors, you would use:

```
VADD V1, V2, V3
```

### Matrix Instructions

For matrix instructions, you need to use matrix registers denoted by `M`. These registers range from `M0` to `M4`. For example, to add two matrices, you would use:

```
MADD M1, M2, M3
```

### Special Case: VDOT Instruction

For the `VDOT` instruction, the destination is a general-purpose register, not a vector register. Therefore, you should use `R` registers for the destination. For example, to perform a dot product of two vectors and store the result in a general-purpose register, you would use:

```
VDOT R0, V1, V2
```

## Operand Definitions

- **`d` (Destination Register):** The register where the result of the operation is stored.
- **`s` (Source Register 1):** The first operand for the operation.
- **`t` (Source Register 2):** The second operand for the operation (if applicable).
- **`Imm` (Immediate Value):** A constant value provided directly in the instruction.
- **`Addr` (Memory Address):** A memory location used for load/store instructions.

---

## 1. R-Type (Register-Register Instructions)

| **MMX** | **TAlu** | **Stack** | **Immediate (BA)** | **Write** | **Branch** | **Load/Store** | **Opcode** | **Rdest (`d`)** | **Rsource 1 (`s`)** | **Rsource 2 (`t`)** | **Mnemonic** | **Function**       |
| ------- | -------- | --------- | ------------------ | --------- | ---------- | -------------- | ---------- | --------------- | ------------------- | ------------------- | ------------ | ------------------ |
| `0`     | `0`      | `0`       | `00`               | `1`       | `0`        | `0`            | `0000`     | `Rd`            | `Rs`                | `Rt`                | `ADD`        | `Rd = Rs + Rt`     |
| `0`     | `0`      | `0`       | `00`               | `1`       | `0`        | `0`            | `0001`     | `Rd`            | `Rs`                | `Rt`                | `SUB`        | `Rd = Rs - Rt`     |
| `0`     | `0`      | `0`       | `00`               | `1`       | `0`        | `0`            | `0010`     | `Rd`            | `Rs`                | `Rt`                | `MUL`        | `Rd = Rs * Rt`     |
| `0`     | `0`      | `0`       | `00`               | `1`       | `0`        | `0`            | `0011`     | `Rd`            | `Rs`                | `Rt`                | `AND`        | `Rd = Rs & Rt`     |
| `0`     | `0`      | `0`       | `00`               | `1`       | `0`        | `0`            | `0100`     | `Rd`            | `Rs`                | `Rt`                | `OR`         | `Rd = Rs \| Rt`    |
| `0`     | `0`      | `0`       | `00`               | `1`       | `0`        | `0`            | `0101`     | `Rd`            | `Rs`                | `Rt`                | `XOR`        | `Rd = Rs ^ Rt`     |
| `0`     | `0`      | `0`       | `10`               | `1`       | `0`        | `0`            | `0110`     | `Rd`            | `---`               | `Imm`               | `MOV`        | `Rd = Imm`         |
| `0`     | `0`      | `0`       | `10`               | `0`       | `0`        | `0`            | `0111`     | `Rd`            | `Rs`                | `---`               | `NOT`        | `Rd = ~Rs`         |
| `0`     | `0`      | `0`       | `00`               | `1`       | `0`        | `0`            | `1000`     | `Rd`            | `Rs`                | `Imm`               | `LSL`        | `Rd = Rs << Imm`   |
| `0`     | `0`      | `0`       | `00`               | `1`       | `0`        | `0`            | `1009`     | `Rd`            | `Rs`                | `Imm`               | `LSR`        | `Rd = Rs >> Imm`   |
| `0`     | `0`      | `0`       | `00`               | `0`       | `0`        | `0`            | `0001`     | `NONE`          | `Rs`                | `Rt`                | `CMP`        | `Rs - Rt NO STORE` |

---

## 2. Memory Access (Load/Store Instructions)

| **MMX** | **TAlu** | **Stack** | **Immediate (BA)** | **Write** | **Branch** | **Load/Store** | **Opcode** | **Rdest (`d`)** | **Address (`Addr`)** | **Immediate (`Imm`)** | **Mnemonic** | **Function**     |
| ------- | -------- | --------- | ------------------ | --------- | ---------- | -------------- | ---------- | --------------- | -------------------- | --------------------- | ------------ | ---------------- |
| `0`     | `0`      | `0`       | `11`               | `0`       | `0`        | `1`            | `0000`     | `Rd`            | `Addr`               | `---`                 | `LD`         | `Rd = Mem[Addr]` |
| `0`     | `0`      | `0`       | `11`               | `0`       | `0`        | `1`            | `1111`     | `---`           | `Rs`                 | `Addr`                | `ST`         | `Mem[Addr] = Rs` |

---

## 3. Stack Operations (Push/Pop)

| **MMX** | **TAlu** | **Stack** | **Immediate (BA)** | **Write** | **Branch** | **Load/Store** | **Opcode** | **Rsource/Dest (`d`)** | **SP** | **Immediate (`Imm`)** | **Mnemonic** | **Function**           |
| ------- | -------- | --------- | ------------------ | --------- | ---------- | -------------- | ---------- | ---------------------- | ------ | --------------------- | ------------ | ---------------------- |
| `0`     | `0`      | `0`       | `11`               | `0`       | `0`        | `0`            | `1110`     | `Rs`                   | `SP`   | `---`                 | `PUSH`       | `Stack[SP] = Rs; SP--` |
| `0`     | `0`      | `0`       | `00`               | `1`       | `0`        | `0`            | `1100`     | `Rd`                   | `SP`   | `---`                 | `POP`        | `SP++; Rs = Stack[SP]` |

---

## 4. Branching Instructions

| **MMX** | **TAlu** | **Stack** | **Immediate (BA)** | **Write** | **Branch** | **Load/Store** | **Opcode** | **Offset (`Imm`)** | **Mnemonic** | **Function**                  |
| ------- | -------- | --------- | ------------------ | --------- | ---------- | -------------- | ---------- | ------------------ | ------------ | ----------------------------- |
| `0`     | `0`      | `0`       | `00`               | `0`       | `1`        | `0`            | `0000`     | `Imm`              | `B`          | `Unconditional branch`        |
| `0`     | `0`      | `0`       | `00`               | `0`       | `1`        | `0`            | `0001`     | `Imm`              | `BEQ`        | `if (Rs == Rt) offset += Imm` |
| `0`     | `0`      | `0`       | `00`               | `0`       | `1`        | `0`            | `0010`     | `Imm`              | `BNE`        | `if (Rs != Rt) offset += Imm` |
| `0`     | `0`      | `0`       | `00`               | `0`       | `1`        | `0`            | `0011`     | `Imm`              | `BLT`        | `if (Rs < Rt) offset += Imm`  |
| `0`     | `0`      | `0`       | `00`               | `0`       | `1`        | `0`            | `0100`     | `Imm`              | `BGT`        | `if (Rs > Rt) offset += Imm`  |
| `0`     | `0`      | `0`       | `00`               | `0`       | `1`        | `0`            | `0101`     | `Imm`              | `BLE`        | `if (Rs <= Rt) offset += Imm` |
| `0`     | `0`      | `0`       | `00`               | `0`       | `1`        | `0`            | `0110`     | `Imm`              | `BGE`        | `if (Rs >= Rt) offset += Imm` |

---

## 4.1 Branch with Link Instructions

| **MMX** | **TAlu** | **Stack** | **Immediate (BA)** | **Write** | **Branch** | **Load/Store** | **Opcode** | **Offset (`Imm`)** | **Mnemonic** | **Function**                    |
| ------- | -------- | --------- | ------------------ | --------- | ---------- | -------------- | ---------- | ------------------ | ------------ | ------------------------------- |
| `0`     | `0`      | `0`       | `00`               | `1`       | `1`        | `0`            | `0000`     | `Imm`              | `BL`         | `Link and branch`               |
| `0`     | `0`      | `0`       | `00`               | `1`       | `1`        | `0`            | `0001`     | `Imm`              | `BLEQ`       | `if (Rs == Rt) link and branch` |
| `0`     | `0`      | `0`       | `00`               | `1`       | `1`        | `0`            | `0010`     | `Imm`              | `BLNE`       | `if (Rs != Rt) link and branch` |
| `0`     | `0`      | `0`       | `00`               | `1`       | `1`        | `0`            | `0011`     | `Imm`              | `BLLT`       | `if (Rs < Rt) link and branch`  |
| `0`     | `0`      | `0`       | `00`               | `1`       | `1`        | `0`            | `0100`     | `Imm`              | `BLGT`       | `if (Rs > Rt) link and branch`  |
| `0`     | `0`      | `0`       | `00`               | `1`       | `1`        | `0`            | `0101`     | `Imm`              | `BLLE`       | `if (Rs <= Rt) link and branch` |
| `0`     | `0`      | `0`       | `00`               | `1`       | `1`        | `0`            | `0110`     | `Imm`              | `BLGE`       | `if (Rs >= Rt) link and branch` |

---

## 4.2 Branch and Return Instructions

| **MMX** | **TAlu** | **Stack** | **Immediate (BA)** | **Write** | **Branch** | **Load/Store** | **Opcode** | **Offset (`Imm`)** | **Mnemonic** | **Function**                      |
| ------- | -------- | --------- | ------------------ | --------- | ---------- | -------------- | ---------- | ------------------ | ------------ | --------------------------------- |
| `0`     | `0`      | `0`       | `10`               | `0`       | `1`        | `0`            | `0000`     | `Imm`              | `BX`         | `Branch and return`               |
| `0`     | `0`      | `0`       | `10`               | `0`       | `1`        | `0`            | `0001`     | `Imm`              | `BXEQ`       | `if (Rs == Rt) branch and return` |
| `0`     | `0`      | `0`       | `10`               | `0`       | `1`        | `0`            | `0010`     | `Imm`              | `BXNE`       | `if (Rs != Rt) branch and return` |
| `0`     | `0`      | `0`       | `10`               | `0`       | `1`        | `0`            | `0011`     | `Imm`              | `BXLT`       | `if (Rs < Rt) branch and return`  |
| `0`     | `0`      | `0`       | `10`               | `0`       | `1`        | `0`            | `0100`     | `Imm`              | `BXGT`       | `if (Rs > Rt) branch and return`  |
| `0`     | `0`      | `0`       | `10`               | `0`       | `1`        | `0`            | `0101`     | `Imm`              | `BXLE`       | `if (Rs <= Rt) branch and return` |
| `0`     | `0`      | `0`       | `10`               | `0`       | `1`        | `0`            | `0110`     | `Imm`              | `BXGE`       | `if (Rs >= Rt) branch and return` |

---

## 5. Special Instructions

| **MMX** | **TAlu** | **Stack** | **Immediate (B)** | **Write** | **Branch** | **Load/Store** | **Opcode** | **Rdest (`d`)** | **Rsource (`s`)** | **Immediate (`Imm`)** | **Mnemonic** | **Function**  |
| ------- | -------- | --------- | ----------------- | --------- | ---------- | -------------- | ---------- | --------------- | ----------------- | --------------------- | ------------ | ------------- |
| `0`     | `0`      | `0`       | `00`              | `0`       | `0`        | `0`            | `1111`     | `---`           | `---`             | `---`                 | `NOP`        | No operation. |

---

## 6. Status Flags

The status flags represent the state of the processor after executing an instruction. These flags are updated based on the result of operations and are used for conditional branching and other operations.

| **Flag** | **Mnemonic** | **Description**                                                                                                                                     |
| -------- | ------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Z`      | Zero         | Set to `1` if the result of the operation is zero, otherwise set to `0`. Used to check if a result is zero.                                         |
| `N`      | Negative     | Set to `1` if the result of the operation is negative (i.e., the most significant bit of the result is `1`), otherwise set to `0`.                  |
| `C`      | Carry        | Set to `1` if the operation resulted in a carry out of the most significant bit or if a borrow occurred in a subtraction. Otherwise, set to `0`.    |
| `V`      | Overflow     | Set to `1` if the operation resulted in an overflow (for example, an addition that exceeds the maximum representable value). Otherwise, set to `0`. |

---

### Flag Update Rules

- **Zero (Z):** Set when the result of an operation is zero.
- **Negative (N):** Set if the result of an operation is negative.
- **Carry (C):** Set during an addition or subtraction that generates a carry or borrow.
- **Overflow (V):** Set if the result of an operation causes a signed overflow.

---

### Usage in Instructions

- **Arithmetic Operations:** The `Z`, `N`, and `C` flags are updated after arithmetic operations (like addition, subtraction, multiplication) based on the result.
- **Branching Instructions:** The `Z` and `N` flags are commonly used in conditional branch instructions to make decisions based on zero or negative results.

Example:

- After executing `ADD R1, R2, R3`, the processor will check the result stored in `R1` and update the `Z`, `N`, and `C` flags based on the outcome.

## 7. MMX Instructions

### Register File for Vectors and Matrices

The processor has a dedicated register file for vector and matrix operations. This register file is shared between vectors and matrices, which requires careful management to avoid conflicts. The compiler differentiates between vector and matrix registers in assembly by using distinct identifiers (e.g., `Vx` for vectors and `Mx` for matrices). It ensures that the register addresses are set correctly to prevent overlap. For example, if `addr_V1` and `addr_V2` are used for vectors, `addr_M2` might correspond to `addr_V7` to avoid conflicts with matrix operations.

### Vector Operations

| **MMX** | **TAlu** | **Stack** | **Immediate (BA)** | **Write** | **Branch** | **Load/Store** | **Opcode** | **Rdest (`d`)** | **Rsource 1 (`s`)** | **Rsource 2 (`t`)** | **Mnemonic** | **Function**                |
| ------- | -------- | --------- | ------------------ | --------- | ---------- | -------------- | ---------- | --------------- | ------------------- | ------------------- | ------------ | --------------------------- |
| `1`     | `0`      | `0`       | `00`               | `1`       | `0`        | `0`            | `0000`     | `Rd`            | `Rs`                | `Rt`                | `VADD`       | `Rd = Rs + Rt (vector)`     |
| `1`     | `0`      | `0`       | `00`               | `1`       | `0`        | `0`            | `0001`     | `Rd`            | `Rs`                | `Rt`                | `VSUB`       | `Rd = Rs - Rt (vector)`     |
| `1`     | `0`      | `0`       | `00`               | `1`       | `0`        | `0`            | `0010`     | `Rd`            | `Rs`                | `Rt`                | `VMUL`       | `Rd = Rs * Rt (vector)`     |
| `1`     | `0`      | `0`       | `00`               | `1`       | `0`        | `0`            | `0011`     | `Rd`            | `Rs`                | `Rt`                | `VAND`       | `Rd = Rs & Rt (vector)`     |
| `1`     | `0`      | `0`       | `00`               | `1`       | `0`        | `0`            | `0100`     | `Rd`            | `Rs`                | `Rt`                | `VOR`        | `Rd = Rs \| Rt (vector)`    |
| `1`     | `0`      | `0`       | `00`               | `1`       | `0`        | `0`            | `0101`     | `Rd`            | `Rs`                | `Rt`                | `VXOR`       | `Rd = Rs ^ Rt (vector)`     |
| `1`     | `0`      | `0`       | `10`               | `0`       | `0`        | `0`            | `0111`     | `Rd`            | `Rs`                | `---`               | `VNOT`       | `Rd = ~Rs (vector)`         |
| `1`     | `0`      | `0`       | `00`               | `1`       | `0`        | `0`            | `1000`     | `Rd`            | `Rs`                | `Imm`               | `VLSL`       | `Rd = Rs << Imm (vector)`   |
| `1`     | `0`      | `0`       | `00`               | `1`       | `0`        | `0`            | `1009`     | `Rd`            | `Rs`                | `Imm`               | `VLSR`       | `Rd = Rs >> Imm (vector)`   |
| `1`     | `0`      | `0`       | `00`               | `0`       | `0`        | `0`            | `0001`     | `NONE`          | `Rs`                | `Rt`                | `VCMP`       | `Rs - Rt NO STORE (vector)` |

### Matrix Operations

### Matrix Operations

| **MMX** | **TAlu** | **Stack** | **Immediate (BA)** | **Write** | **Matrix** | **Load/Store** | **Opcode** | **Rdest (`d`)** | **Rsource 1 (`s`)** | **Rsource 2 (`t`)** | **Mnemonic** | **Function**              |
| ------- | -------- | --------- | ------------------ | --------- | ---------- | -------------- | ---------- | --------------- | ------------------- | ------------------- | ------------ | ------------------------- |
| `1`     | `0`      | `0`       | `00`               | `1`       | `0`        | `0`            | `0000`     | `Rd`            | `Rs`                | `Rt`                | `MADD`       | `Rd = Rs + Rt (matrix)`   |
| `1`     | `0`      | `0`       | `00`               | `1`       | `0`        | `0`            | `0001`     | `Rd`            | `Rs`                | `Rt`                | `MSUB`       | `Rd = Rs - Rt (matrix)`   |
| `1`     | `0`      | `0`       | `00`               | `1`       | `0`        | `0`            | `0010`     | `Rd`            | `Rs`                | `Rt`                | `MMUL`       | `Rd = matmul(Rs, Rt)`     |
| `1`     | `0`      | `0`       | `00`               | `1`       | `0`        | `0`            | `0011`     | `Rd`            | `Rs`                | `Rt`                | `MAND`       | `Rd = Rs & Rt (matrix)`   |
| `1`     | `0`      | `0`       | `00`               | `1`       | `0`        | `0`            | `0100`     | `Rd`            | `Rs`                | `Rt`                | `MOR`        | `Rd = Rs \| Rt (matrix)`  |
| `1`     | `0`      | `0`       | `00`               | `1`       | `0`        | `0`            | `0101`     | `Rd`            | `Rs`                | `Rt`                | `MXOR`       | `Rd = Rs ^ Rt (matrix)`   |
| `1`     | `0`      | `0`       | `10`               | `0`       | `0`        | `0`            | `0111`     | `Rd`            | `Rs`                | `---`               | `MNOT`       | `Rd = ~Rs (matrix)`       |
| `1`     | `0`      | `0`       | `00`               | `1`       | `0`        | `0`            | `1000`     | `Rd`            | `Rs`                | `Imm`               | `MLSL`       | `Rd = Rs << Imm (matrix)` |
| `1`     | `0`      | `0`       | `00`               | `1`       | `0`        | `0`            | `1009`     | `Rd`            | `Rs`                | `Imm`               | `MLSR`       | `Rd = Rs >> Imm (matrix)` |

### Move and Conversion Operations

| **MMX** | **TAlu** | **Stack** | **Immediate (BA)** | **Write** | **Matrix** | **Load/Store** | **Opcode** | **Rdest (`d`)** | **Rsource (`s`)** | **Immediate (`Imm`)** | **Mnemonic** | **Function**          |
| ------- | -------- | --------- | ------------------ | --------- | ---------- | -------------- | ---------- | --------------- | ----------------- | --------------------- | ------------ | --------------------- |
| `1`     | `0`      | `0`       | `10`               | `1`       | `0`        | `0`            | `0110`     | `Rd`            | `---`             | `Imm`                 | `VMOV`       | `Rd = Imm (vector)`   |
| `1`     | `1`      | `0`       | `00`               | `1`       | `0`        | `0`            | `0010`     | `Rd`            | `Rs`              | `Rt`                  | `VDOT`       | `Rd = dot(Rs, Rt)`    |
| `1`     | `1`      | `0`       | `00`               | `1`       | `1`        | `0`            | `0010`     | `Rd`            | `Rs`              | `Rt`                  | `MATMUL`     | `Rd = matmul(Rs, Rt)` |

## Have Fun!

Enjoy working with the RISC processor and exploring its capabilities. Remember, the best way to learn is by doing, so dive in, experiment, and have fun with me projects. Happy coding!
