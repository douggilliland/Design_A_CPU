-----------------------------------------

library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

----------------------------------------------------

entity ConstantsUnit is
port(	
	i_clock		:	in std_logic;
	i_dataIn		:	in std_logic_vector(7 downto 0);
	i_ldStr		:	in std_logic;
	i_rdStr		:	in std_logic;
	o_constData	:	out std_logic_vector(7 downto 0)
);
end ConstantsUnit;

----------------------------------------------------

architecture behv of ConstantsUnit is		 	  
	
	signal Pre_Q			: std_logic_vector(7 downto 0);
	signal w_incConAdr	:	std_logic;
	signal w_ConstsAddr			:	std_logic_vector(7 downto 0);

begin
	-- Constants ROM address latch/count
	DLY_INC : PROCESS (i_clock,i_rdStr)
	BEGIN
		IF rising_edge(i_clock) THEN
			w_incConAdr <= i_rdStr;						-- Buffer K to avoid metastable inputs
		END IF;
	END PROCESS;
	
	CONSTROM : entity work.counterLdInc
	generic map ( 
		n => 8
	)
	port map (
		i_clock		=> i_clock,
		i_dataIn		=> i_dataIn,
		i_load		=> i_ldStr,
		i_inc			=> w_incConAdr and not i_rdStr,
		o_dataOut	=> w_ConstsAddr
	);
	
	CONST_ROM : ENTITY work.ConstantsROM_256B
	PORT MAP
	(
		address	=> w_ConstsAddr,
		clock		=> i_clock,
		q			=> o_constData
	);


end behv;
