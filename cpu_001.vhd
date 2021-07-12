-- File: cpu_001.vhd

-- Library boilerplates
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY cpu_001 IS
	generic (
		constant INST_SRAM_SIZE_PASS	: integer;	-- Legal Values are 256, 512, 1024, 2048, 4096
		constant STACK_DEPTH_PASS		: integer	-- Legal Values are 0, 1 (single), > 1 (2^N) (nested subroutines)
	);
  PORT 
  (
		i_clock					: IN std_logic;		-- 50 MHz clock
		i_resetN					: IN std_logic := '1';
		-- Peripheral bus
		i_peripDataToCPU		: in std_logic_vector(7 downto 0);
		o_peripAddr				: out std_logic_vector(7 downto 0);
		o_peripDataFromCPU	: out std_logic_vector(7 downto 0);
		o_peripWr				: out std_logic;
		o_peripRd				: out std_logic
	);
END cpu_001;

ARCHITECTURE beh OF cpu_001 IS

	-- Program Counter
	signal w_loadPC	: std_logic;
	signal w_incPC		: std_logic;
	signal w_ProgCtr	: std_logic_vector(11 downto 0);
	signal pcPlus1		: std_logic_vector(11 DOWNTO 0);		-- Program Couner + 1
	
	-- Stack Return address
	signal w_rtnAddr	: std_logic_vector(11 downto 0);
	signal w_LDAddr	: std_logic_vector(11 downto 0);
	signal w_ldPCSel	: std_logic;
	
	-- Register File
	signal w_ldRegF			: std_logic;
	signal w_regFIn			: std_logic_vector(7 downto 0) := x"55";
	signal w_regFOut			: std_logic_vector(7 downto 0);
	signal w_ldRegFileSel	: std_logic;
	
	-- ROM
	signal w_romData	: std_logic_vector(15 downto 0);
	
	-- Opcode decoder
	signal OP_ADI		: std_logic;
	signal OP_CMP		: std_logic;
	signal OP_LRI		: std_logic;
	signal OP_SRI		: std_logic;
	signal OP_XRI		: std_logic;
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
	
	-- Peripherals
	signal w_serialLoopback		: std_logic;
	signal w_segs					: std_logic_vector(7 downto 0);
	
	-- State Machine
	signal w_GreyCode				: std_logic_vector(1 downto 0);
	
	-- ALU
	signal w_ALUDataOut		: std_logic_vector(7 downto 0);
	signal w_ALUZBit			: std_logic;
	
	-- Shifter
	signal w_ShiftDataOut	: std_logic_vector(7 downto 0);
	
	-- Signal Tap
	attribute syn_keep	: boolean;
	attribute syn_keep of w_ProgCtr			: signal is true;
	attribute syn_keep of w_peripAddr			: signal is true;
	attribute syn_keep of w_peripDataFromCPU	: signal is true;
	attribute syn_keep of w_peripDataToCPU		: signal is true;
	attribute syn_keep of OP_IOR					: signal is true;
	attribute syn_keep of OP_IOW					: signal is true;
	
	
BEGIN

	OP_ADI <= '1' when w_romData(15 downto 12) = "0000" else '0';
	OP_CMP <= '1' when w_romData(15 downto 12) = "0001" else '0';
	OP_LRI <= '1' when w_romData(15 downto 12) = "0010" else '0';
	OP_SRI <= '1' when w_romData(15 downto 12) = "0011" else '0';
	OP_XRI <= '1' when w_romData(15 downto 12) = "0100" else '0';	
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
		i_resetN		=> i_resetN,
		i_loadPC		=> w_loadPC,	-- Load PC control
		i_incPC		=> w_incPC,		-- Increment PC control
		i_PCLdValr	=> w_LDAddr,	-- Load PC value
		-- Outs
		o_ProgCtr	=> w_ProgCtr	-- Program Counter
	);	
	w_LDAddr <= w_rtnAddr when (OP_RTS = '1') else		-- Return from Subroutine instruction
					w_romData(11 downto 0);
	-- Instruction that affects flow control
	w_ldPCSel <= OP_JMP or OP_RTS or OP_JSR or (OP_BEZ and w_ALUZBit) or (OP_BNZ and (not w_ALUZBit));
	w_loadPC <= '1' when ((w_GreyCode = "10") and (w_ldPCSel = '1')) else '0';
	w_incPC	<= '1' when  (w_GreyCode = "10") else '0';
	
	-- JSR/RTS Stack
