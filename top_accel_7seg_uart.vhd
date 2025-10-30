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
    spi_sclk : buffer std_logic;
    spi_cs_n : buffer std_logic_vector(0 downto 0);

    -- Switch input: selects which axis to show on 7-seg
    sw      : in  std_logic_vector(1 downto 0);

    -- 7-segment display outputs
    HEX1,HEX2,HEX3,HEX4,HEX5,HEX6 : out std_logic_vector(6 downto 0);

    -- UART TX output
    uart_txd : out std_logic
  );
end entity;

architecture rtl of top_accel_7seg_uart is
  -- Accelerometer outputs
  signal data_select, accel_x, accel_y, accel_z : std_logic_vector(15 downto 0);

  -- BCD digit outputs
  signal d1,d2,d3,d4,d5,d6 : std_logic_vector(3 downto 0);

  -- 7-seg decoded outputs
  signal seg_d1,seg_d2,seg_d3,seg_d4,seg_d5,seg_d6 : std_logic_vector(6 downto 0);

  -- UART signals
  signal tx_busy, tx_start : std_logic;
  signal tx_data : std_logic_vector(7 downto 0);
  signal byte_sel : integer range 0 to 7 := 0;

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
      data_x   => accel_x,
      data_y   => accel_y,
      data_z   => accel_z,
      data_out => data_select
    );

  ----------------------------------------------------------------
  -- Binary to BCD converter
  ----------------------------------------------------------------
  bcd_inst : entity work.bin2bcd
    port map (
      sw  => sw,
      bin => data_select,
      d1  => d1, d2 => d2, d3 => d3, d4 => d4, d5 => d5, d6 => d6
    );

  ----------------------------------------------------------------
  -- 7-seg decoders
  ----------------------------------------------------------------
  seg1_inst : entity work.seg7_decoder port map (bin => d1, seg => seg_d1);
  seg2_inst : entity work.seg7_decoder port map (bin => d2, seg => seg_d2);
  seg3_inst : entity work.seg7_decoder port map (bin => d3, seg => seg_d3);
  seg4_inst : entity work.seg7_decoder port map (bin => d4, seg => seg_d4);
  seg5_inst : entity work.seg7_decoder port map (bin => d5, seg => seg_d5);
  seg6_inst : entity work.seg7_decoder port map (bin => d6, seg => seg_d6);

  HEX1 <= seg_d1;
  HEX2 <= seg_d2;
  HEX3 <= seg_d3;
  HEX4 <= seg_d4;
  HEX5 <= seg_d5;
  HEX6 <= seg_d6;

    ----------------------------------------------------------------
  -- UART transmitter (ส่งเฟรมต่อเนื่อง)
  ----------------------------------------------------------------
  UTX : entity work.uart_tx_de10
    port map (
      CLK     => clk,
      NRST    => rst_n,
      X_IN    => accel_x,
      Y_IN    => accel_y,
      Z_IN    => accel_z,
      TX      => uart_txd

    );

end architecture;