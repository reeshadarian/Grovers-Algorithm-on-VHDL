library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity VHDLGrover_tb is
end VHDLGrover_tb;

architecture tb of VHDLGrover_tb is

    COMPONENT VHDLGrover PORT(
        b: out std_logic_vector (2 downto 0);
        a: in std_logic_vector (2 downto 0);
        clk: in std_logic;
        rst: in std_logic
    );
    END COMPONENT;
    signal check: std_logic;
    signal b: std_logic_vector (2 downto 0);
    signal a: std_logic_vector (2 downto 0) := "000";
    signal clk: std_logic := '0';
    signal rst: std_logic := '1';
begin
    uut: VHDLGrover PORT MAP (
        b => b,
        a => a,
        clk => clk,
        rst => rst
    );
    
    process is begin
        clk <= '0';
        wait for 1 ns;
        clk <= '1';
        wait for 1 ns;
    end process;
    
    testproc: process is begin
        rst <= '1';
        a <= "000";
        wait until clk'event and clk = '1';
        rst <= '0';
        wait for 150 ns;
        rst <= '1';
        a <= "100";
        wait until clk'event and clk = '1';
        rst <= '0';
        wait;
    end process testproc;
    
    process (b, a) begin
        if b = a then
            check <= '1';
        else
            check <= '0';
        end if;
    end process;

end tb;
