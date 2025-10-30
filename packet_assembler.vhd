library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity packet_assembler is
  generic(
    CLOCK_FREQ : integer := 50000000;
    BAUD_RATE  : integer := 115200
  );
  port(
    clk      : in  std_logic;
    reset_n  : in  std_logic;

    -- data from sensor pipeline
    xyz_valid : in  std_logic;
    x_in      : in  std_logic_vector(15 downto 0);
    y_in      : in  std_logic_vector(15 downto 0);
    z_in      : in  std_logic_vector(15 downto 0);

    -- UART
    tx       : out std_logic
  );
end entity;

architecture rtl of packet_assembler is
  -- UART
  signal u_data  : std_logic_vector(7 downto 0);
  signal u_start : std_logic := '0';
  signal u_busy  : std_logic;

  -- CRC
  signal crc_clr, crc_en, crc_dv : std_logic := '0';
  signal crc   : std_logic_vector(15 downto 0);

  -- Housekeeping
  type state_t is (IDLE, LATCH, START_HDR, STREAM, WAIT_BYTE, DONE);
  signal st : state_t := IDLE;

  signal seq      : unsigned(7 downto 0) := (others=>'0');
  signal ts       : unsigned(31 downto 0) := (others=>'0'); -- timestamp counter
  signal byte_idx : integer range 0 to 255 := 0;

  -- Latched sample (to keep stable during send)
  signal x_l, y_l, z_l : std_logic_vector(15 downto 0);
begin
  -- timestamp free-run
  process(clk, reset_n)
  begin
    if reset_n='0' then ts <= (others=>'0');
    elsif rising_edge(clk) then ts <= ts + 1; end if;
  end process;

  -- Instantiate UART TX
  UTX: entity work.uart_tx
    generic map (CLOCK_FREQ => CLOCK_FREQ, BAUD_RATE => BAUD_RATE)
    port map (
      clk=>clk, reset_n=>reset_n,
      data_in=>u_data, start=>u_start,
      tx=>tx, busy=>u_busy
    );

  -- CRC16
  UCRC: entity work.crc16_ccitt
    port map (
      clk=>clk, reset_n=>reset_n, clr=>crc_clr,
      en=>crc_en, data_in=>u_data, data_valid=>crc_dv,
      crc_out=>crc
    );

  -- Byte mux according to byte_idx
  -- Build packet fields on the fly (little-endian where noted)
  -- NOTE: We feed CRC with bytes from Type..(end of payload), not Preamble/Length
  function sel_byte(
    idx : integer;
    seq_b : std_logic_vector(7 downto 0);
    ts_b  : std_logic_vector(31 downto 0);
    x_b,y_b,z_b : std_logic_vector(15 downto 0);
    crc_b : std_logic_vector(15 downto 0)
  ) return std_logic_vector is
    variable b : std_logic_vector(7 downto 0);
  begin
    -- packet layout as a linear byte stream:
    -- 0: AA, 1:55,
    -- 2: Length L, 3: Length H  (Length = bytes from Type..CRC)
    -- 4: Type(0x01)
    -- 5: Seq
    -- 6..9: Timestamp (LE)
    -- 10: Nsamp(=1)
    -- 11..16: X L,H ; Y L,H ; Z L,H
    -- 17..18: CRC L,H
    case idx is
      when 0  => b := x"AA";
      when 1  => b := x"55";
      when 2  => b := x"12";  -- Length = 0x0012 = 18 bytes (Type..CRC)
      when 3  => b := x"00";
      when 4  => b := x"01";  -- Type
      when 5  => b := seq_b;
      when 6  => b := ts_b(7 downto 0);
      when 7  => b := ts_b(15 downto 8);
      when 8  => b := ts_b(23 downto 16);
      when 9  => b := ts_b(31 downto 24);
      when 10 => b := x"01";  -- Nsamp = 1
      -- payload X, Y, Z (LE):
      when 11 => b := x_b(7  downto 0);
      when 12 => b := x_b(15 downto 8);
      when 13 => b := y_b(7  downto 0);
      when 14 => b := y_b(15 downto 8);
      when 15 => b := z_b(7  downto 0);
      when 16 => b := z_b(15 downto 8);
      -- CRC (LE):
      when 17 => b := crc_b(7 downto 0);
      when 18 => b := crc_b(15 downto 8);
      when others => b := (others=>'0');
    end case;
    return b;
  end function;

  process(clk, reset_n)
    variable b : std_logic_vector(7 downto 0);
  begin
    if reset_n='0' then
      st <= IDLE; byte_idx <= 0; u_start<='0'; crc_clr<='0'; crc_en<='0'; crc_dv<='0';
    elsif rising_edge(clk) then
      u_start <= '0';      -- default
      crc_clr <= '0';
      crc_en  <= '0';
      crc_dv  <= '0';

      case st is
        when IDLE =>
          if xyz_valid = '1' then
            x_l <= x_in; y_l <= y_in; z_l <= z_in;
            st <= LATCH;
          end if;

        when LATCH =>
          -- init CRC before streaming (covers Type..payload)
          crc_clr <= '1';
          byte_idx <= 0;
          st <= START_HDR;

        when START_HDR =>
          if u_busy='0' then
            -- pick current byte
            b := sel_byte(byte_idx, std_logic_vector(seq), std_logic_vector(ts), x_l,y_l,z_l, crc);
            u_data <= b;
            u_start <= '1';

            -- Feed CRC only for bytes from Type (idx=4) to end of payload (idx=16)
            if (byte_idx >= 4) and (byte_idx <= 16) then
              crc_en <= '1';
              crc_dv <= '1';
            end if;

            if byte_idx = 16 then
              -- after payload, next two bytes will output CRC L,H automatically (no feed)
              st <= STREAM;
            end if;
            if byte_idx = 18 then
              st <= DONE;
            end if;

            byte_idx <= byte_idx + 1;
          end if;

        when STREAM =>
          if u_busy='0' then
            b := sel_byte(byte_idx, std_logic_vector(seq), std_logic_vector(ts), x_l,y_l,z_l, crc);
            u_data <= b; u_start <= '1';
            if byte_idx = 18 then
              st <= DONE;
            end if;
            byte_idx <= byte_idx + 1;
          end if;

        when DONE =>
          seq <= seq + 1;
          st <= IDLE;

        when others =>
          st <= IDLE;
      end case;
    end if;
  end process;

end architecture;