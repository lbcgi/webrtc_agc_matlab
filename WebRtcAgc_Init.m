function [y, stt] = WebRtcAgc_Init(agcInst, minLevel, maxLevel, agcMode, fs, param)
   
    global AGC_UNINITIALIZED_ERROR
    global kAgcModeUnchanged
    global kAgcModeFixedDigital
    global kAgcModeAdaptiveDigital
    global kAgcTrue
    global AGC_UNSPECIFIED_ERROR
    
    kMsecSpeechInner = 520;
    kMsecSpeechOuter = 340;
    kNormalVadThreshold = 400;
    
    stt = agcInst;
 
    [y, stt.digitalAgc] = WebRtcAgc_InitDigital(stt, agcMode, param);
    if(y~=0)
        stt.lastError = param.AGC_UNINITIALIZED_ERROR;
        y = -1;
    end
    
    stt.envSum = 0;
    
    if (agcMode < param.kAgcModeUnchanged || agcMode > param.kAgcModeFixedDigital)
        y = -1;
    end
    
    stt.agcMode = agcMode;
    stt.fs = fs;
    
    stt.vadMic = WebRtcAgc_InitVad;

    tmpNorm = WebRtcSpl_NormU32(maxLevel);
    stt.scale = tmpNorm - 23;
    if (stt.scale < 0)
        stt.scale = 0;
    end
    stt.scale = 0;
    maxLevel = bitshift(maxLevel, stt.scale);
    minLevel = bitshift(minLevel, stt.scale);
%     
    if (stt.agcMode == param.kAgcModeAdaptiveDigital)
        minLevel = 0;
        maxLevel = 255;
        stt.scale = 0;
    end
    max_add = (maxLevel - minLevel)/2^2;
    stt.minLevel = minLevel;
    stt.maxAnalog = maxLevel;
    stt.maxLevel = maxLevel + max_add;
    stt.maxInit = stt.maxLevel;
    stt.zeroCtrlMax = stt.maxAnalog;
%     
    stt.micVol = stt.maxAnalog;
    if (stt.agcMode == param.kAgcModeAdaptiveDigital)
        stt.micVol = 127;
    end
    stt.micRef = stt.micVol;
    stt.micGainIdx = 127;
% %         /* Minimum output volume is 4% higher than the available lowest volume level */
% 
    tmp32 = bitshift(round((stt.maxLevel - stt.minLevel)) * 10, -3);
    stt.minOutput = stt.minLevel + tmp32;
%     
    stt.msTooLow = 0;
    stt.msTooHigh = 0;
    stt.changeToSlowMode = 0;
    stt.firstCall = 0;
    stt.msZero = 0;
    stt.muteGuardMs = 0;
    stt.gainTableIdx = 0;
    stt.msecSpeechInnerChange = kMsecSpeechInner;
    stt.msecSpeechOuterChange = kMsecSpeechOuter;
    stt.activeSpeech = 0;
    stt.Rxx16_LPw32Max = 0;
    stt.vadThreshold = kNormalVadThreshold;
    stt.inActive = 0;
    stt.Rxx16_vectorw32 = NaN(1,param.RXX_BUFFER_LEN);
    for i = 0:param.RXX_BUFFER_LEN-1
        stt.Rxx16_vectorw32(i + 1) = 1000; %/* -54dBm0 */
    end
    stt.Rxx160w32 = 125*param.RXX_BUFFER_LEN;
    stt.Rxx16pos = 0;
    stt.Rxx16_LPw32 = 16284;
%     
    for i = 0:4
            stt.Rxx16w32_array(1, i + 1) = 0;
    end
    for i = 0:9
            stt.env(1, i + 1) = 0;
            stt.env(2, i + 1) = 0;
    end
    stt.inQueue = 0;
    stt.filterState = zeros(8,1);
    stt.initFlag = param.kInitCheck;
% 
    stt.defaultConfig.limiterEnable = param.kAgcTrue;
% 
    stt.defaultConfig.targetLevelDbfs = param.AGC_DEFAULT_TARGET_LEVEL;
    stt.defaultConfig.compressionGaindB = param.AGC_DEFAULT_COMP_GAIN;
% 
    [y, stt] = WebRtcAgc_set_config(stt,stt.defaultConfig, param);
    if(y == -1)
        stt.lastError = param.AGC_UNSPECIFIED_ERROR;
    end
%     
%     stt.Rxx160_LPw32 = stt.analogTargetLevel;
    stt.analogTargetLevel = rand;
    stt.lowLevelSignal = 0;
%     
    if ((minLevel >= maxLevel) || bitand(maxLevel,hex2dec('FC000000')))
        y = -1;
    else
        y = 0;
    end
    
end