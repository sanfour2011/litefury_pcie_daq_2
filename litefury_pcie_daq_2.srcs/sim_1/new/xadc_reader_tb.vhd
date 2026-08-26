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
begin
	UUT : entity work.xadc_reader
	port map (
		clk             => clk_sig,
		rst_n           => rst_n_sig,
		drdy            => drdy_sig,
		data              => do_sig,
		eoc             => eoc_sig,
		daddr           => daddr_sig,
		den             => den_sig,
		di              => di_sig,
		dwe             => dwe_sig,
		temperature_out => temperature_out_sig
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

		FSM_seq : process
		variable output_15 : std_logic_vector(15 downto 0);

		begin
			wait until reset_test_done = true;
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
			do_sig <= output_15;
			drdy_sig <= '1';
			wait until rising_edge(clk_sig);--S_WAIT_DRDY_LOW
			drdy_sig <= '0';
			wait until rising_edge(clk_sig); --S_IDLE
			wait for 1 ns;
			assert temperature_out_sig = std_logic_vector'(31 downto 12 => '0') & output_15(15 downto 4)
			report "FSM Error: temperature_out must be 0!" severity error;
			wait;
		end process FSM_seq;

	end Behavioral;
