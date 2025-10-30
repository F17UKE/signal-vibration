library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx_de10 is
    Port (
        CLK   : in  STD_LOGIC;     -- 50 MHz input clock
        NRST  : in  STD_LOGIC;     -- Active-low reset
        X_IN  : in  STD_LOGIC_VECTOR(15 downto 0);
        Y_IN  : in  STD_LOGIC_VECTOR(15 downto 0);
        Z_IN  : in  STD_LOGIC_VECTOR(15 downto 0);
        TX    : out STD_LOGIC      -- UART transmit output
    );
end uart_tx_de10;

architecture Behavioral of uart_tx_de10 is

    -- UART configuration
    constant BAUD_RATE        : integer := 115200;
    constant CLOCK_FREQ       : integer := 50000000;
    constant CLOCKS_PER_BIT   : integer := CLOCK_FREQ / BAUD_RATE;

    -- Add a small delay between transmissions (in bit periods)
    constant GAP_BITS         : integer := 10;  -- number of bit times to wait
    constant GAP_TICKS        : integer := CLOCKS_PER_BIT * GAP_BITS;

    -- UART transmitter state machine
    type STATE_TYPE is (IDLE, START_BIT, DATA_BITS, STOP_BIT, GAP);
    signal state     : STATE_TYPE := IDLE;

    signal counter   : integer range 0 to CLOCKS_PER_BIT - 1 := 0;
    signal gap_count : integer range 0 to GAP_TICKS - 1 := 0;
    signal bit_pos   : integer range 0 to 7 := 0;
    signal tx_reg    : STD_LOGIC := '1';

    -- Frame buffer
    type byte_array_t is array (0 to 7) of std_logic_vector(7 downto 0);
    signal frame     : byte_array_t;
    signal byte_idx  : integer range 0 to 7 := 0;

begin

    process(CLK, NRST)
    begin
        if NRST = '0' then
            -- Reset all internal registers
            state     <= IDLE;
            counter   <= 0;
            bit_pos   <= 0;
            tx_reg    <= '1';
            gap_count <= 0;
            byte_idx  <= 0;

        elsif rising_edge(CLK) then
            case state is

                when IDLE =>
                    -- เตรียมเฟรมใหม่ทุกครั้ง
                    frame(0) <= x"AA";
                    frame(1) <= X_IN(7 downto 0);
                    frame(2) <= X_IN(15 downto 8);
                    frame(3) <= Y_IN(7 downto 0);
                    frame(4) <= Y_IN(15 downto 8);
                    frame(5) <= Z_IN(7 downto 0);
                    frame(6) <= Z_IN(15 downto 8);
                    frame(7) <= x"55";

                    tx_reg   <= '1';
                    counter  <= 0;
                    bit_pos  <= 0;
                    state    <= START_BIT;

                when START_BIT =>
                    tx_reg <= '0'; -- start bit
                    if counter = CLOCKS_PER_BIT - 1 then
                        counter <= 0;
                        state   <= DATA_BITS;
                    else
                        counter <= counter + 1;
                    end if;

                when DATA_BITS =>
                    tx_reg <= frame(byte_idx)(bit_pos); -- LSB first
                    if counter = CLOCKS_PER_BIT - 1 then
                        counter <= 0;
                        if bit_pos = 7 then
                            bit_pos <= 0;
                            state   <= STOP_BIT;
                        else
                            bit_pos <= bit_pos + 1;
                        end if;
                    else
                        counter <= counter + 1;
                    end if;

                when STOP_BIT =>
                    tx_reg <= '1'; -- stop bit
                    if counter = CLOCKS_PER_BIT - 1 then
                        counter <= 0;
                        if byte_idx = 7 then
                            byte_idx  <= 0;
                            gap_count <= 0;
                            state     <= GAP;  -- Wait before next frame
                        else
                            byte_idx <= byte_idx + 1;
                            state    <= START_BIT; -- ส่ง byte ถัดไป
                        end if;
                    else
                        counter <= counter + 1;
                    end if;

                when GAP =>
                    tx_reg <= '1'; -- keep line idle
                    if gap_count = GAP_TICKS - 1 then
                        gap_count <= 0;
                        state     <= IDLE; -- send next frame
                    else
                        gap_count <= gap_count + 1;
                    end if;

                when others =>
                    state <= IDLE;

            end case;
        end if;
    end process;

    TX <= tx_reg;

end Behavioral;