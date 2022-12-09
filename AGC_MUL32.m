function y = AGC_MUL32(A, B)
        y = floor(B / 8192)*A + floor((bitand(B, hex2dec('00001FFF'), 'int32')*A) /8192);
end