library ieee;

use ieee.NUMERIC_STD.all;
use ieee.STD_LOGIC_1164.all;

entity top_level is
	port (
		-- Pins aus deiner top.xdc
		pcie_clkin_clk_n : in  std_logic_vector(0 to 0);
		pcie_clkin_clk_p : in  std_logic_vector(0 to 0);
		pcie_reset       : in  std_logic;
		pcie_clkreq_l    : out std_logic;

		-- Pins aus deiner early.xdc
		pcie_mgt_rxn : in  std_logic_vector (3 downto 0);
		pcie_mgt_rxp : in  std_logic_vector (3 downto 0);
		pcie_mgt_txn : out std_logic_vector (3 downto 0);
		pcie_mgt_txp : out std_logic_vector (3 downto 0);

		-- Pins aus deiner normal.xdc
		ledn : out std_logic_vector (3 downto 0);
		-- sysclk_p : IN STD_LOGIC;
		-- sysclk_n : IN STD_LOGIC
		sysclk_p : in std_logic;  -- liteury internal clk 200 MHz
		sysclk_n : in std_logic   -- liteury internal clk 200 MHz
	);
end top_level;

architecture Behavioral of top_level is
	constant BRAM_SIZE      : integer := 2048;         -- number of 32-bit samples (words) that the BRAM is holding and NOT bytes: 2048 words x 4 bytes = 8192 bytes total.
	constant SAMPLE_RATE_Hz : integer := 30;           -- at 30 samples/s, filling 2048 samples takes ~1 min , convenient for manual hardware tests via RWEverything.
	constant CLK_FREQ_Hz    : integer := 200_000_000;

	component IBUFDS is
	port (
		O  : out std_logic;  -- 1-bit output: Buffer output
		I  : in  std_logic;  -- 1-bit input: Diff_p buffer input (connect directly to top-level port)
		IB : in  std_logic
	); -- 1-bit input: Diff_n buffer input (connect directly to top-level port)
end component IBUFDS;

attribute ASYNC_REG : string;             --K�nnte man auch im xdc setzen, aber hier ist es einfacher: set_property ASYNC_REG TRUE [get_cells {FF1_reg FF2_reg}]

signal sys_clk              : std_logic;
signal soft_rst_pci_rst_sig : std_logic := '1';
signal tick_1Hz             : std_logic;
signal count                : std_logic_vector(3 downto 0) := (others => '0');  -- 4-bit counter

--CSR
signal enable_acquisition_sig : std_logic;

signal irq_pending_A_sig                        : std_logic;
signal irq_pending_A_sig_synced                 : std_logic;
signal irq_pending_A_FF1                        : std_ulogic := '0';
attribute ASYNC_REG of irq_pending_A_FF1        : signal is "TRUE";
attribute ASYNC_REG of irq_pending_A_sig_synced : signal  is "TRUE";

signal irq_pending_B_sig                        : std_logic;
signal irq_pending_B_sig_synced                 : std_logic;
signal irq_pending_B_FF1                        : std_ulogic := '0';
attribute ASYNC_REG of irq_pending_B_FF1        : signal is "TRUE";
attribute ASYNC_REG of irq_pending_B_sig_synced : signal  is "TRUE";

signal is_running_sig  : std_logic;
signal buffer_full_sig : std_logic;

signal FF1_reg                                   : std_ulogic := '0';
signal enable_acquisition_synced                 : std_ulogic := '0';  -- Synchronisiertes Signal for enable_acquisition (Hint CDC)
attribute ASYNC_REG of FF1_reg                   : signal is "TRUE";
attribute ASYNC_REG of enable_acquisition_synced : signal is "TRUE";

signal soft_reset_sig                        : std_logic;
signal soft_reset_FF1                        : std_ulogic := '0';
signal soft_reset_sig_synced                 : std_logic;
attribute ASYNC_REG of soft_reset_FF1        : signal is "TRUE";
attribute ASYNC_REG of soft_reset_sig_synced : signal  is "TRUE";

