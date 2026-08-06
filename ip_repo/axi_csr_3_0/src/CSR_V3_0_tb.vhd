----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 19.07.2026 13:43:03
-- Design Name:
-- Module Name: CSR_V3_0_tb - Behavioral
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

entity CSR_V3_0_tb is
	--  Port ( );
end CSR_V3_0_tb;

architecture Behavioral of CSR_V3_0_tb is
	constant    C_CONTROL_STATUS_REG_DATA_WIDTH : integer := 32;
	constant 	C_CONTROL_STATUS_REG_ADDR_WIDTH   : integer := 4;
	constant ENABLE_ACQUISITION_BIT             : integer := 0;
	constant SOFT_RESET_BIT                     : integer := 1;

	-- Status Register Bits:
	constant IS_RUNNING_BIT    : integer := 0;
	constant BUFFER_FULL_BIT   : integer := 1;
	constant IRQ_PENDING_A_BIT : integer := 2;
	constant IRQ_PENDING_B_BIT : integer := 3;

	signal clk_sig                        : std_logic  ;
	signal reset_sig                      : std_logic ;
	signal enable_acquisition_sig         : std_logic := '0';
	signal irq_pending_A_sig              : std_logic := '0';
	signal irq_pending_B_sig              : std_logic := '0';
	signal soft_reset_sig                 : std_logic := '0';
	signal is_running_sig                 : std_logic := '0';
	signal buffer_full_sig                : std_logic := '0';
	signal control_status_reg_awvalid_sig : std_logic := '0';
	signal control_status_reg_awaddr_sig  : std_logic_vector(C_CONTROL_STATUS_REG_ADDR_WIDTH - 1 downto 0);
	signal control_status_reg_awready_sig : std_logic := '0';
	signal control_status_reg_wdata_sig   : std_logic_vector(C_CONTROL_STATUS_REG_DATA_WIDTH - 1 downto 0);
	signal control_status_reg_wvalid_sig  : std_logic := '0';
	signal control_status_reg_wready_sig  : std_logic := '0';
	signal control_status_reg_bresp_sig   : std_logic_vector (1 downto 0);
	signal control_status_reg_bvalid_sig  : std_logic := '0';
	signal ready_A_sig                    : std_logic := '0';
	signal ready_B_sig                    : std_logic := '0';
	signal a_test_done                    : boolean := false;
	signal b_test_done                    : boolean := false;
	signal buffer_test_done               : boolean := false;
	component axi_csr_V3_0 is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line
		-- Parameters of Axi Slave Bus Interface CONTROL_STATUS_REG
		C_CONTROL_STATUS_REG_DATA_WIDTH : integer := 32;
		C_CONTROL_STATUS_REG_ADDR_WIDTH : integer := 4
	);
	port (
		-- Users to add ports here
		is_running  : in std_logic;
		ready_A     : in std_logic;
		ready_B     : in std_logic;
		buffer_full : in std_logic;

		enable_acquisition : out std_logic;
		irq_pending_A      : out std_logic;
		irq_pending_B      : out std_logic;
		soft_reset         : out std_logic;  -- makes possible to reset the whole system from the host side

		-- User ports ends
		-- Do not modify the ports beyond this line
		-- Ports of Axi Slave Bus Interface CONTROL_STATUS_REG
		control_status_reg_aclk    : in  std_logic;
		control_status_reg_aresetn : in  std_logic;
		control_status_reg_awaddr  : in  std_logic_vector(C_CONTROL_STATUS_REG_ADDR_WIDTH - 1 downto 0);
		control_status_reg_awprot  : in  std_logic_vector(2 downto 0);
		control_status_reg_awvalid : in  std_logic;
		control_status_reg_awready : out std_logic;
		control_status_reg_wdata   : in  std_logic_vector(C_CONTROL_STATUS_REG_DATA_WIDTH - 1 downto 0);
		control_status_reg_wstrb   : in  std_logic_vector((C_CONTROL_STATUS_REG_DATA_WIDTH/8) - 1 downto 0);
		control_status_reg_wvalid  : in  std_logic;
		control_status_reg_wready  : out std_logic;
		control_status_reg_bresp   : out std_logic_vector(1 downto 0);
		control_status_reg_bvalid  : out std_logic;
		control_status_reg_bready  : in  std_logic;
		control_status_reg_araddr  : in  std_logic_vector(C_CONTROL_STATUS_REG_ADDR_WIDTH - 1 downto 0);
		control_status_reg_arprot  : in  std_logic_vector(2 downto 0);
		control_status_reg_arvalid : in  std_logic;
		control_status_reg_arready : out std_logic;
		control_status_reg_rdata   : out std_logic_vector(C_CONTROL_STATUS_REG_DATA_WIDTH - 1 downto 0);
		control_status_reg_rresp   : out std_logic_vector(1 downto 0);
		control_status_reg_rvalid  : out std_logic;
		control_status_reg_rready  : in  std_logic
	);
