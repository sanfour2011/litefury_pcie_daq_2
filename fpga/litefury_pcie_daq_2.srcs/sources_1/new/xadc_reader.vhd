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
		clk              : in  std_logic;
		rst_n            : in  std_logic;
		src_drdy         : in  std_logic;
		src_data         : in  std_logic_vector (15 downto 0);
		src_eoc          : in  std_logic;
		avg              : in  std_logic_vector (2 downto 0);
		daddr            : out std_logic_vector (6 downto 0);
		den              : out std_logic;
		di               : out std_logic_vector (15 downto 0);
		dwe              : out std_logic;
		sample_out       : out std_logic_vector(31 downto 0);
		sample_valid_out : out std_logic
	);
end xadc_reader;

architecture Behavioral of xadc_reader is
	type xadc_state_t is (
		S_IDLE, 
		-- Just Readign sample States
		S_DEN, S_WAIT_DRDY, S_WAIT_DRDY_LOW,

		-- Config xadc Read and Write states
		S_CFG_RD_DEN, S_CFG_RD_WAIT_DRDY, S_CFG_RD_WAIT_DRDY_LOW,
		S_CFG_WR_DEN, S_CFG_WR_WAIT_DRDY, S_CFG_WR_WAIT_DRDY_LOW,

	);
	signal next_xadc_state : xadc_state_t;
	signal xadc_Config_Reg_0 : std_logic_vector(15 downto 0) := (others => '0');

begin

	u_process_1 : process (clk, rst_n)
	variable avg_prev : std_logic_vector(2 downto 0) := (others => '0');
	begin
		if rst_n = '0' then
			daddr <= (others => '0');
			di <= (others => '0');
			dwe <= '0'; -- alway reading
			daddr <= (others => '0'); -- reading temp add ist 0
			den <= '0';
			next_xadc_state <= S_IDLE;
			sample_out <= (others => '0');
			sample_valid_out <= '0';
			avg_prev := (others => '0');

		elsif rising_edge(clk) then
			case next_xadc_state is
				when S_IDLE =>
					if avg_prev /= avg then
						avg_prev := avg;
						daddr <= "01000000"; -- 0x40 average control register
						next_xadc_state <= S_CFG_RD_DEN;
					elsif src_eoc = '1' then
						daddr <= "00000000"; -- temperature channel
						next_xadc_state <= S_DEN;
						den <= '1';
					end if;
				when S_DEN =>
					den <= '0';
					next_xadc_state <= S_WAIT_DRDY;
				when S_WAIT_DRDY =>
					if src_drdy = '1' then
						next_xadc_state <= S_WAIT_DRDY_LOW;
						sample_out <= (31 downto 12 => '0') & src_data(15 downto 4);
						sample_valid_out <= '1';
					end if;
				when S_WAIT_DRDY_LOW =>
					sample_valid_out <= '0'; -- ! should be a puls of 1 clk-cykle ! otherwise ping-pong wirtes same value every clk cycle
					if src_drdy = '0' then
						next_xadc_state <= S_IDLE;
					end if;

					-- config read states:
				when S_CFG_RD_DEN =>
					den <= '0';
					next_xadc_state <= S_CFG_RD_WAIT_DRDY;
				when S_CFG_RD_WAIT_DRDY =>
					if src_drdy = '1' then
						next_xadc_state <= S_CFG_RD_WAIT_DRDY_LOW;
						xadc_Config_Reg_0 <=  src_data(15 downto 0);
					end if;
				when S_CFG_RD_WAIT_DRDY_LOW =>
					if src_drdy = '0' then
						next_xadc_state <= S_IDLE;
					end if;

					--config write states:
				when S_CFG_WR_DEN =>
					den <= '0';
					next_xadc_state <= S_CFG_WR_WAIT_DRDY;
				when S_CFG_WR_WAIT_DRDY =>
					if src_drdy = '1' then
						next_xadc_state <= S_CFG_WR_WAIT_DRDY_LOW;
						di <= xadc_Config_Reg_0(15) & avg & xadc_Config_Reg_0(11 downto 0);
					end if;
				when S_CFG_WR_WAIT_DRDY_LOW =>
					if src_drdy = '0' then
						next_xadc_state <= S_IDLE;
					end if;
			end case;
		end if;

	end process u_process_1;
end Behavioral;
