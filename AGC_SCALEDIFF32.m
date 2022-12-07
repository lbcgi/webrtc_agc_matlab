function y = AGC_SCALEDIFF32(A, B, C)
        tmp = bitand(hex2dec('0000FFFF'),round(abs(B)))*A*sign(B);
        y = C + sign(B)*bitshift(round(abs(B)), -16)*A + sign(tmp)*bitshift(abs(tmp), -16);
end