-- BRAM
signal BRAM_PORTB_0_addr_sig : std_logic_vector (31 downto 0) := (others => '0');
signal BRAM_PORTB_0_we_sig   : std_logic_vector (3 downto 0) := (others => '0');
signal BRAM_PORTB_0_rst_sig  : std_logic;                                          -- unfortnattly we need a reset signal for the BRAM, because its reset
signal sample_valid_sig      : std_logic;                                          -- Signal to indicate when the sample is valid
signal sawtooth_out_sig      : std_logic_vector (31 downto 0) := (others => '0');  -- 32-bit sawtooth output

--irq
signal usr_irq_req_sig                        : std_logic_vector (1 downto 0);
signal usr_irq_ack_sig                        : std_logic_vector (1 downto 0);
signal usr_irq_req_A_sig, usr_irq_req_B_sig   : std_logic := '0';
signal msi_enable_sig                         : std_logic;
signal msi_vector_width_sig                   : std_logic_vector (2 downto 0);
signal usr_irq_ack_FF1                        : std_ulogic := '0';
signal usr_irq_ack_sig_sycend                 : std_logic_vector (0 downto 0);
attribute ASYNC_REG of usr_irq_ack_FF1        : signal is "TRUE";
attribute ASYNC_REG of usr_irq_ack_sig_sycend : signal is "TRUE";
signal usr_irq_ack_A_sig                      : std_logic := '0';
signal usr_irq_ack_B_sig                      : std_logic := '0';

constant IDLE                             : std_logic_vector(2 downto 0) := "000";
constant WAIT_FOR_HOST_ACK                : std_logic_vector(2 downto 0) := "010";
constant WAIT_FOR_IRQ_PENDING_CLEARED     : std_logic_vector(2 downto 0) := "100";
signal next_state_A_sig, next_state_B_sig : std_logic_vector(2 downto 0) := IDLE;

--ping_pong_ctrl
signal write_enable_A_sig   : std_logic := '0';
signal write_enable_B_sig   : std_logic := '0';
signal ready_A_sig          : std_logic := '0';
signal ready_B_sig          : std_logic := '0';
signal BRAM_PORTB_0_din_sig : std_logic_vector (31 downto 0) := (others => '0');
signal mem_addr_out_sig     : std_logic_vector (12 downto 0) := (others => '0');
signal ping_pong_we_sig     : std_logic;

begin

efury_sys_clk : IBUFDS
port map (
	O  => sys_clk,   -- 1-bit output: Buffer output
	I  => sysclk_p,  -- 1-bit input: Diff_p buffer input (connect directly to top-level port)
	IB => sysclk_n   -- 1-bit input: Diff_n buffer input (connect directly to top-level port)
);

tick_gen_inst : entity work.tick_gen
generic map (
	TICK_RATE_HZ => 1,           -- 1 Hz
	CLK_FREQ_HZ  => CLK_FREQ_Hz  -- 200 MHz
)
port map (
	rst_n  => soft_rst_pci_rst_sig,
	tick   => tick_1Hz,
	sysclk => sys_clk
);
acquisition_ctrl_inst : entity work.acquisition_ctrl
generic map (
	buffer_size    => BRAM_SIZE,
	sample_rate_hz => SAMPLE_RATE_Hz,
	clk_freq_hz    => CLK_FREQ_Hz
)
port map (
	clk          => sys_clk,
	rst_n        => soft_rst_pci_rst_sig,
	acq_en       => enable_acquisition_synced,
	is_running   => is_running_sig,
	sample_ready => sample_valid_sig,
	sample_out   => sawtooth_out_sig
);

ping_pong_ctrl_inst : entity work.ping_pong_ctrl
generic map (
	mem_size   => BRAM_SIZE,
	data_width => 32,
	addr_width => 13
)	
port map (
	clk            => sys_clk,
	rst_n          => soft_rst_pci_rst_sig,
	data_in        => sawtooth_out_sig,
	data_valid     => sample_valid_sig,
	write_enable_A => write_enable_A_sig,
	write_enable_B => write_enable_B_sig,
	ready_A        => ready_A_sig,
	ready_B        => ready_B_sig,
	mem_addr       => mem_addr_out_sig,      -- just a adress counter starting from 0 to mem_size -1
	mem_data_out   => BRAM_PORTB_0_din_sig,
	mem_we         => ping_pong_we_sig
);

