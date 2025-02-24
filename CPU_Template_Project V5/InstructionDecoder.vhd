library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity InstructionDecoder is
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
end InstructionDecoder;

architecture Combinational of InstructionDecoder is
begin
    -- Direct signal extraction from instruction bus
    MMX               <= inst(INST_WIDTH - 1);
    TAlu              <= inst(INST_WIDTH - 2);
    immediate         <= inst(INST_WIDTH - 4 downto INST_WIDTH - 5);
    reg_write_en      <= inst(INST_WIDTH - 6);
    branch_condition  <= inst(INST_WIDTH - 7);
    load_store_enable <= inst(INST_WIDTH - 8);
    OpCode            <= inst(INST_WIDTH - 9 downto INST_WIDTH - 12);
    pc_stack_select   <= inst(INST_WIDTH - 22);

    -- Register addresses
    AddrDest <= inst(INST_WIDTH - 13 downto INST_WIDTH - 15);
    AddrRA   <= inst(INST_WIDTH - 16 downto INST_WIDTH - 18);
    AddrRB   <= inst(INST_WIDTH - 19 downto INST_WIDTH - 21);

    -- Matrix register addresses
    AddrMest <= inst(INST_WIDTH - 13 downto INST_WIDTH - 16);
    AddrMA   <= inst(INST_WIDTH - 17 downto INST_WIDTH - 20);
    AddrMB   <= inst(INST_WIDTH - 21 downto INST_WIDTH - 24);

    -- Pop address
    pop_Addr <= inst(4 downto 0);

end Combinational;