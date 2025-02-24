library ieee;

use IEEE.STD_LOGIC_1164.ALL;
Use ieee.numeric_std.all ;


entity ram is
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
end ram;

architecture ram_a of ram is

type ram is array(0 to 255) of std_logic_vector(DATA_WIDTH - 1 downto 0);

signal Data_Ram : ram ;



--------------- BEGIN -----------------------------------------------------------------
begin
-- rw='1' alors lecture
	acces_ram:process(rst, clk)
		begin
		
		if rst='1' then
			for k in 0 to 255 loop
				Data_Ram(k) <= (others=>'0');
			end loop;
		
		else
			if rising_edge(clk) then
				if en='1' then
					if(rw='1') then 
						Data_out <= Data_Ram(to_integer(unsigned(Adress)));
					else
						Data_Ram(to_integer(unsigned(Adress))) <= Data_in;
					end if;
				end if;
			end if;
		end if;
		
	end process acces_ram;

	hex_out <= Data_Ram(to_integer(unsigned(AddrUsr)));
end ram_a;
