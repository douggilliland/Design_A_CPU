-- File: PeripheralUnit.vhd

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


ENTITY PeripheralUnit IS
  PORT  (
		-- Ins
		i_clock					: IN std_logic;		-- Clock (50 MHz)
		i_peripWr				: IN std_logic;		-- Peripheral Write Strobe
		i_peripRd				: IN std_logic;		-- Peripheral Read Strove
		i_peripAddr				: in std_logic_vector(7 downto 0);
		i_peripDataFromCPU	: in std_logic_vector(7 downto 0);
		-- Outs
		o_peripDataToCPU		: out std_logic_vector(7 downto 0)
	);
END PeripheralUnit;

ARCHITECTURE beh OF PeripheralUnit IS

	signal w_keyBuff	: std_logic;
	
	-- Peripheral bus
	signal w_peripAddr			: std_logic_vector(7 downto 0);
	signal w_peripDataFromCPU	: std_logic_vector(7 downto 0);
	signal w_peripDataToCPU		: std_logic_vector(7 downto 0);
	signal w_peripWr				: std_logic;
	signal w_peripRd				: std_logic;
	
BEGIN

--	w_peripTRWr <= '1' when w_peripAddr = x"AA" else '0';
--	w_peripTRRd <= '1' when w_peripAddr = x"55" else '0';
--	
--	-- Peripheral Test Register
--	testPeriphReg : ENTITY work.PeriphTestReg
--	  PORT  MAP (
--			i_clock			=> i_clock,
--			i_wrReg			=> w_peripTRWr,
--			i_periphRegIn	=> i_peripDataFromCPU,
--			o_PeriphRegOut	=> w_PerTestReg
--		);
--	
--	-- Peripheral read data mux
--	w_peripDataToCPU <=	w_PerTestReg when w_peripTRRd = '1' else
--								x"00";
--
--	
--	PeripheralUnit : PROCESS (i_clock)			-- Sensitivity list
--		BEGIN
--			IF rising_edge(i_clock) THEN		-- On clocks
--				w_slowClkCt		<= w_slowClkCt+1;
--				w_slowD1			<= w_slowClkCt(21);
--				w_slowD2			<= w_slowD1;
--				o_PeripheralUnit		<= w_slowD1 and (not w_slowD2);
--			END IF;
--		END PROCESS;
END beh;

