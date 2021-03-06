-- File: RegisterFile.vhd

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY RegisterFile IS
  PORT  (
		i_clock		: in std_logic;		-- Clock (50 MHz)
		i_ldRegF		: in std_logic;		-- Load signal
		i_regSel		: in std_logic_vector(3 downto 0);
		i_RegFData	: in std_logic_vector(7 downto 0);
		o_RegFData	: out std_logic_vector(7 downto 0)
	);
END RegisterFile;

ARCHITECTURE beh OF RegisterFile IS

	signal reg0 	: std_logic_vector(7 downto 0);
	signal reg1 	: std_logic_vector(7 downto 0);
	signal reg2 	: std_logic_vector(7 downto 0);
	signal reg3 	: std_logic_vector(7 downto 0);
	signal reg4 	: std_logic_vector(7 downto 0);
	signal reg5 	: std_logic_vector(7 downto 0);
	signal reg6 	: std_logic_vector(7 downto 0);
	signal reg7 	: std_logic_vector(7 downto 0);
	
BEGIN
	-- Register stores
	RegisterFile : PROCESS (i_clock)			-- Sensitivity list
		BEGIN
			IF rising_edge(i_clock) THEN		-- On clocks
				if    ((i_ldRegF = '1') and (i_regSel = x"0")) then
					reg0 <= i_RegFData;
				elsif ((i_ldRegF = '1') and (i_regSel = x"1")) then
					reg1 <= i_RegFData;
				elsif ((i_ldRegF = '1') and (i_regSel = x"2")) then
					reg2 <= i_RegFData;
				elsif ((i_ldRegF = '1') and (i_regSel = x"3")) then
					reg3 <= i_RegFData;
				elsif ((i_ldRegF = '1') and (i_regSel = x"4")) then
					reg4 <= i_RegFData;
				elsif ((i_ldRegF = '1') and (i_regSel = x"5")) then
					reg5 <= i_RegFData;
				elsif ((i_ldRegF = '1') and (i_regSel = x"6")) then
					reg6 <= i_RegFData;
				elsif ((i_ldRegF = '1') and (i_regSel = x"7")) then
					reg7 <= i_RegFData;
				END IF;
			END IF;
		END PROCESS;
		
	-- Register Read Multiplexer
	o_RegFData <=	reg0	when i_regSel = x"0" else
						reg1	when i_regSel = x"1" else
						reg2	when i_regSel = x"2" else
						reg3	when i_regSel = x"3" else
						reg4	when i_regSel = x"4" else
						reg5	when i_regSel = x"5" else
						reg6	when i_regSel = x"6" else
						reg7	when i_regSel = x"7" else
						x"00"	when i_regSel = x"8" else
						x"01"	when i_regSel = x"9" else
						x"FF"	when i_regSel = x"F" else
						x"00";

END beh;

