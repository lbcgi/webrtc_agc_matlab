function y = DivW32W16ResW16(num,  den) 
    if(floor(den) ~= 0)
        y = floor(floor(num) /floor(den));
    else
        y = hex2dec('7FFF');
    end