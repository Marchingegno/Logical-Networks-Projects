----------------------------------------------------------------------------------
--Progetto finale Reti Logiche
--Scaglione prof. Salice
--
--MEMBRI
--
--Nome      Cognome          Codice Matricola        Codice Persona
--
--Matteo    Marchisciana        870199                  10586574
--Andrea    Marcer              868629                  10537040
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use IEEE.NUMERIC_STD.ALL;


entity project_reti_logiche is
port(
	i_clk : in std_logic;
	i_start : in std_logic;
	i_rst : in std_logic;
	i_data : in std_logic_vector(7 downto 0);
	o_address : out std_logic_vector(15 downto 0);
	o_done : out std_logic;
	o_en : out std_logic;
	o_we : out std_logic;
	o_data : out std_logic_vector(7 downto 0)
);
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

--State declaration
type state_type is (
	 WAIT_START 		--Inizializes all the signals and waits the i_start signal.
	,START				--Requests the input mask to the RAM.
	,MEM_MASK			--Allows to memorize the mask, and requests to the RAM the X coordinate of the point.
	,MEM_XPOINT			--Allows to memorize the X coordinate of the point, and requests to the RAM the Y coordinate of the point
	,MEM_YPOINT			--Allows to memorize the Y coordinate of the point, and requests to the RAM the X coordinate of a centroid.
	,MEM_XCENTROID		--Allows to memorize the X coordinate of a centroid, and requests to the RAM the Y coordinate of a centroid.
	,MEM_YCENTROID		--Allows to memorize the Y coordinate of a centroid.
	,COMPUTE_MIN_DIST	--Calculates the distance between the current centroid and the point, and checks if it is less than the current minimum distance.
	,GIVE_OUTPUT		--Writes the output mask to the ram.
	,DONE				--Raises the done signal and resets the component.
);
signal current_state, next_state : state_type;

--Constant declaration
constant ZERO : std_logic_vector(7 downto 0) := "00000000";
constant ONE : std_logic_vector(7 downto 0) := "00000001";
constant ZERO_ADDRESS : std_logic_vector(15 downto 0) := "0000000000000000";
constant ONE_ADDRESS : std_logic_vector(15 downto 0) := "0000000000000001";
constant MAXDISTANCE : std_logic_vector(8 downto 0) := "111111111";
constant MASK_ADDRESS : std_logic_vector(15 downto 0) := "0000000000000000";
constant XP_ADDRESS : std_logic_vector(15 downto 0) := "0000000000010001";
constant YP_ADDRESS : std_logic_vector(15 downto 0) := "0000000000010010";
constant OMASK_ADDDRESS : std_logic_vector(15 downto 0) := "0000000000010011";

--Signal declaration
signal XP, XP_register, YP, YP_register: std_logic_vector(7 downto 0);
signal XC, XC_register, YC, YC_register: std_logic_vector(7 downto 0);
signal MASK, MASK_register: std_logic_vector(7 downto 0);
signal curr_O_MASK, next_O_MASK: std_logic_vector(7 downto 0);
signal X_DIST, Y_DIST : std_logic_vector(8 downto 0);
signal TOT_DIST : std_logic_vector(8 downto 0);
signal curr_MIN_DIST, next_MIN_DIST : std_logic_vector(8 downto 0);
signal currPoint, nextPoint : std_logic_vector(7 downto 0);
signal curr_ram_address, next_ram_address : std_logic_vector(15 downto 0);

