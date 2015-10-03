library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rmi is
port (
  --- kit
   led3, led7, led9: out std_logic;
   clk: in std_logic;
	
  --- kbd
	rows: out std_logic_vector(4 downto 0);
	cols: in std_logic_vector(4 downto 0);
  --- LED	
   anode: out std_logic_vector(8 downto 0);
   cathode: out std_logic_vector(7 downto 0)
	);
end entity;

architecture mtest of rmi is

signal Hz1: std_logic:='0';
signal cpuClock5: std_logic;
signal segone:std_logic_vector(8 downto 0):="111111110";

signal cpuAddr: std_logic_vector(15 downto 0);
signal cpuAddrTemp: std_logic_vector(15 downto 0);
signal cpuDataOut: std_logic_vector(7 downto 0);
signal cpuDataIn: std_logic_vector(7 downto 0);
signal cpuClock: std_logic;
signal cpuClkCount: integer range 0 to 31:=0; 
signal cpuReset: std_logic:='0';
signal cpuIO: std_logic;
signal cpuRd: std_logic;
signal cpuWr: std_logic;
signal cpuVMA: std_logic;

signal memRD, memWR, ioRD, ioWR: std_logic;
signal n_MREQ,n_ioRQ,n_RD,n_WR: std_logic;

signal ramDataOut: std_logic_vector(7 downto 0);
signal ramCS: std_logic;

signal romDataOut: std_logic_vector(7 downto 0);
signal romCS: std_logic;


signal pioDataOut: std_logic_vector(7 downto 0);
signal pioCS: std_logic;
signal PA1Out: std_logic_vector(7 downto 0);
signal PB1Out: std_logic_vector(7 downto 0);
signal PC1Out: std_logic_vector(7 downto 0);
signal PA1In: std_logic_vector(7 downto 0);
signal PB1In: std_logic_vector(7 downto 0);
signal PC1In: std_logic_vector(7 downto 0);


signal adlatch: std_logic_vector(15 downto 0);
signal dalatch: std_logic_vector(7 downto 0);

signal keys: std_logic_vector(24 downto 0);
signal keyrows: std_logic_vector(2 downto 0);
signal kreset, kint: std_logic;
begin

CPU: entity work.light8080 port map (
  addr_out=>cpuAddrTemp,
 data_in=>cpuDataIn,
  data_out=>cpuDataOut,
 
  intr=>'0',
  io=>cpuIO,
  rd=>cpuRd,
  wr=>cpuWr,
  vma=>cpuVMA,
  
--  clk=>Hz1, --cpuClock,
  clk=>cpuClock,
  reset=>cpuReset
);


--cpu1 : entity work.t80s
--generic map(mode => 0, t2write => 0, iowait => 1)
--port map(
--reset_n => not cpureset,
--clk_n => Hz1,
--wait_n => '1',
--int_n => '1',
--nmi_n => '1',
--busrq_n => '1',
--mreq_n => n_MREQ,
--iorq_n => n_IORQ,
--rd_n => n_RD,
--wr_n => n_WR,
--a => cpuAddr,
--di => cpuDataIn,
--do => cpuDataOut);

------------------
----- RAM
 ram1: entity work.RAM2
 port map (
 rdaddress=>cpuAddr(9 downto 0),
 wraddress=>cpuAddrTemp(9 downto 0),
 clock=>clk,
 data=>cpuDataOut,
 wren=> ramCS and memWR,
 q => RamDataOut
 );
-- PROA: entity work.adprobe port map(cpuAddr&cpuDataIn&cpuVMA&cpuRD&CpuWR&ramCS&memRD&memWR&ioRD&ioWR);

--ram1: entity work.MEMO
--port map (
--address=>cpuAddr(9 downto 0),
--data_in=>cpuDataOut,
--WE=> memWR,
--CE=>ramCS,
--data_out => RamDataOut
--);

------------------
----- ROM
rom1: entity work.ROM
port map (
address=>cpuAddr(9 downto 0),
clock=>clk,
q => RomDataOut
);

----------------
----- 8255 if 1
io1: entity work.pia8255
port map (
reset=>cpuReset,
clken=>'1',
clk=>clk,
rd => ioRD,
wr => ioWR,
cs => pioCS,
d_i => cpuDataOut,
d_o=> pioDataOut,

pa_i=>PA1In,
pb_i=>PB1In,
pc_i=>PC1In,
pa_o=>PA1Out,
pb_o=>PB1Out,
pc_o=>PC1Out,

a=>cpuAddr(1 downto 0)
);


