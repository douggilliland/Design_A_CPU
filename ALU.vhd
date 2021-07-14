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

	signal w_Zero	 	: std_logic;
	
	signal w_latchZOps	: std_logic;
	signal w_ARI_Result		: std_logic_vector(7 downto 0);
	signal w_ORI_Result		: std_logic_vector(7 downto 0);
	signal w_XRI_Result		: std_logic_vector(7 downto 0);
	signal w_ADI_Result		: std_logic_vector(7 downto 0);
	signal w_CMP_Result		: std_logic_vector(7 downto 0);
	
	attribute syn_keep	: boolean;
	attribute syn_keep of w_Zero	: signal is true;
	attribute syn_keep of i_ALU_A_In	: signal is true;
	attribute syn_keep of i_ALU_B_In	: signal is true;
	attribute syn_keep of o_ALU_Out	: signal is true;
	attribute syn_keep of i_OP_ARI	: signal is true;
	attribute syn_keep of i_OP_ORI	: signal is true;
	attribute syn_keep of i_OP_XRI	: signal is true;
	attribute syn_keep of i_OP_ADI	: signal is true;
	attribute syn_keep of i_OP_CMP	: signal is true;
	
BEGIN

	-- Opcodes which need to latch the Z bit
	w_latchZOps <= i_OP_ORI or i_OP_ARI or i_OP_XRI or i_OP_ADI or i_OP_CMP;
	
	w_ARI_Result <= i_ALU_A_In and i_ALU_B_In;
	w_ORI_Result <= i_ALU_A_In or  i_ALU_B_In;
	w_XRI_Result <= i_ALU_A_In Xor i_ALU_B_In;
	w_ADI_Result <= i_ALU_A_In  +  i_ALU_B_In;
	
	o_ALU_Out <= w_ARI_Result when (i_OP_ARI = '1') else
					 w_ORI_Result when (i_OP_ORI = '1') else
					 w_XRI_Result when (i_OP_XRI = '1') else
					 w_ADI_Result when (i_OP_ADI = '1') else
					 i_ALU_A_In   when (i_OP_CMP = '1') else	-- CMP does not change the value
					 X"00";
	
	w_Zero <=	'1' WHEN ((w_ARI_Result = X"00") AND (i_OP_ARI = '1')) ELSE
					'1' WHEN ((w_ORI_Result = X"00") AND (i_OP_ORI = '1')) ELSE
					'1' WHEN ((w_XRI_Result = X"00") AND (i_OP_XRI = '1')) ELSE
					'1' WHEN ((w_ADI_Result = X"00") AND (i_OP_ADI = '1')) ELSE
					'1' WHEN ((w_XRI_Result = X"00") AND (i_OP_CMP = '1')) ELSE
					'0';

	latchZBit : PROCESS (i_clock)			-- Sensitivity list
		BEGIN
			IF rising_edge(i_clock) THEN		-- On clocks
				if ((i_LatchZBit = '1') and (w_latchZOps = '1')) then
					o_Z_Bit <= w_Zero;
				END IF;
			END IF;
		END PROCESS;
END beh;

