-- CPU_top.vhd
-- Calls the CPU and the individual Peripheral units

-- Library boilerplates
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- The pinout of the part
ENTITY CPU_top IS
  PORT 
  (
		i_clock		: IN std_logic;		-- 50 MHz clock
		i_KEY0		: IN std_logic;		-- KEY0
		o_LED			: OUT std_logic;
		
		-- SDRAM - Not used
		DRAM_CS_N	: OUT std_logic := '1';
		DRAM_CLK		: OUT std_logic := '0';
		DRAM_CKE		: OUT std_logic := '0';
		DRAM_CAS_N	: OUT std_logic := '1';
		DRAM_RAS_N	: OUT std_logic := '1';
		DRAM_WE_N	: OUT std_logic := '1';
		DRAM_UDQM	: OUT std_logic := '0';
		DRAM_LDQM	: OUT std_logic := '0';
		DRAM_BA		: OUT std_logic_vector(1 downto 0) := "00";
		DRAM_ADDR	: OUT std_logic_vector(12 downto 0) := "0"&x"000";
		DRAM_DQ		: inout std_logic_vector(15 downto 0) := (others=>'Z');
		
		-- Ethernet
		-- Ins
		e_rxc			: IN std_logic := '0';
		e_rxdv		: IN std_logic := '0';					-- Rx Data Valid
		e_rxer		: IN std_logic := '0';					-- Transmit error
		e_rxd			: IN std_logic_vector(7 downto 0);	-- Tx data
		e_txc			: in std_logic := '0';					-- Tx clock
		-- Outs
		e_mdc			: OUT std_logic := '0';					-- Management Data Clock
		e_gtxc		: OUT std_logic := '0';
		e_reset		: OUT std_logic := '0';					-- Hold in reset (low)
		e_txen		: OUT std_logic := '0';
		e_txer		: OUT std_logic := '0';
		e_txd			: OUT std_logic_vector(7 downto 0) := X"00";
		e_mdio		: INOUT std_logic := 'Z';				-- Management Data
		
		-- 3 Digits, 7 Segment Display
		SMG_Data		: out std_logic_vector(7 downto 0);
		Scan_Sig		: out std_logic_vector(2 downto 0);
		
		-- UART
		uart_rx		: in std_logic := '1';
		uart_tx		: OUT std_logic
		
	);
END CPU_top;

ARCHITECTURE beh OF CPU_top IS
	
	-- Slow clock signals
	signal w_slowPulse	: std_logic;
	
	-- Peripheral bus
	signal w_peripAddr			: std_logic_vector(7 downto 0);
	signal w_peripDataFromCPU	: std_logic_vector(7 downto 0);
	signal w_peripDataToCPU		: std_logic_vector(7 downto 0) := x"00";
	signal w_peripWr				: std_logic;
	signal w_peripRd				: std_logic;
	
	-- Peripherals
	signal w_serialLoopback		: std_logic;
	
	-- Pushbutton
	signal w_keyBuff				: std_logic;

	-- Test Register
--	signal w_PerTestReg			: std_logic_vector(7 downto 0);
--	signal w_peripTRWr			: std_logic;
--	signal w_peripTRRd			: std_logic;
	
	-- Seven Segment Display
	signal w_SevenSegData		: std_logic_vector(11 downto 0);
	
BEGIN

	-- The CPU
	CPU : ENTITY work.cpu_001
	PORT map 
	(
		i_clock					=> i_clock,					-- 50 MHz clock
		i_peripDataToCPU		=> w_peripDataToCPU,
		-- Peripheral bus
		o_peripAddr				=> w_peripAddr,
		o_peripDataFromCPU	=> w_peripDataFromCPU,
		o_peripWr				=> w_peripWr,
		o_peripRd				=> w_peripRd
	);
	-- Peripheral read data mux
	w_peripDataToCPU <=	"0000000"&w_keyBuff when (w_peripAddr = x"00") else
								x"00";
	w_keyBuff	<= i_KEY0;

	-- Slow clock - used for debugging CPU
	slowClock : ENTITY work.SlowClock
	PORT MAP  (
		i_clock		=> i_clock,
		o_slowClock	=> w_slowPulse
	);
	
	-- CPU Write Latches
	latchLED : process (i_clock)
	begin
		if rising_edge(i_clock) then
			if ((w_peripAddr = x"00") and (w_peripWr = '1')) then		-- LED
				o_LED <= w_peripDataFromCPU(0);
			elsif ((w_peripAddr = x"02") and (w_peripWr = '1')) then	-- 7Seg lower 8 bits
				w_SevenSegData(7 downto 0) <= w_peripDataFromCPU;
			elsif ((w_peripAddr = x"03") and (w_peripWr = '1')) then	-- 7Seg upper 4 bits
				w_SevenSegData(11 downto 8) <= w_peripDataFromCPU( 3 downto 0);
			end if;
		end if;
	end process;
	
	-- USB-Serial for UART
	w_serialLoopback	<= uart_rx;
	uart_tx				<= w_serialLoopback;

	-- Seven Segment, 3 digits
	sevSeg : entity work.Loadable_7SD_3LED
   Port map ( 
		i_clock_50Mhz 			=> i_clock,
		i_reset 					=> '0', 					-- i_reset - active high
		i_displayed_number 	=> w_SevenSegData,	-- 3 digits
		o_Anode_Activate 		=> Scan_Sig,			-- 3 Anode signals
		o_LED_out 				=> SMG_Data				-- Cathode patterns of 7-segment display
	);	
	
END beh;
