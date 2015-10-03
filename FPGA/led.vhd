library ieee;
use ieee.std_logic_1164.all;

-- led display 9 pos

entity LED is
port (anode: out std_logic_vector(8 downto 0);
   cathode: out std_logic_vector(7 downto 0);
	segment: in std_logic_vector(7 downto 0);
	position: in std_logic_vector(8 downto 0)
	);
end entity;

architecture a of LED is

begin
anode <= position;
cathode<=segment;
end architecture;