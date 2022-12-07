function y = SHIFT_W32(x, c)
        if( c >=0 )
            y = x*bitshift(1, c);
        else
            bitshift(x, -c);
        end
end