----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 25.08.2026 14:13:00
-- Design Name:
-- Module Name: xadc_reader - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------

library ieee;
use ieee.STD_LOGIC_1164.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity xadc_reader is
	port (
		clk             : in  std_logic;
		rst_n           : in  std_logic;
		drdy            : in  std_logic;
		do              : in  std_logic_vector (15 downto 0);
		eoc             : in  std_logic;
		daddr           : out std_logic_vector (6 downto 0);
		den             : out std_logic;
		di              : out std_logic_vector (15 downto 0);
		dwe             : out std_logic;
		temperature_out : out std_logic_vector(31 downto 0));
end xadc_reader;

architecture Behavioral of xadc_reader is
	type drp_read_fsm is (S_IDLE, S_PULSE_DEN, S_WAIT_DRDY, S_WAIT_DRDY_LOW);
	signal  next_read_state : drp_read_fsm;

begin

	u_process_1 : process (clk, rst_n)
	begin
		if rst_n = '0' then
			daddr <= (others => '0');
			di <= (others => '0');
			dwe <= '0'; -- alway reading
			daddr <= (others => '0'); -- reading temp add ist 0
			den <= '0';
			next_read_state <= S_IDLE;
			temperature_out <= (others => '0');

		elsif rising_edge(clk) then
			case next_read_state is
				when S_IDLE =>
					if eoc = '1' then
						next_read_state <= S_PULSE_DEN;
						den <= '1';
					end if;
				when S_PULSE_DEN =>
					den <= '0';
					next_read_state <= S_WAIT_DRDY;
				when S_WAIT_DRDY =>
					if drdy = '1' then
						next_read_state <= S_WAIT_DRDY_LOW;
						temperature_out <= (31 downto 12 => '0') & do(15 downto 4);
					end if;
				when S_WAIT_DRDY_LOW =>
					if drdy = '0' then
						next_read_state <= S_IDLE;
					end if;
			end case;
		end if;

	end process u_process_1;
end Behavioral;
