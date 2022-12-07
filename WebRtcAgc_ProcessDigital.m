function  [y, stt, out] = WebRtcAgc_ProcessDigital(stt, in_near, num_bands, FS, lowlevelSignal, param) 
    % array for gains (one value per ms, incl start & end)
     gains = zeros(11,1);

     env = zeros(10,1);
   
%     // determine number of samples per ms
    if (FS == 8000)
        L = 8;
        L2 = 3;
    elseif (FS == 16000 || FS == 32000 || FS == 48000) 
        L = 16;
        L2 = 4;
     else 
        y = -1;
        return;
    end
    out = NaN(num_bands,10*L);
    for i = 0:num_bands - 1
%             // Only needed if they don't already point to the same place.
            out(i + 1,1:10*L) =  in_near(i + 1, 1:10*L);%�账������ָ��
    end
%     // VAD for near end
    [logratio, stt.vadNearend] = WebRtcAgc_ProcessVad(stt.vadNearend, out, L * 10, param);

%     // Account for far end VAD
    if (stt.vadFarend.counter > 10) 
        tmp32 = 3 * logratio;
        logratio = bitshift(tmp32 - stt.vadFarend.logRatio, 2);
    end

%     // Determine decay factor depending on VAD
%     //  upper_thr = 1.0f;
%     //  lower_thr = 0.25f;
    upper_thr = 1024; % // Q10
    lower_thr = 0;   %  // Q10
    if (logratio > upper_thr) 
%         // decay = -2^17 / DecayTime;  ->  -65
        decay = -65;
    elseif (logratio < lower_thr)
        decay = 0;
    else
%         // decay = (int16_t)(((lower_thr - logratio)
%         //       * (2^27/(DecayTime*(upper_thr-lower_thr)))) >> 10);
%         // SUBSTITUTED: 2^27/(DecayTime*(upper_thr-lower_thr))  ->  65
        tmp32 = (lower_thr - logratio) * 65;
        decay = fix(tmp32/2^10);
    end

%     // adjust decay factor for long silence (detected as low standard deviation)
%     // This is only done in the adaptive modes
    if (stt.agcMode ~= param.kAgcModeFixedDigital) 
        if (stt.vadNearend.stdLongTerm < 4000) 
            decay = 0;
        elseif (stt.vadNearend.stdLongTerm < 8096) 
%             // decay = (int16_t)(((stt->vadNearend.stdLongTerm - 4000) * decay) >>
%             // 12);
            tmp32 = (stt.vadNearend.stdLongTerm - 4000) * decay;
            decay = bitshift(tmp32 , -12);
        end

        if (lowlevelSignal ~= 0) 
            decay = 0;
        end
    end
% #ifdef WEBRTC_AGC_DEBUG_DUMP
%     stt->frameCounter++;
%     fprintf(stt->logFile, "%5.2f\t%d\t%d\t%d\t", (float)(stt->frameCounter) / 100,
%             logratio, decay, stt->vadNearend.stdLongTerm);
% #endif
%     // Find max amplitude per sub frame
%     // iterate over sub frames
    for k = 0:1:9
%         // iterate over samples
        max_nrg = 0;
        for n = 0:1:L-1 
             nrg = out(1, k * L + n + 1) * out(1, k * L + n + 1);
            if (nrg > max_nrg) 
                max_nrg = nrg;
            end
        end
        env(k + 1) = max_nrg;
    end

%     // Calculate gain per sub frame
    gains(1) = stt.gain;
    for k = 0:1:9 
%         // Fast envelope follower
%         //  decay time = -131000 / -1000 = 131 (ms)
        stt.capacitorFast =...
                AGC_SCALEDIFF32(-1000, stt.capacitorFast, stt.capacitorFast);
        if (env(k + 1) > stt.capacitorFast) 
            stt.capacitorFast = env(k + 1);
        end
%         // Slow envelope follower
        if (env(k + 1) > stt.capacitorSlow) 
%             // increase capacitorSlow
            stt.capacitorSlow = AGC_SCALEDIFF32(500, (env(k + 1) - stt.capacitorSlow),...
                                                 stt.capacitorSlow);
        else 
%             // decrease capacitorSlow
            stt.capacitorSlow =...
                    AGC_SCALEDIFF32(decay, stt.capacitorSlow, stt.capacitorSlow);
        end

%         // use maximum of both capacitors as current level
        if (stt.capacitorFast > stt.capacitorSlow) 
            cur_level = stt.capacitorFast;
        else 
            cur_level = stt.capacitorSlow;
        end
%         // Translate signal level into gain, using a piecewise linear approximation
%         // find number of leading zeros
        mzeros = NormU32(cur_level);
        if (mzeros == 0) 
            mzeros = 31;
        end
        tmp32 = bitand(bitshift(cur_level , mzeros) , hex2dec('7FFFFFFF'));
        frac = sign(tmp32)*bitshift(abs(tmp32) , -19); % // Q12.//notice
        tmp32 = (stt.gainTable(mzeros) - stt.gainTable(mzeros + 1)) * frac;
        gains(k + 2) = stt.gainTable(mzeros + 1) + tmp32/2^12;
