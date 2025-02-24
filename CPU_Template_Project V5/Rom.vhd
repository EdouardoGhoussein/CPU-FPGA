library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity rom is
  generic (
    DATA_WIDTH : integer := 20 -- Default data width is 20 bits
  );
  port (
    en       	: in  std_logic;
    clk      	: in  std_logic;
    rst      	: in  std_logic;
    Adress   	: in  std_logic_vector(7 downto 0);

    skip	: out std_logic;

    Data_out1 	: out std_logic_vector(DATA_WIDTH - 1 downto 0);
	 Data_out2 	: out std_logic_vector(DATA_WIDTH - 1 downto 0)
  );
end entity;

architecture rom_a of rom is

  -- Define ROM type with generic data width
  type rom is array (0 to 255) of std_logic_vector(DATA_WIDTH - 1 downto 0);

  signal Data_Rom : rom;

begin
  -- Process to handle ROM access logic
  acces_rom: process (rst, clk)
  begin
    if rst = '1' then
      -- Reset ROM content
      for k in 0 to 255 loop
        Data_Rom(k) <= (others => '0');
      end loop;
             -- Initialize ROM with binary instructions
    Data_Rom(0) <= "00000010000000000000000000000000"; -- B 0 (next instruction)
    Data_Rom(1) <= "10010100011000000000000000001010"; -- VMOV M0 (10,0,4)
    Data_Rom(2) <= "00000000000000000000000000000100"; -- DATA
    Data_Rom(3) <= "10010100011000010000000000000101"; -- VMOV M1 (5,9,9)
    Data_Rom(4) <= "00000000000010010000000000001001"; -- DATA
    Data_Rom(5) <= "10010100011000100000000000001010"; -- VMOV M2 (10,10,7)
    Data_Rom(6) <= "00000000000010100000000000000111"; -- DATA
    Data_Rom(7) <= "10010100011000110000000000000000"; -- VMOV M3 (0,8,0)
    Data_Rom(8) <= "00000000000010000000000000000000"; -- DATA
    Data_Rom(9) <= "10010100011001000000000000001001"; -- VMOV M4 (9,10,8)
    Data_Rom(10) <= "00000000000010100000000000001000"; -- DATA
    Data_Rom(11) <= "10010100011001010000000000000000"; -- VMOV M5 (0,8,8)
    Data_Rom(12) <= "00000000000010000000000000001000"; -- DATA
    Data_Rom(13) <= "10000110000001100000001100000000"; -- MADD M6 M0 M3
    Data_Rom(14) <= "10000110000101100110000000000000"; -- MSUB M6 M6 M0
    Data_Rom(15) <= "00010101000000100000000001100100"; -- LD R1 100
    Data_Rom(16) <= "11000100001000000000001000000000"; -- VDOT R0 M0 M2
    Data_Rom(17) <= "00010100011000100000000011001000"; -- MOV R1 200
    Data_Rom(18) <= "00010001111100000000000001100100"; -- ST R0 100
    Data_Rom(19) <= "00010001111100000100000001100101"; -- ST R1 101
    Data_Rom(20) <= "11000110001010010000001100000000"; -- MATMUL M9 M0 M3 
    Data_Rom(21) <= "10010100011011110000000000001010"; -- VMOV M15 (10,0,4)
    Data_Rom(22) <= "00000000000000000000000000000100"; -- DATA
    Data_Rom(23) <= "10010100011011100000000000000000"; -- VMOV M14 (0,0,0)
    Data_Rom(24) <= "00000000000000000000000000000000"; -- DATA
    Data_Rom(25) <= "10000100000011000000000000000000"; -- VADD M12 M0 M0 (10,0,4)
    Data_Rom(26) <= "00000100000000000000000000000000"; -- ADD R0 R0 R0
    Data_Rom(27) <= "00010001111100000000000001100110"; -- ST R0 102
    Data_Rom(28) <= "00010101000001100000000001100100"; -- LD R3 100
    Data_Rom(29) <= "00000000111000000001100000000000"; -- PUSH R3
    Data_Rom(30) <= "00010100110010100000000000000001"; -- POP R5 1
    Data_Rom(31) <= "00010001111100010100000001100111"; -- ST R5 103
    Data_Rom(32) <= "00010010000011100000000000000000"; -- BX (0)
	Data_out1 <= "00000000111100000000000000000000";
	Data_out2 <= (others => '0');

    else
      if rising_edge(clk) then
        if en = '1' then
          Data_out1 <= Data_Rom(to_integer(unsigned(Adress)));
			 Data_out2 <= Data_Rom(to_integer(unsigned(Adress)+1));
        end if;
      end if;
    end if;
  end process;

  process(rst, Adress)
  begin
	if rst = '1' then
		skip <= Data_Rom(0)(DATA_WIDTH-1) and Data_Rom(0)(DATA_WIDTH-4);
	else
		skip <= Data_Rom(to_integer(unsigned(Adress)))(DATA_WIDTH-1) and Data_Rom(to_integer(unsigned(Adress)))(DATA_WIDTH-4);
	end if;
  end process;

end architecture;

