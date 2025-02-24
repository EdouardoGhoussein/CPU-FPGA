library ieee;

use IEEE.STD_LOGIC_1164.ALL;
Use ieee.numeric_std.all ;


entity Fetch is
	port(
			en			:	in std_logic;
			clk		:	in std_logic;
			rst		:	in std_logic;
			PC_load	:	in std_logic;
			PC_Jump	:	in std_logic_vector(7 downto 0);
			
			skip		:	in std_logic;
			
			PC_out	:	out std_logic_vector(7 downto 0)
			);
end Fetch;


architecture Fetch_a of Fetch is

signal PC_counter: std_logic_vector(7 downto 0);

Begin


Process (clk, rst, skip)


begin

	
	if rst='1' then
	
		PC_counter<= (others=>'0');
	
	else
	
		If rising_edge(clk) then
			if en='1' then
			
				If PC_Load='0' then
					if skip = '1' then
						PC_counter<=std_logic_vector(unsigned(PC_counter)+2);
					else
						PC_counter<=std_logic_vector(unsigned(PC_counter)+1);
					end if;			
				else
				
					PC_counter<=PC_Jump;
					
				end if;
				
			end if;
			
		end if;
		
	end if;
	
end Process;


PC_out <= PC_counter;


end Architecture Fetch_a;

	
			
	