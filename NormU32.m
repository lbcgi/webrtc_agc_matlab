function mzeros = NormU32(v)
    
	if (v == 0) 
        mzeros = 0;
    end
    v = fix(v);
	if (~(bitand(hex2dec('FFFF0000') , v))) 
		mzeros = 16;
	else 
		mzeros = 0;
    end
	if (~(bitand(hex2dec('FF000000') , bitshift(v , mzeros)))) 
            mzeros = mzeros +  8;
    end
    if (~(bitand(hex2dec('F0000000') , bitshift(v , mzeros)))) 
        mzeros = mzeros +  4;
    end
    if (~(bitand(hex2dec('C0000000') , bitshift(v , mzeros)))) 
        mzeros = mzeros +  2;
    end
    if (~(bitand(hex2dec('80000000') , bitshift(v , mzeros)))) 
        mzeros = mzeros +  1;
    end
    


