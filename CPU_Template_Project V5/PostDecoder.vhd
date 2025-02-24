library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- PostDecoder Component
entity PostDecoder is
    generic (
        INST_WIDTH  : integer := 32;
		  REG_WIDTH   : integer := 16;
		  IMM_WIDTH   : integer := 14
    );
    port (
			clk                : in  std_logic;
			inst               : in  std_logic_vector(INST_WIDTH-1 downto 0);
			data_inst          : in  std_logic_vector(INST_WIDTH-1 downto 0);
			
			RegA, RegB               : in  std_logic_vector(REG_WIDTH - 1 downto 0);

			MRegA1, MRegA2, MRegA3	  : in  std_logic_vector(REG_WIDTH - 1 downto 0);
			MRegB1, MRegB2, MRegB3	  : in  std_logic_vector(REG_WIDTH - 1 downto 0);
			
			counter				 : in std_logic_vector(4 downto 0);

			PC_in				 : in std_logic_vector(7 downto 0);

			wr             	 : out std_logic;
			
			en_ls, ls                : out std_logic;
			push, pop                : out std_logic;
			
			pop_Addr                 : out std_logic_vector(4 downto 0);
			
			AddrDest, AddrRA, AddrRB : out std_logic_vector(2 downto 0);
			
			SelR                     : out std_logic_vector(3 downto 0);


			A1, A2, A3, B1, B2, B3	  	: out std_logic_vector(REG_WIDTH - 1 downto 0);
			Mwr							  	: out std_logic;
			AddrMA, AddrMB, AddrMest 	: out std_logic_vector(3 downto 0);
			column               	  	: out std_logic_vector(1 downto 0);

			TALU_sel, MATMUL_sel			: out std_logic
    );
end PostDecoder;

architecture Structural of PostDecoder is 
	
	component InstructionDecoder is
    generic (
        INST_WIDTH : integer := 32  -- Default 12 (override with actual instruction size)
    );
    port (
        inst                : in  std_logic_vector(INST_WIDTH-1 downto 0);
        MMX                 : out std_logic;
        TAlu                : out std_logic;
        immediate           : out std_logic_vector(1 downto 0);
        reg_write_en        : out std_logic;
        branch_condition    : out std_logic;
        load_store_enable   : out std_logic;
        OpCode              : out std_logic_vector(3 downto 0);
        pc_stack_select     : out std_logic;
        AddrDest            : out std_logic_vector(2 downto 0);
        AddrRA              : out std_logic_vector(2 downto 0);
        AddrRB              : out std_logic_vector(2 downto 0);
        AddrMest            : out std_logic_vector(3 downto 0);
        AddrMA              : out std_logic_vector(3 downto 0);
        AddrMB              : out std_logic_vector(3 downto 0);
        pop_Addr            : out std_logic_vector(4 downto 0)
    );
