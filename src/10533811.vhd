----------------------------------------------------------------------------------
-- Antonino Elia Mandri
-- cod. persona 10533811
-- matricola 870882
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


entity project_reti_logiche is
    Port ( i_clk : in STD_LOGIC ;
           i_start : in STD_LOGIC ;
           i_rst : in STD_LOGIC ;
           i_data : in STD_LOGIC_VECTOR (7 downto 0) ;
           o_address : out STD_LOGIC_VECTOR (15 downto 0) ;
           o_done : out STD_LOGIC ;
           o_en : out STD_LOGIC ;
           o_we : out STD_LOGIC ;
           o_data : out STD_LOGIC_VECTOR (7 downto 0)
           );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

type state_type is ( INIT, RESET, START, STORE_MASK, READ_XP, STORE_XP, READ_YP, STORE_YP, READ_X, STORE_X, READ_Y, 
                        STORE_Y, CHECK_VALIDITY,INCREASE_ADDRESS, CALC_DISTANCE, CHECK_MIN,  WRITE_OUTPUT, DONE);

signal current_state: state_type := INIT;
signal next_state : state_type := INIT;
signal mask: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
signal Xp: STD_LOGIC_VECTOR(8 downto 0) := (others => '0');
signal Yp: STD_LOGIC_VECTOR(8 downto 0) := (others => '0');
signal coorX: STD_LOGIC_VECTOR(8 downto 0) := (others => '0');
signal coorY: STD_LOGIC_VECTOR(8 downto 0) := (others => '0');
signal distance: UNSIGNED(8 downto 0) := "000000000";
signal min_distance: UNSIGNED(8 downto 0) := "111111111";
signal current_address: UNSIGNED(15 downto 0) := "0000000000000001";
signal next_address: UNSIGNED(15 downto 0) := "0000000000000001";
signal alpha: STD_LOGIC_VECTOR(7 downto 0) := "00000001";
signal next_alpha: STD_LOGIC_VECTOR(7 downto 0) := "00000001";
signal output: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
signal next_output: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

                     
begin

    state_flow: process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            current_state <= RESET;
            --next_state <= RESET;
            
        elsif (rising_edge(i_clk)) then
                current_state <= next_state;
        end if;
    end process;
    
    transition: process( i_clk, current_state, i_start, i_rst) 
    begin
        if(falling_edge(i_clk)) then
            case current_state is
                when INIT => 
                    o_done <= '0';
                    o_en <= '0';
                    o_we <= '0';
                    o_address <= "0000000000000000";
                    current_address <= "0000000000000001"; --1
                    min_distance <= "111111111";
                   -- if(i_rst = '1') then
                        --next_state <= RESET;
                    --end if;
                 
                 when RESET =>
                    o_done <= '0';
                    o_en <= '0';
                    o_we <= '0';
                    o_address <= "0000000000000000";
                    current_address <= "0000000000000001"; --1
                    next_address <= "0000000000000001";
                    alpha <= "00000001";
                    next_alpha <= "00000001";
                    min_distance <= "111111111";
                    distance <= "000000000";
                    output <= "00000000";
                    next_output <= "00000000";
                    
                    if(i_start = '1') then
                        next_state <= START;
                    else 
                        next_state <= RESET;
                    end if;
                    
                 when START =>
                    o_en <= '1';
                    next_state <= STORE_MASK;
                    
                 when STORE_MASK =>
                    mask <= i_data;
                    next_state <= READ_XP;
                 
                 when READ_XP =>
                    o_address <= "0000000000010001"; -- 17
                    next_state <= STORE_XP;
                 
                 when STORE_XP =>
                    Xp <= '0' & i_data;
                    next_state <= READ_YP;
                 
                 when READ_YP => 
                    o_address <= "0000000000010010";
                    next_state <= STORE_YP;
                 
                 when STORE_YP => 
                    Yp <= '0' & i_data;
                    next_state <= CHECK_VALIDITY;
                 
                 when READ_X =>
                     o_address <= STD_LOGIC_VECTOR(next_address);
                     next_state <= STORE_X;
                     current_address <= next_address;
                     alpha <= next_alpha;
                 
                 when STORE_X =>
                    coorX <= '0' & i_data;
                    next_address <= current_address + 1;
                    next_state <= READ_Y;
                    
                 when READ_Y =>
                     current_address <= next_address;
                     o_address <= STD_LOGIC_VECTOR(next_address);
                     next_state <= STORE_Y;
                 
                 when STORE_Y =>
                    coorY <= '0' & i_data;
                    next_address <= current_address + 1;
                    next_state <= CALC_DISTANCE;
                 
                 when CHECK_VALIDITY =>
                    output <= next_output;
                    if (UNSIGNED(alpha and mask) > 0) then
                        next_state <=  READ_X;
                        
                    else 
                        next_address <= current_address +2;
                        next_state <= INCREASE_ADDRESS;
                        next_alpha <= alpha(6 downto 0) & '0';
                    end if;

                 
                 when INCREASE_ADDRESS =>
                    if (UNSIGNED(alpha) > 0) then 
                        current_address <= next_address;
                        next_state <= CHECK_VALIDITY;
                    else 
                        next_state <= WRITE_OUTPUT;
                    end if;
                    alpha <= next_alpha;
                    output <= next_output;
                 
                 when CALC_DISTANCE =>
                    distance <= UNSIGNED(ABS(SIGNED(coorX) - SIGNED(Xp)) + ABS(SIGNED(coorY) - SIGNED(Yp)));
                    next_state <= CHECK_MIN;
                    current_address <= next_address;
                    alpha <= next_alpha;
                    next_alpha <= alpha(6 downto 0) & '0';
                    
                 when CHECK_MIN =>
                    if (distance < min_distance) then
                        next_output <= alpha;
                        min_distance <= distance;
                        
                    elsif (distance = min_distance) then
                        next_output <= output or alpha;
                    end if;                   
                    next_state <= CHECK_VALIDITY;
                    alpha <= next_alpha;
                    
                 when WRITE_OUTPUT => 
                    o_en <= '1';
                    o_we <= '1';
                    o_data <= output;
                    o_address <= "0000000000010011";
                    o_done <= '1';
                    next_state <= DONE;
                    
                 when DONE =>
                 if(i_start = '0') then
                    o_en <= '0';
                    o_we <= '0';
                    o_done <= '0';
                 end if;
                                             
             end case;      
        end if;
    end process;    
end Behavioral;
