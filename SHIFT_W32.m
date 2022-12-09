function y = SHIFT_W32(x, c)

        if( c >=0 )
            y = x*2^c;
        else
            y = floor(x/2^(-c));
        end
end