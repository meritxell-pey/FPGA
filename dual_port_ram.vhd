library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dual_port_memory is
  port (
    wclk          : in  std_logic;
    rclk          : in  std_logic;
    raddr         : in  std_logic_vector(4 downto 0);  -- 5-bit address (0 to 31)
    ren           : in  std_logic;
    waddr         : in  std_logic_vector(4 downto 0);  -- 5-bit address
    wen           : in  std_logic;
    write_data_in : in  std_logic_vector(7 downto 0);
    read_data_out : out std_logic_vector(7 downto 0)
  );
end dual_port_memory;

architecture arch of dual_port_memory is

  -- Define memory array with 32 locations, each 8 bits wide
  type storage_t is array (0 to 31) of std_logic_vector(7 downto 0);
  signal storage : storage_t := (others => (others => '0'));  -- Initialize memory to 0

begin

  -- Write process
  process (wclk)
  begin
    if rising_edge(wclk) then
      if wen = '1' then
        storage(to_integer(unsigned(waddr))) <= write_data_in;
      end if;
    end if;
  end process;

  -- Read process
  process (rclk)
  begin
    if rising_edge(rclk) then
      if ren = '1' then
        read_data_out <= storage(to_integer(unsigned(raddr)));
      end if;
    end if;
  end process;

end arch;
