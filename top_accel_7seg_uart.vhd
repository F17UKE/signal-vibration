library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_accel_7seg_uart is
  generic (
    CLOCK_FREQ : integer := 50000000;
    BAUD_RATE  : integer := 115200
  );
  port (
    clk    : in  std_logic;
    rst_n  : in  std_logic;

    -- SPI interface to ADXL345
    spi_mosi : out std_logic;
    spi_miso : in  std_logic;
    spi_sclk : out std_logic;
    spi_cs_n : out std_logic;

    -- Switch input: selects which axis to show on 7-seg
    sw      : in  std_logic_vector(1 downto 0);

    -- 7-segment display outputs (HEX0–HEX5 on DE1/DE2 boards)
    HEX1    : out std_logic_vector(6 downto 0);
    HEX2    : out std_logic_vector(6 downto 0);
    HEX3    : out std_logic_vector(6 downto 0);
    HEX4    : out std_logic_vector(6 downto 0);
    HEX5    : out std_logic_vector(6 downto 0);
	 HEX6    : out std_logic_vector(6 downto 0);

    -- UART TX output
    uart_txd : out std_logic
  );
end entity;

architecture rtl of top_accel_7seg_uart is
  -- Accelerometer outputs
  signal data_select, accel_x, accel_y, accel_z : signed(15 downto 0);
  signal data_rdy : std_logic := '1';

  -- BCD digit outputs from bin2bcd
  signal d1, d2, d3, d4, d5, d6 : std_logic_vector(3 downto 0);

  -- 7-seg decoded outputs
  signal seg_d1, seg_d2, seg_d3, seg_d4, seg_d5, seg_d6 : std_logic_vector(6 downto 0);

  -- UART packet signals
  signal pkt_valid, pkt_last, tx_busy, tx_start : std_logic;
  signal pkt_byte : std_logic_vector(7 downto 0);

begin
  ----------------------------------------------------------------
  -- ADXL345 interface
  ----------------------------------------------------------------
  mux : entity work.mux
    port map (
      clk      => clk,
      reset_n  => rst_n,
      miso     => spi_miso,
      mosi     => spi_mosi,
      sclk     => spi_sclk,
      ss_n     => spi_cs_n,
      sw       => sw,
		data_x 	=> accel_x,
		data_y 	=> accel_y,
		data_z 	=> accel_z,
      data_out => data_select
    );

  ----------------------------------------------------------------
  -- Binary to BCD converter
  -- sw selects which axis to convert; outputs six BCD digits d1–d6
  ----------------------------------------------------------------
  bcd_inst : entity work.bin2bcd
    port map (
      clk   => clk,
      rst_n => rst_n,
      sw    => sw,
      bin  => data_select,
      d1    => d1,
      d2    => d2,
      d3    => d3,
      d4    => d4,
      d5    => d5,
      d6    => d6
    );

  ----------------------------------------------------------------
  -- 7-seg decoders for each digit
  ----------------------------------------------------------------
  seg1_inst : entity work.seg7_decoder port map (bin => d1, seg => seg_d1);
  seg2_inst : entity work.seg7_decoder port map (bin => d2, seg => seg_d2);
  seg3_inst : entity work.seg7_decoder port map (bin => d3, seg => seg_d3);
  seg4_inst : entity work.seg7_decoder port map (bin => d4, seg => seg_d4);
  seg5_inst : entity work.seg7_decoder port map (bin => d5, seg => seg_d5);
  seg6_inst : entity work.seg7_decoder port map (bin => d6, seg => seg_d6);

  -- Map decoded segments to HEX displays
  HEX1 <= seg_d1;
  HEX2 <= seg_d2;
  HEX3 <= seg_d3;
  HEX4 <= seg_d4;
  HEX5 <= seg_d5;
  HEX6 <= seg_d6;

  ----------------------------------------------------------------
  -- Packet assembler
  -- Formats X, Y, Z into a byte stream for UART transmission
  ----------------------------------------------------------------
  pkt_inst : entity work.packet_assembler
  port map (
    clk       => clk,
    reset_n   => rst_n,
    xyz_valid => '1',   -- จาก accelerometer
    x_in      => std_logic_vector(accel_x),
    y_in      => std_logic_vector(accel_y),
    z_in      => std_logic_vector(accel_z),
    tx        => uart_txd    -- ต่อออก UART pin
  );

end architecture;