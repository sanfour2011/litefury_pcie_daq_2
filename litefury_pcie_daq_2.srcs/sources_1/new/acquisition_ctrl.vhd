----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 11.07.2026 19:55:30
-- Design Name:
-- Module Name: acquisition_ctrl - Behavioral
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

entity acquisition_ctrl is

	port (
		clk              : in  std_logic;
		rst_n            : in  std_logic;
		acq_en           : in  std_logic;                      -- Acquisition enable signal, to start/stop generating samples
		src_sample       : in  std_logic_vector(31 downto 0);
		src_sample_valid : in  std_logic;
		is_running       : out std_logic;
		sample_ready_out : out std_logic;                      -- Signal indicating that a new sample is ready
		sample_out       : out std_logic_vector(31 downto 0)

	);
end acquisition_ctrl;

architecture Behavioral of acquisition_ctrl is

begin

	u_process_1 : process (clk, rst_n)
	begin
		if rst_n = '0' then
			is_running <= '0';
		elsif rising_edge(clk) then
			is_running <= acq_en;
		end if;
	end process u_process_1;

	sample_ready_out <= src_sample_valid when acq_en = '1' else '0';
	sample_out <= src_sample;

end Behavioral;
