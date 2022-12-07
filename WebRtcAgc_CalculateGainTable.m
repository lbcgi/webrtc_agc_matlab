function  [y, gainTable]= WebRtcAgc_CalculateGainTable(digCompGaindB, targetLevelDbfs, limiterEnable, analogTarget, param) 
      gainTable = zeros(1,32);
%     // This function generates the compressor gain table used in the fixed digital part.
      kCompRatio = 3;
%     const int16_t kSoftLimiterLeft = 1;
      limiterOffset = 0; 
%     int16_t limiterIdx, limiterLvlX;
%     int16_t constLinApprox, zeroGainLvl, maxGain, diffGain;
%     int16_t i, tmp16, tmp16no1;
%     int zeros, zerosScale;

%     // Constants
      kLogE_1 = 23637; % log2(e)      in Q14
      kLog10 = 54426; % log2(10)     in Q14
      kLog10_2 = 49321; % 10*log10(2)  in Q14

%     // Calculate maximum digital gain and zero gain level
    tmp32no1 = (digCompGaindB - analogTarget)*(kCompRatio - 1);
    tmp16no1 = analogTarget - targetLevelDbfs;
    tmp16no1 = tmp16no1 + DivW32W16ResW16(tmp32no1 + (kCompRatio /2), kCompRatio);
    maxGain = max(tmp16no1, (analogTarget - targetLevelDbfs));
%     tmp32no1 = WEBRTC_SPL_MUL_16_16(maxGain, kCompRatio);
%     zeroGainLvl = digCompGaindB;
%     zeroGainLvl = zeroGainLvl - WebRtcSpl_DivW32W16ResW16(tmp32no1 + ((kCompRatio - 1) /2),kCompRatio - 1);
    if ((digCompGaindB <= analogTarget) && (limiterEnable))
    
%         zeroGainLvl = zeroGainLvl + (analogTarget - digCompGaindB + kSoftLimiterLeft);
        limiterOffset = 0;
    end

%     // Calculate the difference between maximum gain and gain at 0dB0v:
%     //  diffGain = maxGain + (compRatio-1)*zeroGainLvl/compRatio
%     //           = (compRatio-1)*digCompGaindB/compRatio
    tmp32no1 = digCompGaindB*(kCompRatio - 1);
    diffGain = DivW32W16ResW16(tmp32no1 + (kCompRatio / 2), kCompRatio);
    if (diffGain < 0 || diffGain >= param.kGenFuncTableSize)
        y = -1;
    end

%     // Calculate the limiter level and index:
%     //  limiterLvlX = analogTarget - limiterOffset
%     //  limiterLvl  = targetLevelDbfs + limiterOffset/compRatio
    limiterLvlX = analogTarget - limiterOffset;
    limiterIdx = 2 + DivW32W16ResW16(limiterLvlX*2^13, (kLog10_2/2));
    tmp16no1 = DivW32W16ResW16(limiterOffset + (kCompRatio / 2), kCompRatio);
    limiterLvl = targetLevelDbfs + tmp16no1;

%     // Calculate (through table lookup):
%     //  constMaxGain = log2(1+2^(log2(e)*diffGain)); (in Q8)
    constMaxGain = param.kGenFuncTable(floor(diffGain) + 1);% // in Q8

%     // Calculate a parameter used to approximate the fractional part of 2^x with a
%     // piecewise linear function in Q14:
%     //  constLinApprox = round(3/2*(4*(3-2*sqrt(2))/(log(2)^2)-0.5)*2^14);
    constLinApprox = 22817; %// in Q14

%     // Calculate a denominator used in the exponential part to convert from dB to linear scale:
%     //  den = 20*constMaxGain (in Q8)
    den = 20*constMaxGain;% // in Q8

    for idx = 0:1:31
    
%         // Calculate scaled input level (compressor):
%         //  inLevel = fix((-constLog10_2*(compRatio-1)*(1-i)+fix(compRatio/2))/compRatio)
        tmp16 = (kCompRatio - 1)*(idx - 1); %// Q0
        tmp32 = tmp16*kLog10_2 + 1;% // Q14
        inLevel = DivW32W16(tmp32, kCompRatio); %// Q14

%         // Calculate diffGain-inLevel, to map using the genFuncTable
        inLevel = diffGain*2^14 - inLevel; %// Q14

%         // Make calculations on abs(inLevel) and compensate for the sign afterwards.
        absInLevel = abs(inLevel); %// Q14

%         // LUT with interpolation
        intPart = round(absInLevel/2^14);
        fracPart = bitand(round(absInLevel) , hex2dec('00003FFF')); %// extract the fractional part
        tmpU16 = param.kGenFuncTable(intPart + 2) - param.kGenFuncTable(intPart+1); %// Q8
        tmpU32no1 = tmpU16*fracPart; %// Q22
        tmpU32no1 = tmpU32no1 + param.kGenFuncTable(intPart+1)*2^14; %// Q22
        logApprox = fix(tmpU32no1/2^8); %// Q14
