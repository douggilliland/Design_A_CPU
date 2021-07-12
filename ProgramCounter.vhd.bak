-- File: ProgramCounter.vhd

-- Library boilerplates
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Program Counter
ENTITY ProgramCounter IS
  PORT 
  (
		-- Ins
		i_clock		: IN std_logic;		-- Clock (50 MHz)
		i_loadPC		: IN std_logic;		-- Load PC control
		i_incPC		: IN std_logic;		-- Increment PC control
		i_PCLdValr	: IN std_logic_vector(11 downto 0);
		-- Outs
		o_ProgCtr	: OUT std_logic_vector(11 downto 0)
	);
END ProgramCounter;

ARCHITECTURE beh OF ProgramCounter IS

	signal w_progCtr		: std_logic_vector(11 downto 0);
	
BEGIN

		progCtr : PROCESS (i_clock)			-- Sensitivity list
		BEGIN
			IF rising_edge(i_clock) THEN		-- On clocks
				if i_loadPC = '1' then			-- Load new PC
					w_progCtr <= i_PCLdValr;
				elsif i_incPC = '1' then		-- Increment counter
					w_progCtr <= w_progCtr+1;
				END IF;
			END IF;
		END PROCESS;
		
		o_ProgCtr <= w_progCtr;					-- Output pins

END beh;
