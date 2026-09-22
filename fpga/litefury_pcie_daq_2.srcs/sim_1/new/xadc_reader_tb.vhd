----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 26.08.2026 13:11:19
-- Design Name:
-- Module Name: xadc_reader_tb - Behavioral
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
use ieee.NUMERIC_STD.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity xadc_reader_tb is
	--  Port ( );
end xadc_reader_tb;

architecture Behavioral of xadc_reader_tb is

	constant AVG_VALUE     : std_logic_vector(1 downto 0) := "10";
	constant CFG0_INIT     : std_logic_vector(15 downto 0) := x"DEAD";
	constant CFG0_EXPECTED : std_logic_vector(15 downto 0) := CFG0_INIT(15 downto 14) & AVG_VALUE & CFG0_INIT(11 downto 0);
	-- DRP addresses
	constant ADDR_CFG0 : std_logic_vector(6 downto 0) := "1000000";  -- 0x40 config register 0 

	signal clk_sig             : std_logic := '0';
	signal rst_n_sig           : std_logic;
	signal drdy_sig            : std_logic := '0';
	signal do_sig              : std_logic_vector (15 downto 0) := (others => '0');
	signal eoc_sig             : std_logic := '0';
	signal daddr_sig           : std_logic_vector (6 downto 0) := (others => '0');
	signal den_sig             : std_logic := '0';
	signal di_sig              : std_logic_vector (15 downto 0) := (others => '0');
	signal dwe_sig             : std_logic := '0';
	signal temperature_out_sig : std_logic_vector(31 downto 0) := (others => '0');
	signal reset_test_done     : boolean := false;
	signal config_test_done    : boolean := false;
	signal read_test_done      : boolean := false;
	signal drdy_cfg, drdy_rd   : std_logic := '0';
	signal do_cfg, do_rd       : std_logic_vector (15 downto 0) := (others => '0');

	type test_t is (TEST_RESET, TEST_CONFIG_XADC, TEST_READ_SAMPLE, TEST_FINISHED);
	signal current_test : test_t := TEST_RESET;

begin

	drdy_sig <= drdy_cfg when current_test = TEST_CONFIG_XADC else drdy_rd;
	do_sig <= do_cfg     when current_test = TEST_CONFIG_XADC else do_rd;

	UUT : entity work.xadc_reader
	port map (
		clk              => clk_sig,
		rst_n            => rst_n_sig,
		src_drdy         => drdy_sig,
		src_data         => do_sig,
		src_eoc          => eoc_sig,
		daddr            => daddr_sig,
		den              => den_sig,
		di               => di_sig,
		dwe              => dwe_sig,
		sample_out       => temperature_out_sig,
		sample_valid_out => open,
		avg              => "10"
	);

	clk_process : process
	begin
		while true loop
			clk_sig <= '1';
			wait for 2.5 ns;
			clk_sig <= '0';
			wait for 2.5 ns;
		end loop;
		end process clk_process;

		reset_process : process
		begin
			rst_n_sig <= '0';
			reset_test_done <= false;
			wait for 5 ns ;
			assert daddr_sig = (daddr_sig'range => '0') report "Reset Error: daddr must be 0!" severity error;
			assert di_sig = (di_sig'range => '0') report "Reset Error: di must be 0!" severity error;
			assert dwe_sig = '0' report "Reset Error: dwe must be '0'!" severity error;
			assert den_sig = '0' report "Reset Error: den must be '0'!" severity error;
			assert temperature_out_sig = (temperature_out_sig'range => '0') report "Reset Error: temperature_out must be '0'!" severity error;

			rst_n_sig <= '1';
			reset_test_done <= true;
			wait;
		end process reset_process;

		sequencer_process : process
		begin
			wait until reset_test_done;
			current_test <= TEST_CONFIG_XADC;
			wait until config_test_done;
			current_test <= TEST_READ_SAMPLE;
			wait until read_test_done;
			current_test <= TEST_FINISHED;
			report "xadc_reader_tb: all tests finished" severity note;
			wait;
		end process sequencer_process;

		config_xadc_test_process : process
		begin
			wait until current_test = TEST_CONFIG_XADC;

			-- 1st transfer: read of config register 0
			wait until rising_edge(clk_sig) and den_sig = '1';
			assert daddr_sig = ADDR_CFG0 report "Config Error: first transfer must address 0x40!" severity error;
			assert dwe_sig = '0' report "Config Error: first transfer must be a read (dwe = '0')!" severity error;
			do_cfg <= CFG0_INIT; -- answer the read
			drdy_cfg <= '1';
			wait until rising_edge(clk_sig);
			drdy_cfg <= '0';

			-- 2nd transfer: write back with the new averaging bits
			wait until rising_edge(clk_sig) and den_sig = '1';
			assert daddr_sig = ADDR_CFG0 report "Config Error: write must address 0x40!" severity error;
			assert dwe_sig = '1' report "Config Error: second transfer must be a write (dwe = '1')!" severity error;
			assert di_sig(13 downto 12) = AVG_VALUE report "Config Error: bits 13:12 must be avg!" severity error;
			assert di_sig = CFG0_EXPECTED report "Config Error: all other bits must stay as read!" severity error;
			drdy_cfg <= '1'; -- acknowledge the write
			wait until rising_edge(clk_sig);
			drdy_cfg <= '0';

			-- FSM back to S_IDLE, hand drdy and do over to the next test
			wait until rising_edge(clk_sig);
			wait until rising_edge(clk_sig);

			config_test_done <= true;
			wait;
		end process config_xadc_test_process;

		read_xadc_test_process : process
		variable output_15 : std_logic_vector(15 downto 0);
		begin
			wait until current_test = TEST_READ_SAMPLE;
			wait until rising_edge(clk_sig); --S_IDLE
			eoc_sig <= '1';
			wait until rising_edge(clk_sig); --S_PULSE_DEN
			eoc_sig <= '0';
			wait for 1 ns;
			assert den_sig = '1' report "FSM Error: den must be '1' after an asserted eoc!" severity error;
			wait until rising_edge(clk_sig); --S_WAIT_DRDY
			wait for 1 ns;
			assert den_sig = '0' report "FSM Error: den must be '0' one clk cycle after assertion" severity error;
			wait until rising_edge(clk_sig); --S_WAIT_DRDY
			-- nothing should happen, waiting FSM should wait for drdy
			assert daddr_sig = (daddr_sig'range => '0') report "FSM Error: daddr must be 0!" severity error;
			assert di_sig = (di_sig'range => '0') report "FSM Error: di must be 0!" severity error;
			assert dwe_sig = '0' report "FSM Error: dwe must be '0'!" severity error;
			assert den_sig = '0' report "FSM Error: den must be '0'!" severity error;
			wait until rising_edge(clk_sig);--S_WAIT_DRDY
			wait for 1 ns;
			output_15 := std_logic_vector(to_unsigned(16#ABC#, 12)) & "0000";
			do_rd  <= output_15;
			drdy_rd <= '1';
			wait until rising_edge(clk_sig);--S_WAIT_DRDY_LOW
			drdy_rd <= '0';
			wait until rising_edge(clk_sig); --S_IDLE
			wait for 1 ns;
			assert temperature_out_sig = std_logic_vector'(31 downto 12 => '0') & output_15(15 downto 4)
			report "FSM Error: temperature_out must be 0!" severity error;
			read_test_done <= true;
			wait;
		end process read_xadc_test_process;

	end Behavioral;
