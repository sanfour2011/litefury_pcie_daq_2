----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 04.08.2026 17:15:15
-- Design Name:
-- Module Name: ping_pong_addr_tb - Behavioral
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

entity ping_pong_addr_tb is
	--  Port ( );
end entity ping_pong_addr_tb;

architecture Behavioral of ping_pong_addr_tb is

	-- Scaled generics for fast simulation (16 words total -> Buffer A: 0-7, Buffer B: 8-15)
	constant C_MEM_SIZE   : integer := 16;
	constant C_DATA_WIDTH : integer := 32;
	constant C_ADDR_WIDTH : integer := 4;

	signal clk_sig            : std_logic := '0';
	signal rst_n_sig          : std_logic := '0';
	signal data_in_sig        : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
	signal data_valid_sig     : std_logic := '0';
	signal write_enable_A_sig : std_logic := '0';
	signal write_enable_B_sig : std_logic := '0';
	signal ready_A_sig        : std_logic;
	signal ready_B_sig        : std_logic;
	signal mem_we_sig         : std_logic;
	signal mem_addr_sig       : std_logic_vector(C_ADDR_WIDTH-1 downto 0);
	signal mem_data_out_sig   : std_logic_vector(C_DATA_WIDTH-1 downto 0);

begin

	UUT : entity work.ping_pong_addr
	generic map (
		mem_size   => C_MEM_SIZE,
		data_width => C_DATA_WIDTH,
		addr_width => C_ADDR_WIDTH
	)
	port map (
		clk            => clk_sig,
		rst_n          => rst_n_sig,
		data_in        => data_in_sig,
		data_valid     => data_valid_sig,
		write_enable_A => write_enable_A_sig,
		write_enable_B => write_enable_B_sig,
		ready_A        => ready_A_sig,
		ready_B        => ready_B_sig,
		mem_we         => mem_we_sig,
		mem_addr       => mem_addr_sig,
		mem_data_out   => mem_data_out_sig
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
			wait for 10 ns ;
			assert ready_A_sig = '0'
			report "ERROR [Reset]: ready_A must be '0' after reset!" severity error;
			assert ready_B_sig = '0'
			report "ERROR [Reset]: ready_B must be '0' after reset!" severity error;
			assert mem_we_sig = '0'
			report "ERROR [Reset]: mem_we must be '0' after reset!" severity error;
			assert unsigned(mem_addr_sig) = 0
			report "ERROR [Reset]: mem_addr must be 0 after reset!" severity error;
			rst_n_sig <= '1';
			wait;
		end process reset_process;

		stim_proc : process
		variable saved_addr : unsigned(C_ADDR_WIDTH-1 downto 0);
		begin
			report "------------------------------------------------------------------";
			report "1. Test Case: Write Buffer A (addresses 0 to 7)";
			report "------------------------------------------------------------------";

			wait until rising_edge(clk_sig);
			write_enable_A_sig <= '1';

			for i in 0 to (C_MEM_SIZE/2) - 1 loop
				wait until rising_edge(clk_sig);
				assert unsigned(mem_addr_sig) = i report "ERROR Buffer A: mem_addr mismatch!" severity error;
				data_in_sig <= std_logic_vector(mem_addr_sig);
				data_valid_sig <= '1';

				wait until rising_edge(clk_sig);
				assert mem_data_out_sig = std_logic_vector(to_unsigned(i, C_DATA_WIDTH)) report "ERROR Buffer A: mem_data_out mismatch!" severity error;
				assert mem_we_sig = '1'
				report "ERROR Buffer A: mem_we output must be '1' on valid write!" severity error;
			end loop;

				--once full, ready_A should be set
				wait until rising_edge(clk_sig);
				assert ready_A_sig = '1' report "ERROR Buffer A: ready_A was not set after reaching half_mem_size!" severity error;
				data_valid_sig <= '0';
				write_enable_A_sig <= '0';

				report "------------------------------------------------------------------";
				report "1. Test Case: Overrun / Discard (data_valid='1', but NO write_enable)";
				report "------------------------------------------------------------------";

				wait until rising_edge(clk_sig);
				-- the address should remain the same during discard, so we save it for comparison
				saved_addr := unsigned(mem_addr_sig);
				--garbage data, should be discarded
				data_in_sig <= std_logic_vector(to_unsigned(9999, C_DATA_WIDTH));
				data_valid_sig <= '1';
				wait for 10 ns; --wait for 2 clock cycles 

				wait until rising_edge(clk_sig);
				assert mem_we_sig = '0'	report "ERROR Buffer A: mem_we MUST remain '0' when no write_enable is active!" severity error;
				assert unsigned(mem_addr_sig) = saved_addr report "ERROR Buffer A: Address must not change during discard!" severity error;

				wait until rising_edge(clk_sig);
				data_valid_sig <= '0';
				wait for 10 ns; --wait for 2 clock cycles 

				report "------------------------------------------------------------------";
				report "2. Test Case: Write Buffer B (addresses 8 to 15)";
				report "------------------------------------------------------------------";

				assert mem_addr_sig = std_logic_vector(to_unsigned(C_MEM_SIZE/2, C_ADDR_WIDTH))	report "ERROR Buffer B: mem_addr should start at half_mem_size for Buffer B!" severity error;

				wait until rising_edge(clk_sig);
				write_enable_B_sig <= '1';

				for i in (C_MEM_SIZE/2) to C_MEM_SIZE - 1 loop
					wait until rising_edge(clk_sig);
					data_in_sig <= std_logic_vector(to_unsigned(i, C_DATA_WIDTH));
					data_valid_sig <= '1';

					wait until rising_edge(clk_sig);
					assert mem_data_out_sig = std_logic_vector(to_unsigned(i, C_DATA_WIDTH)) report "ERROR Buffer B: mem_data_out mismatch!" severity error;
					assert unsigned(mem_addr_sig) = i report "ERROR Buffer B: mem_addr mismatch!" severity error;
					assert mem_we_sig = '1'	report "ERROR Buffer B: mem_we must be '1' on valid write!" severity error;
				end loop;

					--once full, ready_B should be set
					wait until rising_edge(clk_sig);
					assert ready_B_sig = '1' report "ERROR Buffer B: ready_B was not set after reaching max_addr!" severity error;
					data_valid_sig <= '0';
					write_enable_B_sig <= '0';

					report "------------------------------------------------------------------";
					report "3. Test Case: Wrap-Around / Ping-Pong Cycle (Buffer B -> Buffer A)";
					report "------------------------------------------------------------------";
					-- Re-assert write_enable_A to clear ready_B and roll back to Buffer A
					write_enable_A_sig <= '1';
					wait until rising_edge(clk_sig);
					assert ready_B_sig = '1' and ready_A_sig = '0' report "ERROR Wrap-Around: write_enable_A_sig from 0->1 must clear ready flags A only!" severity error;
					-- Write first word of the new cycle, should write to address 0 on Buffer A
					data_in_sig <= std_logic_vector(to_unsigned(16#DEADBEEF#, C_DATA_WIDTH));
					data_valid_sig <= '1';

					wait until rising_edge(clk_sig);
					assert unsigned(mem_addr_sig) = 0 report "ERROR Buffer A: Address failed to wrap around to 0!" severity error;
					assert mem_we_sig = '1' report "ERROR Buffer A: mem_we should be active for new write at address 0!" severity error;

					wait until rising_edge(clk_sig);
					data_valid_sig <= '0';
					write_enable_A_sig <= '0';
					wait for 10 ns; --wait for 2 clock cycles 

					write_enable_B_sig <= '1';
					wait until rising_edge(clk_sig);
					assert ready_B_sig = '0' report "ERROR Buffer B: write_enable_B_sig from 0->1 must clear ready flags B only!" severity error;

					-- End of Simulation
					assert 1=1 report "Simulation COMPLETED SUCCESSFULLY - All assertions passed." severity note;
					wait;
				end process stim_proc;

			end architecture Behavioral;
