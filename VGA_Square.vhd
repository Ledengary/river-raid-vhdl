library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity VGA_Square is
  port ( CLK_24MHz		: in std_logic;
			RESET				: in std_logic;
			ColorOut			: out std_logic_vector(5 downto 0); -- RED & GREEN & BLUE
			SQUAREWIDTH		: in std_logic_vector(7 downto 0);
			ScanlineX		: in std_logic_vector(10 downto 0);
			ScanlineY		: in std_logic_vector(10 downto 0);
			rightArrow 		: in std_logic;
			leftArrow 		: in std_logic;
			startGame		: in std_logic;
			obstaclesMovingSpeed : Integer range 0 to 10;
			passedAnObstacle : out std_logic;
			accidentHappened	: out std_logic;
			fire 				: in std_logic;
			blownMain				: out std_logic;
			blownYmain			: out std_logic_vector(9 downto 0);
			autoPilot		: in std_logic;
			flag				: out std_logic_vector(9 downto 0)
  );
end VGA_Square;
	
architecture Behavioral of VGA_Square is
  
	signal ColorOutput: std_logic_vector(5 downto 0);
  
	signal SquareX: std_logic_vector(9 downto 0) := "0101000111";  
	signal SquareY: std_logic_vector(9 downto 0) := "0110101100";  
	signal SquareXMoveDir, SquareYMoveDir: std_logic := '0';
	--constant SquareWidth: std_logic_vector(4 downto 0) := "11001";
   constant SquareXmin: std_logic_vector(9 downto 0) := "0000000001";
	signal SquareXmax: std_logic_vector(9 downto 0); -- := "1010000000"-SquareWidth;
	constant SquareYmin: std_logic_vector(9 downto 0) := "0000000001";
	signal SquareYmax: std_logic_vector(9 downto 0); -- := "0111100000"-SquareWidth;
	signal ColorSelect: std_logic_vector(2 downto 0) := "001";
	signal Prescaler: std_logic_vector(30 downto 0) := (others => '0');
	signal obstaclesDelay: std_logic_vector(30 downto 0) := (others => '0');
	signal gameMode : std_logic := '0';
	signal obstacleSetOrNot : std_logic := '0';
	signal rrr : std_logic_vector(31 downto 0) := "010101010101" & "0101000111" & "0110101100";
	signal obX : std_logic_vector(9 downto 0) := (others => '0');
	signal obY : std_logic_vector(9 downto 0) := (others => '0');
	type arrayOfVectors is array (0 to 13) of std_logic_vector(9 downto 0);
	signal randomObjects: arrayOfVectors;
	signal delayFor0 : std_logic_vector(7 downto 0) := (others => '0');
	signal delayFor2 : std_logic_vector(7 downto 0):= (others => '0');
	signal delayFor4 : std_logic_vector(7 downto 0):= (others => '0');
	signal delayFor6 : std_logic_vector(7 downto 0):= (others => '0');
	signal delayFor8 : std_logic_vector(7 downto 0):= (others => '0');
	signal delayFor10 : std_logic_vector(7 downto 0):= (others => '0');
	signal waitingTimeFor0 : std_logic_vector(7 downto 0) := (others => '0');
	signal waitingTimeFor2 : std_logic_vector(7 downto 0):= (others => '0');
	signal waitingTimeFor4 : std_logic_vector(7 downto 0):= (others => '0');
	signal waitingTimeFor6 : std_logic_vector(7 downto 0):= (others => '0');
	signal waitingTimeFor8 : std_logic_vector(7 downto 0):= (others => '0');
	signal waitingTimeFor10 : std_logic_vector(7 downto 0):= (others => '0');
	signal endOfLineFor0 : std_logic := '0';
	signal endOfLineFor2 : std_logic := '0';
	signal endOfLineFor4 : std_logic := '0';
	signal endOfLineFor6 : std_logic := '0';
	signal endOfLineFor8 : std_logic := '0';
	signal endOfLineFor10 : std_logic := '0';
	signal passed : std_logic := '0';
	signal previousPassed1 : std_logic_vector(9 downto 0) := (others => '0');
	signal previousPassed3 : std_logic_vector(9 downto 0) := (others => '0');
	signal previousPassed5 : std_logic_vector(9 downto 0) := (others => '0');
	signal previousPassed7 : std_logic_vector(9 downto 0) := (others => '0');
	signal previousPassed9 : std_logic_vector(9 downto 0) := (others => '0');
	signal previousPassed11 : std_logic_vector(9 downto 0) := (others => '0');
	signal previous1, previous3, previous5, previous7, previous9, previous11 : std_logic_vector(9 downto 0) := (others => '0');
	signal accident : std_logic := '0';
	signal fireDelay : Integer range 0 to 12000001 := 0;
	signal fireX : std_logic_vector(9 downto 0) := "0000000000";
	signal fireY : std_logic_vector(9 downto 0) := "0000000000";
	signal fireSet : std_logic := '0';
	signal fireDelay2 : std_logic_vector(30 downto 0) := (others => '0');
	signal fireBlown : std_logic := '0';
	signal blownY : std_logic_vector(9 downto 0) := (others => '0');
	signal pilotX : std_logic_vector(9 downto 0) := (others => '0');
	signal pilotY : std_logic_vector(9 downto 0) := (others => '0');
	type arrayOfVectors2 is array (0 to 5) of std_logic_vector(9 downto 0);
	signal toBeSortedList: arrayOfVectors2;
	signal bubbleSortTemp : std_logic_vector(9 downto 0) := (others => '0');
	signal startShapeX : std_logic_vector(9 downto 0) := "0000111111";
	signal startShapeY : std_logic_vector(9 downto 0) := "1001111000";
	signal gating : std_logic := '1';
	signal gates0 : std_logic_vector(9 downto 0) := "0000111111";
	signal gates1 : std_logic_vector(9 downto 0) := "1001111000";
	signal gates2 : std_logic_vector(9 downto 0) := "0101000111" + "00011001" + 10;
	signal gates3 : std_logic_vector(9 downto 0) := "1001111000";
	function eligibleCoordinatesX(x : std_logic_vector(9 downto 0)) return std_logic is
	begin
		if(x > "0000111111" and x + "00011001" < "1001111000") then
			return '1';
		else
			return '0';
		end if;
	end function;
	function eligibleCoordinatesY(y : std_logic_vector(9 downto 0)) return std_logic is
	begin
		if(y > "0000000011" and y < "0110101100") then
			return '1';
		else
			return '0';
		end if;
	end function;
	function eligibleObstacleCoordinates(x : std_logic_vector(9 downto 0)) return std_logic_vector is
	begin
		if(x <= "0000111111") then
			return "0000111111" + 10;
		elsif(x + "00011001" >= "1001111000") then
			return x - ("1001111000" - (x + "00011001")) - 10;
		else
			return x;
		end if;
	end function;

