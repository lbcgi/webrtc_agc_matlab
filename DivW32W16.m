function z = DivW32W16(x, y)
    if(y~=0)
        z = round(round(x)/round(y));
    else
        z = hex2dec('7FFFFFFF');
    end