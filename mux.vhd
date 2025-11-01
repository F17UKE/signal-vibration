LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux is 
	port(
			 clk            : IN      STD_LOGIC;                      --system clock
			 reset_n        : IN      STD_LOGIC;                      --active low asynchronous reset
			 a_x 				 : IN      STD_LOGIC_VECTOR(15 DOWNTO 0);
			 a_y 				 : IN      STD_LOGIC_VECTOR(15 DOWNTO 0);
			 a_z 				 : IN      STD_LOGIC_VECTOR(15 DOWNTO 0);
			 sw				 : IN      STD_LOGIC_VECTOR(1 DOWNTO 0);
			 data_out 		 : OUT     STD_LOGIC_VECTOR(15 DOWNTO 0)   --acceleration data that select
	);
end entity;

architecture behavioral of mux is
	signal result : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');

	begin 
		
		process(clk, reset_n)
		begin
		
		if reset_n = '0' then
			data_out <= (OTHERS => '0');
		
		elsif rising_edge(clk) then 
			if sw = "00" then --x
				result <= a_x;
			elsif sw = "01" then --y
				result <= a_y;
			else
				result <= a_z;
			end if;
		end if;
		data_out <= result;
	end process;
	data_out <= result;
end architecture;