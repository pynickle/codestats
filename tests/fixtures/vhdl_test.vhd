-- VHDL Test File
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Counter is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           count : out INTEGER);
end Counter;

architecture Behavioral of Counter is
    signal cnt : INTEGER := 0;
begin
    -- This is a comment in VHDL
    process(clk, reset)
    begin
        if reset = '1' then
            cnt <= 0;
        elsif rising_edge(clk) then
            cnt <= cnt + 1;
        end if;
    end process;
    count <= cnt;
end Behavioral;
