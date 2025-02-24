library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all; -- For log and ceiling functions

entity Decoder is
  generic (
    INST_WIDTH  : integer := 32;
    NOP_INST    : std_logic_vector(31 downto 0) := (others => '0');
    REG_WIDTH   : integer := 16;
    IMM_WIDTH   : integer := 10
  );
  port (
    clk                      : in  std_logic;
    inst, data_inst          : in  std_logic_vector(INST_WIDTH - 1 downto 0);
    RegA, RegB               : in  std_logic_vector(REG_WIDTH - 1 downto 0);
    Z, N, C, V               : in  std_logic;
    PC_in                    : in  std_logic_vector(7 downto 0);
	 

    wr, PC_load              : out std_logic;
    en_ls, ls                : out std_logic;
    push, pop                : out std_logic;
    pop_Addr                 : out std_logic_vector(4 downto 0);
    AddrDest, AddrRA, AddrRB : out std_logic_vector(2 downto 0);
    SelR                     : out std_logic_vector(3 downto 0);
    PC_out                   : out std_logic_vector(7 downto 0);
	 
	 
	 MRegA1, MRegA2, MRegA3	  : in  std_logic_vector(REG_WIDTH - 1 downto 0);
	 MRegB1, MRegB2, MRegB3	  : in  std_logic_vector(REG_WIDTH - 1 downto 0);
	 
	 
	 A1, A2, A3, B1, B2, B3	  : out std_logic_vector(REG_WIDTH - 1 downto 0);
	 Mwr							  : out std_logic;
	 AddrMA, AddrMB, AddrMest : out std_logic_vector(3 downto 0);
	 column               	  : out std_logic_vector(1 downto 0);
	 
	 TALU_sel, MATMUL_sel			  : out std_logic
	 
  );
end Decoder;

