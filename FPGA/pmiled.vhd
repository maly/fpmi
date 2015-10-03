library ieee;
use ieee.std_logic_1164.all;

-- led display 9 pos

entity PMILED is
port (anode: out std_logic_vector(8 downto 0);
   cathode: out std_logic_vector(7 downto 0);
	segment: in std_logic_vector(7 downto 0); --PA
	position: in std_logic_vector(3 downto 0) --PC
	);
end entity;

architecture a of PMILED is

begin
with position select
  anode <= "011111111" when "0111",
			  "101111111" when "1000",	
			  "110111111" when "1001",	
			  "111011111" when "1010",	
			  "111101111" when "1011",	
			  "111110111" when "1100",	
			  "111111011" when "1101",	
			  "111111101" when "1110",	
			  "111111110" when "1111",	
			  "111111111" when others;
cathode<= segment xor "01111111";
end architecture;