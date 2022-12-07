function y = WebRtcSpl_AddSatW16(a, b)
    y = a + b;
    if(y > 32767)
        y = 32767;
    end
    if(y < -32767)
        y = -32767;
    end