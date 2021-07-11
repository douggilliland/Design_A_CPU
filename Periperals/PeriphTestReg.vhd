-- PeriphTestReg.vhd

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY PeriphTestReg IS
  PORT  (
	-- Ins
		i_clock			: IN std_logic;		-- Clock (50 MHz)
		i_wrReg			: IN std_logic;		-- Write strobe
		i_periphRegIn	: in std_logic_vector(7 downto 0);
		-- Outs
		o_PeriphRegOut	: out std_logic_vector(7 downto 0)
	);
END PeriphTestReg;

ARCHITECTURE beh OF PeriphTestReg IS

	signal w_periphReg 	: std_logic_vector(7 downto 0);
	
BEGIN
	PeriphTestReg : PROCESS (i_clock)			-- Sensitivity list
		BEGIN
			IF rising_edge(i_clock) THEN		-- On clocks
				if i_wrReg = '1' then
					o_PeriphRegOut <= not i_periphRegIn;
				END IF;
			END IF;
		END PROCESS;
END beh;

