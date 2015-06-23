library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
  
entity Scheduler is
  port (
    clk, reset, arpV, ftpV : in  std_logic;
    arpEn, ftpEn : out std_logic;
    data  : out std_logic_vector(7 downto 0);
    );
  
end entity Scheduler;

architecture rtl of Scheduler is
  type arp_interface is record
    data : std_logic_vector(7 downto 0);
    eof : std_logic;
  end record;

  type tftp_interface is record
    data : std_logic_vector(7 downto 0);
    eof : std_logic;
  end record;
    
  type state_type is (s0,s1,s2,s3,s4);  --type of state machine.
  signal current_s,next_s: state_type;  --current and next state declaration.
  signal arp : arp_interface;
  signal tftp: tftp_interface;
  signal cnt, byteCnt: std_logic_vector(7 downto 0); --cnt is for the 16 bit spaces between packets, byteCnt is to make sure packets are at least 68 bytes long.
    
  begin
    FSM : process(clk, reset)
    begin
      if reset = '1' then
        current_s <= s0;
        byteCnt <= "00000000";
      else if clk'event and clk = '1' then
        current_s <= next_s;
        
        if current_s = s0 then
          arpEn => 1;
        else if current_s = s1 then
          ftpEn => 1;
        end if;
      end if;
    end process FSM;

    next_state : process (next_s, cnt)
    begin
      current_s <= next_s;
        
      case current_s is
        when s0 =>        --when current state is "s0"
          if arp.eof = '1' and arpV = '1' then
            data <= arp.data;
          else if arpV = '0' then
            next_s <= s2;
          else
            data <= arp.data;
            cnt <= "00000000";
            next_s <= s2;
          end if;  

        when s1 =>        --when current state is "s1"
          byteCnt <= byteCnt + 1;
          
          if tftp.eof = '1' and ftpV = '1' then
            data <= tftp.data;
          else if ftpV = '0' then
            if byteCnt < 68 then --if the amount of bytes in the packet is less than minimum go to s4
              next_s <= s4;
            else
              next_s <= s0;
            end if;
          else
            data <= tftp.data;
            cnt <= "00000000";
            next_s <= s3;
          end if;
          
        when s2 =>        --when current state is "s2"
          if cnt < 16 then
            cnt <= cnt + 1;
          else
            next_s <= s1;
          end if;
            
        when s3 =>        --when current state is "s3"
          if cnt < 16 then
            cnt <= cnt + 1;
          else
            next_s <= s0;
          end if;
        when s4 =>        --when current state is "s4"
          if byteCnt < 68 then
            next_s <= s4;
            byteCnt <= byteCnt + 1;
          else
            next_s <= s3;
          end if;
      end case;
        
  end process next_state;

end architecture Scheduler;

