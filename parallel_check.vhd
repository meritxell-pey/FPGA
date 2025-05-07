library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fcs_check_parallel is
    port (
        clk             : in std_logic;
        reset           : in std_logic;
        start_of_frame  : in std_logic;
        end_of_frame    : in std_logic;
        data_in         : in std_logic_vector(7 downto 0);
        fcs_error       : out std_logic;
        -- Debug outputs:
        byte_counter    : out integer;
        crc_reg         : out std_logic_vector(31 downto 0)
    );
end fcs_check_parallel;

architecture rtl of fcs_check_parallel is
    -- Polynomial for CRC-32 (Ethernet)
    constant CRC_POLY : std_logic_vector(32 downto 0) := "100000100110000010001110110110111"; -- x^32 + x^26 + x^23 + x^22 + x^16 + x^12 + x^11 + x^10 + x^8 + x^7 + x^5 + x^4 + x^2 + x + 1

    signal R          : std_logic_vector(31 downto 0) := (others => '0');
    signal counter    : integer := 0;
    signal crc_value  : std_logic_vector(31 downto 0) := (others => '0');
    signal temp_crc   : std_logic_vector(31 downto 0);
    
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                R <= (others => '0');
                counter <= 0;
                fcs_error <= '1';
            elsif start_of_frame = '1' then
                -- Initialize for frame reception
                counter <= 1;
                R <= (others => '1');  -- Initial value of the CRC register is all ones (for CRC-32)
                fcs_error <= '1';
            elsif end_of_frame = '1' then
                -- Final check for CRC value
                if R = x"00000000" then
                    fcs_error <= '0';  -- No error, CRC is valid
                else
                    fcs_error <= '1';  -- CRC error
                end if;
            else
                -- CRC calculation here
                -- Shift the CRC register and process the incoming data
                temp_crc(31 downto 8) <= R(23 downto 0);  -- Shift register
                temp_crc(7 downto 0) <= data_in;

                -- XOR with polynomial if the MSB is 1
                if temp_crc(31) = '1' then
                    R <= temp_crc xor CRC_POLY(31 downto 0);
                else
                    R <= temp_crc;
                end if;
                
                -- Increment byte counter
                counter <= counter + 1;
            end if;
        end if;
    end process;

    -- Output assignments
    byte_counter <= counter;
    crc_reg <= R;

end rtl;

