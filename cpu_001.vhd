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
		i_clock		: IN std_logic;		-- 50 MHz clock
		i_KEY0		: IN std_logic;		-- KEY0
		o_LED			: OUT std_logic;
		
		-- SDRAM - Not used
		DRAM_CS_N	: OUT std_logic := '0';
		DRAM_CLK		: OUT std_logic := '0';
		DRAM_CKE		: OUT std_logic := '0';
		DRAM_CAS_N	: OUT std_logic := '0';
		DRAM_WE_N	: OUT std_logic := '1';
		DRAM_UDQM	: OUT std_logic := '0';
		DRAM_LDQM	: OUT std_logic := '0';
		DRAM_BA		: OUT std_logic_vector(1 downto 0) := "00";
		DRAM_ADDR	: OUT std_logic_vector(12 downto 0) := "0"&x"000";
		DRAM_DQ		: in std_logic_vector(15 downto 0) := (others=>'Z')
		
	);
END cpu_001;

ARCHITECTURE beh OF cpu_001 IS

	signal w_keyBuff	: std_logic;
	
	-- Program Counter
	signal w_loadPC	: std_logic;
	signal w_incPC		: std_logic;
	signal w_PCLDVal	: std_logic_vector(11 downto 0) := x"123";
	signal w_ProgCtr	: std_logic_vector(11 downto 0);
	
	-- Stack Return address
	signal w_rtnAddr	: std_logic_vector(11 downto 0);
	signal w_LDAddr	: std_logic_vector(11 downto 0);
	
	-- Slow clock signals
	signal w_slowPulse	: std_logic;
	
	-- Register File
	signal w_ldRegF	: std_logic;
--	signal w_regSel	: std_logic_vector(3 downto 0) := "0000";
	signal w_regFIn	: std_logic_vector(7 downto 0) := x"55";
	signal w_regFOut	: std_logic_vector(7 downto 0);
	
	-- ROM
	signal w_romData	: std_logic_vector(15 downto 0);
	
	-- Opcode decoder
	signal OP_LRI		: std_logic;
	signal OP_IOR		: std_logic;
	signal OP_IOw		: std_logic;
	signal OP_ARI		: std_logic;
	signal OP_ORI		: std_logic;
	signal OP_BEZ		: std_logic;
	signal OP_BNZ		: std_logic;
	signal OP_JMP		: std_logic;
	signal OP_JSR		: std_logic;
	signal OP_RTS		: std_logic;
	
	-- Peripheral bus
	signal w_peripAddr			: std_logic_vector(7 downto 0);
	signal w_peripDataFromCPU	: std_logic_vector(7 downto 0);
	signal w_peripDataToCPU		: std_logic_vector(7 downto 0) := x"00";
	signal w_peripWr				: std_logic;
	signal w_peripRd				: std_logic;
	signal w_peripTRWr			: std_logic;
	signal w_peripTRRd			: std_logic;
	
	-- State Machine
	signal w_GreyCode				: std_logic_vector(1 downto 0);
	
	-- ALU
	signal w_ALUDataOut		: std_logic_vector(7 downto 0);
	signal w_ALUZBit		: std_logic;
	
	
	attribute syn_keep	: boolean;
	attribute syn_keep of OP_IOR					: signal is true;
	attribute syn_keep of OP_IOW					: signal is true;
	attribute syn_keep of w_peripAddr			: signal is true;
	attribute syn_keep of w_peripDataFromCPU	: signal is true;
	attribute syn_keep of w_peripDataToCPU		: signal is true;
	
	
