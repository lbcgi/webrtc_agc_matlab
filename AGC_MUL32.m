function y = AGC_MUL32(A, B)
        y = bitshift(B, -13)*A + bitshift(bitand(hex2dec('00001FFF'),B)*A, -13);
end