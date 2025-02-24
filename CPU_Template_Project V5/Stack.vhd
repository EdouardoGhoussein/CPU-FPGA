library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;
  use ieee.math_real.all; -- For log and ceiling functions

entity Stack is
  generic (
    STACK_DEPTH : integer := 32; -- Number of elements in the stack
    DATA_WIDTH  : integer := 16   -- Width of each stack element
  );
  port (
    clk         : in  STD_LOGIC;                                 -- Clock signal
    reset       : in  STD_LOGIC;                                 -- Reset signal
    push        : in  STD_LOGIC;                                 -- Push control signal
    pop         : in  STD_LOGIC;                                 -- Pop control signal
    pop_Addr    : in  STD_LOGIC_VECTOR(4 downto 0);
    write_data  : in  STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0); -- Data to push onto the stack
    read_data   : out STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0); -- Data popped from the stack	
    full, empty : out STD_LOGIC                                  -- Flag indicating the stack is full
  );
end entity;

architecture Behavioral of Stack is
  -- Internal stack memory
  type stack_array is array (0 to STACK_DEPTH - 1) of STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
  signal stack_mem : stack_array := (others => (others => '0'));

  -- Stack pointer (points to the next free location or top of the stack)
  signal sp : integer range 0 to STACK_DEPTH - 1 := STACK_DEPTH - 1;
  
  signal full_e, empty_e : std_logic;

  signal index : integer range 0 to 63;

begin
  -- Stack process
  process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        -- Reset stack pointer and memory
        sp <= STACK_DEPTH - 1;
        stack_mem <= (others => (others => '0'));
      else
        -- Push operation
        if push = '1' and full_e = '0' then
          sp <= sp - 1; -- Move stack pointer down
          stack_mem(sp) <= write_data; -- Store data in stack
        end if;

        -- Pop operation
        if pop = '1' and empty_e = '0' then
          sp <= sp + 1; -- Move stack pointer up
        end if;
      end if;
    end if;
  end process;

  -- Output the top of the stack
  index <= sp + to_integer(unsigned(pop_Addr));
  
  read_data <= stack_mem(index) when index < STACK_DEPTH else (others => '0');  -- Default value when out of range


  -- Flags
  empty_e <= '1' when sp = STACK_DEPTH else '0';
  full_e  <= '1' when sp = 0 else '0';

  full	<= full_e;
  empty	<= empty_e;

end architecture;
