library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TripleALU is
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
end TripleALU;

architecture Behavioral of TripleALU is
    signal sig_R1, sig_R2, sig_R3 : unsigned(DATA_WIDTH-1 downto 0);
	 
	 type reg is array(0 to 2) of std_logic_vector(DATA_WIDTH - 1 downto 0);
	 signal Data_Reg	: reg ;
	 signal counter	: integer range 0 to 2 := 0;

begin
    -- Convert inputs to signed with extended width for overflow detection
    sig_R1 <= unsigned(R1);
    sig_R2 <= unsigned(R2);
    sig_R3 <= unsigned(R3);

    -- Perform arithmetic operations
    process(clk)
	 begin
		if rising_edge(clk) then
			if op_sel = '1' then
				if counter < 2 then
					counter <= counter + 1;
				else
					counter <= 0;
				end if;
			else
				counter <= 0;
			end if;
		end if;
	 end process;

    Data_Reg(counter) <= std_logic_vector(sig_R1 + sig_R2 + sig_R3);


    -- Select results based on operation selection
    Res1 <= Data_Reg(0);
    Res2 <= Data_Reg(1);
    Res3 <= Data_Reg(2);
end Behavioral;