-------------------
-- matrix
KBDM: entity work.matrix port map (clk,rows,cols,keys);
--PROA: entity work.adprobe port map(keyrows&"00"&iord&iowr&'0'&PC1Out(3 downto 0)&"00000000000000000000");
PMIK: entity work.pmikey port map (keys, kreset,kint, PC1Out(3 downto 0),keyrows);
PC1In<='1'&keyrows&"1111";
-- PROA: entity work.adprobe port map(cpuAddr&cpuDataIn&pioCS&cpuRD&CpuWR&cpuIO&memRD&memWR&ioRD&ioWR);
----------------
----- CS logic
memRD <= cpuRd and not cpuIO and cpuVMA;
memWR <= cpuWr and not cpuIO and cpuVMA;
ioRD <=  cpuRd and cpuIO;
ioWR <= cpuWr and cpuIO and cpuVMA;


--memRD <=  not (n_RD or n_MREQ);
--memWR <= not (n_WR or n_MREQ);
--ioRD <=  not (n_RD or n_IORQ);
--ioWR <= not (n_WR or n_IORQ);


ramCS <= '1' when (cpuAddr(15 downto 10)="000111") and (cpuIO='0') else '0';
romCS <= '1' when (cpuAddr(15 downto 10)="000000") and (cpuIO='0') else '0';
pioCS <= '1' when (cpuAddr(7 downto 2)="111110") and (cpuIO='1') else '0';

---bus bus bus
--cpuDataIn <=
--  '1'&keyrows&"1111" when pioCS='1' else
--  RamDataOut when ramCS='1' else
--  RomDataOut when (romCS='1') else;
--  cpuDataIn;

process (clk) is
begin
if rising_edge(clk) then
  if cpuRD='1' then 
	if pioCS='1' then cpuDataIn <= pioDataOut; end if;
	if ramCS='1' then cpuDataIn <= RamDataOut; end if;
	if romCS='1' then cpuDataIn <= RomDataOut; end if;
  end if;	
end if;
end process;



--led3<= not cpuAddr(13);
--led7<= not cpuAddr(14);
--led9<= not cpuAddr(15);

--led3<= not cpuAddr(0);
--led7<= not cpuAddr(1);
--led9<= not cpuAddr(2);

--led3<= not (ramCS and memRD);
--led7<= not (romCS and memRD);
--led9<= not (pioCS and cpuIO);
led3<= keyrows(2);
led7<= keyrows(1);
led9<= keyrows(0);


cpuReset<=not kreset;

--cpuClock<=Hz1;
cpuClock<=cpuClock5;


process (clk) is
	 begin
	   if (rising_edge(clk)) then
			if cpuVMA='1' then
				cpuAddr<=cpuAddrTemp;
			end if;	
	end if;
end process;


	
  process (clk) is
    variable counter:integer:=0;
	 begin
	   if (rising_edge(clk)) then
		  counter:= counter + 1;
		  if (counter<2000000) then Hz1<='1'; else Hz1<='0'; end if;
		end if;

	  if (counter=4000000) then
	    counter:=0;
	  end if;

	end process;

	
	
process (clk)
begin
if rising_edge(clk) then

if cpuClkCount < 31 then -- 4 = 10MHz, 3 = 12.5MHz, 2=16.6MHz, 1=25MHz
cpuClkCount <= cpuClkCount + 1;
else
cpuClkCount <= 0;
end if;
if cpuClkCount < 15 then -- 2 when 10MHz, 2 when 12.5MHz, 2 when 16.6MHz, 1 when 25MHz
cpuClock5 <= '0';
else
cpuClock5 <= '1';
end if; 
end if; --rising edge
end process;	

DSPL: entity work.PMILED port map (anode, cathode,PA1Out, PC1Out(3 downto 0));  -- segment je aktivni v 0
--DSPL: entity work.PMILED port map (anode, cathode,cpuDataIn, "1110");  -- segment je aktivni v 0

--DSPL: entity work.DISP8 port map (anode, cathode,cpuDataIn,PC1Out,cpuAddr, clk);  -- segment je aktivni v 0
--DSPL: entity work.DISP8 port map (anode, cathode,RamDataOut,cpuDataIn,cpuAddr, clk);  -- segment je aktivni v 0
--DSPL: entity work.DISP8 port map (anode, cathode,dalatch,cpuDataIn,adlatch, clk);  -- segment je aktivni v 0

end architecture;