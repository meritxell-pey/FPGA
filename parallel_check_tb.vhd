library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fcs_check_parallel is
end tb_fcs_check_parallel;

architecture behavior of tb_fcs_check_parallel is
    -- Component declaration
    component fcs_check_parallel
        port (
            clk             : in std_logic;
            reset           : in std_logic;
            start_of_frame  : in std_logic;
            end_of_frame    : in std_logic;
            data_in         : in std_logic_vector(7 downto 0);
            fcs_error       : out std_logic;
            byte_counter    : out integer;
            crc_reg         : out std_logic_vector(31 downto 0)
        );
    end component;

    -- Signal declarations
    signal clk             : std_logic := '0';
    signal reset           : std_logic := '0';
    signal start_of_frame  : std_logic := '0';
    signal end_of_frame    : std_logic := '0';
    signal data_in         : std_logic_vector(7 downto 0) := (others => '0');
    signal fcs_error       : std_logic;
    signal byte_counter    : integer;
    signal crc_reg         : std_logic_vector(31 downto 0);

    -- Clock period constant
    constant clk_period : time := 10 ns;

    -- Define the Ethernet packet data (without the FCS)
    type packet_type is array (0 to 59) of std_logic_vector(7 downto 0);  -- 60 bytes in total
    signal ethernet_packet : packet_type := (
        x"00", x"10", x"A4", x"7B", x"EA", x"80", x"00", x"12", 
        x"34", x"56", x"78", x"90", x"08", x"00", x"45", x"00", 
        x"00", x"2E", x"B3", x"FE", x"00", x"00", x"80", x"11", 
        x"05", x"40", x"C0", x"A8", x"00", x"2C", x"C0", x"A8", 
        x"00", x"04", x"04", x"00", x"04", x"00", x"00", x"1A", 
        x"2D", x"E8", x"00", x"01", x"02", x"03", x"04", x"05", 
        x"06", x"07", x"08", x"09", x"0A", x"0B", x"0C", x"0D", 
        x"0E", x"0F", x"10", x"11"  -- Frame data section (without the FCS)
    );

    -- The expected FCS value (last 4 bytes)
    constant expected_fcs : std_logic_vector(31 downto 0) := x"E6C53DB2";

begin
    -- Instantiate the fcs_check_parallel component
    uut: fcs_check_parallel
        port map (
            clk => clk,
            reset => reset,
            start_of_frame => start_of_frame,
            end_of_frame => end_of_frame,
            data_in => data_in,
            fcs_error => fcs_error,
            byte_counter => byte_counter,
            crc_reg => crc_reg
        );

    -- Clock generation process
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period / 2;
        clk <= '1';
        wait for clk_period / 2;
    end process;

    -- Stimulus process
    stimulus_process : process
    variable i : integer := 0;
    begin
        -- Reset the DUT
        reset <= '1';
        wait for 20 ns;
        reset <= '0';
        wait for 20 ns;

        -- Start of frame, send first byte
        start_of_frame <= '1';
        data_in <= ethernet_packet(i);
        wait for clk_period;
        start_of_frame <= '0';
        wait for clk_period;

        -- Send the rest of the frame bytes
        for i in 1 to 59 loop
            data_in <= ethernet_packet(i);
            wait for clk_period;
        end loop;

        -- The last 4 bytes are the FCS, which we'll ignore during input.
        -- Normally the FCS would be provided externally in real cases.
        -- Simulate the frame end.
        end_of_frame <= '1';
        wait for clk_period;
        end_of_frame <= '0';
        wait for clk_period;

        -- Assert the expected CRC result
        assert (fcs_error = '0') report "Error in CRC check" severity failure;
        assert (byte_counter = 60) report "Byte counter mismatch" severity failure;  -- 60 bytes for this example
        assert (crc_reg = expected_fcs) report "CRC register mismatch" severity failure;

        -- Test completed, stop simulation
        wait;
    end process;

end behavior;
