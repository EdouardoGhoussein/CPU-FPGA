library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity Meg is
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
end Meg;

architecture Meg_a of Meg is
    type reg_row is array (0 to 2) of std_logic_vector(REG_WIDTH - 1 downto 0);
    type reg is array (0 to 15) of reg_row;
    
    signal Data_Reg : reg;
    signal AddrMB_num : unsigned(AddrMB'range);

begin

    AddrMB_num <= unsigned(AddrMB);

    acces_reg: process(rst, clk)
    begin
        if rst = '1' then
            for k in 0 to 15 loop
                Data_Reg(k)(0) <= (others => '0');
                Data_Reg(k)(1) <= (others => '0');
                Data_Reg(k)(2) <= (others => '0');

		output <= (others => '0');
            end loop;
        elsif rising_edge(clk) then
            if wr = '1' then
                    Data_Reg(to_integer(unsigned(AddrDest)))(0) <= R1;
                    Data_Reg(to_integer(unsigned(AddrDest)))(1) <= R2;
                    Data_Reg(to_integer(unsigned(AddrDest)))(2) <= R3;

		    output <= Data_Reg(to_integer(unsigned(row)))(to_integer(unsigned(col)));
            end if;
        end if;
    end process acces_reg;

    -- Output assignments for port A
    outA1 <= Data_Reg(to_integer(unsigned(AddrMA)))(0);
    outA2 <= Data_Reg(to_integer(unsigned(AddrMA)))(1);
    outA3 <= Data_Reg(to_integer(unsigned(AddrMA)))(2);

    -- Output assignments for port B
    outB1 <= Data_Reg(to_integer(AddrMB_num))(0) when column = "11" else
				 Data_Reg(to_integer(AddrMB_num))(to_integer(unsigned(column)));

    outB2 <= Data_Reg(to_integer(AddrMB_num))(1) when column = "11" else
             Data_Reg(to_integer(AddrMB_num + 1))(to_integer(unsigned(column)))
				 when AddrMB_num < 14 else (others => '0');

    outB3 <= Data_Reg(to_integer(AddrMB_num))(2) when column = "11" else
             Data_Reg(to_integer(AddrMB_num + 2))(to_integer(unsigned(column)))
				 when AddrMB_num < 13 else (others => '0');
				

end Meg_a;