--	---------------------------------------------------------------------------------------------------------
-- Timer Unit
--	Operates as a On-shot counter with single value
--	Count uS, mSec or secs (allows for different resolutions)
--	Write to count vale starts timer
--	Poll timer status
-- Address	Value			Read/Write	Data
-- 0			uSec Count	Write			0-255 uS count - write starts timer
--	1			mSec Count	Write			0-255 mS count - write starts timer 
--	2			Sec Count	Write			0-255 sec count - write starts timer
--	3			Not Used		Write			Not used
-- 0-3		Status		Read			1 = Count In progresss, 0 = Done
--	---------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use  IEEE.STD_LOGIC_ARITH.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;

entity TimerUnit is
	port
	(
		-- Clock and Reset
		i_clk							: in std_logic := '1';						-- Clock (50 MHz)
		i_n_reset					: in std_logic := '1';						-- KEY2 on FPGA the card
		-- CPU I/F
		i_timerSel					: in std_logic;								-- Timer is being addressed
		i_writeStrobe				: in std_logic;								-- Write strobe (active high)
		i_regSel						: in std_logic_vector(1 downto 0);		-- Resister select
		i_dataIn						: in std_logic_vector(7 downto 0);		-- Data In
		o_dataOut					: out std_logic_vector(7 downto 0)		-- Data Out
	);
	end TimerUnit;

architecture struct of TimerUnit is

	-- 
	signal prescalerUSec		:	std_logic_vector(5 downto 0);		-- Prescale 50 MHz clock to 1 Mhz (count of 50)
	signal w_countuSecs		:	std_logic_vector(9 downto 0);		-- Count Microseconds
	signal w_countmSecs		:	std_logic_vector(9 downto 0);		-- Count Milliseconds
	signal w_countSecs		:	std_logic_vector(7 downto 0);		-- Count seconds
	-- Value from CPU
	signal countValue			:	std_logic_vector(7 downto 0);		-- Up to 255 uSec loaded from the CPU
	-- Clock ticks
	signal uSecTick			:	std_logic;								-- Microseconds tick
	signal mSecTick			:	std_logic;								-- Milliseconds tick
	signal SecTick				:	std_logic;								-- Seconds tick
	-- Status values
	signal clockRunning		:	std_logic;								-- High while the timer is running
	signal mode_uSec			:	std_logic;								-- Running as Microsecond counter
	signal mode_mSec			:	std_logic;								-- Running as Millisecond counter
	signal mode_Sec			:	std_logic;								-- Running as Second counter
	
	-- Signal Tap Logic Analyzer signals
--	attribute syn_keep	: boolean;
--	attribute syn_keep of clockRunning			: signal is true;
--	attribute syn_keep of mode_uSec				: signal is true;
--	attribute syn_keep of mode_mSec				: signal is true;
--	attribute syn_keep of countValue				: signal is true;
--	attribute syn_keep of w_countuSecs			: signal is true;
--	attribute syn_keep of w_countmSecs			: signal is true;
--	attribute syn_keep of w_countSecs			: signal is true;
	
begin
	
	o_dataOut <= "0000000"&clockRunning;
	
	-- Writing to any of the counters starts the clock
	startProcess : PROCESS (i_clk) BEGIN
		if rising_edge(i_clk) then
			if i_n_reset = '0' then						-- Clear at reset
				clockRunning	<= '0';
				prescalerUSec	<= "000000";
				w_countuSecs	<= "0000000000";
				w_countmSecs	<= "0000000000";
				w_countSecs		<= "00000000";
				mode_uSec		<= '0';
				mode_mSec		<= '0';
				mode_Sec			<= '0';
			elsif ((i_timerSel = '1') and (i_writeStrobe = '1')) then		-- Write to the counter
				if (i_regSel = "00") then
					mode_uSec		<= '1';
					mode_mSec		<= '0';
					mode_Sec			<= '0';
					countValue		<= i_dataIn;
					clockRunning	<= '1';
					prescalerUSec	<= "000000";
					w_countuSecs	<= "0000000000";
					w_countmSecs	<= "0000000000";
					w_countSecs		<= "00000000";
				elsif  (i_regSel = "01") then
					mode_uSec		<= '0';
					mode_mSec		<= '1';
					mode_Sec			<= '0';
					countValue		<= i_dataIn;
					clockRunning	<= '1';
					prescalerUSec	<= "000000";
					w_countuSecs	<= "0000000000";
					w_countmSecs	<= "0000000000";
					w_countSecs		<= "00000000";
				elsif (i_regSel = "10") then
					mode_uSec		<= '0';
					mode_mSec		<= '0';
					mode_Sec			<= '1';
					countValue 		<= i_dataIn;
					clockRunning	<= '1';
					prescalerUSec	<= "000000";
					w_countuSecs	<= "0000000000";
					w_countmSecs	<= "0000000000";
					w_countSecs		<= "00000000";
				end if;
			end if;
			if ((mode_uSec = '1') and (w_countuSecs = countValue)) then
				clockRunning	<= '0';
				mode_uSec		<= '0';
			elsif ((mode_mSec = '1') and (w_countmSecs = countValue)) then
				clockRunning	<= '0';
				mode_MSec		<= '0';
			elsif ((mode_Sec = '1') and (w_countSecs = countValue)) then
				clockRunning	<= '0';
				mode_Sec			<= '0';
			end if;
			if clockRunning = '1' then
				if prescalerUSec = 49 then
					prescalerUSec <= "000000";
					uSecTick <= '1';
				else
					prescalerUSec <= prescalerUSec +1;
					uSecTick <= '0';
				end if;
			end if;			
			if uSecTick = '1' then
				IF w_countuSecs = 999 THEN
					w_countuSecs <= "0000000000";
					mSecTick <= '1';
				ELSE
					w_countuSecs <= w_countuSecs + 1;
				END IF;
			else
				mSecTick <= '0';
			END IF;
			if mSecTick = '1' then
				IF w_countmSecs = 999 THEN
					w_countmSecs <= "0000000000";
					SecTick <= '1';
				ELSE
					w_countmSecs <= w_countmSecs + 1;
				END IF;
			else
				SecTick <= '0';
			END IF;
			if SecTick = '1' then
				w_countSecs <= w_countSecs + 1;
			END IF;
		end if;
	END PROCESS;

end;
