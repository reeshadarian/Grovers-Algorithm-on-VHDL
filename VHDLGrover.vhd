library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.all;
use IEEE.NUMERIC_STD.ALL;

entity VHDLGrover is
    port(
        b: out std_logic_vector (2 downto 0);
        a: in std_logic_vector (2 downto 0);
        clk: in std_logic;
        rst: in std_logic
    );
end VHDLGrover;

architecture Behavioral of VHDLGrover is

subtype fixed is std_logic_vector (20 downto 0);

type cmpx is record
    re: fixed;
    im: fixed;
end record cmpx;

function fix(x: in integer) return fixed is
begin
    return std_logic_vector(to_signed(x, 21));
end;
                                                       
function "+"(x: in fixed; y : in fixed) return fixed is
begin
    return std_logic_vector(signed(x) + signed(y));
end;
                                                       
function "-"(x: in fixed; y: in fixed) return fixed is
begin
    return std_logic_vector(signed(x) - signed(y));
end;
                                                       
function ">"(x: in fixed; y : in fixed) return boolean is
begin
    return (signed(x)) > (signed(y));
end;

function cmp(x: in fixed; y: in fixed) return cmpx is
variable ret: cmpx;
begin
    ret.re := x;
    ret.im := y;
    return ret;
end;
                                                       
function "+"(x: in cmpx; y : in cmpx) return cmpx is
begin
    return cmp(x.re+ y.re, x.im + y.im);
end;
                                                       
function "-"(x: in cmpx; y: in cmpx) return cmpx is
begin
    return cmp(x.re - y.re, x.im - y.im);
end;
                                        
function "*"(x: in fixed; y: in fixed) return fixed is
begin
    return fix(to_integer(signed(x) * signed(y) / 2**16));
end;
                                                       
function "*"(x: in fixed; y: in cmpx) return cmpx is
begin
    return cmp(x * y.re, x * y.im);
end;

type cmpx_array is array (7 downto 0) of cmpx;
signal qubit1, qubit2: cmpx_array;
type real_array is array (7 downto 0) of fixed;
signal prob_cdf: real_array;
signal foo: cmpx;
signal ran: std_logic_vector (31 downto 0) := "00110011100010010010111111010000";
signal r: fixed;

begin
    process begin
        foo <= cmp(fix(1), fix(1));
        foo <= fix(2)*foo;
        for i in 0 to 7 loop
            qubit1(i) <= cmp(fix(23170), fix(0));
            wait until clk'event and clk = '1';
        end loop;
        for i in 0 to 1 loop
            qubit1(to_integer(unsigned(a))) <= cmp(fix(0), fix(0)) - qubit1(to_integer(unsigned(a)));
            qubit2(0) <= fix(16384) * qubit1(0) + fix(16384) * qubit1(1) + fix(16384) * qubit1(2) + fix(16384) * qubit1(3) + fix(16384) * qubit1(4) + fix(16384) * qubit1(5) + fix(16384) * qubit1(6) + fix(16384) * qubit1(7) - qubit1(0);
            qubit2(1) <= fix(16384) * qubit1(0) + fix(16384) * qubit1(1) + fix(16384) * qubit1(2) + fix(16384) * qubit1(3) + fix(16384) * qubit1(4) + fix(16384) * qubit1(5) + fix(16384) * qubit1(6) + fix(16384) * qubit1(7) - qubit1(1);
            qubit2(2) <= fix(16384) * qubit1(0) + fix(16384) * qubit1(1) + fix(16384) * qubit1(2) + fix(16384) * qubit1(3) + fix(16384) * qubit1(4) + fix(16384) * qubit1(5) + fix(16384) * qubit1(6) + fix(16384) * qubit1(7) - qubit1(2);
            qubit2(3) <= fix(16384) * qubit1(0) + fix(16384) * qubit1(1) + fix(16384) * qubit1(2) + fix(16384) * qubit1(3) + fix(16384) * qubit1(4) + fix(16384) * qubit1(5) + fix(16384) * qubit1(6) + fix(16384) * qubit1(7) - qubit1(3);
            qubit2(4) <= fix(16384) * qubit1(0) + fix(16384) * qubit1(1) + fix(16384) * qubit1(2) + fix(16384) * qubit1(3) + fix(16384) * qubit1(4) + fix(16384) * qubit1(5) + fix(16384) * qubit1(6) + fix(16384) * qubit1(7) - qubit1(4);
            qubit2(5) <= fix(16384) * qubit1(0) + fix(16384) * qubit1(1) + fix(16384) * qubit1(2) + fix(16384) * qubit1(3) + fix(16384) * qubit1(4) + fix(16384) * qubit1(5) + fix(16384) * qubit1(6) + fix(16384) * qubit1(7) - qubit1(5);
            qubit2(6) <= fix(16384) * qubit1(0) + fix(16384) * qubit1(1) + fix(16384) * qubit1(2) + fix(16384) * qubit1(3) + fix(16384) * qubit1(4) + fix(16384) * qubit1(5) + fix(16384) * qubit1(6) + fix(16384) * qubit1(7) - qubit1(6);
            qubit2(7) <= fix(16384) * qubit1(0) + fix(16384) * qubit1(1) + fix(16384) * qubit1(2) + fix(16384) * qubit1(3) + fix(16384) * qubit1(4) + fix(16384) * qubit1(5) + fix(16384) * qubit1(6) + fix(16384) * qubit1(7) - qubit1(7);
            wait until clk'event and clk = '1';
            for j in 0 to 7 loop
                qubit1(j) <= qubit2(j);
            end loop;
        end loop;
        wait until a'event;
    end process;
    
    process (clk)
    begin
        prob_cdf(0) <= qubit1(0).re * qubit1(0).re + qubit1(0).im * qubit1(0).im;
        for i in 1 to 7 loop
            if (clk'event and clk = '1') then
                prob_cdf(i) <= qubit1(i).re * qubit1(i).re + qubit1(i).im * qubit1(i).im + prob_cdf(i-1);
                --prob_cdf(i) <= fix(1);
            end if;
        end loop;
    end process;
    
    process
    variable bb: std_logic;
    begin
        bb := ran(31) xor ran(21) xor ran(1);
        ran <= std_logic_vector(shift_right(unsigned(ran), 1));
        ran(31) <= bb;
        wait until clk'event;
    end process;
    
    process (ran)
    begin
        r <= fix(to_integer(unsigned(ran) mod 2**16));
        if (r > prob_cdf(6)) then
            b <= std_logic_vector(to_unsigned(7, 3));
        elsif(r > prob_cdf(5)) then
            b <= std_logic_vector(to_unsigned(6, 3));
        elsif(r > prob_cdf(4)) then
            b <= std_logic_vector(to_unsigned(5, 3));
        elsif(r > prob_cdf(3)) then
            b <= std_logic_vector(to_unsigned(4, 3));
        elsif(r > prob_cdf(2)) then
            b <= std_logic_vector(to_unsigned(3, 3));
        elsif(r > prob_cdf(1)) then
            b <= std_logic_vector(to_unsigned(2, 3));
        elsif(r > prob_cdf(0)) then
            b <= std_logic_vector(to_unsigned(1, 3));
        else
            b <= std_logic_vector(to_unsigned(0, 3));
        end if;
    end process;
end Behavioral;