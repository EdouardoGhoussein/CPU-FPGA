library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALU is 
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
end ALU;

architecture ALU_a of ALU is
    signal output : std_logic_vector(R'left downto 0);
begin
    -- ALU operation block (sequential)
    process(en, SelR, A, B)
    begin
        if en = '1' then
            case SelR is
                when "0000" =>
                    -- ADD
                    output <= std_logic_vector(resize(unsigned(A) + unsigned(B), output'length));

                when "0001" =>
                    -- SUB
                    output <= std_logic_vector(resize(unsigned(A) - unsigned(B), output'length));

                when "0010" =>
                    -- MUL
                    output <= std_logic_vector(resize(unsigned(A) * unsigned(B), output'length));

                when "0011" =>
                    -- AND
                    output <= A AND B;

                when "0100" =>
                    -- OR
                    output <= A OR B;

                when "0101" =>
                    -- XOR
                    output <= A XOR B;

                when "0110" =>
                    -- MOV
                    output <= B;
					 when "0111" =>
						  -- NOT
						  output <= not B;
					 when "1000" =>
					     -- LSL
						  output <= std_logic_vector(unsigned(A) sll to_integer(unsigned(B)));
					 when "1001" =>
					     -- LSR
						  output <= std_logic_vector(unsigned(A) srl to_integer(unsigned(B)));
                when others =>
                    -- Default case
                    output <= (others => '0');
            end case;
        else
            -- If enable is not active, reset output and flags
            output <= (others => '0');
        end if;
    end process;

    -- Update carry and overflow flags instantly (combinatorial logic)
    -- Carry and overflow update directly based on operation and output
    process(all)
begin
    --if rising_edge(clk) then  -- Ensure this block is triggered on the rising edge of the clock
        -- Logic for C
        if (SelR = "0000" and unsigned(A) > unsigned(output)) or 
           (SelR = "0001" and unsigned(A) < unsigned(B)) then
            C <= '1';
        else
            C <= '0';
        end if;

        -- Logic for V (signed overflow check for ADD and SUB)
        if (SelR = "0000" and ((A(7) = '0' and B(7) = '0' and output(7) = '1') or 
                               (A(7) = '1' and B(7) = '1' and output(7) = '0'))) or  -- ADD: signed overflow
           (SelR = "0001" and ((A(7) = '0' and B(7) = '1' and output(7) = '1') or
                                (A(7) = '1' and B(7) = '0' and output(7) = '0'))) then  -- SUB: signed overflow
            V <= '1';
        else
            V <= '0';
        end if;

        if unsigned(output) = 0 then
            Z <= '1';
        else
            Z <= '0';
        end if;
        N <= output(output'left);  -- Negative flag is the MSB of the result
    --end if;
end process;
R <= output;

end ALU_a;