architecture Behavior of Decoder is

  -- Internal signals for storing instruction data and control bits:
  signal instruction_reg    : std_logic_vector(INST_WIDTH - 1 downto 0) := (others => '0');
  signal data_instru_reg	 : std_logic_vector(INST_WIDTH - 1 downto 0) := (others => '0');
  signal nop_hold_counter   	 : integer range 0 to 8 := 0;
  signal nop_hold_counter_next   : integer range 0 to 8 := 0;
  
  -- Control signals extracted from the instruction:
  signal OpCode             : std_logic_vector(3 downto 0);
  signal immediate          : std_logic_vector(1 downto 0);
  signal branch_condition   : std_logic;
  signal load_store_enable  : std_logic;
  signal reg_write_en       : std_logic;
  
  -- Other control signals:
  signal load_request       : std_logic;
  signal branch_request     : std_logic;
  signal pc_stack_select    : std_logic;
  signal push_enable        : std_logic;
  signal pop_enable			 : std_logic;
  
  signal pc_output_buffer   : std_logic_vector(7 downto 0);
  --signal internal_B         : std_logic_vector(REG_WIDTH - 1 downto 0);
  
  signal MMX, sig_wr				 : std_logic;
  signal TAlu					 : std_logic;
  signal sig_AddrMest, sig_AddrMA, sig_AddrMB	:	std_logic_vector(AddrMA'range);

  signal MATMUL			: std_logic;
 begin

  ------------------------------------------------------------------------------
  -- Process 1: NOP Insertion & Instruction Register Update
  ------------------------------------------------------------------------------
    nop_hold_counter_next <= 
    	1 when (branch_request = '1' or load_request = '1' or (pop_enable = '1' and pc_stack_select = '1')) else
	8 when (TAlu = '1' and MMX = '1' and branch_condition = '1') else
    	2 when (branch_condition = '1' and MMX = '1') else
    	(nop_hold_counter - 1) when (nop_hold_counter > 0) else
    	0;

	MATMUL <= '1' when nop_hold_counter_next = 8 else
				 '0' when nop_hold_counter = 0 else
				 MATMUL;
	MATMUL_sel <= MATMUL;
process(clk)
begin
  if rising_edge(clk) then
    nop_hold_counter <= nop_hold_counter_next;
  end if;
end process;

  
  -- Combinational update of the instruction register:
  process(clk)
  begin
     if rising_edge(clk) then
    if nop_hold_counter_next = 0 then
      instruction_reg <= inst;
		data_instru_reg <= data_inst;
    else
	if (branch_request = '1' or load_request = '1' or (pop_enable = '1' and pc_stack_select = '1')) then
      		instruction_reg <= NOP_INST;
	else
		instruction_reg <= instruction_reg(inst'left downto INST_WIDTH - 6) & '0' & instruction_reg(INST_WIDTH - 8 downto 0);
	end if;
    end if;
end if;
  end process;

  ------------------------------------------------------------------------------
  -- Process 2: Control & Address Extraction
  ------------------------------------------------------------------------------
	-- Extract control bits:
	MMX					<= instruction_reg(INST_WIDTH - 1);
	TAlu					<= instruction_reg(INST_WIDTH - 2);
	-- Stack				<= instruction_reg(INST_WIDTH - 3);
	immediate         <= instruction_reg(INST_WIDTH - 4 downto INST_WIDTH - 5);
	reg_write_en      <= instruction_reg(INST_WIDTH - 6);
	branch_condition  <= instruction_reg(INST_WIDTH - 7);
	load_store_enable <= instruction_reg(INST_WIDTH - 8);
	OpCode            <= instruction_reg(INST_WIDTH - 9 downto INST_WIDTH - 12);
	pc_stack_select   <= instruction_reg(INST_WIDTH - 22);

	-- Extract register addresses (3 bits each):
	AddrDest <= instruction_reg(INST_WIDTH - 13 downto INST_WIDTH - 15);
	AddrRA   <= instruction_reg(INST_WIDTH - 16 downto INST_WIDTH - 18);
	AddrRB   <= instruction_reg(INST_WIDTH - 19 downto INST_WIDTH - 21);
	
	-- Extract Matrix register addresses (4 bits each):
	sig_AddrMest <= instruction_reg(INST_WIDTH - 13 downto INST_WIDTH - 16);
	sig_AddrMA   <= instruction_reg(INST_WIDTH - 17 downto INST_WIDTH - 20);
	sig_AddrMB   <= instruction_reg(INST_WIDTH - 21 downto INST_WIDTH - 24);

	-- Extract pop address (5 bits):
	pop_Addr <= instruction_reg(4 downto 0);

  ------------------------------------------------------------------------------
  -- Process 3: Branch Condition Evaluation
  ------------------------------------------------------------------------------
  process(all)
  begin
    if branch_condition = '1' and MMX = '0' then
      case OpCode is
        when "0000" => branch_request <= '1';
        when "0001" => branch_request <= Z;
        when "0010" => branch_request <= not Z;
        when "0011" => branch_request <= N and not Z;
        when "0100" => branch_request <= not N and not Z;
        when "0101" => branch_request <= (N or Z);
        when "0110" => branch_request <= (not N or Z);
        when others => branch_request <= '0';
      end case;
    else
      branch_request <= '0';
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- Process 4: Operand Selection
  ------------------------------------------------------------------------------
process(all)
    variable temp_A : unsigned(REG_WIDTH-1 downto 0);
    variable temp_B : unsigned(REG_WIDTH-1 downto 0);
  begin
    -- Operand A1: Use immediate operand or RegA:
		if MMX = '0' then
			if immediate(0) = '1' then
				temp_A := resize(unsigned(instruction_reg(2*IMM_WIDTH - 1 downto IMM_WIDTH)), REG_WIDTH);
				A1 <= std_logic_vector(temp_A);
			else
				A1 <= RegA;
			end if;

			-- Operand B1: Select between pc value, immediate, or RegB:
			if pc_stack_select='1' and (push_enable='1' or pop_enable='1') then
				temp_B := resize(unsigned(pc_output_buffer), REG_WIDTH);
				B1 <= std_logic_vector(temp_B);
			elsif immediate(1) = '1' then
				if opcode = "0110" then
					temp_B := unsigned(instruction_reg(REG_WIDTH - 1 downto 0));
					B1 <= std_logic_vector(temp_B);
				else
					temp_B := resize(unsigned(instruction_reg(IMM_WIDTH - 1 downto 0)), REG_WIDTH);
					B1 <= std_logic_vector(temp_B);
				end if;
			else
				B1 <= RegB;
			end if;

			
			A2 <= (others => '0');
			A3 <= (others => '0');
			B2 <= (others => '0');
			B3 <= (others => '0');
		else
			A1 <= MRegA1;
			A2 <= MRegA2;
			A3 <= MRegA3;
			
			if immediate(1) = '1' then 
				B1 <= instruction_reg(B1'left downto 0);
				B2 <= data_instru_reg(inst'left downto B2'length);
				B3 <= data_instru_reg(B3'left downto 0);
			else
				B1	<= MRegB1;
				B2 <= MRegB2;
				B3 <= MRegB3;
			end if;
		end if;
end process;

  ------------------------------------------------------------------------------
  -- Process 5: Memory & PC Control Signals
  ------------------------------------------------------------------------------
-- Determine load_request based on OpCode and load_store_enable
load_request <= '1' when (OpCode = "0000" and load_store_enable = '1') else '0';

-- Direct assignments for ls and en_ls
ls    <= load_request;
en_ls <= load_store_enable;

-- Write enables based on reg_write_en and MMX
sig_wr  <= reg_write_en and (not MMX or (MMX and TAlu and not branch_condition)) and not MATMUL;
wr  <= sig_wr;
Mwr <= reg_write_en and not sig_wr when MATMUL = '0' else 
       '1' when MATMUL = '1' and (nop_hold_counter_next = 0 or nop_hold_counter_next = 3 or nop_hold_counter_next = 6)
	else '0';

-- PC_load is '0' when nop_hold_counter is 0, otherwise '1'
PC_load <= '1' when inst(INST_WIDTH - 7) = '1' else '0';

  ------------------------------------------------------------------------------
  -- Process 6: Program Counter (PC) Calculation
  ------------------------------------------------------------------------------
pc_output_buffer <= std_logic_vector(signed(PC_in) + signed(instruction_reg(7 downto 0)))
                      when branch_request = '1' else PC_in;

PC_out <= pc_output_buffer;

  ------------------------------------------------------------------------------
  -- Process 7: Stack Operations & Opcode Routing
  ------------------------------------------------------------------------------

    push_enable <= '1' when (OpCode = "1110") else '0';
	 pop_enable  <= '1' when (OpCode = "1100") else '0';
    push        <= push_enable;
    pop			 <= pop_enable;

    SelR <= OpCode;
  ------------------------------------------------------------------------------
  -- Process 8:  column
  ------------------------------------------------------------------------------
  TAlu_sel		<= TAlu;
  ------------------------------------------------------------------------------
  -- Process 9: AddrMx setting and culomn
  ------------------------------------------------------------------------------
   process(all)
    -- Internal signals to store the output values
    variable v_AddrMA : std_logic_vector(AddrMA'range);
    variable v_AddrMest : std_logic_vector(AddrMest'range);
    variable v_AddrMB : std_logic_vector(AddrMB'range);
begin
    if MATMUL = '0' then
        column <= "11";
        AddrMA <= std_logic_vector(unsigned(sig_AddrMA) + to_unsigned(nop_hold_counter_next, AddrMA'length));
        AddrMB <= std_logic_vector(unsigned(sig_AddrMB) + to_unsigned(nop_hold_counter_next, AddrMA'length));
        AddrMest <= std_logic_vector(unsigned(sig_AddrMest) + to_unsigned(nop_hold_counter_next, AddrMA'length));
    else
        v_AddrMB := sig_AddrMB;
        case nop_hold_counter_next is
            when 0 | 1 | 2 =>
                v_AddrMA := sig_AddrMA;
                v_AddrMest := sig_AddrMest;
            when 3 | 4 | 5 =>
                v_AddrMA := std_logic_vector(unsigned(sig_AddrMA) + 1);
                v_AddrMest := std_logic_vector(unsigned(sig_AddrMest) + 1);
            when 6 | 7 | 8 =>
                v_AddrMA := std_logic_vector(unsigned(sig_AddrMA) + 2);
                v_AddrMest := std_logic_vector(unsigned(sig_AddrMest) + 2);
            when others =>
                v_AddrMA := v_AddrMA;  -- Retain the current value
                v_AddrMest := v_AddrMest;  -- Retain the current value
        end case;

        case nop_hold_counter_next is
            when 0 | 3 | 6 =>
                column <= "00";
            when 1 | 4 | 7 =>
                column <= "01";
            when 2 | 5 | 8 =>
                column <= "10";
            when others =>
                column <= "00";  -- Default case
        end case;

	AddrMA <= v_AddrMA;
    AddrMest <= v_AddrMest;
    AddrMB <= v_AddrMB;
    end if;

    -- Assign the internal signals to the outputs
    
end process;


end Behavior;
