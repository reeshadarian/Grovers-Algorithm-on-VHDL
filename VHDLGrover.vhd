library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.all;
use IEEE.NUMERIC_STD.ALL;

entity VHDLGrover is
    port(
        b: out std_logic_vector (2 downto 0);   -- OUTPUT QUBIT FROM GROVER'S ALGORITHM
        a: in std_logic_vector (2 downto 0);    -- QUBIT TO BE SEARCHED
        clk: in std_logic                       -- CLOCK
    );
end VHDLGrover;

architecture Behavioral of VHDLGrover is
    -- FIXED-POINT NUMBER REPRESENTED AS a*2^16
    subtype fixed is std_logic_vector (20 downto 0);    
    
    -- COMPLEX NUMBER AS TUPLE OF TWO FIXED POINT NUMBERS
    type cmpx is record                                 
        re: fixed;
        im: fixed;
    end record cmpx;
    
    -- RETURN FIXED FROM INTEGER REPRESENTATION
    -- Integer must be less than or equal to 2^16
    -- Must be signed
    -- 21 bits for "overflow"
    -- fixed point number, a, is equivalent to a*2^-16 in normal notation
    function fix(x: in integer) return fixed is         
    begin
        return std_logic_vector(to_signed(x, 21));
    end;
    
    -- RETURN ADDITION OF FIXED POINT NUMBERS
    -- a*2^-16 + b*2^-16 = (a+b)*2^-16
    -- Addition is preserved                                                     
    function "+"(x: in fixed; y : in fixed) return fixed is 
    begin
        return std_logic_vector(signed(x) + signed(y));
    end;
    
    -- RETURN DIFFERENCE OF FIXED POINT NUMBERS
    -- a*2^-16 - b*2^-16 = (a-b)*2^-16
    -- Subtraction is preserved                                                
    function "-"(x: in fixed; y: in fixed) return fixed is
    begin
        return std_logic_vector(signed(x) - signed(y));
    end;
    
    -- RETURN BOOLEAN IF x > y
    -- If a*2^-16 > b*2^-16 then a > b
    -- Greater than is preserved                                                       
    function ">"(x: in fixed; y : in fixed) return boolean is
    begin
        return (signed(x)) > (signed(y));
    end;
    
    -- RETURN COMPLEX NUMBER AS THE LIST OF TWO FIXED POINT NUMBERS
    function cmp(x: in fixed; y: in fixed) return cmpx is
    variable ret: cmpx;
    begin
        ret.re := x;
        ret.im := y;
        return ret;
    end;
    
    -- RETURN ADDITION OF COMPLEX NUMBERS
    -- a*2^-16 + b*2^-16 = (a+b)*2^-16
    -- Addition is preserved                                                       
    function "+"(x: in cmpx; y : in cmpx) return cmpx is
    begin
        return cmp(x.re+ y.re, x.im + y.im);
    end;
    
    -- RETURN DIFFERENCE OF COMPLEX NUMBERS
    -- a*2^-16 - b*2^-16 = (a-b)*2^-16
    -- Subtraction is preserved                                                       
    function "-"(x: in cmpx; y: in cmpx) return cmpx is
    begin
        return cmp(x.re - y.re, x.im - y.im);
    end;
    
    -- RETURN MULTIPLICATION OF TWO FIXED POINT NUMBERS
    -- (x*2^-16) * (y*2^-16) = (x*y*2^-16)*2^-16 which is approximately (x*y/2^16)*2^-16
    -- Multiplication loses accuracy as more numbers are multiplied
    function "*"(x: in fixed; y: in fixed) return fixed is
    begin
        return fix(to_integer(signed(x) * signed(y) / 2**16));
    end;
    
    -- RETURN MULTIPLICATION OF A FIXED POINT NUMBER AND COMPLEX NUMBER
    -- (a*2^-16)*(re*2^-16 + i*im*2^-16) which is approximately (a*re/2^16)*2^-16 + i*(a*im/2^16)*2^-16
    -- Multiplication loses accuracy as more numbers are multiplied
    function "*"(x: in fixed; y: in cmpx) return cmpx is
    begin
        return cmp(x * y.re, x * y.im);
    end;

