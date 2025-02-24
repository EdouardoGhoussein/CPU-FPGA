library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity DecoderV2 is
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

    LR			     : in std_logic_vector(REG_WIDTH - 1 downto 0);
     
    wr, PC_load              : out std_logic;
    en_ls, ls                : out std_logic;
    push, pop                : out std_logic;
    pop_Addr                 : out std_logic_vector(4 downto 0);
    AddrDest, AddrRA, AddrRB : out std_logic_vector(2 downto 0);
    SelR                     : out std_logic_vector(3 downto 0);
    PC_out                   : out std_logic_vector(7 downto 0);
     
    MRegA1, MRegA2, MRegA3   : in  std_logic_vector(REG_WIDTH - 1 downto 0);
    MRegB1, MRegB2, MRegB3   : in  std_logic_vector(REG_WIDTH - 1 downto 0);
     
    A1, A2, A3, B1, B2, B3  : out std_logic_vector(REG_WIDTH - 1 downto 0);
    Mwr                      : out std_logic;
    AddrMA, AddrMB, AddrMest : out std_logic_vector(3 downto 0);
    column                   : out std_logic_vector(1 downto 0);
     
    TALU_sel, MATMUL_sel     : out std_logic
  );
end DecoderV2;

architecture Structural of DecoderV2 is
    -- Internal connections between pre and post decoder
    signal inst_reg          : std_logic_vector(INST_WIDTH-1 downto 0);
    signal data_inst_reg     : std_logic_vector(INST_WIDTH-1 downto 0);
    signal counter_sig       : std_logic_vector(4 downto 0);
    
    -- Component declarations
    component Predecoder is
        generic (
            INST_WIDTH : integer := 32;
            NOP_INST   : std_logic_vector(31 downto 0)
        );
        port (
            clk           : in  std_logic;
            inst          : in  std_logic_vector(INST_WIDTH-1 downto 0);
            data_inst     : in  std_logic_vector(INST_WIDTH-1 downto 0);
            PC_in         : in  std_logic_vector(7 downto 0);
            Z, N, C, V    : in  std_logic;
            PC_load       : out std_logic;
            PC_out        : out std_logic_vector(7 downto 0);
            counter       : out std_logic_vector(4 downto 0);
            inst_reg      : out std_logic_vector(INST_WIDTH-1 downto 0);
            data_inst_reg : out std_logic_vector(INST_WIDTH-1 downto 0);

            LR		: in std_logic_vector(REG_WIDTH - 1 downto 0)
        );
    end component;

    component PostDecoder is
        generic (
            INST_WIDTH  : integer := 32;
            REG_WIDTH   : integer := 16;
            IMM_WIDTH   : integer := 10
        );
        port (
            clk         : in  std_logic;
            inst        : in  std_logic_vector(INST_WIDTH-1 downto 0);
            data_inst   : in  std_logic_vector(INST_WIDTH-1 downto 0);
            RegA, RegB  : in  std_logic_vector(REG_WIDTH-1 downto 0);
            MRegA1, MRegA2, MRegA3 : in  std_logic_vector(REG_WIDTH-1 downto 0);
            MRegB1, MRegB2, MRegB3 : in  std_logic_vector(REG_WIDTH-1 downto 0);
            counter     : in  std_logic_vector(4 downto 0);

	    PC_in         : in  std_logic_vector(7 downto 0);

            wr          : out std_logic;
            en_ls, ls   : out std_logic;
            push, pop   : out std_logic;
            pop_Addr    : out std_logic_vector(4 downto 0);
            AddrDest    : out std_logic_vector(2 downto 0);
            AddrRA      : out std_logic_vector(2 downto 0);
            AddrRB      : out std_logic_vector(2 downto 0);
            SelR        : out std_logic_vector(3 downto 0);
            A1, A2, A3, B1, B2, B3 : out std_logic_vector(REG_WIDTH-1 downto 0);
            Mwr         : out std_logic;
            AddrMA      : out std_logic_vector(3 downto 0);
            AddrMB      : out std_logic_vector(3 downto 0);
            AddrMest    : out std_logic_vector(3 downto 0);
            column      : out std_logic_vector(1 downto 0);
            TALU_sel    : out std_logic;
            MATMUL_sel  : out std_logic
        );
    end component;

begin
    -- Predecoder Instance
    predecoder_inst: Predecoder
        generic map(
            INST_WIDTH => INST_WIDTH,
            NOP_INST   => NOP_INST
        )
        port map(
            clk           => clk,
            inst          => inst,
            data_inst     => data_inst,
            PC_in         => PC_in,
            Z             => Z,
            N             => N,
            C             => C,
            V             => V,
            PC_load       => PC_load,
            PC_out        => PC_out,
            counter       => counter_sig,
            inst_reg      => inst_reg,
            data_inst_reg => data_inst_reg,

            LR 		  => LR
        );

    -- PostDecoder Instance
    postdecoder_inst: PostDecoder
        generic map(
            INST_WIDTH  => INST_WIDTH,
            REG_WIDTH   => REG_WIDTH,
            IMM_WIDTH   => IMM_WIDTH
        )
        port map(
            clk         => clk,
            inst        => inst_reg,
            data_inst   => data_inst_reg,
            RegA        => RegA,
            RegB        => RegB,
	    PC_in       => PC_in,
            MRegA1      => MRegA1,
            MRegA2      => MRegA2,
            MRegA3      => MRegA3,
            MRegB1      => MRegB1,
            MRegB2      => MRegB2,
            MRegB3      => MRegB3,
            counter     => counter_sig,
            wr          => wr,
            en_ls       => en_ls,
            ls          => ls,
            push        => push,
            pop         => pop,
            pop_Addr    => pop_Addr,
            AddrDest    => AddrDest,
            AddrRA      => AddrRA,
            AddrRB      => AddrRB,
            SelR        => SelR,
            A1          => A1,
            A2          => A2,
            A3          => A3,
            B1          => B1,
            B2          => B2,
            B3          => B3,
            Mwr         => Mwr,
            AddrMA      => AddrMA,
            AddrMB      => AddrMB,
            AddrMest    => AddrMest,
            column      => column,
            TALU_sel    => TALU_sel,
            MATMUL_sel  => MATMUL_sel
        );

end Structural;