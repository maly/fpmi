library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity matrix is
port(
   --phys
	clk: in std_logic;
	rows: out std_logic_vector(4 downto 0);
	cols: in std_logic_vector(4 downto 0);
	
	--log
	keys_n: out std_logic_vector(24 downto 0)
	);
end entity;

architecture behav of matrix is
signal clkx: unsigned(4 downto 0):="11110";

begin

process (clk) is
variable div:integer:=0;
begin
 if rising_edge(clk) then
   div:=div+1;

	if (div=10000) then
	  if clkx="11110" then keys_n(4 downto 0) <= cols; end if;
	  if clkx="11101" then keys_n(9 downto 5) <= cols; end if;
	  if clkx="11011" then keys_n(14 downto 10) <= cols; end if;
	  if clkx="10111" then keys_n(19 downto 15) <= cols; end if;
	  if clkx="01111" then keys_n(24 downto 20) <= cols; end if;
	  clkx<=clkx(3 downto 0) & clkx(4);
	  div:=0;
	end if;
  end if;
end process;

rows<=std_logic_vector(clkx);  
	
	
end architecture;	
	