type cmpx_array is array (7 downto 0) of cmpx;
signal qubit: cmpx_array;   -- 3-QUBIT, CAN BE EASILY MODIFIED FOR n-QUBIT PROGRAMS
type real_array is array (7 downto 0) of fixed;
signal prob_cdf: real_array;    -- PROBABILITY CUMULATIVE DISTRIBTION FUNSTION CORRESPONDING TO "qubit"
signal ran: std_logic_vector (31 downto 0) := "10000111010010111101100100101010";   -- RANDOM NUMBER CORRESPONDING TO 32-BIT LFSR. MUST BE CHANGED FOR OTHER n-QUBIT STATE
begin
    -- ONLY PROCESS CORRESPONDING TO GROVER'S ALGORITHM IN PARTICULAR
    QUANTUM_CIRCUIT: process 
    variable qubit_temp: cmpx_array;
    begin
        -- HADAMARD STATE
        for i in 0 to 7 loop
            qubit(i) <= cmp(fix(23170), fix(0));
        end loop;
        wait on clk;
        for i in 0 to 1 loop
            -- GROVER DIFFUSION
            qubit(to_integer(unsigned(a))) <= cmp(fix(0), fix(0)) - qubit(to_integer(unsigned(a)));
            wait on clk;
            for j in 0 to 7 loop
                qubit_temp(j) := fix(16384) * (qubit(0) + qubit(1) + qubit(2) + qubit(3) + qubit(4) + qubit(5) + qubit(6) + qubit(7)) - qubit(j);
            end loop;
            wait on clk;
            qubit <= qubit_temp;
            wait on clk;
        end loop;
        -- ONLY COMPUTED AGAIN IF INPUT IS CHANGED
        wait on a;
    end process QUANTUM_CIRCUIT;
    
    -- PROCESS TO MAKE AND UPDATE THE PROBABILITY CDF AT EVERY CLOCK CYCLE
    MAKE_PROB_CDF: process (clk)
    begin
        prob_cdf(0) <= qubit(0).re * qubit(0).re + qubit(0).im * qubit(0).im;
        for i in 1 to 7 loop
            if (clk'event and clk = '1') then
                prob_cdf(i) <= qubit(i).re * qubit(i).re + qubit(i).im * qubit(i).im + prob_cdf(i-1);
            end if;
        end loop;
    end process MAKE_PROB_CDF;
    
    -- GENERATES PSEUDORANDOM NUMBERS USING 32-BIT LFSR
    -- Uses the polynimial x^32 + x^22 + x^2  + 1
    -- Must be changed for higher qubit systems
    PSEUDORAND_GEN: process
    variable lfsr_bit: std_logic;
    begin
        lfsr_bit := ran(31) xor ran(21) xor ran(1);
        ran <= std_logic_vector(shift_right(unsigned(ran), 1));
        ran(31) <= lfsr_bit;
        wait until clk'event;
    end process PSEUDORAND_GEN;
    
    -- GENERATES PSEUDO RANDOM NUMBERS CORRESPONDING TO THE PROBABILITY DISTRIBUTION GIVEN BY THE QUBIT
    -- Uses the probability CDF with a uniform distribution between 0 and 1, "ran"
    RAND_DIST: process (ran)
    variable ran_fixed: fixed;
    variable i: integer := 0;
    begin
        ran_fixed := fix(to_integer(unsigned(ran) mod 2**16));
--        while i <= 7 and ran_fixed < prob_cdf(i) loop
--            i := i + 1;
--        end loop;
        if (ran_fixed > prob_cdf(6)) then
            b <= std_logic_vector(to_unsigned(7, 3));
        elsif(ran_fixed > prob_cdf(5)) then
            b <= std_logic_vector(to_unsigned(6, 3));
        elsif(ran_fixed > prob_cdf(4)) then
            b <= std_logic_vector(to_unsigned(5, 3));
        elsif(ran_fixed > prob_cdf(3)) then
            b <= std_logic_vector(to_unsigned(4, 3));
        elsif(ran_fixed > prob_cdf(2)) then
            b <= std_logic_vector(to_unsigned(3, 3));
        elsif(ran_fixed > prob_cdf(1)) then
            b <= std_logic_vector(to_unsigned(2, 3));
        elsif(ran_fixed > prob_cdf(0)) then
            b <= std_logic_vector(to_unsigned(1, 3));
        else
            b <= std_logic_vector(to_unsigned(0, 3));
        end if;
    end process RAND_DIST;
end Behavioral;