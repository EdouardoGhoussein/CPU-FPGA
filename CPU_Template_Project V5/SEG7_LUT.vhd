library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SEG7_LUT is 
     port (
        iDIG :  in std_logic_vector( 3  downto 0  );
        oSEG :  out std_logic_vector( 6  downto 0  )
    );
end entity; 


architecture rtl of SEG7_LUT is 
    begin 
        process(iDIG)
        begin
            case  ( iDIG ) is 
                when X"1"  => 
                    oSEG <= B"1111001" ;
                when X"2"  => 
                    oSEG <= B"0100100" ;
                when X"3"  => 
                    oSEG <= B"0110000" ;
                when X"4"  => 
                    oSEG <= B"0011001" ;
                when X"5"  => 
                    oSEG <= B"0010010" ;
                when X"6"  => 
                    oSEG <= B"0000010" ;
                when X"7"  => 
                    oSEG <= B"1111000" ;
                when X"8"  => 
                    oSEG <= B"0000000" ;
                when X"9"  => 
                    oSEG <= B"0011000" ;
                when X"a"  => 
                    oSEG <= B"0001000" ;
                when X"b"  => 
                    oSEG <= B"0000011" ;
                when X"c"  => 
                    oSEG <= B"1000110" ;
                when X"d"  => 
                    oSEG <= B"0100001" ;
                when X"e"  => 
                    oSEG <= B"0000110" ;
                when X"f"  => 
                    oSEG <= B"0001110" ;
                when X"0"  => 
                    oSEG <= B"1000000" ;
					 when others =>
						  oSEG <= B"0111111" ;
            end case;
        end process;
end architecture; 


