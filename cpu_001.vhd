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
	
	-- Opcode decoder
	signal OP_LRI		: std_logic;
	signal OP_IOR		: std_logic;
	signal OP_IOw		: std_logic;
	signal OP_ARI		: std_logic;
	signal OP_BEZ		: std_logic;
	signal OP_BNZ		: std_logic;
	signal OP_JMP		: std_logic;
	
	-- Peripheral bus
	signal w_peripAddr				: std_logic_vector(7 downto 0);
	signal w_peripDataFromCPU	: std_logic_vector(7 downto 0);
	signal w_peripDataToCPU		: std_logic_vector(7 downto 0) := x"00";
	signal w_peripWr				: std_logic;
	signal w_peripRd				: std_logic;
	
	-- ALU
	signal ALUDataOut				: std_logic_vector(7 downto 0) := x"00";
	
BEGIN

	w_keyBuff	<= i_KEY0;
	
	OP_LRI <= '1' when romData(15 downto 12) = "0010" else '0';
	OP_IOR <= '1' when romData(15 downto 12) = "0110" else '0';
	OP_IOW <= '1' when romData(15 downto 12) = "0111" else '0';
	OP_ARI <= '1' when romData(15 downto 12) = "1000" else '0';
	OP_BEZ <= '1' when romData(15 downto 12) = "1100" else '0';
	OP_BNZ <= '1' when romData(15 downto 12) = "1101" else '0';
	OP_JMP <= '1' when romData(15 downto 12) = "1110" else '0';
	
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
	
	w_regFIn <= w_peripDataToCPU 		when OP_IOR = '1' else
					ALUDataOut				when OP_ARI = '1' else
					romData(7 downto 0)	when OP_LRI = '1' else
					x"00";
	
	-- ROM
	rom : ENTITY work.ROM_1KW
	PORT map
	(
		clock		=> i_clock,
		address	=> w_ProgCtr(9 downto 0),
		q			=> romData
	);
	
	-- Peripheral bus
	w_peripAddr				<= romData(7 downto 0);
	w_peripDataFromCPU	<= w_regFOut;
	w_peripWr				<= '0';
	w_peripRd				<= '0';
	
	
	w_ldRegF		<= '1';				-- Continuously re-load PC
	w_regSel		<= "0000";			-- Ignored
	w_PCLDVal	<= x"000";			-- PC Load Address = 0x000
	o_LED 		<= romData(15) when i_KEY0 = '0' else -- LED0
						romData(0);
	

END beh;
