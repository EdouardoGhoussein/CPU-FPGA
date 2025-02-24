library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Predecoder is
    generic (
        INST_WIDTH : integer := 32;
        NOP_INST   : std_logic_vector(31 downto 0) := "00000000111100000000000000000000"
    );
    port (
        clk            : in  std_logic;
        inst           : in  std_logic_vector(INST_WIDTH-1 downto 0);
        data_inst      : in  std_logic_vector(INST_WIDTH-1 downto 0);
        PC_in          : in  std_logic_vector(7 downto 0);
        Z, N, C, V     : in  std_logic;

	LR	       : IN std_logic_vector(15 downto 0);	

        PC_load        : out std_logic;
        PC_out         : out std_logic_vector(7 downto 0);
        counter        : out std_logic_vector(4 downto 0);
        inst_reg       : out std_logic_vector(INST_WIDTH-1 downto 0);
        data_inst_reg  : out std_logic_vector(INST_WIDTH-1 downto 0)
    );
end Predecoder;

architecture Structural of Predecoder is 

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
	
    signal TALu, MMX	     : std_logic;

    signal branch_condition  : std_logic;
    signal OpCode            : std_logic_vector(3 downto 0);
    signal load_store_enable : std_logic;
    signal branch_request    : std_logic;
    signal load_request      : std_logic;
    signal cond1, cond2, cond3      : std_logic;
    signal num_counter       : integer range 0 to 8 := 0;
    signal internal_inst_reg : std_logic_vector(INST_WIDTH-1 downto 0);

    signal sig_PC_load	     : std_logic;

    signal state	     : std_logic;

    signal immediate	     : std_logic_vector(1 downto 0);

begin
    -- InstructionDecoder with unused ports opened
    decoder : InstructionDecoder
        generic map(INST_WIDTH => INST_WIDTH)
        port map(
            inst => inst,
            MMX  => MMX,
            TAlu => TAlu,
            immediate => immediate,
            reg_write_en => open,
            branch_condition => branch_condition,
            load_store_enable => load_store_enable,
            OpCode => OpCode,
            pc_stack_select => open,
            AddrDest => open,
            AddrRA => open,
            AddrRB => open,
            AddrMest => open,
            AddrMA => open,
            AddrMB => open,
            pop_Addr => open
        );

    cond1 <= '1' when branch_request = '1' or load_request = '1' or opcode = "1100" else '0';
    cond2 <= MMX and branch_condition;
    cond3 <= cond2 and TAlu;
    counter <= std_logic_vector(to_unsigned(num_counter, counter'length));

    -- Counter control process
    process(clk)
    begin
	if rising_edge(clk) then
	if num_counter = 0 then
		state <= '0';
		if cond3 then
			num_counter <= 8;
		elsif cond2 then
            		num_counter <= 2;
        	elsif cond1 = '1' then
			state <= '1';
            		num_counter <= 1;
        	else
            		num_counter <= 0;
		end if;
	else
		num_counter <= num_counter - 1;	
        end if;
	end if;
    end process;

    -- Branch control process
    process(branch_condition, opcode, Z,N)
    begin
        if branch_condition = '1' then
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

process(PC_in, inst, branch_request, immediate, LR)
begin
    if branch_request = '1' then
        if immediate(1) = '1' then
            PC_out <= std_logic_vector(resize(signed(LR), PC_out'length));
        else
            PC_out <= std_logic_vector(
                        signed(PC_in) + signed(inst(7 downto 0))
                    );
        end if;
    else
        PC_out <= PC_in;
    end if;
end process;


    sig_PC_load <= (branch_condition and MMX) or cond1;
    --PC_load <= sig_PC_load and PC_load_1;
    PC_load <= '1' when num_counter >= 2 else '0' when num_counter = 1 else sig_pc_load;
    -- Memory control
    load_request <= '1' when (MMX = '0' and OpCode = "0000" and load_store_enable = '1') else '0';

    -- Instruction registration
    process(clk)
    begin
        if rising_edge(clk) then
            --if cond1 = '1' and cond2 = '0' and state = '1' then
            --    internal_inst_reg <= inst;
            if num_counter = 0 then
                internal_inst_reg <= inst;
            else
                internal_inst_reg <= internal_inst_reg;--internal_inst_reg(internal_inst_reg'left downto INST_WIDTH - 6) & '0' 
                                   --& internal_inst_reg(INST_WIDTH - 8 downto 0);
            end if;
            data_inst_reg <= data_inst;
        end if;
    end process;

    inst_reg <= internal_inst_reg;

end Structural;