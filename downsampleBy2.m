function [out, filtState] = downsampleBy2(in, len, filtState) 

     state0 = filtState(1);
     state1 = filtState(2);
     state2 = filtState(3);
     state3 = filtState(4);
     state4 = filtState(5);
     state5 = filtState(6);
     state6 = filtState(7);
     state7 = filtState(8);
     kResampleAllpass2 = [12199, 37471, 60255];
     pos_in = 0;
     pos_out = 0;
     num_h2d = hex2dec('0000FFFF');
    for i = bitshift(len , -1):-1:1
%       // lower allpass filter
        in32 =  in(pos_in + 1) * bitshift(1 , 10);
        pos_in = pos_in + 1;
        diff = in32 - state1;
        diff = round(diff);
        tmp1 =  state0 + floor(diff/2^16) * (kResampleAllpass2(1)) + floor(bitand(diff,num_h2d,'int32')*kResampleAllpass2(1)/2^16);
        state0 = in32;
        diff = tmp1 - state2;
        diff = round(diff);
        tmp2 =  state1 + floor(diff/2^16) * (kResampleAllpass2(2)) + floor(bitand(diff,num_h2d,'int32')*kResampleAllpass2(2)/2^16);

        state1 = tmp1;
        diff = tmp2 - state3;
        diff = round(diff);
        state3 =  state2 + floor(diff/2^16) * (kResampleAllpass2(3)) + floor(bitand(diff,num_h2d,'int32')*kResampleAllpass2(3)/2^16);

        state2 = tmp2;

%       // upper allpass filter
        in32 =  in(pos_in + 1) * bitshift(1 , 10);
        pos_in = pos_in + 1;
        diff = in32 - state5;
        diff = round(diff);
        tmp1 =  state4 + floor(diff/2^16) * (kResampleAllpass2(1)) + floor(bitand(diff,num_h2d,'int32')*kResampleAllpass2(1)/2^16);
       
        state4 = in32;
        diff = tmp1 - state6;
        diff = round(diff);
        tmp2 =  state5 + floor(diff/2^16) * (kResampleAllpass2(2)) + floor(bitand(diff,num_h2d,'int32')*kResampleAllpass2(2)/2^16);

        state5 = tmp1;
        diff = tmp2 - state7;
        diff = round(diff);
        state7 =  state6 + floor(diff/2^16) * (kResampleAllpass2(3)) + floor(bitand(diff,num_h2d,'int32')*kResampleAllpass2(3)/2^16);
        state6 = tmp2;

%         // add two allpass outputs, divide by two and round
        out32 = floor((state3 + state7 + 1024)/2^11);

%         // limit amplitude to prevent wrap-around, and write to output array
%         out(pos_out + 1) = SatW32ToW16(out32);
        out(pos_out + 1) = out32;

        pos_out = pos_out + 1;
    end

        filtState(1) = state0;
        filtState(2) = state1;
        filtState(3) = state2;
        filtState(4) = state3;
        filtState(5) = state4;
        filtState(6) = state5;
        filtState(7) = state6;
        filtState(8) = state7;
end