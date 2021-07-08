-- File: cpu_001.vhd

-- Library boilerplates
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- The pinout of the part
ENTITY cpu_001 IS
  PORT 
  (
		i_clock	: IN std_logic;		-- 50 MHz clock
		i_KEY0	: IN std_logic;		-- KEY0
		o_LED		: OUT std_logic
	);
END cpu_001;

ARCHITECTURE beh OF cpu_001 IS

	signal w_keyBuff	: std_logic;
	
	-- Program Counter
	signal w_loadPC	: std_logic := '0';
	signal w_incPC		: std_logic := '0';
	signal w_PCLDVal	: std_logic_vector(11 downto 0) := x"123";
	signal w_ProgCtr	: std_logic_vector(11 downto 0);
	
	-- Slow clock signals
	signal w_slowPulse	: std_logic;
	
	-- Register File
	signal w_ldRegF	: std_logic := '1';
	signal w_regSel	: std_logic_vector(3 downto 0) := "0000";
	signal w_regFIn	: std_logic_vector(7 downto 0) := x"55";
	signal w_regFOut	: std_logic_vector(7 downto 0);
	
	-- ROM
	signal romData		: std_logic_vector(15 downto 0);
	
BEGIN

	w_keyBuff	<= i_KEY0;
	
	-- Program Counter
	progCtr : ENTITY work.ProgramCounter
	PORT map
   (
		-- Ins
		i_clock		=> i_clock,		-- Clock (50 MHz)
		i_loadPC		=> w_loadPC,	-- Load PC control
		i_incPC		=> w_incPC,		-- Increment PC control
		i_PCLdValr	=> w_PCLDVal,	-- Load PC value
		-- Outs
		o_ProgCtr	=> w_ProgCtr	-- Program Counter
	);
	
	-- Slow clock
	slowClock : ENTITY work.SlowClock
	PORT MAP  (
		i_clock		=> i_clock,
		o_slowClock	=> w_slowPulse
	);
	
	-- Register File
	RegFile : ENTITY work.RegisterFile
	PORT MAP (
		i_clock		=> i_clock,
		i_ldRegF		=> w_ldRegF,
		i_regSel		=> w_regSel,
		i_RegFData	=> w_regFIn,
		o_RegFData	=> w_regFOut
	);
	
	-- ROM
	rom : ENTITY work.ROM_1KW
	PORT map
	(
		clock		=> i_clock,
		address	=> w_ProgCtr(9 downto 0),
		q			=> romData
	);
	
	w_ldRegF		<= '1';				-- Continuously re-load PC
	w_regSel		<= "0000";			-- Ignored
	w_regFIn		<= "00000000";		-- Ignored
	w_PCLDVal	<= x"000";			-- PC Load Address = 0x000
	o_LED 		<= romData(15) when i_KEY0 = '0' else -- LED0
						romData(0);
	

END beh;
