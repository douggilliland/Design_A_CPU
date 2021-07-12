-- File: Shifter.vhd
-- Supports:
--		Shift Logical left/right
--		Shift Arithmetic left/right
--		Rotate left/right
--
-- Info: https://open4tech.com/logical-vs-arithmetic-shift/

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY Shifter IS
  PORT  (
		-- Ins
		i_clock			: IN std_logic;		-- Clock (50 MHz)
		i_OP_SRI			: IN std_logic;		-- Shift/Rotate Instruction
		i_ShiftL0A1		: IN std_logic;		-- 0=Logical, 1=Arithmetic
		i_Shift0Rot1	: IN std_logic;		-- Shift=0, Rotate=1
		i_ShiftL0R1		: IN std_logic;		-- 0=left, 1=right
		i_ShiftCount	: IN std_logic_vector(2 downto 0);	-- 0x1
		i_DataIn			: IN std_logic_vector(7 downto 0);	-- Data In
		-- Outs
		o_DataOut		: out std_logic_vector(7 downto 0)	-- Data Out
	);
END Shifter;

ARCHITECTURE beh OF Shifter IS

	-- Signal Tap
	attribute syn_keep	: boolean;
	attribute syn_keep of i_OP_SRI			: signal is true;
	attribute syn_keep of i_Shift0Rot1		: signal is true;
	attribute syn_keep of i_ShiftL0R1		: signal is true;
	attribute syn_keep of i_ShiftCount		: signal is true;
	attribute syn_keep of i_DataIn			: signal is true;
	attribute syn_keep of o_DataOut			: signal is true;
	
BEGIN

	o_DataOut<=	i_DataIn(6 downto 0)&'0' 			when ((i_OP_SRI='1') and (i_ShiftL0R1='0') and (i_Shift0Rot1='0') and (i_ShiftCount="001") and (i_ShiftL0A1='0'))	else	-- Shift left Logical
					'0'&i_DataIn(7 downto 1) 			when ((i_OP_SRI='1') and (i_ShiftL0R1='1') and (i_Shift0Rot1='0') and (i_ShiftCount="001") and (i_ShiftL0A1='0'))	else	-- Shift right Logical
					i_DataIn(6 downto 0)&'0' 			when ((i_OP_SRI='1') and (i_ShiftL0R1='0') and (i_Shift0Rot1='0') and (i_ShiftCount="001") and (i_ShiftL0A1='1'))	else	-- Shift left Logical
					i_DataIn(7)&i_DataIn(7 downto 1)	when ((i_OP_SRI='1') and (i_ShiftL0R1='1') and (i_Shift0Rot1='0') and (i_ShiftCount="001") and (i_ShiftL0A1='1'))	else	-- Shift right Logical
					i_DataIn(6 downto 0)&i_DataIn(7) when ((i_OP_SRI='1') and (i_ShiftL0R1='0') and (i_Shift0Rot1='1') and (i_ShiftCount="001"))	else	-- rotate left
					i_DataIn(0)&i_DataIn(7 downto 1) when ((i_OP_SRI='1') and (i_ShiftL0R1='1') and (i_Shift0Rot1='1') and (i_ShiftCount="001"))	else	-- rotate right
					i_DataIn;
	
		
END beh;
