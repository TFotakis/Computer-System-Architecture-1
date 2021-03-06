library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Bus32pkg.ALL;
entity processor is
    Port ( reset : in  STD_LOGIC;
					  clk : in  STD_LOGIC;
					  miss : out  STD_LOGIC);
end processor;

architecture Structural of processor is

component CONTROL
    Port (Instr 							: in  	STD_LOGIC_VECTOR (31 downto 0);
					Reset 							: in  	STD_LOGIC;
					Clk 									: in  	STD_LOGIC;
					PC_sel 						: out  STD_LOGIC;
					RF_WrEn 					: out  STD_LOGIC;
					RF_WrData_sel 	: out  STD_LOGIC_VECTOR (1 downto 0);
					RF_B_sel 					: out  STD_LOGIC;
					ALU_Bin_sel 			: out  STD_LOGIC;
					ALU_func 				: out 	STD_LOGIC_VECTOR (3 downto 0);
					UnknownOpCode: out STD_LOGIC);
end component;

component IFSTAGE 
    Port ( 	EPC : in  STD_LOGIC_VECTOR (31 downto 0);
						PC_Sel : in  STD_LOGIC_VECTOR(1 downto 0);
						PC_LdEn : in  STD_LOGIC;
						Reset : in  STD_LOGIC;
						Clk : in  STD_LOGIC;
						Instr : out  STD_LOGIC_VECTOR (31 downto 0);
						Addr: out  STD_LOGIC_VECTOR (31 downto 0));
end component;

component IFID_Register
    Port ( 	input : in  STD_LOGIC_VECTOR (63 downto 0);
						output : out  STD_LOGIC_VECTOR (63 downto 0);
						clk : in  STD_LOGIC;
						reset : in STD_LOGIC);
end component;

component DECSTAGE
    Port (Instr 						: in  	STD_LOGIC_VECTOR (31 downto 0);
					Awr							: in 	STD_LOGIC_VECTOR (4 downto 0);
					RF_WrEn 				: in  	STD_LOGIC;
					Data		: in  	STD_LOGIC_VECTOR (31 downto 0);
					RF_B_sel 				: in  	STD_LOGIC;
					Reset 					: in  	STD_LOGIC;
					Clk 						: in  	STD_LOGIC;
					ImmedOut 				: out  STD_LOGIC_VECTOR (31 downto 0);
					RF_A 						: out  STD_LOGIC_VECTOR (31 downto 0);
					RF_B 						: out  STD_LOGIC_VECTOR (31 downto 0));
end component;

component WrongAddressControl
    Port ( 	input : in  STD_LOGIC_VECTOR (21 downto 0);
						Instr : in  STD_LOGIC_VECTOR (31 downto 0);
						output : out  STD_LOGIC);
end component;

component IDEX_Register is
    Port ( 	input : in  STD_LOGIC_VECTOR (168 downto 0);
						output : out  STD_LOGIC_VECTOR (168 downto 0);
						clk : in  STD_LOGIC;
						reset : in STD_LOGIC);
end component;

component ALUSTAGE
    Port (RF_A 				: in  	STD_LOGIC_VECTOR (31 downto 0);
				RF_B 					: in  	STD_LOGIC_VECTOR (31 downto 0);
				Immed 			: in  	STD_LOGIC_VECTOR (31 downto 0);
				ALU_Bin_sel	: in  	STD_LOGIC;
				ALU_func 		: in  	STD_LOGIC_VECTOR (3 downto 0);
				ALU_out 			: out  STD_LOGIC_VECTOR (31 downto 0);
				ALU_Zero			: out 	STD_LOGIC);
end component;

component EXDF_Register
    Port ( 	input : in  STD_LOGIC_VECTOR (100 downto 0);
						output : out  STD_LOGIC_VECTOR (100 downto 0);
						clk : in  STD_LOGIC;
						reset : in STD_LOGIC);
end component;

component Cache 
	port (
	clk : in std_logic;
	addr : in std_logic_vector(6 downto 0);
	dout : out std_logic_vector(31 downto 0);
	valid: out std_logic;
	tag: out std_logic_vector(2 downto 0));
end component;

component DFTC_Register
    Port ( 	input : in  STD_LOGIC_VECTOR (136 downto 0);
						output : out  STD_LOGIC_VECTOR (136 downto 0);
						clk : in  STD_LOGIC;
						reset : in STD_LOGIC);
end component;

component TCWB_Register
    Port ( 	input : in  STD_LOGIC_VECTOR (104 downto 0);
						output : out  STD_LOGIC_VECTOR (104 downto 0);
						clk : in  STD_LOGIC;
						reset : in STD_LOGIC);
end component;