--	stackVal : PROCESS (i_clock)			-- Sensitivity list
--	BEGIN
--		IF rising_edge(i_clock) THEN		-- On clocks
--			if ((OP_JSR = '1') and (w_GreyCode = "10")) then	-- If instruction is JSR then store next addr + 1
--				w_rtnAddr <= w_ProgCtr + 1;
--			END IF;
--		END IF;
--	END PROCESS;
	
	-- LIFO - Return address stack (JSR writes, RTS reads)
	-- Single depth uses no memory
	-- Deeper depth uses memory
	GEN_STACK_SINGLE : if (STACK_DEPTH_PASS = 1) generate
	begin
	-- Store the return address for JSR opcodes
	-- Single level stack
		returnAddress : PROCESS (i_clock)
		BEGIN
			IF rising_edge(i_clock) THEN
				if ((OP_JSR = '1') and (w_GreyCode="10")) then
					w_rtnAddr <= w_ProgCtr + 1;
				END IF;
			END IF;
		END PROCESS;
	end generate GEN_STACK_SINGLE;

	GEN_STACK_DEEPER : if (STACK_DEPTH_PASS > 1) generate
	begin
		pcPlus1 <= (w_ProgCtr + 1);				-- Next address past PC is the return address
		lifo : entity work.lifo
			generic map (
				g_INDEX_WIDTH => STACK_DEPTH_PASS, -- internal index bit width affecting the LIFO capacity
				g_DATA_WIDTH  => 12 				-- bit width of stored data
			)
			port map (
				i_clk		=> i_clock, 					-- clock signal
				i_rst		=> not i_resetN,			-- reset signal
				--
				i_we   	=> (OP_JSR and w_GreyCode(1) and (not w_GreyCode(0))), -- write enable (push)
				i_data 	=> pcPlus1,			-- written data
	--			o_full	=> ,
				i_re		=> (OP_RTS and w_GreyCode(1) and w_GreyCode(0)), -- read enable (pop)
				o_data  	=> w_rtnAddr			-- read data
		--		o_empty :=>							-- empty LIFO indicator
			);	
	end generate GEN_STACK_DEEPER;
	
	-- Register File
	RegFile : ENTITY work.RegisterFile
	PORT MAP (
		i_clock		=> i_clock,
		i_ldRegF		=> w_ldRegF,
		i_regSel		=> w_romData(11 downto 8),
		i_RegFData	=> w_regFIn,
		o_RegFData	=> w_regFOut
	);
	w_regFIn <= i_peripDataToCPU 			when OP_IOR = '1' else
					w_ALUDataOut				when OP_ARI = '1' else
					w_ALUDataOut				when OP_ADI = '1' else
					w_ALUDataOut				when OP_ORI = '1' else
					w_ALUDataOut				when OP_xRI = '1' else
					w_romData(7 downto 0)	when OP_LRI = '1' else
					w_ShiftDataOut				when OP_SRI = '1' else
					x"00";
	-- Operations that load the Register File
	w_ldRegFileSel <= OP_LRI or OP_IOR or OP_ARI or OP_ORI or OP_ADI or OP_SRI or OP_xRI;
	w_ldRegF	<= '1' when ((w_GreyCode = "10") and (w_ldRegFileSel = '1')) else '0';
	
	-- Shifter - Left/Right, Shift/Rotatte
	Shifter : ENTITY work.Shifter
	  PORT map (
			-- Ins
			i_clock			=> i_clock,						-- Clock (50 MHz)
			i_OP_SRI			=> OP_SRI,						-- Shift/Rotate Instruction
			i_ShiftL0A1		=> w_romData(5),				-- 0=Logical, 1=Arithmetic
			i_Shift0Rot1	=> w_romData(6),				-- Shift=0, Rotate=1
			i_ShiftL0R1		=> w_romData(7),				-- 0=left, 1=right
			i_ShiftCount	=> w_romData(2 downto 0),	-- 0x1
			i_DataIn			=> w_regFOut,					-- Data In
			-- Outs
			o_DataOut		=> w_ShiftDataOut				-- Data Out
		);	

