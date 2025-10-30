library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bin2bcd is
  generic (
    BIN_WIDTH : integer := 16;
    DIGITS    : integer := 5
  );
  port (
	 sw : in std_logic_vector(1 downto 0);
    bin: in  std_logic_vector(BIN_WIDTH-1 downto 0);
    d1 : out std_logic_vector(3 downto 0);
	 d2 : out std_logic_vector(3 downto 0);
	 d3 : out std_logic_vector(3 downto 0);
	 d4 : out std_logic_vector(3 downto 0);
	 d5 : out std_logic_vector(3 downto 0);  -- sign
	 d6 : out std_logic_vector(3 downto 0)  -- x y z
  );
end entity;

architecture rtl of bin2bcd is
signal abs_value : unsigned(BIN_WIDTH-1 downto 0);
signal int1, int2, int3, int4, int5, int6 : integer;

begin
  process(sw, bin)
  begin
    if bin(15) = '1' then 
		abs_value <= unsigned(-signed(bin)); 
		int5 <= 10;
	 else 
		abs_value <= unsigned(signed(bin));
		int5 <= 15;
	end if;
	
	case sw is
		when "00" => int6 <= 11;
		when "01" => int6 <= 12;
		when "10" => int6 <= 13;
		when "11" => int6 <= 15;
	end case;
	
	int1 <= to_integer(abs_value) mod 10;
	int2 <= to_integer(abs_value)/10 mod 10;
	int3 <= to_integer(abs_value)/100 mod 10;
	int4 <= to_integer(abs_value)/1000 mod 10;
	
  end process;
  d1 <= std_logic_vector(to_unsigned(int1,4));
  d2 <= std_logic_vector(to_unsigned(int2,4));
  d3 <= std_logic_vector(to_unsigned(int3,4));
  d4 <= std_logic_vector(to_unsigned(int4,4));
  d5 <= std_logic_vector(to_unsigned(int5,4));
  d6 <= std_logic_vector(to_unsigned(int6,4));
end architecture;