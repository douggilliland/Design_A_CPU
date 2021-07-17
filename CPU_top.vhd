-- -----------------------------------------------------------------------------------------------------------------
-- CPU_top.vhd
-- Calls the CPU and the individual Peripheral units
--
--	16-Bit Processor
-- Peripherals On the FPGA card
--		VDU
--		UART (USB/Serial)
--		Timer Unit
--		3 digit Seven Segment LED
--		KEY0 pushbutton used as reset
--		LED0

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
		i_resetN		: IN std_logic;		-- Reset Pushbutton - KEY0 on FPGA card
		o_LED			: INOUT std_logic;	-- LED0 on FPGA card
		
		-- 3 Digits, 7 Segment Display on FPGA card
		o_SMG_Data	: out std_logic_vector(7 downto 0);		-- 7 segments plus decimal point
		o_Scan_Sig	: out std_logic_vector(2 downto 0);		-- 3 digits
		
		-- VGA - Mapped from 2:2:2 to 5:6:5 on FPGA card
		o_vga_r		: out std_logic_vector(4 downto 0);		-- 5 bits of red on FPGA card
		o_vga_g		: out std_logic_vector(5 downto 0);		-- 6 bits of green on FPGA card
		o_vga_b		: out std_logic_vector(4 downto 0);		-- 5 bits of blue on FPGA card
		o_vga_hs		: OUT std_logic;
		o_vga_vs		: OUT std_logic;
		
		-- J12 on FPGA card
		io_J12		: inout std_logic_vector(36 downto 3) := "00"&x"00000000";
		
		-- UART
		-- USB-to-Serial - on FPGA card
		i_uart_rx	: in std_logic := '1';
		o_uart_tx	: OUT std_logic;
		
		-- SDRAM - Not used but pulled to inactive values
		DRAM_CS_N	: OUT std_logic := '1';
		DRAM_CLK		: OUT std_logic := '0';
		DRAM_CKE		: OUT std_logic := '0';
		DRAM_CAS_N	: OUT std_logic := '1';
		DRAM_RAS_N	: OUT std_logic := '1';
		DRAM_WE_N	: OUT std_logic := '1';
		DRAM_UDQM	: OUT std_logic := '0';
		DRAM_LDQM	: OUT std_logic := '0';
		DRAM_BA		: OUT std_logic_vector(1 downto 0)		:= "00";
		DRAM_ADDR	: OUT std_logic_vector(12 downto 0)		:= "0"&x"000";
		DRAM_DQ		: inout std_logic_vector(15 downto 0)	:= (others=>'Z');
		
		-- Ethernet - Not used but pulled to inactive values
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
		e_mdio		: INOUT std_logic := 'Z'				-- Management Data
		
	);
END CPU_top;

ARCHITECTURE beh OF CPU_top IS
	
	-- Reset debounced and turned into active-low pulse
	signal w_resetClean_n		: std_logic;
	
	-- CPU Peripheral bus
	signal w_peripAddr			: std_logic_vector(7 downto 0);
	signal w_peripDataFromCPU	: std_logic_vector(7 downto 0);
	signal w_peripDataToCPU		: std_logic_vector(7 downto 0) := x"00";
	signal w_peripWr				: std_logic;
	signal w_peripRd				: std_logic;
	
	-- Register write/Read for register to register transfers
	signal W_RegXfer				: std_logic_vector(7 downto 0);
	
	-- Seven Segment Display
	signal w_SevenSegData		: std_logic_vector(11 downto 0);
	
   -- UART
	signal w_serialEn    		: std_logic;							-- 16x Serial Clock
	signal w_UARTDataOut			: std_logic_vector(7 downto 0);
	signal w_UARTWr    			: std_logic;
	signal W_UARTRd    			: std_logic;
	
	-- VDU - VGA
	signal w_videoR				: std_logic_vector(1 downto 0);
	signal w_videoG				: std_logic_vector(1 downto 0);
	signal w_videoB				: std_logic_vector(1 downto 0);
	signal w_VDUDataOut			: std_logic_vector(7 downto 0);
	signal W_VDUWr    			: std_logic;
	signal W_VDURd    			: std_logic;
	
	-- Timer
	signal w_timerAdr				:	std_logic;
	signal w_timerOut				: 	std_logic_vector(7 downto 0);
	
	-- J12 Connectpr
	signal w_io_J12				: std_logic_vector(36 downto 3);
	
	-- GPIO
  signal w_dat0_i    			: std_logic_vector(2 downto 0);
  signal w_dat0_o    			: std_logic_vector(2 downto 0);
  signal w_n_dat0_oe 			: std_logic_vector(2 downto 0);
  signal w_dat2_i    			: std_logic_vector(7 downto 0);
  signal w_dat2_o    			: std_logic_vector(7 downto 0);
  signal w_n_dat2_oe 			: std_logic_vector(7 downto 0);
  signal w_GPIO_Out 				: std_logic_vector(7 downto 0);

 -- Slow clock signals
	signal w_slowPulse			: std_logic;
	