--	-- ROM (max 4K words)
--	rom : ENTITY work.ROM_1KW
--	PORT map
--	(
--		clock		=> i_clock,
--		address	=> w_ProgCtr(8 downto 0),
--		q			=> w_romData
--	);
	
	-- IO Processor ROM
	GEN_256W_INST_ROM: if (INST_SRAM_SIZE_PASS=256) generate
		begin
		IopRom : ENTITY work.IOP_ROM
		PORT map
		(
			address		=> w_ProgCtr(7 downto 0),
			clock			=> i_clock,
			q				=> w_romData
		);
	end generate GEN_256W_INST_ROM;
	
	GEN_512W_INST_ROM: if (INST_SRAM_SIZE_PASS=512) generate
		begin
		IopRom : ENTITY work.IOP_ROM
		PORT map
		(
			address		=> w_ProgCtr(8 downto 0),
			clock			=> i_clock,
			q				=> w_romData
		);
	end generate GEN_512W_INST_ROM;
	
	GEN_1KW_INST_ROM: if (INST_SRAM_SIZE_PASS=1024) generate
		begin
		IopRom : ENTITY work.IOP_ROM
		PORT map
		(
			address		=> w_ProgCtr(9 downto 0),
			clock			=> i_clock,
			q				=> w_romData
		);
	end generate GEN_1KW_INST_ROM;
	
	GEN_2KW_INST_ROM: if (INST_SRAM_SIZE_PASS=2048) generate
		begin
		IopRom : ENTITY work.IOP_ROM
		PORT map
		(
			address		=> w_ProgCtr(10 downto 0),
			clock			=> i_clock,
			q				=> w_romData
		);
	end generate GEN_2KW_INST_ROM;
	
	GEN_4KW_INST_ROM: if (INST_SRAM_SIZE_PASS=4096) generate
		begin
		IopRom : ENTITY work.IOP_ROM
		PORT map
		(
			address		=> w_ProgCtr,
			clock			=> i_clock,
			q				=> w_romData
		);
	end generate GEN_4KW_INST_ROM;
	
	-- Grey code counter
	GreyCodeCounter : ENTITY work.GreyCode
	  PORT  map (
			i_clock		=> i_clock,
			i_resetN		=> i_resetN,
			o_GreyCode	=> w_GreyCode
		);
		
	-- ALU Unit
	ALU_Unit : ENTITY work.ALU_Unit
	  PORT  MAP (
			i_clock		=> i_clock,
			i_ALU_A_In	=> w_regFOut,				-- Register file out
			i_ALU_B_In	=> w_romData(7 downto 0),	-- Immediate value
			i_OP_ADI		=> OP_ADI,					-- ADD opcode
			i_OP_CMP		=> OP_ARI,					-- COMPARE opcode
			i_OP_ARI		=> OP_ARI,					-- AND opcode
			i_OP_ORI		=> OP_ORI,					-- OR opcode
			i_OP_XRI		=> OP_XRI,					-- XOR opcode
			i_LatchZBit	=> (OP_ORI or OP_ARI) and w_GreyCode(1) and (not w_GreyCode(0)),
			o_Z_Bit		=> w_ALUZBit,				-- Z bit from ALU
			o_ALU_Out	=> w_ALUDataOut				-- Register file input mux
		);

	-- Peripheral bus
	o_peripAddr				<= w_romData(7 downto 0);
	o_peripDataFromCPU	<= w_regFOut;
	o_peripWr				<= '1' when ((w_GreyCode = "10")   and (OP_IOW = '1'))	else '0';
	o_peripRd				<= '1' when ((w_GreyCode(1) = '1') and (OP_IOR = '1'))	else '0';
	
END beh;
