library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_async_fifo is
end tb_async_fifo;

architecture simulation of tb_async_fifo is

  -- Array type for test data
  type fifo_data_array is array (0 to 15) of std_logic_vector(7 downto 0);

  -- Signal declarations for the DUT (Device Under Test)
  signal rst               : std_logic := '0';
  signal write_clock       : std_logic := '0';
  signal read_clock        : std_logic := '0';
  signal write_enable      : std_logic := '0';
  signal read_enable       : std_logic := '0';
  signal data_in           : std_logic_vector(7 downto 0) := (others => '0');

  -- Outputs from FIFO
  signal fifo_fill_in      : std_logic_vector(4 downto 0) := (others => '0');
  signal fifo_fill_out     : std_logic_vector(4 downto 0) := (others => '0');
  signal data_out          : std_logic_vector(7 downto 0) := (others => '0');
  signal write_valid       : std_logic;
  signal read_valid        : std_logic;
  signal write_enable_out  : std_logic;
  signal read_enable_out   : std_logic;

  -- Constants for clock periods
  constant fast_clk_period : time := 15 ns;
  constant slow_clk_period : time := 30 ns;

  -- Test data array
  constant test_data : fifo_data_array := (
    x"12", x"34", x"56", x"78",
    x"90", x"AB", x"CD", x"EF",
    x"12", x"34", x"56", x"78",
    x"90", x"AB", x"CD", x"EF"
  );

  -- Helper function to convert std_logic_vector to hex string
  function std_logic_vector_to_hex(vec: std_logic_vector) return string is
    variable result : string(1 to vec'length / 4);
    variable nibble : std_logic_vector(3 downto 0);
    variable i      : integer := 1;
  begin
    for idx in 0 to vec'length/4 - 1 loop
      nibble := vec((vec'length - 1 - idx*4) downto (vec'length - 4 - idx*4));
      case nibble is
        when "0000" => result(i) := '0';
        when "0001" => result(i) := '1';
        when "0010" => result(i) := '2';
        when "0011" => result(i) := '3';
        when "0100" => result(i) := '4';
        when "0101" => result(i) := '5';
        when "0110" => result(i) := '6';
        when "0111" => result(i) := '7';
        when "1000" => result(i) := '8';
        when "1001" => result(i) := '9';
        when "1010" => result(i) := 'A';
        when "1011" => result(i) := 'B';
        when "1100" => result(i) := 'C';
        when "1101" => result(i) := 'D';
        when "1110" => result(i) := 'E';
        when "1111" => result(i) := 'F';
        when others => result(i) := 'X';
      end case;
      i := i + 1;
    end loop;
    return result;
  end function;

  -- DUT component declaration
  component async_fifo
    port (
      rst               : in std_logic;
      write_clock       : in std_logic;
      read_clock        : in std_logic;
      write_enable      : in std_logic;
      read_enable       : in std_logic;
      data_in           : in std_logic_vector(7 downto 0);
      fifo_fill_in      : out std_logic_vector(4 downto 0);
      fifo_fill_out     : out std_logic_vector(4 downto 0);
      data_out          : out std_logic_vector(7 downto 0);
      write_valid       : out std_logic;
      read_valid        : out std_logic;
      write_enable_out  : out std_logic;
      read_enable_out   : out std_logic
    );
  end component;

begin

  -- DUT instantiation
  dut: async_fifo
    port map (
      rst               => rst,
      write_clock       => write_clock,
      read_clock        => read_clock,
      write_enable      => write_enable,
      read_enable       => read_enable,
      data_in           => data_in,
      fifo_fill_in      => fifo_fill_in,
      fifo_fill_out     => fifo_fill_out,
      data_out          => data_out,
      write_valid       => write_valid,
      read_valid        => read_valid,
      write_enable_out  => write_enable_out,
      read_enable_out   => read_enable_out
    );

  -- Clock generation for write clock
  write_clk_process : process
  begin
    loop
      write_clock <= '0';
      wait for slow_clk_period / 2;
      write_clock <= '1';
      wait for slow_clk_period / 2;
    end loop;
  end process;

  -- Clock generation for read clock
  read_clk_process : process
  begin
    loop
      read_clock <= '0';
      wait for fast_clk_period / 2;
      read_clock <= '1';
      wait for fast_clk_period / 2;
    end loop;
  end process;

  -- Stimulus process
  stimulus_process : process
  begin
    -- Apply reset
    rst <= '1';
    wait for slow_clk_period;
    rst <= '0';
    wait for slow_clk_period;

    -- Write data into FIFO
    for idx in 0 to 15 loop
      write_enable <= '1';
      data_in <= test_data(idx);
      wait for slow_clk_period;
      write_enable <= '0';
      wait for slow_clk_period;
    end loop;

    -- Wait for pointers to sync
    wait for 5 * slow_clk_period;

    -- Read data from FIFO
    for idx in 0 to 15 loop
      read_enable <= '1';
      wait for fast_clk_period;
      if data_out /= test_data(idx) then
        report "Mismatch at index " & integer'image(idx) & 
               ": got " & std_logic_vector_to_hex(data_out) & 
               ", expected " & std_logic_vector_to_hex(test_data(idx)) 
               severity warning;
      end if;
      read_enable <= '0';
      wait for fast_clk_period;
    end loop;

    -- Test writing when FIFO is full
    report "Testing write when FIFO is full...";
    write_enable <= '1';
    data_in <= x"FF";
    wait for slow_clk_period;
    assert write_valid = '0' severity warning;
    assert write_enable_out = '0' severity warning;
    write_enable <= '0';
    wait for slow_clk_period;

    -- Test reading when FIFO is empty
    report "Testing read when FIFO is empty...";
    read_enable <= '1';
    wait for fast_clk_period;
    assert read_valid = '0' severity warning;
    assert read_enable_out = '0' severity warning;
    read_enable <= '0';
    wait for fast_clk_period;

    report "Testbench completed successfully." severity note;
    wait;

  end process;

end simulation;

