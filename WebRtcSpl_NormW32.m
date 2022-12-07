function y = WebRtcSpl_NormW32(a)
    if(a == 0)
        y = 0;
    end
    if(~(hex2dec('FFFF0000') && a))
        zeros = 16;
    else
        zeros = 0;
    end
    if(~(hex2dec('FF000000') && (a * 2^zeros))) 
        zeros = zeros + 8;
    end
    if(~(hex2dec('F0000000') && (a * 2^zeros))) 
        zeros = zeros + 4;
    end
    if(~(hex2dec('C0000000') && (a * 2^zeros))) 
        zeros = zeros + 2;
    end
    if(~(hex2dec('80000000') && (a * 2^zeros))) 
        zeros = zeros + 1;
    end
    
    y = zeros;
    
end