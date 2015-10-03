library ieee;
use ieee.std_logic_1164.all;

entity pmikey is 
port(
  keys_n: in std_logic_vector(24 downto 0);
  k_reset_n: out std_logic;
  k_int_n: out std_logic;
  position: in std_logic_vector(3 downto 0); --PA
  k_row: out std_logic_vector(2 downto 0) --PC
);
end entity;

architecture coder of pmikey is

begin
k_reset_n<=keys_n(24);
k_int_n<=keys_n(19);

with position select
  k_row <= keys_n(15) & keys_n(5) & keys_n(0) when "0111",
			  keys_n(16) & keys_n(6) & '1' when "1000",	
			  keys_n(17) & keys_n(7) & '1' when "1001",	
			  keys_n(23) & keys_n(13) & keys_n(3) when "1010",	
			  keys_n(18) & keys_n(8) & keys_n(4) when "1011",	
			  keys_n(14) & keys_n(9) & '1' when "1100",	
			  keys_n(22) & keys_n(12) & keys_n(2) when "1101",	
			  keys_n(21) & keys_n(11) & keys_n(1) when "1110",	
			  keys_n(20) & keys_n(10) & '1' when "1111",	
--			  '0' & keys_n(10) & '1' when "1111",	
			  "111" when others;

end architecture;