--	-- Signal Tap Logic Analyzer signals
--	attribute syn_keep	: boolean;
--	attribute syn_keep of w_peripAddr			: signal is true;
--	attribute syn_keep of w_peripDataFromCPU			: signal is true;
--	attribute syn_keep of w_peripDataToCPU			: signal is true;

BEGIN

	-- -----------------------------------------------------------------------------------------------------------------
	-- Loopback values
	debounceReset : entity work.Debouncer
		port map
		(
			i_clk				=> i_clock,
			i_PinIn			=> i_resetN,
			o_PinOut			=> w_resetClean_n
		);
		
	-- -----------------------------------------------------------------------------------------------------------------
	-- The CPU
	CPU : ENTITY work.cpu_001
		generic	map ( 
			INST_ROM_SIZE_PASS	=> 512,		-- Instruction ROM size
			STACK_DEPTH_PASS		=> 4			-- JSR/RTS nesting depth - Stack size 2^n - n (4-12 locations)
		)
	PORT map 
	(
		i_clock					=> i_clock,					-- 50 MHz clock
		i_resetN					=> w_resetClean_n,		-- Reset CPU
		i_peripDataToCPU		=> w_peripDataToCPU,		-- Data from the Peripherals to the CPU
		-- Peripheral bus
		o_peripAddr				=> w_peripAddr,			-- Peripher address bus (256 I/O locations)
		o_peripDataFromCPU	=> w_peripDataFromCPU,	-- Data from CPU to Peripherals
		o_peripWr				=> w_peripWr,				-- Write strobe
		o_peripRd				=> w_peripRd				-- Read strobe
	);
	
	-- Peripheral read data mux
	-- Read data memory map
	w_peripDataToCPU <=	
		"0000000"&o_LED							when (w_peripAddr = x"00") else							-- 0X00 = Was: KEY0
		W_RegXfer									when (w_peripAddr = x"01") else							-- 0X01 - Register-to-register transfer latch
		w_SevenSegData(7 downto 0)				when (w_peripAddr = x"02") else							-- 0X02 = 7 SEG BOTTOM 2 NIBBLES
		"0000"&w_SevenSegData(11 downto 8)	when (w_peripAddr = x"03") else							-- 0X03 = 7 SEG UPPER NIBBLE
		w_UARTDataOut								when (w_peripAddr(7 downto 1) = "0000010") else		-- 0X04-0X05 = UART
		w_VDUDataOut								when (w_peripAddr(7 downto 1) = "0000011") else		-- 0X06-0X07 = VDU
		w_timerOut									when (w_peripAddr(7 downto 2) = "000010") else		-- 0X08-0X0B = TIMER
		io_J12(10 downto 3)						when (w_peripAddr = x"0C") else							-- 0X0C = Readback output latch
		io_J12(36 downto 29)						when (w_peripAddr = x"0D") else							-- 0X0D = Readback output latch
		w_GPIO_Out									when (w_peripAddr(7 downto 1) = "0000111") else		-- 0X0E-0x0F = GPIO
		x"00";

	-- -----------------------------------------------------------------------------------------------------------------
	-- Peripherals
	
	-- ____________________________________________________________________________________
	-- CPU Write Latches
	-- Write when w_peripWr and address
	WriteLatches : process (i_clock)
	begin
		if rising_edge(i_clock) then
			if ((w_peripAddr = x"00") and (w_peripWr = '1')) then			-- LED
				o_LED <= w_peripDataFromCPU(0);
			ELSif ((w_peripAddr = x"01") and (w_peripWr = '1')) then		-- Register-to-register transfer
				W_RegXfer <= w_peripDataFromCPU;
			elsif ((w_peripAddr = x"02") and (w_peripWr = '1')) then		-- 7Seg lower 8 bits
				w_SevenSegData(7 downto 0) <= w_peripDataFromCPU;
			elsif ((w_peripAddr = x"03") and (w_peripWr = '1')) then		-- 7Seg upper 4 bits
				w_SevenSegData(11 downto 8) <= w_peripDataFromCPU( 3 downto 0);
			elsif ((w_peripAddr = x"0C") and (w_peripWr = '1')) then		-- J12 input lines
				io_J12(10 downto 3) <= w_peripDataFromCPU;
			end if;
		end if;
	end process;
	
	-- ____________________________________________________________________________________
	-- Seven Segment, 3 digits
   sevSeg : entity work.Loadable_7SD_3LED
	Port map ( 
		i_clock_50Mhz 			=> i_clock,					-- 50 MHZ clock
		i_reset 					=> not w_resetClean_n, 	-- i_reset - active high
		i_displayed_number 	=> w_SevenSegData,		-- 3 digits
		o_Anode_Activate 		=> o_Scan_Sig,				-- 3 Anode signals
		o_LED_out 				=> o_SMG_Data					-- Cathode patterns of 7-segment display
	);
	
	-- ____________________________________________________________________________________
	-- Grant Searle's VGA driver from Multicomp
	-- DGG removed the PS/2 keyboard, Composite output and CTS
	-- Interface matches ACIA software interface address/control/status contents
	o_vga_r <= w_videoR(1)&w_videoR(1)&w_videoR(0)&w_videoR(0)&w_videoR(0);					-- Map VGA pins 2:2:2 to 5:6:5
	o_vga_g <= w_videoG(1)&w_videoG(1)&w_videoG(0)&w_videoG(0)&w_videoG(0)&w_videoG(0);
	o_vga_b <= w_videoB(1)&w_videoB(1)&w_videoB(0)&w_videoB(0)&w_videoB(0);

	W_VDUWr <= '1' when ((w_peripAddr(7 downto 1) = "0000011") and (w_peripWr = '1')) else '0';
	W_VDURd <= '1' when ((w_peripAddr(7 downto 1) = "0000011") and (w_peripRd = '1')) else '0';
	-- Resource usage can be reduced by changing the generics below
	-- EXTENDED_CHARSET=0, COLOUR_ATTS_ENABLED=0 - Uses 3 M9K blocks
	-- EXTENDED_CHARSET=1, COLOUR_ATTS_ENABLED=0 - Uses 4 M9K blocks
	-- EXTENDED_CHARSET=0, COLOUR_ATTS_ENABLED=1 - Uses 5 M9K blocks
	-- EXTENDED_CHARSET=1, COLOUR_ATTS_ENABLED=1 - Uses 6 M9K blocks
	vdu : entity work.ANSIDisplayVGA
	GENERIC map (
		EXTENDED_CHARSET		=> 0,		 		-- 1 = 256 chars
														-- 0 = 128 chars
		COLOUR_ATTS_ENABLED	=> 0,				-- 1 = Color for each character
														-- 0 = Color applied to whole display
		SANS_SERIF_FONT		=> 1				-- 0 => use conventional CGA font
														-- 1 => use san serif font
	)
		port map (
			clk		=> i_clock,
			n_reset	=> w_resetClean_n,
			-- CPU interface
			n_WR		=> not W_VDUWr,
			n_rd		=> not W_VDURd,
			regSel	=> w_peripAddr(0),
			dataIn	=> w_peripDataFromCPU,
			dataOut	=> w_VDUDataOut,
			-- VGA video signals
			hSync		=> o_vga_hs,
			vSync		=> o_vga_vs,
			videoR0	=> w_videoR(0),
			videoR1	=> w_videoR(1),
			videoG0	=> w_videoG(0),
			videoG1	=> w_videoG(1),
			videoB0	=> w_videoB(0),
			videoB1	=> w_videoB(1)
		);
	
	-- ____________________________________________________________________________________
	-- ACIA UART serial interface
	-- Grant Searle's UART driver from Multicomp
	-- Modified by Neal Crook from Grant Searle's code to use rising clk
	--		and to use baud rate enables rather than clocks
	-- https://github.com/nealcrook/multicomp6809
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
			rxClkEn	=> w_serialEn,
			txClkEn	=> w_serialEn,
			rxd		=> i_uart_rx,
			txd		=> o_uart_tx
		);
		
	-- ____________________________________________________________________________________
	-- Baud Rate Generator as an entity with passed baud rate
	-- Legal BAUD_RATE values are 115200, 38400, 19200, 9600, 4800, 2400, 1200, 600, 300
	BaudRateGen : entity work.BaudRate6850
	GENERIC map (
		BAUD_RATE	=>  115200
	)
	PORT map (
		i_CLOCK_50	=> i_clock,
		o_serialEn	=> w_serialEn
	);

	-- ____________________________________________________________________________________
	-- Timer Unit
	w_timerAdr	<=	'1' when (w_peripAddr(7 downto 2) = "000010") else '0';
	timerUnit : entity work.TimerUnit
		port map
		(
			-- Clock and Reset
			i_clk					=> i_clock,
			i_n_reset			=> w_resetClean_n,
			-- The key and LED on the FPGA card 
			i_timerSel			=> w_timerAdr,
			i_writeStrobe		=> w_peripWr,
			i_regSel				=> w_peripAddr(1 downto 0),
			i_dataIn				=> w_peripDataFromCPU,
			o_dataOut			=> w_timerOut
		);
	
	-- ____________________________________________________________________________________
	-- GPIO Unit by Neal Crook - Built for 6809 Multicomp
	-- https://github.com/nealcrook/multicomp6809/blob/master/multicomp/Components/GPIO/gpio.vhd
	gpio : entity WORK.gpio
	port MAP (
        n_reset 	=> w_resetClean_n,
        clk     	=> i_clock,
        hold    	=> '0',
        -- conditioned with chip select externally
        n_wr    	=> not w_peripWr,
        dataIn  	=> w_peripDataFromCPU,
        dataOut 	=> w_GPIO_Out,
        -- 0 for GPIOADR, 1 for GPIODAT
        regAddr 	=> w_peripAddr(0),

        -- GPIO
        dat0_i    => w_dat0_i,
        dat0_o    => w_dat0_o,
        n_dat0_oe => w_n_dat0_oe,

        dat2_i    => w_dat2_i,
        dat2_o    => w_dat2_o,
        n_dat2_oe => w_n_dat2_oe
	);
	-- io_J12(11) 
	
	
	-- io_J12(11) to io_J12(21)
	-- 
   -- pin control.
	-- There's probably an easier way of doing this??
--    gpio_dat0_i <= gpio0;
--    pad_ctl_gpio0: process(gpio_dat0_o, n_gpio_dat0_oe)
--    begin
--      for gpio_bit in 0 to 2 loop
--        if n_gpio_dat0_oe(gpio_bit) = '0' then
--          io_J12(11gpio_bit) <= gpio_dat0_o(gpio_bit);
--        else
--          gpio0(gpio_bit) <= 'Z';
--        end if;
--      end loop;
--    end process;
--
--    gpio_dat2_i <= gpio2;
--    pad_ctl_gpio2: process(gpio_dat2_o, n_gpio_dat2_oe)
--    begin
--      for gpio_bit in 0 to 7 loop
--        if n_gpio_dat2_oe(gpio_bit) = '0' then
--          gpio2(gpio_bit) <= gpio_dat2_o(gpio_bit);
--        else
--          gpio2(gpio_bit) <= 'Z';
--        end if;
--      end loop;
--    end process;
	
	-- ____________________________________________________________________________________
	-- Slow clock - used for debugging CPU
	slowClock : ENTITY work.SlowClock
	PORT MAP  (
		i_clock		=> i_clock,
		o_slowClock	=> w_slowPulse
	);

END beh;