%         // Compensate for negative exponent using the relation:
%         //  log2(1 + 2^-x) = log2(1 + 2^x) - x
        if (inLevel < 0)
        
            mzeros = WebRtcSpl_NormU32(absInLevel);
            zerosScale = 0;
            if (mzeros < 15)
            
%                 // Not enough space for multiplication
                tmpU32no2 = WEBRTC_SPL_RSHIFT_U32(absInLevel, 15 - mzeros); 
                tmpU32no2 = WEBRTC_SPL_UMUL_32_16(tmpU32no2, kLogE_1); 
                if (mzeros < 9)
                
                    tmpU32no1 = WEBRTC_SPL_RSHIFT_U32(tmpU32no1, 9 - mzeros);
                    zerosScale = 9 - mzeros;
                 else
                
                    tmpU32no2 = WEBRTC_SPL_RSHIFT_U32(tmpU32no2, mzeros - 9); 
                end
             else
            
                tmpU32no2 = WEBRTC_SPL_UMUL_32_16(absInLevel, kLogE_1); 
                tmpU32no2 = bitshift(tmpU32no2, -6); 
            end
            logApprox = 0;
            if (tmpU32no2 < tmpU32no1)
            
                logApprox = bitshift(tmpU32no1 - tmpU32no2, -8 + zerosScale); 
            end
        end
        numFIX = maxGain*constMaxGain*2^6; 
%         numFIX = numFIX - bitand(floor(logApprox*diffGain),hex2dec('FFFFFFFF')); 
        numFIX = numFIX - logApprox*diffGain;
%         // Calculate ratio
%         // Shift |numFIX| as much as possible.
%         // Ensure we avoid wrap-around in |den| as well.
        if ((numFIX > floor(den /2^8))||((-numFIX > floor(den /2^8))))  %// |den| is Q8.
        
            mzeros = NormW32(numFIX);
        else
        
            mzeros = NormW32(den) + 8;
        end
         numFIX = WEBRTC_SPL_LSHIFT_W32(numFIX, mzeros); %// Q(14+zeros)

%         // Shift den so we end up in Qy1
        tmp32no1 = WEBRTC_SPL_SHIFT_W32(den, mzeros - 9); %// Q(zeros)
        if (numFIX < 0)
        
            numFIX = numFIX - WEBRTC_SPL_RSHIFT_W32(tmp32no1, 1);
        else
        
            numFIX = numFIX + WEBRTC_SPL_RSHIFT_W32(tmp32no1, 1);
        end
        y32 = floor(floor(numFIX)/(floor(tmp32no1) + 0.0001)); %// in Q15
        if(y32>0)
            y32 = floor((y32 + 1)/2);
        else
            y32 = -floor((-y32 + 1)/2);
        end
        
        if (limiterEnable && (idx < limiterIdx))
        
            tmp32 = WEBRTC_SPL_MUL_16_U16(idx - 1, kLog10_2);% // Q14
            tmp32 = tmp32 - limiterLvl*2^14; %// Q14
            y32 = DivW32W16(tmp32 + 10, 20);
        end
        if (y32 > 39000)
        
            tmp32 = y32/2 * kLog10 + 4096; %// in Q27
            tmp32 = WEBRTC_SPL_RSHIFT_W32(tmp32, 13); %// in Q14
        else
        
            tmp32 = y32 * kLog10 + 8192; %// in Q28
            tmp32 = floor(tmp32/2^14); %// in Q14
        end
        tmp32 = tmp32 + 16*2^14; %// in Q14 (Make sure final output is in Q16)

%         // Calculate power
        if (tmp32 > 0)
            intPart = bitshift(floor(tmp32), -14);
            fracPart = bitand(floor(tmp32),hex2dec('00003FFF'));
%             fracPart = round(tmp32/2^14 - intPart);
            
            if (bitshift(fracPart, -13))
                tmp16 = 2*2^14 - constLinApprox;
                tmp32no2 = 2^14 - fracPart;
                tmp32no2 = tmp32no2*tmp16;
                tmp32no2 = bitshift(tmp32no2, -13);
                tmp32no2 = 2^14 - tmp32no2;
            else          
                tmp16 = constLinApprox - 2^14;
                tmp32no2 = fracPart*tmp16;
                tmp32no2 = bitshift(tmp32no2, -13);
            end
                 fracPart = round(tmp32no2);
                 gainTable(idx+1) = 2^intPart...
                    + fracPart*2^(intPart - 14);
         else
        
            gainTable(idx+1) = 0;
        end
    end

     y = 0;
end