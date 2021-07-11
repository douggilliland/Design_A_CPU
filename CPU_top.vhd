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
		
		-- VGA
		vga_r			: out std_logic_vector(4 downto 0);
		vga_g			: out std_logic_vector(5 downto 0);
		vga_b			: out std_logic_vector(4 downto 0);
		vga_hs		: OUT std_logic;
		vga_vs		: OUT std_logic;
		
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
	
	-- Pushbutton
	signal w_keyBuff				: std_logic;

	-- Seven Segment Display
	signal w_SevenSegData		: std_logic_vector(11 downto 0);
	
   -- UART
	signal serialEn     			: std_logic;							-- 16x Serial Clock
	signal w_UARTDataOut			: std_logic_vector(7 downto 0);
	signal w_UARTWr    				: std_logic;
	signal W_UARTRd    				: std_logic;
	
	-- VGA
	signal w_videoR		: std_logic_vector(1 downto 0);
	signal w_videoG		: std_logic_vector(1 downto 0);
	signal w_videoB		: std_logic_vector(1 downto 0);
	signal w_VDUDataOut	: std_logic_vector(7 downto 0);
	signal W_VDUWr    	: std_logic;
	signal W_VDURd    	: std_logic;

	
BEGIN

	-- -----------------------------------------------------------------------------------------------------------------
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
	
	-- -----------------------------------------------------------------------------------------------------------------
	-- Peripherals
	-- Peripheral read data mux
	w_peripDataToCPU <=	"0000000"&w_keyBuff						when (w_peripAddr = x"00") else
								w_SevenSegData(7 downto 0)				when (w_peripAddr = x"02") else
								"0000"&w_SevenSegData(11 downto 8)	when (w_peripAddr = x"03") else
								w_UARTDataOut								when (w_peripAddr(7 downto 1) = "0000010") else
								w_VDUDataOut								when (w_peripAddr(7 downto 1) = "0000011") else
								x"00";
	w_keyBuff	<= i_KEY0;

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
--	w_serialLoopback	<= uart_rx;
--	uart_tx				<= w_serialLoopback;

	-- Seven Segment, 3 digits
	sevSeg : entity work.Loadable_7SD_3LED
   Port map ( 
		i_clock_50Mhz 			=> i_clock,
		i_reset 					=> '0', 					-- i_reset - active high
		i_displayed_number 	=> w_SevenSegData,	-- 3 digits
		o_Anode_Activate 		=> Scan_Sig,			-- 3 Anode signals
		o_LED_out 				=> SMG_Data				-- Cathode patterns of 7-segment display
	);
	vga_r <= w_videoR(1)&w_videoR(1)&w_videoR(0)&w_videoR(0)&w_videoR(0);
	vga_g <= w_videoG(1)&w_videoG(1)&w_videoG(0)&w_videoG(0)&w_videoG(0)&w_videoG(0);
	vga_b <= w_videoB(1)&w_videoB(1)&w_videoB(0)&w_videoB(0)&w_videoB(0);
	
	-- Grant's VGA driver
	W_VDUWr <= '1' when ((w_peripAddr(7 downto 1) = "0000011") and (w_peripWr = '1')) else '0';
	W_VDURd <= '1' when ((w_peripAddr(7 downto 1) = "0000011") and (w_peripRd = '1')) else '0';
	
	vdu : entity work.SBCTextDisplayRGB
		port map (
			clk		=> i_clock,
			n_reset	=> '1',
			-- CPU interface
			n_WR		=> not W_VDUWr,
			n_rd		=> not W_VDURd,
			regSel	=> w_peripAddr(0),
			dataIn	=> w_peripDataFromCPU,
			dataOut	=> w_VDUDataOut,
			-- VGA video signals
			hSync		=> vga_hs,
			vSync		=> vga_vs,
			videoR0	=> w_videoR(0),
			videoR1	=> w_videoR(1),
			videoG0	=> w_videoG(0),
			videoG1	=> w_videoG(1),
			videoB0	=> w_videoB(0),
			videoB1	=> w_videoB(1)
			-- PS/2 keyboard
--			ps2Clk	=> io_ps2Clk,
--			ps2Data	=> io_ps2Data
		);
	
	-- ACIA UART serial interface
	w_UARTWr <= '1' when ((w_peripAddr(7 downto 1) = "0000010") and (w_peripWr = '1')) else '0';
	W_UARTRd <= '1' when ((w_peripAddr(7 downto 1) = "0000010") and (w_peripRd = '1')) else '0';

	acia: entity work.bufferedUART
		port map (
			clk		=> i_clock,     
			n_WR		=> not w_UARTWr,
			n_rd		=> not W_UARTRd,
			regSel	=> w_peripAddr(0),
			dataIn	=> w_peripDataFromCPU,
			dataOut	=> w_UARTDataOut,
			rxClkEn	=> serialEn,
			txClkEn	=> serialEn,
			rxd		=> uart_rx,
			txd		=> uart_tx
		);
		
	-- ____________________________________________________________________________________
	-- Baud Rate Generator
	-- Legal BAUD_RATE values are 115200, 38400, 19200, 9600, 4800, 2400, 1200, 600, 300
	BaudRateGen : entity work.BaudRate6850
	GENERIC map (
		BAUD_RATE	=>  115200
	)
	PORT map (
		i_CLOCK_50	=> i_clock,
		o_serialEn	=> serialEn
	);

	-- Slow clock - used for debugging CPU
	slowClock : ENTITY work.SlowClock
	PORT MAP  (
		i_clock		=> i_clock,
		o_slowClock	=> w_slowPulse
	);
	
END beh;
