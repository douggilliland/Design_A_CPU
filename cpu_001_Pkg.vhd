library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package cpu_001_Pkg is

constant OP0_OP 	: std_logic_vector(3 downto 0) := "0000";
constant OP1_OP 	: std_logic_vector(3 downto 0) := "0001";
constant OP2_OP 	: std_logic_vector(3 downto 0) := "0010";
constant OP3_OP 	: std_logic_vector(3 downto 0) := "0011";
constant LRI_OP 	: std_logic_vector(3 downto 0) := "0100";
constant CMP_OP 	: std_logic_vector(3 downto 0) := "0101";
constant IOR_OP 	: std_logic_vector(3 downto 0) := "0110";
constant IOW_OP 	: std_logic_vector(3 downto 0) := "0111";
constant XRI_OP 	: std_logic_vector(3 downto 0) := "1000";
constant ORI_OP 	: std_logic_vector(3 downto 0) := "1001";
constant ARI_OP 	: std_logic_vector(3 downto 0) := "1010";
constant ADI_OP 	: std_logic_vector(3 downto 0) := "1011";
constant JSR_OP 	: std_logic_vector(3 downto 0) := "1100";
constant JMP_OP 	: std_logic_vector(3 downto 0) := "1101";
constant BEZ_OP 	: std_logic_vector(3 downto 0) := "1110";
constant BNZ_OP 	: std_logic_vector(3 downto 0) := "1111";

end package cpu_001_Pkg;
