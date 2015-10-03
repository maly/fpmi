library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DISP8 is
port (anode: out std_logic_vector(8 downto 0);
   cathode: out std_logic_vector(7 downto 0);
	data1: in std_logic_vector(7 downto 0); --PA
	data2: in std_logic_vector(7 downto 0); --PA
	addr: in std_logic_vector(15 downto 0); --PA
	clk:in std_logic
	);
end entity;

architecture a of DISP8 is
signal clkx: unsigned(2 downto 0):="000";
signal bcd:std_logic_vector(3 downto 0);
begin

process (clk) is
variable div:integer:=0;
begin
 if rising_edge(clk) then
   div:=div+1;

	if (div=10000) then
	clkx<=clkx+1;
	div:=0;
	end if;
case  bcd is
when "0000"=> cathode <="00111111";  -- '0'
when "0001"=> cathode <="00000110";  -- '1'
when "0010"=> cathode <="01011011";  -- '2'
when "0011"=> cathode <="01001111";  -- '3'
when "0100"=> cathode <="01100110";  -- '4' 
when "0101"=> cathode <="01101101";  -- '5'
when "0110"=> cathode <="01111101";  -- '6'
when "0111"=> cathode <="00000111";  -- '7'
when "1000"=> cathode <="01111111";  -- '8'
when "1001"=> cathode <="01101111";  -- '9'
when "1010"=> cathode <="01110111";  -- 'a'
when "1011"=> cathode <="01111100";  -- 'b'
when "1100"=> cathode <="00111001";  -- 'c'
when "1101"=> cathode <="01011110";  -- 'd'
when "1110"=> cathode <="01111001";  -- 'e'
when "1111"=> cathode <="01110001";  -- 'f'
 --nothing is displayed when a number more than 9 is given as input. 
when others=> cathode <="00000000"; 
end case;

	end if;
 end process;

anode<= "111111110" when clkx="000" else 
        "111111101" when clkx="001" else 
        "111111011" when clkx="010" else 
        "111110111" when clkx="011" else 
        "111101111" when clkx="100" else 
        "111011111" when clkx="101" else 
        "110111111" when clkx="110" else 
        "101111111" when clkx="111" else 
		  "111111111";
		  
bcd<= data1(3 downto 0) when clkx="001" else 
      data1(7 downto 4) when clkx="000" else 
      data2(3 downto 0) when clkx="011" else 
      data2(7 downto 4) when clkx="010" else 
      addr(3 downto 0) when clkx="111" else 
      addr(7 downto 4) when clkx="110" else 
      addr(11 downto 8) when clkx="101" else 
      addr(15 downto 12) when clkx="100" else 
		x"0";
	
end architecture;