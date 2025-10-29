library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity seg7_decoder is
  port(
    bin : in  std_logic_vector(3 downto 0);
    seg : out std_logic_vector(6 downto 0)  -- gfedcba (active-low)
  );
end entity;

architecture rtl of seg7_decoder is
begin
  process(bin)
  begin
    case bin is
      when "0000" => seg <= "1000000"; -- 0
      when "0001" => seg <= "1111001"; -- 1
      when "0010" => seg <= "0100100"; -- 2
      when "0011" => seg <= "0110000"; -- 3
      when "0100" => seg <= "0011001"; -- 4
      when "0101" => seg <= "0010010"; -- 5
      when "0110" => seg <= "0000010"; -- 6
      when "0111" => seg <= "1111000"; -- 7
      when "1000" => seg <= "0000000"; -- 8
      when "1001" => seg <= "0010000"; -- 9
		when "1010" => seg <= "0111111"; -- -
		when "1011" => seg <= "0001001"; -- x
		when "1100" => seg <= "0011001"; -- y
		when "1101" => seg <= "0100100"; -- z
      when others => seg <= "1111111"; -- blank
    end case;
  end process;
end architecture;