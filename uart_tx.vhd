library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
  generic(
    CLOCK_FREQ : integer := 50000000; -- 50 MHz on DE10-Lite
    BAUD_RATE  : integer := 115200
  );
  port(
    clk     : in  std_logic;
    reset_n : in  std_logic;                      -- active-low
    data_in : in  std_logic_vector(7 downto 0);   -- byte to send
    start   : in  std_logic;                      -- pulse '1' for 1 clk to start
    tx      : out std_logic;                      -- UART TX line (idle='1')
    busy    : out std_logic                       -- '1' while sending a frame
  );
end entity;

architecture rtl of uart_tx is
  constant BAUD_TICKS : integer := integer(CLOCK_FREQ / BAUD_RATE);
  signal tick_cnt : integer range 0 to BAUD_TICKS-1 := 0;
  signal bit_idx  : integer range 0 to 9 := 0; -- 1 start + 8 data + 1 stop
  signal shreg    : std_logic_vector(9 downto 0) := (others=>'1');
  signal sending  : std_logic := '0';
  signal tx_r     : std_logic := '1';
begin
  tx   <= tx_r;
  busy <= sending;

  process(clk, reset_n)
  begin
    if reset_n = '0' then
      tick_cnt <= 0; bit_idx <= 0; sending <= '0'; tx_r <= '1';
      shreg    <= (others=>'1');
    elsif rising_edge(clk) then
      if sending = '0' then
        if start = '1' then
          -- frame = start(0) + data(LSB..MSB) + stop(1)
          shreg  <= '0' & data_in & '1';
          sending <= '1';
          bit_idx <= 0;
          tick_cnt <= 0;
          tx_r <= '0'; -- first bit (start)
        end if;
      else
        if tick_cnt = BAUD_TICKS-1 then
          tick_cnt <= 0;
          bit_idx  <= bit_idx + 1;
          tx_r     <= shreg(bit_idx+1); -- shift out next bit
          if bit_idx = 9 then
            sending <= '0';
            tx_r    <= '1'; -- idle
          end if;
        else
          tick_cnt <= tick_cnt + 1;
        end if;
      end if;
    end if;
  end process;
end architecture;