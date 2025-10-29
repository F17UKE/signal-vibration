library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity accel_to_7seg_top is
  port (
    CLOCK_50 : in  std_logic;
    RESET_N  : in  std_logic;
    -- SPI to ADXL345
    miso     : in  std_logic;
    sclk     : buffer std_logic;
    ss_n     : buffer std_logic_vector(0 downto 0);
    mosi     : out std_logic;
    -- selection: 00=X, 01=Y, 10=Z, 11=MAG
    SW       : in  std_logic_vector(1 downto 0);
    -- 7-segment (gfedcba, active-low)
    HEX1     : out std_logic_vector(6 downto 0);
    HEX2     : out std_logic_vector(6 downto 0);
    HEX3     : out std_logic_vector(6 downto 0);
    HEX4     : out std_logic_vector(6 downto 0);
    HEX5     : out std_logic_vector(6 downto 0);
	 HEX6     : out std_logic_vector(6 downto 0)
  );
end entity;

architecture rtl of accel_to_7seg_top is
  signal data    : std_logic_vector(15 downto 0);
  signal d1, d2, d3, d4, d5, d6 : std_logic_vector(3 downto 0);

  component mux
    port (
      clk      : in  std_logic;
      reset_n  : in  std_logic;
      miso     : in  std_logic;
      mosi     : out std_logic;
      sclk     : buffer std_logic;
      ss_n     : buffer std_logic_vector(0 downto 0);
      sw       : in  std_logic_vector(1 downto 0);
      data_out : out std_logic_vector(15 downto 0)
    );
  end component;

  component seg7_decoder
    port (
      bin : in  std_logic_vector(3 downto 0);
      seg : out std_logic_vector(6 downto 0)
    );
  end component;

  component bin2bcd
    generic (
      BIN_WIDTH : integer := 16;
      DIGITS    : integer := 5
    );
    port (
	 sw : in std_logic_vector(1 downto 0);
    bin : in  std_logic_vector(BIN_WIDTH-1 downto 0);
    d1 : out std_logic_vector(3 downto 0);
	 d2 : out std_logic_vector(3 downto 0);
	 d3 : out std_logic_vector(3 downto 0);
	 d4 : out std_logic_vector(3 downto 0);
	 d5 : out std_logic_vector(3 downto 0);  -- sign
	 d6 : out std_logic_vector(3 downto 0)  -- x y z
  );
  end component;

begin
  -- เลือกค่า X/Y/Z/MAG จาก mux
  U_MUX: mux
    port map (
      clk      => CLOCK_50,
      reset_n  => RESET_N,
      miso     => miso,
      mosi     => mosi,
      sclk     => sclk,
      ss_n     => ss_n,
      sw       => SW,
      data_out => data
    );

  -- แปลง Binary → BCD
  U_B2BCD: bin2bcd
    port map (
	   sw => SW,
      bin => data,
		d1 => d1, d2 => d2, d3 => d3, d4 => d4, d5 => d5, d6 => d6
    );

  -- ขับออก 7-seg
  UHEX1: seg7_decoder port map(bin => d1, seg => HEX1);
  UHEX2: seg7_decoder port map(bin => d2, seg => HEX2);
  UHEX3: seg7_decoder port map(bin => d3, seg => HEX3);
  UHEX4: seg7_decoder port map(bin => d4, seg => HEX4);
  UHEX5: seg7_decoder port map(bin => d5, seg => HEX5);
  UHEX6: seg7_decoder port map(bin => d6, seg => HEX6);
end architecture;