--ToDo: Siehe PCIe Takt-Anforderung auf Low setzen, sollte nicht immer aktiv sein,
-- nur bei bedarf, windows treiber können das auch steuern, 
--aber für die Demo ist es in Ordnung:
pcie_clkreq_l <= '0';-- PCIe Takt-Anforderung dauerhaft auf Aktiv (Low)

-- Das Port-Mapping verbindet die Wrapper-Ports mit deinen Top-Level-Pins
block_design_inst : entity work.design_1_wrapper
port map (
	pcie_clkin_clk_clk_n  => pcie_clkin_clk_n,
	pcie_clkin_clk_clk_p  => pcie_clkin_clk_p,
	pcie_7x_mgt_rtl_0_rxn => pcie_mgt_rxn,
	pcie_7x_mgt_rtl_0_rxp => pcie_mgt_rxp,
	pcie_7x_mgt_rtl_0_txn => pcie_mgt_txn,
	pcie_7x_mgt_rtl_0_txp => pcie_mgt_txp,

	pcie_reset => pcie_reset,

	--Added by me:
	--GPIOs:
	ledn    => open,     --ledn,
	sys_clk => sys_clk,
	--CSR Control status Register:
	enable_acquisition => enable_acquisition_sig,
	is_running         => is_running_sig,
	irq_pending_A      => irq_pending_A_sig,
	irq_pending_B      => irq_pending_B_sig,
	soft_reset         => soft_reset_sig,
	ready_A            => ready_A_sig,
	ready_B            => ready_B_sig,

	--Bram Port B:
	rsta_busy_0       => open,
	rstb_busy_0       => open,
	BRAM_PORTB_0_addr => BRAM_PORTB_0_addr_sig,
	BRAM_PORTB_0_clk  => sys_clk,
	BRAM_PORTB_0_din  => BRAM_PORTB_0_din_sig,
	BRAM_PORTB_0_dout => open,
	BRAM_PORTB_0_en   => '1',                    -- optional
	BRAM_PORTB_0_rst  => BRAM_PORTB_0_rst_sig,
	BRAM_PORTB_0_we   => BRAM_PORTB_0_we_sig,

	-- Interrupt
	usr_irq_ack_A    => usr_irq_ack_A_sig,
	usr_irq_ack_B    => usr_irq_ack_B_sig,
	usr_irq_req      => usr_irq_req_sig,
	usr_irq_ack      => usr_irq_ack_sig,
	msi_enable       => msi_enable_sig,
	msi_vector_width => msi_vector_width_sig
);

u_process_1 : process (sys_clk)
begin

	if rising_edge(sys_clk) then
		FF1_reg <= enable_acquisition_sig;
		enable_acquisition_synced <= FF1_reg;

		soft_reset_FF1 <= soft_reset_sig;
		soft_reset_sig_synced <= soft_reset_FF1;

		usr_irq_ack_FF1 <= usr_irq_ack_sig(0);
		usr_irq_ack_sig_sycend <= (others => usr_irq_ack_FF1);
	end if;

end process u_process_1;

