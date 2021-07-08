-- File: GreyCode.vhd

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY GreyCode IS
  PORT  (
		i_clock		: IN std_logic;		-- Clock (50 MHz)
		i_resetN		: IN std_logic := '1';
		o_GreyCode	: inout std_logic_vector(1 downto 0)
	);
END GreyCode;

ARCHITECTURE beh OF GreyCode IS

	signal w_greyCode 	: std_logic_vector(1 downto 0);
	
BEGIN

	w_GreyCode <=	"00" when (i_resetN = '0')		else	-- reset
						"01" when (o_GreyCode = "00")	else	-- 00 > 01
						"11" when (o_GreyCode = "01")	else	-- 01 > 11
						"10" when (o_GreyCode = "11")	else	-- 11 > 10
						"00";											-- 10 > 00
	
	GreyCode : PROCESS (i_clock)			-- Sensitivity list
		BEGIN
			IF rising_edge(i_clock) THEN	-- On clocks
				o_greyCode <= w_GreyCode;
			END IF;
		END PROCESS;
		
END beh;