end component;

	signal MMX                : std_logic;
	signal TAlu               : std_logic;
	signal immediate          : std_logic_vector(1 downto 0);
	signal reg_write_en       : std_logic;
	signal branch_condition   : std_logic;
	signal load_store_enable  : std_logic;
	signal OpCode             : std_logic_vector(3 downto 0);
	signal pc_stack_select    : std_logic;
	signal sig_AddrMest           : std_logic_vector(3 downto 0);
	signal sig_AddrMA             : std_logic_vector(3 downto 0);
	signal sig_AddrMB             : std_logic_vector(3 downto 0);
	
	signal branch_request	  : std_logic;
	signal load_request		  : std_logic;
	
	signal sig_wr				  : std_logic;
	
	signal push_enable, pop_enable	: std_logic;
	
	signal MATMUL, MATMUL_1		  : std_logic;
	
	signal counter_num		  : integer range 0 to 8;
	
	signal buffer_pc_in 		  : std_logic_vector(pc_in'range);
	signal buffer_pc_in2	          : std_logic_vector(pc_in'range);

begin
    -- Instantiate Instruction Decoder
    decoder : InstructionDecoder
        generic map(
            INST_WIDTH => INST_WIDTH
        )
        port map(
            inst => inst,
            MMX  => MMX,
            TAlu => TAlu,
            immediate => immediate,
            reg_write_en => reg_write_en,
            branch_condition => branch_condition,
            load_store_enable => load_store_enable,
            OpCode => OpCode,
            pc_stack_select => pc_stack_select,
            AddrDest => AddrDest,
            AddrRA => AddrRA,
            AddrRB => AddrRB,
            AddrMest => sig_AddrMest,
            AddrMA => sig_AddrMA,
            AddrMB => sig_AddrMB,
            pop_Addr => pop_Addr
        );
		  
		counter_num <= to_integer(unsigned(counter));
		  
		 		-- Direct assignments for ls and en_ls
		load_request <= '1' when (OpCode = "0000" and load_store_enable = '1') else '0';
		ls    <= load_request;
		en_ls <= load_store_enable;
		
		MATMUL <= '1' when counter_num = 8 else
			  '0' when counter_num = 0 else
			  MATMUL;
		     -- Matrix multiplication control signal
		process(clk)
		begin
			if rising_edge(clk) then
				if counter_num = 8 then
					MATMUL_1 <= '1';
				elsif counter_num = 0 then
					MATMUL_1 <= '0';
				end if;
			end if;
		end process;
		MATMUL_sel <= MATMUL_1;
		
		
		 ------------------------------------------------------------------------------
  -- Process 4: Operand Selection
  ------------------------------------------------------------------------------
	process(all)
    variable temp_A : unsigned(REG_WIDTH-1 downto 0);
    variable temp_B : unsigned(REG_WIDTH-1 downto 0);
	begin
    -- Operand A1: Use immediate operand or RegA:
		if MMX = '0' then

			A1 <= RegA;

			if branch_condition then 
				--opcode <= "0110";
				B1 <= X"00" & buffer_PC_in2;
			elsif immediate(1) = '1' then
				if opcode = "0110" then
					temp_B := unsigned(inst(REG_WIDTH - 1 downto 0));
					B1 <= std_logic_vector(temp_B);
				else
					temp_B := resize(unsigned(inst(IMM_WIDTH - 1 downto 0)), REG_WIDTH);
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
				B1 <= inst(B1'left downto 0);
				B2 <= data_inst(inst'left downto B2'length);
				B3 <= data_inst(B3'left downto 0);
			else
				B1	<= MRegB1;
				B2 <= MRegB2;
				B3 <= MRegB3;
			end if;
		end if;
end process;


process(clk)
begin
	if rising_edge(clk) then
		buffer_pc_in <= pc_in;
		buffer_pc_in2 <= buffer_pc_in;
		
		if pop_enable = '0' and opcode = "1100" then
			pop_enable <= '1';
		else
			pop_enable <= '0';
		end if;
		 
	end if;
end process;

-- Write enables based on reg_write_en and MMX
sig_wr  <= reg_write_en and (not MMX or (MMX and TAlu and not branch_condition));
wr  <= sig_wr;
Mwr <= reg_write_en and not sig_wr when MATMUL = '0' else 
       '1' when MATMUL_1 = '1' and (counter_num = 0 or counter_num = 3 or counter_num = 6)
		else '0';
------------------------------------------------------------------------------
  -- Process 7: Stack Operations & Opcode Routing
  ------------------------------------------------------------------------------

    push_enable <= '1' when (OpCode = "1110") else '0';
pop			 <= pop_enable;
    push        <= push_enable;

    SelR <= "0110" when branch_condition = '1' and MMX = '0' else opcode;
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
        v_AddrMA := std_logic_vector(unsigned(sig_AddrMA) + to_unsigned(counter_num, AddrMA'length));
        v_AddrMB := std_logic_vector(unsigned(sig_AddrMB) + to_unsigned(counter_num, AddrMA'length));
        v_AddrMest := std_logic_vector(unsigned(sig_AddrMest) + to_unsigned(counter_num, AddrMA'length));
    else
        v_AddrMB := sig_AddrMB;
        case counter_num is
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

        case counter_num is
            when 0 | 3 | 6 =>
                column <= "00";
            when 1 | 4 | 7 =>
                column <= "01";
            when 2 | 5 | 8 =>
                column <= "10";
            when others =>
                column <= "00";  -- Default case
        end case;
    end if;

    -- Assign the internal signals to the outputs
    AddrMA <= v_AddrMA;
    AddrMest <= v_AddrMest;
    AddrMB <= v_AddrMB;
end process;

end Structural;