irq_handler_A : process (sys_clk, soft_rst_pci_rst_sig)
begin
	if soft_rst_pci_rst_sig = '0' then
		next_state_A_sig <= IDLE;
		usr_irq_req_A_sig <= '0';

	elsif rising_edge(sys_clk) then

		irq_pending_A_FF1 <= irq_pending_A_sig;
		irq_pending_A_sig_synced <= irq_pending_A_FF1;
		case next_state_A_sig is
			when IDLE =>
				if (ready_A_sig  = '1') then
					usr_irq_req_A_sig <= '1';			
					next_state_A_sig <= WAIT_FOR_HOST_ACK;
				end if;
			when WAIT_FOR_HOST_ACK =>
				if (usr_irq_ack_A_sig = '1') then 
					usr_irq_req_A_sig <= '0';
					next_state_A_sig <= WAIT_FOR_IRQ_PENDING_CLEARED;
				end if;
			when WAIT_FOR_IRQ_PENDING_CLEARED =>
				-- Ensure ready_A is deasserted within the current clock cycle to prevent a race condition and false IRQ re-trigger.
				if (irq_pending_A_sig_synced = '0'and ready_A_sig = '0') then
					usr_irq_req_A_sig <= '0';
					next_state_A_sig <= IDLE;
				end if;
			when others =>
				null;
		end case;		
	end if;
	-- buffer = 1 -> usr_irq_req_sig <= '1' -> wait usr_irq_ack_sig = 1 -> wait irq_pending =1 -> irq_reg_sig = 0
end process irq_handler_A;

irq_handler_B : process (sys_clk, soft_rst_pci_rst_sig)
begin
	if soft_rst_pci_rst_sig = '0' then
		usr_irq_req_B_sig <= '0';
		next_state_B_sig <= IDLE;

	elsif rising_edge(sys_clk) then

		irq_pending_B_FF1 <= irq_pending_B_sig;
		irq_pending_B_sig_synced <= irq_pending_B_FF1;
		case next_state_B_sig is
			when IDLE =>
				if (ready_B_sig  = '1') then
					usr_irq_req_B_sig <= '1';			
					next_state_B_sig <= WAIT_FOR_HOST_ACK;
				end if;
			when WAIT_FOR_HOST_ACK =>
				if (usr_irq_ack_B_sig = '1') then 
					usr_irq_req_B_sig <= '0';	
					next_state_B_sig <= WAIT_FOR_IRQ_PENDING_CLEARED;
				end if;
			when WAIT_FOR_IRQ_PENDING_CLEARED =>
				-- Ensure ready_B is deasserted within the current clock cycle to prevent a race condition and false IRQ re-trigger.
				if (irq_pending_B_sig_synced = '0' and ready_B_sig = '0') then 
					usr_irq_req_B_sig <= '0';
					next_state_B_sig <= IDLE;
				end if;
			when others =>
				null;
		end case;		
	end if;
	-- buffer = 1 -> usr_irq_req_sig <= '1' -> wait usr_irq_ack_sig = 1 -> wait irq_pending =1 -> irq_reg_sig = 0
end process irq_handler_B;

-- heart beat process for LEDs, shows that every thing is working
Heart_beat : process (sys_clk, soft_rst_pci_rst_sig)
begin
	if soft_rst_pci_rst_sig = '0' then
		count <= (others => '0'); -- Reset: Alle LEDs an
	elsif rising_edge(sys_clk) then
		if tick_1Hz = '1' and enable_acquisition_synced = '1' then
			count <= std_logic_vector(unsigned(count) + 1);
		elsif tick_1Hz = '1' then
			count <= not count;
		end if;
	end if;
end process Heart_beat;

write_enable_A_sig <= not irq_pending_A_sig_synced;
write_enable_B_sig <= not irq_pending_B_sig_synced;

usr_irq_req_sig(0) <= usr_irq_req_A_sig; 
usr_irq_req_sig(1) <= usr_irq_req_B_sig;

BRAM_PORTB_0_rst_sig <= not soft_rst_pci_rst_sig; --bram reset is active high, soft_rst_pci_rst_sig is active low
BRAM_PORTB_0_addr_sig <= (16 downto 0 => '0') & mem_addr_out_sig & "00";
BRAM_PORTB_0_we_sig <= (3 downto 0 => ping_pong_we_sig);

soft_rst_pci_rst_sig <= pcie_reset and not soft_reset_sig_synced; -- soft reset is active high, pcie_reset is active low, so we need to invert it
ledn <= not count; -- LEDs zeigen den Zählerstand an
buffer_full_sig <= ready_A_sig and ready_B_sig;
end Behavioral;