BEGIN

	w_keyBuff	<= i_KEY0;
	
	OP_LRI <= '1' when w_romData(15 downto 12) = "0010" else '0';
	OP_IOR <= '1' when w_romData(15 downto 12) = "0110" else '0';
	OP_IOW <= '1' when w_romData(15 downto 12) = "0111" else '0';
	OP_ARI <= '1' when w_romData(15 downto 12) = "1000" else '0';
	OP_ORI <= '1' when w_romData(15 downto 12) = "1001" else '0';	
	OP_JSR <= '1' when w_romData(15 downto 12) = "1010" else '0';
	OP_RTS <= '1' when w_romData(15 downto 12) = "1011" else '0';
	OP_BEZ <= '1' when w_romData(15 downto 12) = "1100" else '0';
	OP_BNZ <= '1' when w_romData(15 downto 12) = "1101" else '0';
	OP_JMP <= '1' when w_romData(15 downto 12) = "1110" else '0';
	
	-- Program Counter
	progCtr : ENTITY work.ProgramCounter
	PORT map
   (
		-- Ins
		i_clock		=> i_clock,		-- Clock (50 MHz)
		i_loadPC		=> w_loadPC,	-- Load PC control
		i_incPC		=> w_incPC,		-- Increment PC control
		i_PCLdValr	=> w_LDAddr,	-- Load PC value
		-- Outs
		o_ProgCtr	=> w_ProgCtr	-- Program Counter
	);
	
		w_LDAddr <= w_rtnAddr when (OP_RTS = '1') else
						w_romData(11 downto 0);
		
	w_loadPC <= '1' when ((w_GreyCode = "10") and (OP_JMP = '1')) else 
					'1' when ((w_GreyCode = "10") and (OP_RTS = '1')) else 
					'1' when ((w_GreyCode = "10") and (OP_JSR = '1')) else 
					'1' when ((w_GreyCode = "10") and (OP_BEZ = '1') and (w_ALUZBit = '1')) else 
					'1' when ((w_GreyCode = "10") and (OP_BNZ = '1') and (w_ALUZBit = '0')) else 
					'0';
	w_incPC	<= '1' when  (w_GreyCode = "10") else '0';
	
	stackVal : PROCESS (i_clock)			-- Sensitivity list
	BEGIN
		IF rising_edge(i_clock) THEN		-- On clocks
			if ((OP_JSR = '1') and (w_GreyCode = "10")) then	-- store next addr + 1
				w_rtnAddr <= w_ProgCtr + 1;
			END IF;
		END IF;
	END PROCESS;

	
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
		i_regSel		=> w_romData(11 downto 8),
		i_RegFData	=> w_regFIn,
		o_RegFData	=> w_regFOut
	);
	
	w_regFIn <= w_peripDataToCPU 		when ((OP_IOR = '1') and (w_peripTRRd = '1')) else
					w_ALUDataOut				when OP_ARI = '1' else
					w_ALUDataOut				when OP_ORI = '1' else
					w_romData(7 downto 0)	when OP_LRI = '1' else
					x"00";
	
	w_ldRegF	<= '1' when ((w_GreyCode = "10") and (OP_LRI = '1'))	else 
					'1' when ((w_GreyCode = "10") and (OP_IOR = '1'))	else 
					'1' when ((w_GreyCode = "10") and (OP_ARI = '1'))	else 
					'1' when ((w_GreyCode = "10") and (OP_ORI = '1'))	else 
					'0';
	
	-- ROM
	rom : ENTITY work.ROM_1KW
	PORT map
	(
		clock		=> i_clock,
		address	=> w_ProgCtr(8 downto 0),
		q			=> w_romData
	);
	
	-- Grey code counter
	GreyCodeCounter : ENTITY work.GreyCode
	  PORT  map (
			i_clock		=> i_clock,
			i_resetN		=> '1',
			o_GreyCode	=> w_GreyCode
		);
		
	-- Peripheral Test Register
	testPeriphReg : ENTITY work.PeriphTestReg
	  PORT  MAP (
			i_clock			=> i_clock,
			i_wrReg			=> w_peripTRWr,
			i_periphRegIn	=> w_peripDataFromCPU,
			o_PeriphRegOut	=> w_peripDataToCPU
		);
	
	w_peripTRWr <= '1' when w_peripAddr = x"AA" else '0';
	w_peripTRRd <= '1' when w_peripAddr = x"55" else '0';
	
	-- Peripheral bus
	w_peripAddr				<= w_romData(7 downto 0);
	w_peripDataFromCPU	<= w_regFOut;
	w_peripWr				<= '1' when ((w_GreyCode = "10")   and (OP_IOW = '1'))	else '0';
	w_peripRd				<= '1' when ((w_GreyCode(1) = '1') and (OP_IOR = '1'))	else '0';
	
--	w_regSel		<= "0000";			-- Ignored
	w_PCLDVal	<= x"000";			-- PC Load Address = 0x000
	o_LED 		<= w_romData(15) when i_KEY0 = '0' else -- LED0
						w_romData(0);
	
	-- ALU Unit
	ALU_Unit : ENTITY work.ALU_Unit
	  PORT  MAP (
			i_clock		=> i_clock,
			i_ALU_A_In	=> w_regFOut,				-- Register file out
			i_ALU_B_In	=> w_romData(7 downto 0),	-- Immediate value
			i_OP_ARI		=> OP_ARI,					-- AND opcode
			i_OP_ORI		=> OP_ORI,					-- OR opcode
			i_LatchZBit	=> (OP_ORI or OP_ARI) and w_GreyCode(1) and (not w_GreyCode(0)),
			o_Z_Bit		=> w_ALUZBit,				-- Z bit from ALU
			o_ALU_Out	=> w_ALUDataOut				-- Register file input mux
		);

END beh;
