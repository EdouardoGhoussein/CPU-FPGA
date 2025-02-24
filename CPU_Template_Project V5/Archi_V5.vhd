library ieee;
  use ieee.std_logic_1164.all;
  use ieee.math_real.all; -- For log and ceiling functions
library work;

entity Archi_V5 is
  port (
    clk, rst : in std_logic;
    en       : in std_logic;
	 
	 row				 : in std_logic_vector(3 downto 0);
	 col				 : in std_logic_vector(1 downto 0);
	 output			 : out std_logic_vector(15 DOWNTO 0);
	 
	 AddrUsr	:	in std_logic_vector(7 downto 0);
	 hex_out  :  out std_logic_vector(15 downto 0)
  );
end entity;

architecture Behavior of Archi_V5 is

  -- Shared constant for instruction width
  constant INST_WIDTH  : integer                                   := 32;                          -- Set instruction width to 22 bits
  constant NOP_INST    : std_logic_vector(INST_WIDTH - 1 downto 0) := "00000000111100000000000000000000"; -- NOP instruction (22 bits)
  constant STACK_DEPTH : integer                                   := 32;                          -- Number of elements in the stack

  component ALU
    generic (
		REG_WIDTH : integer := 16 -- Default data width is 20 bits
	 );
    port (
        clk, en   : in  std_logic;
        SelR : in  std_logic_vector(3 downto 0);
        A, B : in  std_logic_vector(REG_WIDTH-1 downto 0);
        R    : out std_logic_vector(REG_WIDTH-1 downto 0);
        Z, N, C, V : out std_logic
    );
  end component;

  component Reg
    generic (
		REG_WIDTH : integer := 16 -- Default data width is 20 bits
	 );
	port(
			clk, wr							:	in std_logic;
			rst								:	in std_logic;
			AddrRA, AddrRB, AddrDest	:	in std_logic_vector(2 downto 0);
			R									:	in std_logic_vector(REG_WIDTH - 1 downto 0);
			outA, outB						:	out std_logic_vector(REG_WIDTH - 1 downto 0);
			LR				:	out std_logic_vector(REG_WIDTH - 1 downto 0)
			);
  end component;

  component DecoderV2
		generic (
			INST_WIDTH  : integer := 32;
			NOP_INST    : std_logic_vector(31 downto 0) := NOP_INST;
			REG_WIDTH   : integer := 16;
			IMM_WIDTH   : integer := 14
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

			LR		: in std_logic_vector(REG_WIDTH - 1 downto 0);


			MRegA1, MRegA2, MRegA3	  : in  std_logic_vector(REG_WIDTH - 1 downto 0);
			MRegB1, MRegB2, MRegB3	  : in  std_logic_vector(REG_WIDTH - 1 downto 0);


			A1, A2, A3, B1, B2, B3	  : out std_logic_vector(REG_WIDTH - 1 downto 0);
			Mwr							  : out std_logic;
			AddrMA, AddrMB, AddrMest  : out std_logic_vector(3 downto 0);
			column               	  : out std_logic_vector(1 downto 0);

			TALU_sel, MATMUL_Sel	  : out std_logic
		);
  end component;

  component Fetch
    port (
      en      : in  std_logic;
      clk     : in  std_logic;
      rst     : in  std_logic;
		
		skip	  :	in std_logic;
		
      PC_load : in  std_logic;
      PC_Jump : in  std_logic_vector(7 downto 0);
      PC_out  : out std_logic_vector(7 downto 0)
    );
  end component;

  component ROM
    generic (
      DATA_WIDTH : integer := INST_WIDTH -- Default data width for ROM is 23 bits
    );
    port (
      en       	: in  std_logic;
      clk      	: in  std_logic;
      rst      	: in  std_logic;
      Adress   	: in  std_logic_vector(7 downto 0);
      Data_out1	: out std_logic_vector(DATA_WIDTH - 1 downto 0);
		Data_out2	: out std_logic_vector(DATA_WIDTH - 1 downto 0);

    skip	: out std_logic
    );
  end component;

  component ram
    generic (
		DATA_WIDTH : integer := 16 -- Default data width is 20 bits
	 );
	port(
			rw,en		:	in std_logic;
			clk		:	in std_logic;
			rst		:	in std_logic;
			Adress	:	in std_logic_vector(7 downto 0);
			Data_in	:	in std_logic_vector(DATA_WIDTH - 1 downto 0);
			Data_out	:	out std_logic_vector(DATA_WIDTH - 1 downto 0);
			
			AddrUsr	:	in std_logic_vector(7 downto 0);
			hex_out  :  out std_logic_vector(DATA_WIDTH - 1 downto 0)
			);
  end component;

  component Stack
    generic (
      STACK_DEPTH : integer := STACK_DEPTH; -- Number of elements in the stack
      DATA_WIDTH  : integer := 16            -- Width of each stack element
    );
    port (
      clk         : in  STD_LOGIC;                                 -- Clock signal
      reset       : in  STD_LOGIC;                                 -- Reset signal
      push        : in  STD_LOGIC;                                 -- Push control signal
      pop         : in  STD_LOGIC;                                 -- Pop control signal
      pop_Addr    : in  STD_LOGIC_VECTOR(4 downto 0);
      write_data  : in  STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0); -- Data to push onto the stack
      read_data   : out STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0); -- Data popped from the stack	
      full, empty : out STD_LOGIC                                  -- Flag indicating the stack is full
    );
  end component;
  
  component Meg
    generic (
        REG_WIDTH : integer := 16 -- Default data width is 48 bits
    );
    port(
        clk, wr              		: in  std_logic;
        rst                  		: in  std_logic;
        AddrMA, AddrMB, AddrDest : in  std_logic_vector(3 downto 0);
        R1, R2, R3          		: in  std_logic_vector(REG_WIDTH - 1 downto 0);
        
        column               : in  std_logic_vector(1 downto 0);
        
        outA1, outA2, outA3 : out std_logic_vector(REG_WIDTH - 1 downto 0);
        outB1, outB2, outB3 : out std_logic_vector(REG_WIDTH - 1 downto 0);
		  
		  row				 : in std_logic_vector(3 downto 0);
		  col				 : in std_logic_vector(1 downto 0);
		  output			 : out std_logic_vector(REG_WIDTH -1 DOWNTO 0)
    );
	end component;
	
	component TripleALU
    generic (
        DATA_WIDTH : integer := 16  -- Configurable data width
    );
    port (
		  clk			 : in std_logic;
        -- Input operands
        R1, R2, R3 : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        
        -- Control signal (1: Addition, 0: nothing)
        op_sel     : in  std_logic;
        
        -- Results
        Res1, Res2, Res3 : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
	end component;

  signal Selector                          : std_logic_vector(3 downto 0);
  signal enA1, enA2, enA3 						 : std_logic_vector(15 downto 0); 
  signal enB1, enB2, enB3						 : std_logic_vector(15 downto 0);

  signal ALU_R1, ALU_R2, ALU_R3            : std_logic_vector(15 downto 0);
  signal f_Z, f_N, f_C, f_V                : std_logic;
  signal Reg_wr                            : std_logic;
  signal AddrRA_en, AddrRB_en, AddrDest_en : std_logic_vector(2 downto 0);
  signal Reg_outA, Reg_outB                : std_logic_vector(15 downto 0);
  signal PC_load                           : std_logic;
  signal PC_Jump, PC_out                   : std_logic_vector(7 downto 0);
  signal inst, data_inst                   : std_logic_vector(INST_WIDTH - 1 downto 0);
  signal en_ls, ls_wr                      : std_logic;
  signal mem_data                          : std_logic_vector(15 downto 0);

  signal REG_DATA_IN               : std_logic_vector(15 downto 0);
  signal SelIn                     : std_logic;
  signal Reg_write                 : std_logic;
  signal AddrDest_dl, REG_AddrDest : std_logic_vector(2 downto 0);

  signal push, pop : std_logic;
  signal pop_Addr  : std_logic_vector(4 downto 0);
  signal stack_out : std_logic_vector(15 downto 0);
  
  
  signal skip, Mwr, TALU_sel	: std_logic;
  signal column					: std_logic_vector(1 downto 0);
  
  signal MRegA1, MRegA2, MRegA3	:	std_logic_vector(15 downto 0);
  signal MRegB1, MRegB2, MRegB3	:	std_logic_vector(15 downto 0);
  
  signal inMR1, inMR2, inMR3	:	std_logic_vector(15 downto 0);

  signal AddrMA, AddrMB, AddrMest	:	std_logic_vector(3 downto 0);


  signal TRes1, TRes2, TRes3		:	std_logic_vector(15 downto 0);
  signal MATMUL_Sel			: 	std_logic;

   signal LR				:	std_logic_vector(15 downto 0);

begin
  REG_DATA_IN  <= TRes1 when TAlu_sel = '1' 
		  else stack_out when pop = '1'
		  else ALU_R1 when ls_wr = '0'
		  else mem_data;

  Reg_write    <= Reg_wr;
  REG_AddrDest <= AddrDest_en;-- when SelIn = '1' else AddrDest_en;

  ALU1: ALU
    port map (
      clk  => clk,
      en   => en,
      SelR => Selector,
      A    => enA1,
      B    => enB1,
      R    => ALU_R1,
      Z    => f_Z,
      N    => f_N,
      C    => f_C,
      V    => f_V
    );
	 
  ALU2: ALU
    port map (
      clk  => clk,
      en   => en,
      SelR => Selector,
      A    => enA2,
      B    => enB2,
      R    => ALU_R2,
      Z    => open,
      N    => open,
      C    => open,
      V    => open
    );
	 
  ALU3: ALU
    port map (
      clk  => clk,
      en   => en,
      SelR => Selector,
      A    => enA3,
      B    => enB3,
      R    => ALU_R3,
      Z    => open,
      N    => open,
      C    => open,
      V    => open
    );

  REG1: Reg
    port map (
      clk      => clk,
      rst      => rst,
      wr       => Reg_write,
      AddrRA   => AddrRA_en,
      AddrRB   => AddrRB_en,
      AddrDest => REG_AddrDest,
      R        => REG_DATA_IN,
      outA     => Reg_outA,
      outB     => Reg_outB,
      LR       => LR
    );

  DEC: DecoderV2
    port map (
      clk      => clk,
      inst     => inst,
      RegA     => Reg_outA,
      RegB     => Reg_outB,
      Z        => f_Z,
      N        => f_N,
      C        => f_C,
      V        => f_V,
      wr       => Reg_wr,
      PC_load  => PC_load,
      AddrDest => AddrDest_en,
      AddrRA   => AddrRA_en,
      AddrRB   => AddrRB_en,
      SelR     => Selector,
      A1       => enA1,
      B1       => enB1,
      PC_in    => PC_out,
      PC_out   => PC_Jump,
      en_ls    => en_ls,
      ls       => ls_wr,
      push     => push,
      pop      => pop,
      pop_Addr => pop_Addr,

      LR 	=> LR,
		A2			=> enA2,
		A3			=> enA3,
		B2			=> enB2,
		B3			=> enB3,
		Mwr		=> Mwr,
		
		AddrMA	=> AddrMA,
		AddrMB	=> AddrMB,
		AddrMest	=> AddrMest,
		
		MRegA1	=> MRegA1,
		MRegA2	=> MRegA2,
		MRegA3	=> MRegA3,
		
		MRegB1	=> MRegB1,
		MRegB2	=> MRegB2,
		MRegB3	=> MRegB3,
		
		TALU_sel	=> TALU_sel,
		
		column		=> column,

		data_inst => data_inst,

		MATMUL_Sel => MATMUL_Sel
    );

  FET: Fetch
    port map (
      clk     => clk,
      en      => en,
      rst     => rst,
      PC_load => PC_load,
      PC_Jump => PC_Jump,
      PC_out  => PC_out,
		
		skip	  => skip
    );

  ROM1: ROM
    port map (
      clk      	=> clk,
      en       	=> en,
      rst      	=> rst,
      Adress   	=> PC_out,
      Data_out1	=> inst,
		Data_out2	=> data_inst,
	skip  => skip
    );

  RAM1: RAM
    port map (
      rw       => ls_wr,
      en       => en_ls,
      clk      => clk,
      rst      => rst,
      Adress   => enB1(7 downto 0),
      Data_in  => enA1,
      Data_out => mem_data,
		
		AddrUsr  => AddrUsr,
		hex_out	=> hex_out
    );

  STA: Stack
    port map (
      clk        => clk,
      reset      => rst,
      push       => push,
      pop        => pop,
      pop_Addr   => pop_Addr,
      write_data => enB1,
      read_data  => stack_out,
      full       => open,
      empty      => open
    );


  inMR1 <= ALU_R1 when MATMUL_Sel = '0' else TRes3;
  inMR2 <= ALU_R2 when MATMUL_Sel = '0' else TRes2;
  inMR3 <= ALU_R3 when MATMUL_Sel = '0' else TRes1;

  MEG1: MEG
	port map(
        clk 	=> clk, 
		  wr  	=> Mwr,
        rst 	=> rst,
		  
        AddrMA		=> AddrMA,
		  AddrMB		=> AddrMB,
		  AddrDest	=> AddrMest,
		  
        R1	=> inMR1,
		  R2	=> inMR2,
		  R3	=> inMR3,
        
        column	=> column,
        
        outA1	=> MRegA1,
		  outA2	=> MRegA2,
		  outA3	=> MRegA3,
        
		  outB1	=> MRegB1,
		  outB2	=> MRegB2,
		  outB3	=> MRegB3,
		  
		  row		=> row,
		  col		=> col,
		  output	=> output
   );
	
  TALU: TripleALU
	port map (
		  clk		=>	clk,
        R1		=> ALU_R1,
		  R2		=> ALU_R2,
		  R3		=> ALU_R3,
        
        op_sel	=> TALU_sel,
		  
        Res1	=> TRes1,
		  Res2	=> TRes2,
		  Res3 	=> TRes3
   );

end architecture;