begin

	process(CLK_24MHz)
		function lfsr32(x : std_logic_vector(31 downto 0)) return std_logic_vector is
		begin
			return x(30 downto 0) & (x(0) xnor x(1) xnor x(21) xnor x(31));
		end function;
	begin
		if rising_edge(CLK_24MHz) then
			if RESET='1' then
				rrr <= "010101010101" & "0101000111" & "0110101100";
			else
				rrr <= lfsr32(rrr);
			end if;
		end if;
	end process randomGeneratorProcess;		

	randomObjectProcess : process(CLK_24MHz, RESET)
		variable I : Integer range 0 to 6 := 0;
	begin
		if RESET = '1' then
			randomObjects(0) <= (others => '0');
			randomObjects(1) <= (others => '0');
			randomObjects(2) <= (others => '0');
			randomObjects(3) <= (others => '0');
			randomObjects(4) <= (others => '0');
			randomObjects(5) <= (others => '0'); 
			randomObjects(6) <= (others => '0');
			randomObjects(7) <= (others => '0');
			randomObjects(8) <= (others => '0');
			randomObjects(9) <= (others => '0');
			randomObjects(10) <= (others => '0');
			randomObjects(11) <= (others => '0'); 
			randomObjects(12) <= "0001000000";
			randomObjects(13) <= "1001111000";
			delayFor0 <= (others => '0');
			delayFor2 <= (others => '0');
			delayFor4 <= (others => '0');
			delayFor6 <= (others => '0');
			delayFor8 <= (others => '0');
			delayFor10 <= (others => '0');
			waitingTimeFor0 <= (others => '0');
			waitingTimeFor2 <= (others => '0');
			waitingTimeFor4 <= (others => '0');
			waitingTimeFor6 <= (others => '0');
			waitingTimeFor8 <= (others => '0');
			waitingTimeFor10 <= (others => '0');
			endOfLineFor0 <= '0';
			endOfLineFor2 <= '0';
			endOfLineFor4 <= '0';
			endOfLineFor6 <= '0';
			endOfLineFor8 <= '0';
			endOfLineFor10 <= '0';
			obstacleSetOrNot <= '0';
			gates0			<= "0000111111";
			gates1			<= "1001111000";
			gates2			<= "0101000111" + squareWidth + 10;
			gates3			<= "1001111000";
			gating 			<= '1';
		elsif rising_edge(CLK_24MHz) then
			if(gameMode='0' and obstacleSetOrNot='0') then
				randomObjects(0) <= "0000000001";
				randomObjects(1) <= eligibleObstacleCoordinates(rrr(19 downto 10));
				randomObjects(2) <= "0000000001";
				randomObjects(3) <= eligibleObstacleCoordinates(rrr(14 downto 5));
				randomObjects(4) <= "0000000001";
				randomObjects(5) <= eligibleObstacleCoordinates(rrr(22 downto 13));
				randomObjects(6) <= "0000000001";
				randomObjects(7) <= eligibleObstacleCoordinates(rrr(12 downto 3));
				randomObjects(8) <= "0000000001";
				randomObjects(9) <= eligibleObstacleCoordinates(rrr(15 downto 6));
				randomObjects(10) <= "0000000001";
				randomObjects(11) <= eligibleObstacleCoordinates(rrr(25 downto 16));
				randomObjects(12) <= "0001000000";
				randomObjects(13) <= "1001111000";
				obstacleSetOrNot <= '1';
				gates0			<= "0000111111";
				gates1			<= "1001111000";
				gates2			<= "0101000111" + squareWidth + 10;
				gates3			<= "1001111000";
				gating 			<= '1';
			elsif(gameMode='1' and obstacleSetOrNot='1') then
				obstaclesDelay <= obstaclesDelay + obstaclesMovingSpeed;
				if obstaclesDelay > "11111111110111111" then