begin

	--Flip flop instantiation
	MASK <= i_data when (current_state = MEM_MASK) else MASK_register;
	XP <= i_data when (current_state = MEM_XPOINT) else XP_register;
	YP <= i_data when (current_state = MEM_YPOINT) else YP_register;
	XC <= i_data when (current_state = MEM_XCENTROID) else XC_register;
	YC <= i_data when (current_state = MEM_YCENTROID) else YC_register;

    --Computation of the distance between the centroid and the main point
	X_DIST <= ('0' & (std_logic_vector(unsigned(XC) - unsigned(XP)))) when (XC >= XP) else ('0' & (std_logic_vector(unsigned(XP) - unsigned(XC))));
	Y_DIST <= ('0' & (std_logic_vector(unsigned(YC) - unsigned(YP)))) when (YC >= YP) else ('0' & (std_logic_vector(unsigned(YP) - unsigned(YC))));
	TOT_DIST <= std_logic_vector(unsigned(X_DIST) + unsigned(Y_DIST));

    --Process that updates the signals and the registers.
	state_reg: process(i_clk, i_rst, curr_ram_address, next_state, next_ram_address, nextPoint, next_O_MASK, next_MIN_DIST)   --governa le transizioni e il reset asincrono
	begin

		if rising_edge(i_clk) then
			curr_ram_address <= next_ram_address;
			currPoint <= nextPoint;
			curr_O_MASK <= next_O_MASK;
			curr_MIN_DIST <= next_MIN_DIST;
			  if i_rst='1' then
						current_state <= WAIT_START;
						XP_register <= ZERO;
	          YP_register <= ZERO;
	          XC_register <= ZERO;
	          YC_register <= ZERO;
	          MASK_register <= ZERO;
	      else
						current_state <= next_state;
						XP_register <= XP;
	          YP_register <= YP;
	          XC_register <= XC;
	          YC_register <= YC;
	          MASK_register <= MASK;
	      end if;
		end if;

	end process;

    --Process that runs the component.
	fsa: process(current_state, curr_ram_address, currPoint, i_start, MASK, curr_O_MASK)
	begin

		case current_state is
			when WAIT_START =>
				next_ram_address <= ZERO_ADDRESS;
  			nextPoint <= ONE;
				o_address <= ZERO_ADDRESS;
				o_done <= '0';
				o_en <= '1';
				o_we <= '0';
				o_data <= ZERO;
				if(i_start = '1') then
				   next_state <= START;
				else
				   next_state <= WAIT_START;
				end if;

			when START =>
				next_ram_address <= ZERO_ADDRESS;
				nextPoint <= ONE;
				o_address <= MASK_ADDRESS;
				o_done <= '0';
				o_en <= '1';
				o_we <= '0';
				o_data <= ZERO;
				next_state <= MEM_MASK;

			when MEM_MASK =>
				next_ram_address <= ZERO_ADDRESS;
				nextPoint <= ONE;
				o_address <= XP_ADDRESS;
				o_done <= '0';
				o_en <= '1';
				o_we <= '0';
				o_data <= ZERO;
				if (MASK = "00000000" OR
					MASK = "00000001" OR
					MASK = "00000010" OR
					MASK = "00000100" OR
					MASK = "00001000" OR
					MASK = "00010000" OR
					MASK = "00100000" OR
					MASK = "01000000" OR
					MASK = "10000000") then next_state <= GIVE_OUTPUT;
				else
					next_state <= MEM_XPOINT;
				end if;

			when MEM_XPOINT =>
				next_ram_address <= ONE_ADDRESS;
				nextPoint <= ONE;
				o_address <= YP_ADDRESS;
				o_done <= '0';
				o_en <= '1';
				o_we <= '0';
				o_data <= ZERO;
				next_state <= MEM_YPOINT;

			when MEM_YPOINT =>
				next_ram_address <= curr_ram_address + ONE_ADDRESS;
				nextPoint <= ONE;
				o_address <= curr_ram_address;
				o_done <= '0';
				o_en <= '1';
				o_we <= '0';
				o_data <= ZERO;
				next_state <= MEM_XCENTROID;

			when MEM_XCENTROID =>
				o_done <= '0';
				o_we <= '0';
				o_data <= ZERO;
				if(currPoint = ZERO) then
					next_ram_address <= curr_ram_address;
					nextPoint <= currPoint;
					o_address <= ZERO_ADDRESS;
					o_en <= '0';
					next_state <= GIVE_OUTPUT;
				elsif ((currPoint AND MASK) = ZERO) then
					next_ram_address <= curr_ram_address + ONE_ADDRESS + ONE_ADDRESS;
					nextPoint <= to_stdlogicvector(to_bitvector(currPoint) sll 1);
					o_address <= curr_ram_address + ONE_ADDRESS;
					o_en <= '1';
					next_state <= MEM_XCENTROID;
				else
					next_ram_address <= curr_ram_address + ONE_ADDRESS;
					nextPoint <= currPoint;
					o_address <= curr_ram_address;
					o_en <= '1';
					next_state <= MEM_YCENTROID;
				end if;

			when MEM_YCENTROID =>
				next_ram_address <= curr_ram_address;
				nextPoint <= currPoint;
				o_address <= ZERO_ADDRESS;
				o_done <= '0';
				o_en <= '0';
				o_we <= '0';
				o_data <= ZERO;
				next_state <= COMPUTE_MIN_DIST;

			when COMPUTE_MIN_DIST =>
				next_ram_address <= curr_ram_address + ONE_ADDRESS;
				nextPoint <= to_stdlogicvector(to_bitvector(currPoint) sll 1);
				o_address <= curr_ram_address;
				o_done <= '0';
				o_en <= '1';
				o_we <= '0';
				o_data <= ZERO;
				next_state <= MEM_XCENTROID;

			when GIVE_OUTPUT =>
				next_ram_address <= curr_ram_address;
				nextPoint <= currPoint;
				o_address <= OMASK_ADDDRESS;
				o_done <= '0';
				o_en <= '1';
				o_we <= '1';
				o_data <= curr_O_MASK;
				next_state <= DONE;

			when DONE =>
				next_ram_address <= ZERO_ADDRESS;
				nextPoint <= ONE;
				o_address <= ZERO_ADDRESS;
				o_done <= '1';
				o_en <= '0';
				o_we <= '0';
				o_data <= ZERO;
				next_state <= WAIT_START;
		end case;

    end process;

    --Process that handles the logic relative to the minimum distance, with some optimization.
	compute_min_distance: process(TOT_DIST, current_state, curr_MIN_DIST, curr_O_MASK, currPoint, MASK)
	begin

		case current_state is

			when WAIT_START =>
				next_MIN_DIST <= MAXDISTANCE;
				next_O_MASK <= ZERO;

			when MEM_MASK =>
				next_MIN_DIST <= MAXDISTANCE;
				if (MASK = "00000000" OR
					MASK = "00000001" OR
					MASK = "00000010" OR
					MASK = "00000100" OR
					MASK = "00001000" OR
					MASK = "00010000" OR
					MASK = "00100000" OR
					MASK = "01000000" OR
					MASK = "10000000") then next_O_MASK <= MASK;
				else
					next_O_MASK <= ZERO;
				end if;

			when COMPUTE_MIN_DIST =>
				if(TOT_DIST < curr_MIN_DIST) then
					next_MIN_DIST <= TOT_DIST;
					next_O_MASK <= currPoint;
				elsif (TOT_DIST = curr_MIN_DIST) then
					next_MIN_DIST <= curr_MIN_DIST;
					next_O_MASK <= curr_O_MASK OR currPoint;
				else
					next_MIN_DIST <= curr_MIN_DIST;
					next_O_MASK <= curr_O_MASK;
				end if;

			when others =>
                next_MIN_DIST <= curr_MIN_DIST;
				next_O_MASK <= curr_O_MASK;
		end case;
	end process;

end Behavioral;
