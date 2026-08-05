----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 02.08.2026 14:20:45
-- Design Name:
-- Module Name: ping_pong_ctrl - Behavioral
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

entity ping_pong_ctrl is
	generic (
		mem_size   : integer := 2048*2;  -- Size of the buffer in samples
		data_width : integer := 32 ;     -- Width of the data bus in bits
		addr_width : integer := 12       -- Width of the address bus in bits
	);
	port (
		clk            : in  std_logic;
		rst_n          : in  std_logic;
		data_in        : in  std_logic_vector(data_width-1 downto 0);
		data_valid     : in  std_logic;
		write_enable_A : in  std_logic;
		write_enable_B : in  std_logic;
		ready_A        : out std_logic;
		ready_B        : out std_logic;
		mem_addr       : out std_logic_vector (addr_width-1 downto 0);
		mem_data_out   : out std_logic_vector(data_width-1 downto 0);
		mem_we         : out std_logic
	);
end ping_pong_ctrl;

architecture Behavioral of ping_pong_ctrl is
	signal current_addr_sig : std_logic_vector(addr_width-1 downto 0) := (others => '0');
	constant max_addr       : integer := mem_size - 1;
	constant half_mem_size  : integer := (mem_size / 2)-1;

begin
	u_process : process (clk, rst_n)
	variable write_enable_A_prev : std_logic := '0';
	variable write_enable_B_prev : std_logic := '0';

	begin
		if rst_n = '0' then
			current_addr_sig <= (others => '0');
			write_enable_A_prev := '0';
			ready_A <= '0';
			ready_B <= '0';
			write_enable_B_prev := '0';
			mem_addr <= (others => '0');
			mem_we <= '0';
			mem_data_out <= (others => '0');

		elsif rising_edge(clk) then
			
			mem_we <= '0';

			if write_enable_A = '1' and write_enable_A_prev = '0' then
				ready_A <= '0';
			end if;

			if write_enable_B = '1' and write_enable_B_prev = '0' then
				ready_B <= '0';
			end if;

			if  write_enable_A = '1' and data_valid = '1' then
				if (unsigned(current_addr_sig) <= half_mem_size) then
					current_addr_sig <= std_logic_vector (unsigned(current_addr_sig) +1);
					mem_we <= '1';
					if unsigned(current_addr_sig) = half_mem_size then
						ready_A <= '1';
					end if;
				end if;
			end if;

			if  write_enable_B = '1' and data_valid = '1' then
				if(unsigned(current_addr_sig) <= max_addr and unsigned(current_addr_sig) > half_mem_size) then
					current_addr_sig <= std_logic_vector (unsigned(current_addr_sig) +1);
					mem_we <= '1';
					if unsigned(current_addr_sig) = max_addr then
						ready_B <= '1';
					end if;
				end if;
			end if;

			write_enable_B_prev := write_enable_B;
			write_enable_A_prev := write_enable_A;
			mem_data_out <= data_in;
			mem_addr <= current_addr_sig;

		end if;
	end process u_process;

end Behavioral;
