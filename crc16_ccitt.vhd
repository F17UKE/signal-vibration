library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity crc16_ccitt is
  port(
    clk      : in  std_logic;
    reset_n  : in  std_logic;         -- active-low
    clr      : in  std_logic;         -- '1' => load init 0xFFFF
    en       : in  std_logic;         -- '1' with data_valid to update
    data_in  : in  std_logic_vector(7 downto 0); -- byte
    data_valid : in std_logic;        -- pulse with data_in
    crc_out  : out std_logic_vector(15 downto 0)
  );
end entity;

architecture rtl of crc16_ccitt is
  signal crc : unsigned(15 downto 0) := (others=>'1'); -- 0xFFFF
begin
  crc_out <= std_logic_vector(crc);

  process(clk, reset_n)
    variable d  : unsigned(7 downto 0);
    variable r  : unsigned(15 downto 0);
  begin
    if reset_n = '0' then
      crc <= (others=>'1');
    elsif rising_edge(clk) then
      if clr = '1' then
        crc <= (others=>'1'); -- 0xFFFF
      elsif en = '1' and data_valid = '1' then
        d := unsigned(data_in);
        r := crc;
        -- feed byte MSB-first into CRC-16/CCITT
        for i in 7 downto 0 loop
          if (r(15) xor d(i)) = '1' then
            r := (r(14 downto 0) & '0') xor x"1021";
          else
            r := (r(14 downto 0) & '0');
          end if;
        end loop;
        crc <= r;
      end if;
    end if;
  end process;
end architecture;