component BusMux4
    Port ( input		: in 	Bus4;
					output	: out  STD_LOGIC_VECTOR (31 downto 0);
					control : in  	STD_LOGIC_VECTOR (1 downto 0));
end component;

signal PC_sel_Control_sig, RF_WrEn_sig, RF_B_sel_sig, ALU_Bin_sel_sig, UnknownOpCode_sig, ID_RF_WrEn_sig, EX_RF_WrEn_sig, TC_RF_WrEn_sig, ValidSig, HitSig, WrongAddrOut: STD_LOGIC;
signal RF_WrData_sel_sig, PC_sel_sig : STD_LOGIC_VECTOR(1 downto 0);
signal TagSig :STD_LOGIC_VECTOR(2 downto 0);
signal ALU_func_sig: STD_LOGIC_VECTOR(3 downto 0);
signal CauseRegister: STD_LOGIC_VECTOR(7 downto 0);
signal InstrSig, PCAddr, ImmedSig, RF_A_sig, RF_B_sig, ALU_out_sig, CacheOut, WBData, EPC: STD_LOGIC_VECTOR (31 downto 0);
signal IFIDIn, IFIDOut : STD_LOGIC_VECTOR(63 downto 0);
signal EXDFOut : STD_LOGIC_VECTOR(100 downto 0);
signal DFTCOut : STD_LOGIC_VECTOR(136 downto 0);
signal IDEXOut : STD_LOGIC_VECTOR(168 downto 0);
signal TCWBOut : STD_LOGIC_VECTOR(104 downto 0);

begin

control_0: CONTROL port map(	Instr=>IFIDOut(31 downto 0),
																				Reset=>reset,
																				Clk=>clk,
																				PC_sel=>PC_sel_Control_sig,
																				RF_WrEn=>RF_WrEn_sig,
																				RF_WrData_sel=>RF_WrData_sel_sig,
																				RF_B_sel=>RF_B_sel_sig,
																				ALU_Bin_sel=>ALU_Bin_sel_sig,
																				ALU_func=>ALU_func_sig,
																				UnknownOpCode=>UnknownOpCode_sig);
																				
IFSTAGE_0: IFSTAGE port map(	EPC=>EPC,
																					PC_Sel=>PC_sel_sig,
																					PC_LdEn=>'1',
																					Reset=>reset,
																					Clk=>clk,
																					Instr=>InstrSig,
																					Addr=>PCAddr);


process(UnknownOpCode_sig, clk, reset)
begin
	if(UnknownOpCode_sig='1' or WrongAddrOut='1') then 
		IFIDIn<=std_logic_vector(to_unsigned(0,64));
	else
		IFIDIn(31 downto 0)<=InstrSig;
		IFIDIn(63 downto 32)<=PCAddr;
	end if;
end process;

IFIDRegister: IFID_Register
    Port map( 	input=>IFIDIn,
									output=>IFIDOut,
									clk=>clk,
									reset=>reset);
									
DECSTAGE_0: DECSTAGE port map(Instr=>IFIDOut(31 downto 0),
																									Awr=>TCWBOut(103 downto 99),
																									RF_WrEn=>TCWBOut(96),
																									Data=>WBData,
																									RF_B_sel=>RF_B_sel_sig,
																									Reset=>reset,
																									Clk=>clk,
																									ImmedOut=>ImmedSig,
																									RF_A=>RF_A_sig,
																									RF_B=>RF_B_sig);

ID_RF_WrEn_sig<=(RF_WrEn_sig and not UnknownOpCode_sig);

process(WrongAddrOut, UnknownOpCode_sig, clk, IFIDOut, IDEXOut)
begin
	if(UnknownOpCode_sig='1' and IFIDOut(31 downto 0) /= std_logic_vector(to_unsigned(0,32))) then
		CauseRegister<="00001111";
		EPC<=IFIDOut(63 downto 32);
		PC_sel_sig<="10";
	elsif(WrongAddrOut='1' and IDEXOut(31 downto 26) = "001111") then
		CauseRegister<="11110000";
		EPC<=IDEXOut(167 downto 136);
		PC_sel_sig<="11";
	else
		CauseRegister<=std_logic_vector(to_unsigned(0,8));
--		EPC<=std_logic_vector(to_unsigned(0,32));
		PC_sel_sig(0)<=TCWBOut(104);
		PC_sel_sig(1)<='0';
	end if;
end process;

IDEXRegister: IDEX_Register
    Port map( 	input(31 downto 0)=>IFIDOut(31 downto 0),--Instr
									input(63 downto 32)=>RF_A_sig,
									input(95 downto 64)=>RF_B_sig,
									input(127 downto 96)=>ImmedSig,
									input(128)=>ID_RF_WrEn_sig,
									input(130 downto 129)=>RF_WrData_sel_sig,
									input(131)=>ALU_Bin_sel_sig,
									input(135 downto 132)=>ALU_func_sig,
									input(167 downto 136)=>IFIDOut(63 downto 32), --PCAddr
									input(168)=>PC_sel_Control_sig,
									output=>IDEXOut,
									clk=>clk,
									reset=>reset);

