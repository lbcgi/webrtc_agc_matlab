function [logRatio, state] = WebRtcAgc_ProcessVad(state, in, nrSamples, param)
    
   
    buf1 = zeros(1,8);

%     // process in 10 sub frames of 1 ms (to save on memory)
    nrg = 0;
    HPstate = state.HPstate;
    in_pos = 0;
    for subfr = 0:9
%         // downsample to 4 kHz
        if (nrSamples == 160) 
            for k = 0:7
                tmp32 = in(2 * k + 1 + in_pos) + in(2 * k + 2 + in_pos);
                tmp32 = bitshift(tmp32,-1);
                buf1(k + 1) = tmp32;
            end
            in_pos = in_pos + 16;

            [buf2, state.downState] = downsampleBy2(buf1, 8, state.downState);
         else 
            [buf2, state.downState] = downsampleBy2(in(in_pos + 1:end), 8, state.downState);
            in_pos = in_pos + 8;
         end

%         // high pass filter and compute energy
        for k = 0:3
            out = buf2(k + 1) + HPstate;
            tmp32 = 600 * out;
            HPstate = fix(tmp32/2^10) - buf2(k+1);

%             // Add 'out * out / 2**6' to 'nrg' in a non-overflowing
%             // way. Guaranteed to work as long as 'out * out / 2**6' fits in
%             // an int32_t.
            vl_2exp6 = 2^6;
            nrg = nrg + out * fix((out / vl_2exp6));
            nrg = nrg + out * fix(mod(out , vl_2exp6) / vl_2exp6);
        end
    end
    state.HPstate = HPstate;

%     // find number of leading zeros

    if (~bitand(hex2dec('FFFF0000') ,fix(nrg))) 
        mzeros = 16;
     else 
        mzeros = 0;
    end
    if (~bitand(hex2dec('FF000000') ,bitshift(fix(nrg),mzeros))) 
        mzeros = mzeros + 8;
    end
    if (~bitand(hex2dec('F0000000') ,bitshift(fix(nrg),mzeros))) 
        mzeros = mzeros + 4;
    end
    if (~bitand(hex2dec('C0000000') ,bitshift(fix(nrg),mzeros))) 
        mzeros = mzeros + 2;
    end
    if (~bitand(hex2dec('80000000'),bitshift(fix(nrg),mzeros))) 
        mzeros = mzeros + 1;
    end

%     // energy level (range {-32..30}) (Q10)
    dB = (15 - mzeros) * (1 * 2^11);

%     // Update statistics

    if (state.counter < param.kAvgDecayTime) 
%         // decay time = AvgDecTime * 10 ms
        state.counter = state.counter + 1;
    end

%     // update short-term estimate of mean energy level (Q10)
    tmp32 = state.meanShortTerm * 15 + dB;
    state.meanShortTerm =  floor(tmp32 / 2^4);

%     // update short-term estimate of variance in energy level (Q8)
    tmp32 = floor((dB * dB) /2^12);
    tmp32 = tmp32 + state.varianceShortTerm * 15;
    state.varianceShortTerm = floor(tmp32 / 16);

%     // update short-term estimate of standard deviation in energy level (Q10)
    tmp32 = state.meanShortTerm * state.meanShortTerm;
    tmp32 = state.varianceShortTerm *2^12 - tmp32;
    state.stdShortTerm = fix(sqrt(tmp32));

%     // update long-term estimate of mean energy level (Q10)
    tmp32 = state.meanLongTerm * state.counter + dB;
    state.meanLongTerm =...
            DivW32W16ResW16(tmp32, WebRtcSpl_AddSatW16(state.counter, 1));

%     // update long-term estimate of variance in energy level (Q8)
    tmp32 = floor((dB * dB) / 2^12);
    tmp32 = tmp32 + state.varianceLongTerm * state.counter;
    state.varianceLongTerm =...
            DivW32W16(tmp32, WebRtcSpl_AddSatW16(state.counter, 1));

%     // update long-term estimate of standard deviation in energy level (Q10)
    tmp32 = state.meanLongTerm * state.meanLongTerm;
    tmp32 = (state.varianceLongTerm *2^12) - tmp32;
    state.stdLongTerm = fix(sqrt(tmp32));

%     // update voice activity measure (Q10)
    tmp16 = 3 * 2^12;
%     // TODO(bjornv): (dB - state->meanLongTerm) can overflow, e.g., in
%     // ApmTest.Process unit test. Previously the macro WEBRTC_SPL_MUL_16_16()
%     // was used, which did an intermediate cast to (int16_t), hence losing
%     // significant bits. This cause logRatio to max out positive, rather than
%     // negative. This is a bug, but has very little significance.
    tmp32 = tmp16 * (dB - state.meanLongTerm);
    tmp32 = DivW32W16(tmp32, state.stdLongTerm);
    tmp32b = state.logRatio * 13*2^12;
    tmp32b = floor(tmp32b /2^10);
    tmp32 = tmp32 + tmp32b;
    state.logRatio = floor(tmp32 / 2^6);

%     // limit
    if (state.logRatio > 2048) 
        state.logRatio = 2048;
    end
    if (state.logRatio < -2048) 
        state.logRatio = -2048;
    end

    logRatio =  state.logRatio;  %// Q10
