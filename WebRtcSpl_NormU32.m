function y = WebRtcSpl_NormU32(a)
    if(a == 0)
        y = 0;
    end
    if(~(bitand(hex2dec('FFFF0000') , a)))
        zeros = 16;
    else
        zeros = 0;
    end
    
    tt = (a*2^zeros);
    if(~(bitand(hex2dec('FF000000') , tt))) 
        zeros = zeros + 8;
    end
    
    if(~(bitand(hex2dec('F0000000') , tt))) 
        zeros = zeros + 4;
    end
    
    if(~(bitand(hex2dec('C0000000') , tt))) 
        zeros = zeros + 2;
    end
    
    if(~(bitand(hex2dec('80000000') , tt))) 
        zeros = zeros + 1;
    end
    
    y = zeros;
    
end