end component;

procedure axi_write (
	data : std_logic_vector(C_CONTROL_STATUS_REG_DATA_WIDTH - 1 downto 0);
	addr : std_logic_vector(C_CONTROL_STATUS_REG_ADDR_WIDTH - 1 downto 0);
	signal awddr   : out std_logic_vector(C_CONTROL_STATUS_REG_ADDR_WIDTH - 1 downto 0);
	signal awvalid : out std_logic;
	signal wdata   : out std_logic_vector(C_CONTROL_STATUS_REG_DATA_WIDTH - 1 downto 0);
	signal wvalid  : out std_logic

)is
begin
	-- AMBA AXI and ACE Protocol Specification: "Document number ARM IHI 0022"
	-- (https://developer.arm.com/documentation/ihi0022/e)

	-- Write destination address
	awddr <= addr;
	wdata <= data;
	awvalid <= '1';
	wvalid <= '1';
	wait until rising_edge(clk_sig) and control_status_reg_awready_sig = '1' and control_status_reg_wready_sig = '1';
	wait for 1 ns;
	awvalid <= '0';
	wvalid <= '0';
	awddr <= (others => '0');

	--read response
	wait until rising_edge(clk_sig) and control_status_reg_bvalid_sig = '1';
	assert control_status_reg_bresp_sig = "00" report "error bresp != 00" severity error;
end procedure axi_write;

begin

UUT : axi_csr_V3_0
generic map (
	C_CONTROL_STATUS_REG_DATA_WIDTH => C_CONTROL_STATUS_REG_DATA_WIDTH,
	C_CONTROL_STATUS_REG_ADDR_WIDTH => C_CONTROL_STATUS_REG_ADDR_WIDTH
	--  ENABLE_ACQUISITION_BIT => ENABLE_ACQUISITION_BIT,
	-- SOFT_RESET_BIT         => SOFT_RESET_BIT,
	-- IS_RUNNING_BIT         => IS_RUNNING_BIT,
	-- BUFFER_FULL_BIT        => BUFFER_FULL_BIT,
	-- IRQ_PENDING_A_BIT      => IRQ_PENDING_A_BIT,
	-- IRQ_PENDING_B_BIT      => IRQ_PENDING_B_BIT,
	-- C_CONTROL_STATUS_REG_DATA_WIDTH => C_CONTROL_STATUS_REG_DATA_WIDTH,
	-- C_CONTROL_STATUS_REG_ADDR_WIDTH => C_CONTROL_STATUS_REG_ADDR_WIDTH
)
port map (
	-- Users to add ports here
	is_running         => is_running_sig,
	ready_A            => ready_A_sig,
	ready_B            => ready_B_sig,
	buffer_full        => buffer_full_sig,
	enable_acquisition => enable_acquisition_sig,
	irq_pending_A      => irq_pending_A_sig,
	irq_pending_B      => irq_pending_B_sig,
	soft_reset         => soft_reset_sig,

	-- AMBA AXI and ACE Protocol Specification: "Document number ARM IHI 0022"
	-- (https://developer.arm.com/documentation/ihi0022/e)

	control_status_reg_aclk    => clk_sig,
	control_status_reg_aresetn => reset_sig,
	control_status_reg_awprot  => "000",
	-- Destination Address:
	control_status_reg_awaddr  => control_status_reg_awaddr_sig,
	control_status_reg_awvalid => control_status_reg_awvalid_sig,
	control_status_reg_awready => control_status_reg_awready_sig,
	-- Data:
	control_status_reg_wdata  => control_status_reg_wdata_sig,
	control_status_reg_wvalid => control_status_reg_wvalid_sig,
	control_status_reg_wready => control_status_reg_wready_sig,
	control_status_reg_wstrb  => "1111",                         -- to write all 4 bytes otherwise no write is performed
	-- Responce:
	control_status_reg_bresp  => control_status_reg_bresp_sig,
	control_status_reg_bvalid => control_status_reg_bvalid_sig,
	-- all read operation no need to test:
	control_status_reg_bready  => '1',
	control_status_reg_araddr  => (others => '0'),
	control_status_reg_arprot  => "000",
	control_status_reg_arvalid => '1',
	control_status_reg_arready => open,
	control_status_reg_rdata   => open,
	control_status_reg_rresp   => open,
	control_status_reg_rvalid  => open,
	control_status_reg_rready  => '1'
);

clk_process : process
begin
	while true loop
		clk_sig <= '0';
		wait for 2 ns;
		clk_sig <= '1';
		wait for 2 ns;
	end loop;
	end process clk_process;

	reset_process : process
	begin
		reset_sig <= '0';
		wait for 5 ns;
		reset_sig <= '1';
		wait for 1 ns;
		assert buffer_full_sig = '0' report "buffer_full_sig must be '0' after reset" severity error;
		assert enable_acquisition_sig = '0' report "enable_acquisition_sig must be '0' after reset" severity error;
		assert soft_reset_sig = '0' report "soft_reset_sig must be '0' after reset" severity error;
		assert is_running_sig = '0' report "is_running_sig must be '0' after reset" severity error;
		assert irq_pending_A_sig = '0' report "irq_pending_A_sig must be '0' after reset" severity error;
		assert irq_pending_B_sig = '0' report "irq_pending_B_sig must be '0' after reset" severity error;
		wait;
	end process reset_process;

	test_irq_pending_A_w1c : process
	begin
		wait until rising_edge(clk_sig);
		ready_A_sig <= '1';
		wait until rising_edge(clk_sig);
		wait for 1 ns;
		assert irq_pending_A_sig = '1' report "Error ready_A_sig is set, but irq_pending_A_sig not set!" severity error;
		wait until rising_edge(clk_sig);
		ready_A_sig <= '0';
		wait until rising_edge(clk_sig);
		assert irq_pending_A_sig = '1' report "Error ready_A_sig set to 0, irq_pending_A_sig should be 1 until W1C!" severity error;
		wait until rising_edge(clk_sig);
		ready_A_sig <= '1';
		wait for 1 ns;
		assert irq_pending_A_sig = '1' report "Toggeling ready_A_sig 1->0 and then 0->1 should have no afffect on irq_pending_A_sig" severity error;
		wait until rising_edge(clk_sig);
		--irq_pending_A_sig <= '0';
		wait for 1 ns;
		assert irq_pending_A_sig = '1' report "irq_pending_A_sig should be only cleared by reset or by host through W1C" severity error;
		wait until rising_edge(clk_sig);
		-- "01"&"00" address for slv_reg1, ignoring tow LSBs that for adressing the bytes in a 32 bit vector
		axi_write((IRQ_PENDING_A_BIT => '1', others => '0'), "01"&"00", control_status_reg_awaddr_sig, control_status_reg_awvalid_sig, control_status_reg_wdata_sig, control_status_reg_wvalid_sig);
		wait for 2 ns;
		assert irq_pending_A_sig = '0' report "irq_pending_A_sig should be cleared!" severity error;
		ready_A_sig <= '0';
		wait until rising_edge(clk_sig);
		ready_A_sig <= '1';
		wait until rising_edge(clk_sig);
		wait for 1 ns;
		assert irq_pending_A_sig = '1' report "Setting irq_pending_A_sig again to '1' after clearing failed" severity error;

		wait until rising_edge(clk_sig);
		is_running_sig <= '1';
		ready_B_sig <= '1';
		wait until rising_edge(clk_sig);
		wait for 1 ns;
		assert Buffer_full_sig = '0' report "Error ready_B_sig is set, but buffer_full_sig not set!" severity error;
		assert irq_pending_B_sig = '1' report "Error ready_B_sig is set, but irq_pending_B_sig not set!" severity error;
		wait until rising_edge(clk_sig);
		ready_B_sig <= '0';
		wait until rising_edge(clk_sig);
		assert irq_pending_B_sig = '1' report "Error ready_B_sig set to 0, irq_pending_B_sig should be 1 until W1C!" severity error;
		wait until rising_edge(clk_sig);
		ready_B_sig <= '1';
		wait for 1 ns;
		assert irq_pending_B_sig = '1' report "Toggeling ready_B_sig 1->0 and then 0->1 should have no afffect on irq_pending_B_sig" severity error;
		wait until rising_edge(clk_sig);
		--irq_pending_B_sig <= '0';
		wait for 1 ns;
		assert irq_pending_B_sig = '1' report "irq_pending_B_sig should be only cleared by reset or by host through W1C" severity error;
		wait until rising_edge(clk_sig);
		-- "01"&"00" address for slv_reg1, ignoring tow LSBs that for adressing the bytes in a 32 bit vector
		axi_write((IRQ_PENDING_B_BIT => '1', others => '0'), "01"&"00", control_status_reg_awaddr_sig, control_status_reg_awvalid_sig, control_status_reg_wdata_sig, control_status_reg_wvalid_sig);
		wait for 2 ns;
		assert irq_pending_B_sig = '0' report "irq_pending_B_sig should be cleared!" severity error;
		ready_B_sig <= '0';
		wait until rising_edge(clk_sig);
		ready_B_sig <= '1';
		wait until rising_edge(clk_sig);
		wait for 1 ns;
		assert irq_pending_B_sig = '1' report "Setting irq_pending_B_sig again to '1' after clearing failed" severity error;

		wait until rising_edge(clk_sig);
		axi_write((SOFT_RESET_BIT => '1', others => '0'), "00"&"00", control_status_reg_awaddr_sig, control_status_reg_awvalid_sig, control_status_reg_wdata_sig, control_status_reg_wvalid_sig);
		wait until rising_edge(clk_sig);
		assert enable_acquisition_sig = '0' report "enable_acquisition_sig must be '0' after soft_reset" severity error;
		assert soft_reset_sig = '1' report "soft_reset_sig must be '1' after soft_reset" severity error;
		assert irq_pending_A_sig = '0' report "irq_pending_A_sig must be '0' after soft_reset" severity error;
		assert irq_pending_B_sig = '0' report "irq_pending_B_sig must be '0' after soft_reset" severity error;
		wait until rising_edge(clk_sig);
		-- soft_reset_sig <= '0'; -- not needed because the soft_reset_sig is cleared by the axi_csr_V3_0 module itself after one clock (AXI_ACLK) cycle
		wait until rising_edge(clk_sig);
		assert enable_acquisition_sig = '0' report "enable_acquisition_sig must be '0' after soft_reset" severity error;
		assert soft_reset_sig = '0' report "soft_reset_sig must be '0' after soft_reset" severity error;
		assert irq_pending_A_sig = '0' report "irq_pending_A_sig must be '0' after soft_reset" severity error;
		assert irq_pending_B_sig = '0' report "irq_pending_B_sig must be '0' after soft_reset" severity error;
		wait;
	end process test_irq_pending_A_w1c;

	end Behavioral;
