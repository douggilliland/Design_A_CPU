-- ALU.vhd

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY ALU_Unit IS
  PORT  (
		-- 
		i_clock		: IN std_logic;		-- Clock (50 MHz)
		i_ALU_A_In	: IN std_logic_vector(7 downto 0);
		i_ALU_B_In	: IN std_logic_vector(7 downto 0);
		i_OP_ADI		: IN std_logic;
		i_OP_CMP		: IN std_logic;
		i_OP_ARI		: IN std_logic;
		i_OP_ORI		: IN std_logic;
		i_OP_XRI		: IN std_logic;
		i_LatchZBit	: IN std_logic;
		-- 
		o_Z_Bit		: out std_logic;
		o_ALU_Out	: inOUt std_logic_vector(7 downto 0)
	);
END ALU_Unit;

ARCHITECTURE beh OF ALU_Unit IS

	signal w_zeroVal 	: std_logic;
	
	attribute syn_keep	: boolean;
	attribute syn_keep of w_zeroVal	: signal is true;
	attribute syn_keep of i_ALU_A_In	: signal is true;
	attribute syn_keep of i_ALU_B_In	: signal is true;
	attribute syn_keep of o_ALU_Out	: signal is true;
	attribute syn_keep of i_OP_ARI	: signal is true;
	attribute syn_keep of i_OP_ORI	: signal is true;
	attribute syn_keep of i_OP_XRI	: signal is true;
	attribute syn_keep of i_OP_CMP	: signal is true;
	attribute syn_keep of i_OP_ADI	: signal is true;
	
BEGIN

	o_ALU_Out <= (i_ALU_A_In and i_ALU_B_In) when (i_OP_ARI = '1') else
					 (i_ALU_A_In or  i_ALU_B_In) when (i_OP_ORI = '1') else
					 (i_ALU_A_In Xor i_ALU_B_In) when (i_OP_XRI = '1') else
					 (i_ALU_A_In Xor i_ALU_B_In) when (i_OP_CMP = '1') else
					 (i_ALU_A_In  +  i_ALU_B_In) when (i_OP_ADI = '1') else
					 X"00";
	
	w_zeroVal <=	((not o_ALU_Out(7)) and (not o_ALU_Out(6)) and (not o_ALU_Out(5)) and (not o_ALU_Out(4)) and 
						 (not o_ALU_Out(3)) and (not o_ALU_Out(2)) and (not o_ALU_Out(1)) and (not o_ALU_Out(0)));

	latchZBit : PROCESS (i_clock)			-- Sensitivity list
		BEGIN
			IF rising_edge(i_clock) THEN		-- On clocks
				if i_LatchZBit = '1' then
					o_Z_Bit <= w_zeroVal;
				END IF;
			END IF;
		END PROCESS;
END beh;

