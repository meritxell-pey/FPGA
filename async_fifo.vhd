library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity async_fifo is
  port (
    rst               : in  std_logic;
    write_clock       : in  std_logic;
    read_clock        : in  std_logic;
    write_enable      : in  std_logic;
    read_enable       : in  std_logic;
    data_in           : in  std_logic_vector(7 downto 0);
    fifo_fill_in      : out std_logic_vector(4 downto 0);
    fifo_fill_out     : out std_logic_vector(4 downto 0);
    data_out          : out std_logic_vector(7 downto 0);
    write_valid       : out std_logic;
    read_valid        : out std_logic;
    write_enable_out  : out std_logic;
    read_enable_out   : out std_logic
  );
end async_fifo;

architecture rtl of async_fifo is
  -- Internal signals
  signal waddr, raddr           : std_logic_vector(4 downto 0);
  signal write_ptr_gray_sync    : std_logic_vector(4 downto 0);
  signal read_ptr_gray_sync     : std_logic_vector(4 downto 0);
  signal mem_write_enable       : std_logic;
  signal mem_read_enable        : std_logic;

  -- FIFO control occupancy signals
  signal fifo_occu_wr           : std_logic_vector(4 downto 0);
  signal fifo_occu_rd           : std_logic_vector(4 downto 0);
  signal write_flag, read_flag  : std_logic;

  -- Clocked pointer registers to sync Gray-coded values across domains
  signal wr_ptr_gray_to_rd      : std_logic_vector(4 downto 0) := (others => '0');
  signal rd_ptr_gray_to_wr      : std_logic_vector(4 downto 0) := (others => '0');

  -- Delayed sync registers
  signal wr_ptr_sync1, wr_ptr_sync2 : std_logic_vector(4 downto 0);
  signal rd_ptr_sync1, rd_ptr_sync2 : std_logic_vector(4 downto 0);

  -- Memory output
  signal mem_data_out           : std_logic_vector(7 downto 0);

begin

  -- FIFO control instantiations for write and read control
  write_ctrl: entity work.fifo_control
    port map (
      clk          => write_clock,
      reset        => rst,
      enable       => write_enable,
      sync_pointer => rd_ptr_gray_to_wr,
      pointer      => waddr,
      fifo_occu    => fifo_fill_in,
      flag         => write_flag,
      address      => open,
      mem_en       => mem_write_enable
    );

  read_ctrl: entity work.fifo_control
    port map (
      clk          => read_clock,
      reset        => rst,
      enable       => read_enable,
      sync_pointer => wr_ptr_gray_to_rd,
      pointer      => raddr,
      fifo_occu    => fifo_fill_out,
      flag         => read_flag,
      address      => open,
      mem_en       => mem_read_enable
    );

  -- Dual-Port RAM instantiation
  dp_ram: entity work.dual_port_memory
    port map (
      wclk          => write_clock,
      rclk          => read_clock,
      waddr         => waddr,
      raddr         => raddr,
      wen           => mem_write_enable,  -- Write enable control
      ren           => mem_read_enable,   -- Read enable control
      write_data_in => data_in,
      read_data_out => mem_data_out
    );

  -- Data output and enable flags
  data_out <= mem_data_out;
  write_valid <= not write_flag;  -- write_flag = full
  read_valid  <= not read_flag;   -- read_flag = empty

  write_enable_out <= write_enable and (not write_flag);
  read_enable_out  <= read_enable and (not read_flag);

  -- Gray-coded pointer synchronization across domains
  process(read_clock)
  begin
    if rising_edge(read_clock) then
      wr_ptr_sync1 <= waddr xor ('0' & waddr(4 downto 1));
      wr_ptr_sync2 <= wr_ptr_sync1;
      wr_ptr_gray_to_rd <= wr_ptr_sync2;
    end if;
  end process;

  process(write_clock)
  begin
    if rising_edge(write_clock) then
      rd_ptr_sync1 <= raddr xor ('0' & raddr(4 downto 1));
      rd_ptr_sync2 <= rd_ptr_sync1;
      rd_ptr_gray_to_wr <= rd_ptr_sync2;
    end if;
  end process;

end rtl;