% #ifdef WEBRTC_AGC_DEBUG_DUMP
%         if (k == 0) {
%           fprintf(stt->logFile, "%d\t%d\t%d\t%d\t%d\n", env[0], cur_level,
%                   stt->capacitorFast, stt->capacitorSlow, zeros);
%         }
% #endif
    end

%     // Gate processing (lower gain during absence of speech)
    mzeros = bitshift(mzeros , 9) - bitshift(frac , -3);
%     // find number of leading zeros
    zeros_fast = stt.capacitorFast;
    if (stt.capacitorFast == 0) 
        zeros_fast = 31;
    end
    tmp32 = bitand(bitshift(round(stt.capacitorFast) , round(zeros_fast)) , hex2dec('7FFFFFFF'));
    zeros_fast = bitshift(round(zeros_fast),9);
    zeros_fast = zeros_fast - bitshift(tmp32 , -22);

    gate = 1000 + zeros_fast - mzeros - stt.vadNearend.stdShortTerm;

    if (gate < 0) 
        stt.gatePrevious = 0;
    else 
        tmp32 = stt.gatePrevious * 7;
        gate =  (gate + tmp32)/ 2^3;
        stt.gatePrevious = gate;
    end
%     // gate < 0     -> no gate
%     // gate > 2500  -> max gate
    if (gate > 0) 
        if (gate < 2500) 
            gain_adj = bitshift((2500 - gate) , 5);
        else 
            gain_adj = 0;
        end
        for k = 0:1:9 
            if ((gains(k + 2) - stt.gainTable(1)) > 8388608) 
%                 // To prevent wraparound
                tmp32 = bitshift(gains(k + 2) - stt.gainTable(1) , -8);
                tmp32 = tmp32(178 + gain_adj);
            else 
                tmp32 = (gains(k + 1) - stt.gainTable(1)) * (178 + gain_adj);
                tmp32 = bitshift(tmp32 , -8);
            end
            gains(k + 2) = stt.gainTable(1) + tmp32;
        end
    end

%     // Limit gain to avoid overload distortion
    for k = 0:1:9 
%         // To prevent wrap around
        mzeros = 10;
        if (gains(k + 2) > 47453132) 
            mzeros = 16 - gains(k + 2);
        end
        gain32 = bitshift(gains(k + 2) , -mzeros) + 1;
        gain32 = gain32*gain32;
%         // check for overflow
        while (AGC_MUL32(bitshift(round(env(k+1)) , -12) + 1, gain32) >...
               SHIFT_W32( 32767, 2 * (1 - mzeros + 10))) 
%             // multiply by 253/256 ==> -0.1 dB
            if (gains(k + 2) > 8388607) 
%                 // Prevent wrap around
                gains(k + 2) = (gains(k + 2) / 256) * 253;
            else 
                gains(k + 2) = (gains(k + 2) * 253) / 256;
            end
            gain32 = bitshift(gains(k + 2) , -mzeros) + 1;
            gain32 = gain32*gain32;
        end
    end
%     // gain reductions should be done 1 ms earlier than gain increases
    for k = 1:1:9 
        if (gains(k + 1) > gains(k + 2)) 
            gains(k + 1) = gains(k + 2);
        end
    end
%     // save start gain for next frame
    stt.gain = gains(11);

%     // Apply gain
%     // handle first sub frame separately
    delta = (gains(2) - gains(1)) * bitshift(1 , (4 - L2));
    gain32 = gains(1) * 16;
%     // iterate over samples
    for n = 0:1:L-1 
        for i = 0:num_bands-1 
            tmp32 = out(i + 1,n + 1) * bitshift((gain32 + 127) , -7);
            out_tmp = sign(tmp32)*bitshift(abs(round(tmp32)) , -16);
            if (out_tmp > 4095) 
                out(i + 1,n + 1) =  32767;
            elseif (out_tmp < -4096) 
                out(i + 1,n + 1) =  -32768;
            else 
                tmp32 = out(i + 1,n + 1) * bitshift(gain32 , -4);
                out(i + 1,n + 1) = sign(tmp32)*bitshift(abs(round(tmp32)) , -16);
            end
        end
    
        gain32 = gain32 + delta;
    end
%     // iterate over subframes
    for k = 1:1:9 
        delta = (gains(k + 2) - gains(k + 1)) * bitshift(1 , (4 - L2));
        gain32 = gains(k + 1) * 16;
%         // iterate over samples
        for n3 = 0:L - 1 
            for i3 = 0:num_bands - 1 
                tmp64 = out(i3 + 1,k * L + n3 + 1) * bitshift(gain32 , -4);
                tmp64 = sign(tmp64)*bitshift(round(abs(tmp64)) , -16);
                if (tmp64 > 32767) 
                    out(i3 + 1,k * L + n3 + 1) = 32767;
                elseif (tmp64 < -32768) 
                    out(i3 + 1,k * L + n3 + 1) = -32768;
                else
                    out(i3 + 1,k * L + n3 + 1) = tmp64;
                end
            end
            gain32 = gain32 + delta;
        end
    end
    
    y = 0;
end