--					randomObjects(12) <= "0000111111";
--					randomObjects(13) <= "1001111000";
					if(gating='1') then	
						gates1 <=  gates1 + 1;
						gates3 <=  gates3 + 1;
						if(gates1="1111111101" and gates3="1111111101") then
							gating <= '0';
						end if;
					end if;
					if(delayFor0 = waitingTimeFor0) then
						endOfLineFor0 <= '0';
						previous1 <= randomObjects(1);
						randomObjects(1) <= randomObjects(1) + 1;
					else
						delayFor0 <= delayFor0 + 1;
					end if;
					if(delayFor2 = waitingTimeFor2) then
						endOfLineFor2 <= '0';
						previous3 <= randomObjects(3);
						randomObjects(3) <= randomObjects(3) + 1;
					else
						delayFor2 <= delayFor2 + 1;
					end if;
					if(delayFor4 = waitingTimeFor4) then
						endOfLineFor4 <= '0';
						previous5 <= randomObjects(5);
						randomObjects(5) <= randomObjects(5) + 1;
					else
						delayFor4 <= delayFor4 + 1;
					end if;
					if(delayFor6 = waitingTimeFor6) then
						endOfLineFor6 <= '0';
						previous7 <= randomObjects(7);
						randomObjects(7) <= randomObjects(7) + 1;
					else
						delayFor6 <= delayFor6 + 1;
					end if;
					if(delayFor8 = waitingTimeFor8) then
						endOfLineFor8 <= '0';
						previous9 <= randomObjects(9);
						randomObjects(9) <= randomObjects(9) + 1;
					else
						delayFor8 <= delayFor8 + 1;
					end if;
					if(delayFor10 = waitingTimeFor10) then
						endOfLineFor10 <= '0';
						previous11 <= randomObjects(11);
						randomObjects(11) <= randomObjects(11) + 1;
					else
						delayFor10 <= delayFor10 + 1;
					end if;
					
					if(randomObjects(1)="0000000000") then
						randomObjects(1) <= "0000000001";
						endOfLineFor0 <= '1';
						randomObjects(0) <= eligibleObstacleCoordinates(rrr(19 downto 10));
						waitingTimeFor0 <= rrr(7 downto 0);			
						delayFor0 <= (others => '0');
					end if;
					if(randomObjects(3)="0000000000") then
						randomObjects(3) <= "0000000001";
						endOfLineFor2 <= '1';
						randomObjects(2) <= eligibleObstacleCoordinates(rrr(14 downto 5));
						waitingTimeFor2 <= rrr(7 downto 0);
						delayFor2 <= (others => '0');
					end if;
					if(randomObjects(5)="0000000000") then
						randomObjects(5) <= "0000000001";
						endOfLineFor4 <= '1';
						randomObjects(4) <= eligibleObstacleCoordinates(rrr(22 downto 13));
						waitingTimeFor4 <= rrr(7 downto 0);
						delayFor4 <= (others => '0');
					end if;
					if(randomObjects(7)="0000000000") then
						randomObjects(7) <= "0000000001";
						endOfLineFor6 <= '1';
						randomObjects(6) <= eligibleObstacleCoordinates(rrr(12 downto 3));
						waitingTimeFor6 <= rrr(7 downto 0);
						delayFor6 <= (others => '0');
					end if;
					if(randomObjects(9)="0000000000") then
						randomObjects(9) <= "0000000001";
						endOfLineFor8 <= '1';
						randomObjects(8) <= eligibleObstacleCoordinates(rrr(18 downto 9));
						waitingTimeFor8 <= rrr(7 downto 0);
						delayFor8 <= (others => '0');
					end if;
					if(randomObjects(11)="0000000000") then
						randomObjects(11) <= "0000000001";
						endOfLineFor10 <= '1';
						randomObjects(10) <= eligibleObstacleCoordinates(rrr(25 downto 16));
						waitingTimeFor10 <= rrr(7 downto 0);
						delayFor10 <= (others => '0');
					end if;
					
					if(randomObjects(1) < fireY and fireY < randomObjects(1)+squareWidth and fireX > randomObjects(0) and 					fireX < randomObjects(0) + squareWidth) then
						blownY <= randomObjects(1) ;
						fireBlown <= '1';
						randomObjects(1) <= "0000000001";
						endOfLineFor0 <= '1';
						randomObjects(0) <= eligibleObstacleCoordinates(rrr(19 downto 10));
						waitingTimeFor0 <= rrr(7 downto 0);			
						delayFor0 <= (others => '0');
					end if;
					if(randomObjects(3) < fireY and fireY < randomObjects(3)+squareWidth and fireX > randomObjects(2) and 					fireX < randomObjects(2) + squareWidth) then
						blownY <= randomObjects(3) ;
						fireBlown <= '1';
						randomObjects(3) <= "0000000001";
						endOfLineFor2 <= '1';
						randomObjects(2) <= eligibleObstacleCoordinates(rrr(14 downto 5));
						waitingTimeFor2 <= rrr(7 downto 0);
						delayFor2 <= (others => '0');
					end if;
					if(randomObjects(5) < fireY and fireY < randomObjects(5)+squareWidth and fireX > randomObjects(4) and 					fireX < randomObjects(4) + squareWidth + squareWidth) then
						blownY <= randomObjects(5) ;
						fireBlown <= '1';
						randomObjects(5) <= "0000000001";
						endOfLineFor4 <= '1';
						randomObjects(4) <= eligibleObstacleCoordinates(rrr(22 downto 13));
						waitingTimeFor4 <= rrr(7 downto 0);
						delayFor4 <= (others => '0');
					end if;
					if(randomObjects(7) < fireY and fireY < randomObjects(7)+squareWidth and fireX > randomObjects(6) and 					fireX < randomObjects(6) + squareWidth + squareWidth) then
						blownY <= randomObjects(7) ;
						fireBlown <= '1';
						randomObjects(7) <= "0000000001";
						endOfLineFor6 <= '1';
						randomObjects(6) <= eligibleObstacleCoordinates(rrr(12 downto 3));
						waitingTimeFor6 <= rrr(7 downto 0);
						delayFor6 <= (others => '0');
					end if;
					if(randomObjects(9) < fireY and fireY < randomObjects(9)+squareWidth+squareWidth and fireX > randomObjects(8) and 					fireX < randomObjects(8) + squareWidth) then
						blownY <= randomObjects(9) ;
						fireBlown <= '1';
						randomObjects(9) <= "0000000001";
						endOfLineFor8 <= '1';
						randomObjects(8) <= eligibleObstacleCoordinates(rrr(18 downto 9));
						waitingTimeFor8 <= rrr(7 downto 0);
						delayFor8 <= (others => '0');
					end if;
					if(randomObjects(11) < fireY and fireY < randomObjects(11)+squareWidth and fireX > randomObjects(10) and 					fireX < randomObjects(10) + squareWidth) then
						blownY <= randomObjects(11) ;
						fireBlown <= '1';
						randomObjects(11) <= "0000000001";
						endOfLineFor10 <= '1';
						randomObjects(10) <= eligibleObstacleCoordinates(rrr(25 downto 16));
						waitingTimeFor10 <= rrr(7 downto 0);
						delayFor10 <= (others => '0');
					end if;
					obstaclesDelay <= (others => '0');
				end if;
			end if;
		end if;
	end process;
	
	accidentProcess : process(CLK_24MHz, RESET)
	begin
		if(RESET='1') then
			accident <= '0';
		elsif(rising_edge(CLK_24MHz)) then
			if(SquareY = randomObjects(1) + SquareWidth and ((randomObjects(0) > squareX and randomObjects(0) < squareX+SquareWidth) or (randomObjects(0)+SquareWidth > squareX and randomObjects(0)+SquareWidth < squareX+SquareWidth))) then
				accident <= '1';
			elsif(SquareY = randomObjects(3) + SquareWidth and ((randomObjects(2) > squareX and randomObjects(2) < squareX+SquareWidth) or (randomObjects(2)+SquareWidth > squareX and randomObjects(2)+SquareWidth < squareX+SquareWidth))) then
				accident <= '1';
			elsif(SquareY = randomObjects(5) + SquareWidth and ((randomObjects(4) > squareX and randomObjects(4) < squareX+SquareWidth) or (randomObjects(4)+SquareWidth+SquareWidth > squareX and randomObjects(4)+SquareWidth < squareX+SquareWidth))) then
				accident <= '1';
			elsif(SquareY = randomObjects(7) + SquareWidth and ((randomObjects(6) > squareX and randomObjects(6) < squareX+SquareWidth) or (randomObjects(6)+SquareWidth > squareX and randomObjects(6)+SquareWidth+SquareWidth < squareX+SquareWidth))) then
				accident <= '1';
			elsif(SquareY = randomObjects(9) + SquareWidth + SquareWidth and ((randomObjects(8) > squareX and randomObjects(8) < squareX+SquareWidth) or (randomObjects(7)+SquareWidth > squareX and randomObjects(7)+SquareWidth < squareX+SquareWidth))) then
				accident <= '1';
			elsif(SquareY = randomObjects(11) + SquareWidth and ((randomObjects(10) > squareX and randomObjects(10) < squareX+SquareWidth) or (randomObjects(10)+SquareWidth > squareX and randomObjects(10)+SquareWidth < squareX+SquareWidth))) then
				accident <= '1';
			elsif(squareX = "0000111111" or squareX + squareWidth = "1001111000") then
				accident <= '1';
			else
				accident <= '0';
			end if;
		end if;
	end process;
	
	obstaclesPassProcess : process(CLK_24MHz, RESET)
	begin
		if(RESET='1') then
			passed <= '0';
		elsif(rising_edge(CLK_24MHz)) then
			if(SquareY+SquareWidth = randomObjects(1) and previousPassed1 /= randomObjects(1)) then
				passed <= '1';
				previousPassed1 <= randomObjects(1);
			elsif(SquareY+SquareWidth = randomObjects(3) and previousPassed3 /= randomObjects(3)) then
				passed <= '1';
				previousPassed3 <= randomObjects(3);
			elsif(SquareY+SquareWidth = randomObjects(5) and previousPassed5 /= randomObjects(5)) then
				passed <= '1';
				previousPassed5 <= randomObjects(5);
			elsif(SquareY+SquareWidth = randomObjects(7) and previousPassed7 /= randomObjects(7)) then
				passed <= '1';
				previousPassed7 <= randomObjects(7);
			elsif(SquareY+SquareWidth = randomObjects(9) and previousPassed9 /= randomObjects(9)) then
				passed <= '1';
				previousPassed9 <= randomObjects(9);
			elsif(SquareY+SquareWidth = randomObjects(11) and previousPassed11 /= randomObjects(11)) then
				passed <= '1';
				previousPassed11 <= randomObjects(11);
			else
				if(randomObjects(1) /= previous1) then
					previousPassed1 <= randomObjects(1);
				end if;
				if(randomObjects(3) /= previous3) then 
					previousPassed3 <= randomObjects(3);
				end if;
				if(randomObjects(5) /= previous5) then 
					previousPassed5 <= randomObjects(5);
				end if;
				if(randomObjects(7) /= previous7) then 
					previousPassed7 <= randomObjects(7);
				end if;
				if(randomObjects(9) /= previous9) then 
					previousPassed9 <= randomObjects(9);
				end if;
				if(randomObjects(11) /= previous11) then
					previousPassed11 <= randomObjects(11);
				end if;
				passed <= '0';
			end if;
		end if;	
	end process;

	PrescalerCounter: process(CLK_24MHz, RESET)
	begin
		if RESET = '1' then
			Prescaler <= (others => '0');
			SquareX <= "0101000111"; -- 0000111111 -- 1001111000
			SquareY <= "0110101100";
			SquareXMoveDir <= '0';
			SquareYMoveDir <= '0';
			ColorSelect <= "001";
			toBeSortedList(0) <= (others => '0');
			toBeSortedList(1) <= (others => '0');
			toBeSortedList(2) <= (others => '0');
			toBeSortedList(3) <= (others => '0');
			toBeSortedList(4) <= (others => '0');
			toBeSortedList(5) <= (others => '0');
			startShapeY <= "1001111000";
			gameMode <= '0';
		elsif rising_edge(CLK_24MHz) then
			gameMode <= gameMode;
			if(accident='1') then
				gameMode <= '0';
			end if;
			if(startGame='1') then
				gameMode <= '1';
			end if;
			-----------------------------------------------------------------------------
			if(eligibleCoordinatesY(randomObjects(1))='1') then
				toBeSortedList(0) <= randomObjects(0);
			else
				toBeSortedList(0) <= (others=>'1');
			end if;
			if(eligibleCoordinatesY(randomObjects(3))='1') then
				toBeSortedList(1) <= randomObjects(2);
			else
				toBeSortedList(1) <= (others=>'1');
			end if;
			if(eligibleCoordinatesY(randomObjects(5))='1') then
				toBeSortedList(2) <= randomObjects(4);
			else
				toBeSortedList(2) <= (others=>'1');
			end if;
			if(eligibleCoordinatesY(randomObjects(7))='1') then
				toBeSortedList(3) <= randomObjects(6);
			else
				toBeSortedList(3) <= (others=>'1');
			end if;
			if(eligibleCoordinatesY(randomObjects(9))='1') then
				toBeSortedList(4) <= randomObjects(8);
			else
				toBeSortedList(4) <= (others=>'1');
			end if;
			if(eligibleCoordinatesY(randomObjects(11))='1') then
				toBeSortedList(5) <= randomObjects(10);
			else
				toBeSortedList(5) <= (others=>'1');
			end if;
			for i in 0 to 4 loop
				for j in 0 to 4-i loop
					if (toBeSortedList(j) > toBeSortedList(j + 1)) then
						bubbleSortTemp <= toBeSortedList(j);
						toBeSortedList(j) <= toBeSortedList(j + 1);
						toBeSortedList(j + 1) <= bubbleSortTemp;
					end if;
				end loop;
			end loop;
			------------------------------------------------------------------------------
			Prescaler <= Prescaler + 1;	
			if Prescaler = "11000011010100000" then  -- Activated every 0,002 sec (2 msec)
				if(gameMode='1' and autoPilot='0' and gating='0') then
					if(rightArrow='1' and leftArrow='0') then
						SquareX <= SquareX + 1;
					elsif(leftArrow='1' and rightArrow='0') then
						SquareX <= SquareX - 1;				
					end if;
				elsif(gameMode='1' and autoPilot='1' and gating='0') then
					if((eligibleCoordinatesX(toBeSortedList(5))='1') or eligibleCoordinatesX(squareX)='0') then
						if(toBeSortedList(5) - (toBeSortedList(4) + squareWidth+squareWidth) > squareWidth + 4) then
							squareX <= std_logic_vector(toBeSortedList(4) + squareWidth + squareWidth + 1) + 3;
						else
							squareX <= (others => '1');
						end if;
					end if;
					if((eligibleCoordinatesX(toBeSortedList(4))='1') or eligibleCoordinatesX(squareX)='0') then
						if(toBeSortedList(4) - (toBeSortedList(3) + squareWidth+squareWidth) > squareWidth + 4) then
							squareX <= std_logic_vector(toBeSortedList(3) + squareWidth + squareWidth + 1) + 3;
						else
							squareX <= (others => '1');
						end if;
					end if;
					if((eligibleCoordinatesX(toBeSortedList(3))='1') or eligibleCoordinatesX(squareX)='0') then
						if(toBeSortedList(3) - (toBeSortedList(2) + squareWidth+squareWidth) > squareWidth + 4) then
							squareX <= std_logic_vector(toBeSortedList(2) + squareWidth + squareWidth + 1) + 3;
						else
							squareX <= (others => '1');
						end if;
					end if;
					if((eligibleCoordinatesX(toBeSortedList(2))='1') or eligibleCoordinatesX(squareX)='0') then
						if(toBeSortedList(2) - (toBeSortedList(1) + squareWidth+squareWidth) > squareWidth + 4) then
							squareX <= std_logic_vector(toBeSortedList(1) + squareWidth + squareWidth + 1) + 3;
						else
							squareX <= (others => '1');
						end if;
					end if;
					if((eligibleCoordinatesX(toBeSortedList(1))='1') or eligibleCoordinatesX(squareX)='0') then
						if(toBeSortedList(1) - (toBeSortedList(0) + squareWidth+squareWidth) > squareWidth + 4) then
							squareX <= std_logic_vector(toBeSortedList(0) + squareWidth + squareWidth + 1) + 3;
						else
							squareX <= (others => '1');
						end if;
					end if;
				end if;
				Prescaler <= (others => '0');
			end if;
		end if;
	end process PrescalerCounter; 
		
	fireProcess : process(CLK_24MHz, RESET)
	begin
		if RESET = '1' then
			fireX <= "0000000000";
			fireY <= "0000000000";
			fireSet <= '0';
			fireDelay <= 0;
			fireDelay2 <= (others => '0');
		elsif(rising_edge(CLK_24MHz)) then
			if(fireSet='0') then
				fireDelay <= 0;
				if(fire='1' and gameMode='1') then
					fireX <= squareX + "0001011";
					fireY <= squareY;
					fireSet <= '1';
				end if;
			else
				fireDelay2 <= fireDelay2 + obstaclesMovingSpeed;
				if(fireDelay2>="00011111010100000") then
					fireDelay2 <= (others => '0');
					fireY <= fireY - 1;
					if(fireY="0000000000") then
						fireSet <= '0';
					end if;
				end if;
			end if;
		end if;
	end process;
	
	process(CLK_24MHz, RESET) is
		variable J : Integer range 0 to randomObjects'LENGTH + 1 := 0;
		variable obstacleX, obstacleY : std_logic_vector(9 downto 0);
	begin
	
