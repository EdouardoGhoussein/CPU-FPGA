library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_Archi_V5 is
end tb_Archi_V5;

architecture archi_tb_Module of tb_Archi_V5 is

    COMPONENT CPU
        PORT (
            MAX10_CLK1_50 :  IN  STD_LOGIC;
		SW :  IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
		HEX0 :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		HEX1 :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		HEX2 :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		HEX3 :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		HEX4 :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		HEX5 :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		LEDR :  OUT  STD_LOGIC_VECTOR(9 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL clk  : std_logic := '1';

begin

    -- Instantiate the Archi_V1 component
    UUT : CPU
        PORT MAP (
            MAX10_CLK1_50 => clk, 
	    SW => "0000000000"
        );

    -- Clock generation process
    clk_process : process
    begin
        -- Toggle the clock signal every 10 ns
        while true loop
            clk <= not clk;
            wait for 10 ns;
        end loop;
    end process;

end archi_tb_Module;
