LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux is 
	port(
			 clk            : IN      STD_LOGIC;                      --system clock
			 reset_n        : IN      STD_LOGIC;                      --active low asynchronous reset
			 sw				 : IN      STD_LOGIC_VECTOR(1 DOWNTO 0);
			 miso           : IN      STD_LOGIC;                      --SPI bus: master in, slave out
			 sclk           : BUFFER  STD_LOGIC;                      --SPI bus: serial clock
			 ss_n           : BUFFER  STD_LOGIC_VECTOR(0 DOWNTO 0);   --SPI bus: slave select
			 mosi           : OUT     STD_LOGIC;                      --SPI bus: master out, slave in
			 data_out 		 : OUT     STD_LOGIC_VECTOR(15 DOWNTO 0)  --x-axis acceleration data
	);
end entity;

architecture behavioral of mux is
	signal a_x : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
	signal a_y : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
	signal a_z : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
	
	signal result : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
	begin 
	
		axdl : entity work.pmod_accelerometer_adxl345(behavior)
		port map (clk => clk, reset_n => reset_n, miso => miso, mosi => mosi, sclk => sclk, ss_n => ss_n, acceleration_x => a_x, acceleration_y => a_y, acceleration_z => a_z);
		
		process(clk, reset_n)
		begin
		
		if reset_n = '0' then
			data_out <= (OTHERS => '0');
		
		elsif rising_edge(clk) then 
			if sw = "00" then --x
				result <= a_x(15 downto 0);
			elsif sw = "01" then --y
				result <= a_y(15 downto 0);
			else
				result <= a_z(15 downto 0);
			end if;
		end if;
		data_out <= result;
	end process;
	data_out <= result;
end architecture;