ALUSTAGE_0: ALUSTAGE Port map (RF_A=>IDEXOut(63 downto 32),
																									RF_B=>IDEXOut(95 downto 64),
																									Immed=>IDEXOut(127 downto 96),
																									ALU_Bin_sel=>IDEXOut(131),
																									ALU_func=>IDEXOut(135 downto 132),
																									ALU_out=>ALU_out_sig);

WrongAddr: WrongAddressControl Port map(input=>ALU_out_sig(31 downto 10),
																															Instr=>IDEXOut(31 downto 0),
																															output=>WrongAddrOut);


EX_RF_WrEn_sig<=(IDEXOut(128) and not WrongAddrOut);

EXDFRegister: EXDF_Register port map(	input(31 downto 0)=>IDEXOut(31 downto 0),--Instr
																												input(63 downto 32)=>ALU_out_sig,
																												input(95 downto 64)=>IDEXOut(127 downto 96),--Immed
																												input(96)=>EX_RF_WrEn_sig,
																												input(98 downto 97)=>IDEXOut(130 downto 129),--RF_WrData_sel
																												input(99)=>WrongAddrOut,
																												input(100)=>IDEXOut(168),--PcSel
																												output=>EXDFOut,
																												clk=>clk,
																												reset=>reset);

Cache_0: Cache 
	port map ( 	clk=>clk,
									addr=>EXDFOut(38 downto 32),
									dout=>CacheOut,
									valid=>ValidSig,
									tag=>TagSig);

DFTCRegister: DFTC_Register
    Port map( 	input(31 downto 0)=>EXDFOut(31 downto 0),--Instr
									input(63 downto 32)=>EXDFOut(63 downto 32),--ALUOut
									input(95 downto 64)=>EXDFOut(95 downto 64),--Immed
									input(96)=>EXDFOut(96),--RF_WrEn
									input(98 downto 97)=>EXDFOut(98 downto 97),--RF_WrData_sel
									input(99)=>ValidSig,
									input(102 downto 100)=>TagSig,
									input(134 downto 103)=>CacheOut,
									input(135)=>EXDFOut(99),--WrongAddrOut
									input(136)=>EXDFOut(100), --PcSel
									output=>DFTCOut,
									clk=>clk,
									reset=>reset);

process(DFTCOut, TagSig, ValidSig, clk)
begin
	if((DFTCOut(31 downto 26)="001111" 
	and (DFTCOut(43 downto 41)=TagSig))
	and (DFTCOut(135)='0') and ValidSig='1') then 
		HitSig<='1';
		miss<='0';
	elsif(DFTCOut(31 downto 26)="001111" and DFTCOut(135)='0' and (DFTCOut(43 downto 41)/=TagSig or ValidSig='0')) then
		HitSig<='0';
		miss<='1';
	else
		HitSig<='0';
		miss<='0';
	end if;
end process;

TC_RF_WrEn_sig<=(((not DFTCOut(31)) and (not DFTCOut(30)) and DFTCOut(29) and DFTCOut(28) and DFTCOut(27) and DFTCOut(26)) and HitSig and DFTCOut(96)) or
													(not((not DFTCOut(31)) and (not DFTCOut(30)) and DFTCOut(29) and DFTCOut(28) and DFTCOut(27) and DFTCOut(26)) and DFTCOut(96));

TCWBRegister: TCWB_Register Port map(  input(31 downto 0)=>DFTCOut(134 downto 103),--CacheOut
																													input(63 downto 32)=>DFTCOut(63 downto 32),--ALUOut
																													input(95 downto 64)=>DFTCOut(95 downto 64),--Immed
																													input(96)=>TC_RF_WrEn_sig,--RF_WrEn
																													input(98 downto 97)=>DFTCOut(98 downto 97),--RF_WrData_sel
																													input(103 downto 99)=>DFTCOut(20 downto 16), --Awr(Rd)
																													input(104)=>DFTCOut(136),--PcSel
																													output=>TCWBOut,
																													clk=>clk,
																													reset=>reset);

BusMux4_0: BusMux4 port map(	input(0)=>TCWBOut(63 downto 32),	--ALUOut
																							input(1)=>TCWBOut(95 downto 64),	--Immed
																							input(2)=>TCWBOut(31 downto 0),	--Cache
																							input(3)=>std_logic_vector(to_unsigned(0,32)),
																							output=>WBData,
																							control=>TCWBOut(98 downto 97));
end Structural;