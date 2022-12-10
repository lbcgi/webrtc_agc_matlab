function y = AGC_SCALEDIFF32(A, B, C)
        tmp = bitand(hex2dec('0000FFFF'), B)*A;
        y = C + bitshift(B, -16)*A + bitshift(tmp, -16);
end