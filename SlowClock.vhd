-- File: SlowClock.vhd

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


ENTITY SlowClock IS
  PORT  (
		i_clock		: IN std_logic;		-- Clock (50 MHz)
		o_slowClock	: out std_logic
	);
END SlowClock;

ARCHITECTURE beh OF SlowClock IS
	signal w_slowClkCt 	: std_logic_vector(21 downto 0);
	signal w_slowD1		: std_logic;
	signal w_slowD2		: std_logic;
	signal w_slowPulse	: std_logic;
	
BEGIN
	slowClock : PROCESS (i_clock)			-- Sensitivity list
		BEGIN
			IF rising_edge(i_clock) THEN		-- On clocks
				w_slowClkCt		<= w_slowClkCt+1;
				w_slowD1			<= w_slowClkCt(21);
				w_slowD2			<= w_slowD1;
				o_slowClock		<= w_slowD1 and (not w_slowD2);
			END IF;
		END PROCESS;
END beh;

