library ieee;
use IEEE.STD_LOGIC_1164.ALL;
Use ieee.numeric_std.all ;


entity Reg is
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
end Reg;

architecture Reg_a of Reg is

type reg is array(0 to 7) of std_logic_vector(REG_WIDTH - 1 downto 0);

signal Data_Reg : reg ;


--------------- BEGIN -----------------------------------------------------------------
begin
-- rw='1' alors lecture
	acces_reg:process(rst, clk)
		begin
		
		if rst='1' then

				for k in 0 to 7 loop
					Data_Reg(k) <= (others=>'0');
				end loop;
				
		else
		
			if rising_edge(clk) then
				if wr='1'then
					Data_Reg(to_integer(unsigned(AddrDest))) <= R;
				end if;
			end if;
			
		end if;
		
	end process acces_reg;
	outA <= Data_Reg(to_integer(unsigned(AddrRA)));
	outB <= Data_Reg(to_integer(unsigned(AddrRB)));

	LR   <= Data_Reg(7);
end Reg_a;