--				gates0			<= "0000111111";
--				gates1			<= "1001111000";
--				gates2			<= "0101000111" + squareWidth + 10;
--				gates3			<= "1001111000";
--				gating 			<= '1';
--				
--	signal SquareX: std_logic_vector(9 downto 0) := "0101000111";  
--	signal SquareY: std_logic_vector(9 downto 0) := "0110101100";  

		if rising_edge(CLK_24MHz) then
--			elsif(ScanlineX > "0000111111" and ScanlineX < "0101000100" and ScanlineY > "1001111000" and ScanlineY < "1111111110") then
--				colorOutput <= "001100";
--			elsif(ScanlineX > "0101100111" and ScanlineX < "1001111000" and ScanlineY > "1001111000" and ScanlineY < "1111111110") then
--				colorOutput <= "001100";
--			end if;
			if(ScanlineX >= randomObjects(12) AND ScanlineY >= randomObjects(13) AND ScanlineX < randomObjects(12)+SquareWidth AND ScanlineY < randomObjects(13)+SquareWidth) then
				ColorOutput <=	"110011";
			elsif(ScanlineX <= "0000111111" or ScanlineX >= "1001111000") then
				ColorOutput <=	"001100";
			elsif(ScanlineX >= SquareX AND ScanlineY >= SquareY AND ScanlineX < SquareX+SquareWidth AND ScanlineY < SquareY+SquareWidth) then
				ColorOutput <=	"001100";
			elsif(ScanlineX >= randomObjects(0) AND ScanlineY >= randomObjects(1) AND ScanlineX < randomObjects(0)+SquareWidth AND ScanlineY < randomObjects(1)+SquareWidth) then
				ColorOutput <=	"001100";
			elsif(ScanlineX >= randomObjects(2) AND ScanlineY >= randomObjects(3) AND ScanlineX < randomObjects(2)+SquareWidth AND ScanlineY < randomObjects(3)+SquareWidth) then
				ColorOutput <=	"110000";
			elsif(ScanlineX >= randomObjects(4) AND ScanlineY >= randomObjects(5) AND ScanlineX < randomObjects(4)+SquareWidth+SquareWidth AND ScanlineY < randomObjects(5)+SquareWidth) then
				ColorOutput <=	"110000";
			elsif(ScanlineX >= randomObjects(6) AND ScanlineY >= randomObjects(7) AND ScanlineX < randomObjects(6)+SquareWidth+SquareWidth AND ScanlineY < randomObjects(7)+SquareWidth) then
				ColorOutput <=	"110000";
			elsif(ScanlineX >= randomObjects(8) AND ScanlineY >= randomObjects(9) AND ScanlineX < randomObjects(8)+SquareWidth AND ScanlineY < randomObjects(9)+SquareWidth+SquareWidth) then
				ColorOutput <=	"110011";
			elsif(ScanlineX >= randomObjects(10) AND ScanlineY >= randomObjects(11) AND ScanlineX < randomObjects(10)+SquareWidth AND ScanlineY < randomObjects(11)+SquareWidth) then
				ColorOutput <=	"110000";
			elsif(ScanlineX >= fireX AND ScanlineY >= fireY AND ScanlineX < fireX+"00000111" AND ScanlineY < fireY+SquareWidth) then
				ColorOutput <=	"001100";
			else				
				ColorOutput <=	"000011";
			end if;
--				if((to_integer(unsigned(scanlinex)) - to_integer(unsigned(startShapeX))) <= (to_integer(unsigned(scanlineY)) - to_integer(unsigned(startShapeY)))) then
--					colorOutput <= "001100";
--				else
--				colorOutput <= "110000";
		end if;
	end process;

	ColorOut <= ColorOutput;
	passedAnObstacle <= passed;
	accidentHappened <= accident;
	blownMain <= fireBlown;
	blownYmain <= blownY;
	flag <= startShapeY(9 downto 1) & gating;
	SquareXmax <= "1010000000"-SquareWidth; -- (640 - SquareWidth)
	SquareYmax <= "0111100000"-SquareWidth;	-- (480 - SquareWidth)
end Behavioral;

