library ieee;

use IEEE.STD_LOGIC_1164.ALL;
Use ieee.numeric_std.all ;


entity Event_Detect is
	port(
			clk			:	in std_logic;
			IN_Signal	:	in std_logic;
			Event_L2H	:	out std_logic;
			Event_H2L	:	out std_logic
			);
end Event_Detect;


architecture Event_a of Event_Detect is

signal In_Signal_temp: std_logic;


Begin

Process (clk)
begin
	if rising_edge(clk) then
		IN_Signal_temp <= IN_Signal;
	end if;
	
end process;

Event_L2H<= not(IN_Signal_temp) and IN_Signal;
Event_H2L<= IN_Signal_temp and not(IN_Signal);


end architecture Event_a;