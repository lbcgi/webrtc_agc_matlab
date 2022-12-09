function y = WebRtcAgc_Init(minLevel,maxLevel,agcMode,fs)
   
    global Agc_t_imp
    global AGC_UNINITIALIZED_ERROR
    global kAgcModeUnchanged
    global kAgcModeFixedDigital
    global kAgcModeAdaptiveDigital
    global kAgcTrue
    global AGC_UNSPECIFIED_ERROR

    AGC_UNINITIALIZED_ERROR = 18002;
    
    kMsecSpeechInner = 520;
    kMsecSpeechOuter = 340;
    kNormalVadThreshold = 400;
    
    if (WebRtcAgc_InitDigital(agcMode) ~= 0)
        Agc_t_imp.lastError = AGC_UNINITIALIZED_ERROR;
        y = -1;
    end
        Agc_t_imp.envSum = 0;
    if (agcMode < kAgcModeUnchanged || agcMode > kAgcModeFixedDigital)
        y = -1;
    end
    
    Agc_t_imp.agcMode = agcMode;
    Agc_t_imp.fs = fs;
    
%    WebRtcAgc_InitVad(3);

    tmpNorm = WebRtcSpl_NormU32(maxLevel);
    Agc_t_imp.scale = tmpNorm - 23;
    if(Agc_t_imp.scale<0)
        Agc_t_imp.scale = 0;
    end
    Agc_t_imp.scale = 0;
    maxLevel = maxLevel*2^Agc_t_imp.scale;
    minLevel = minLevel*2^Agc_t_imp.scale;
    
   if (Agc_t_imp.agcMode == kAgcModeAdaptiveDigital)
        minLevel = 0;
        maxLevel = 255;
        Agc_t_imp.scale = 0;
    end
    max_add = (maxLevel - minLevel)/2^2;
    Agc_t_imp.minLevel = minLevel;
    Agc_t_imp.maxAnalog = maxLevel;
    Agc_t_imp.maxLevel = maxLevel + max_add;
    Agc_t_imp.maxInit = Agc_t_imp.maxLevel;
    Agc_t_imp.zeroCtrlMax = Agc_t_imp.maxAnalog;
    
    Agc_t_imp.micVol = Agc_t_imp.maxAnalog;
    if (stt.agcMode == kAgcModeAdaptiveDigital)
        Agc_t_imp.micVol = 127;
    end
    Agc_t_imp.micRef = Agc_t_imp.micVol;
    Agc_t_imp.micGainIdx = 127;
%         /* Minimum output volume is 4% higher than the available lowest volume level */

    tmp32 = (Agc_t_imp.maxLevel - Agc_t_imp.minLevel) * 10/2^8;
    Agc_t_imp.minOutput = Agc_t_imp.minLevel + tmp32;
    
    Agc_t_imp.msTooLow = 0;
    Agc_t_imp.msTooHigh = 0;
    Agc_t_imp.changeToSlowMode = 0;
    Agc_t_imp.firstCall = 0;
    Agc_t_imp.msZero = 0;
    Agc_t_imp.muteGuardMs = 0;
    Agc_t_imp.gainTableIdx = 0;
    Agc_t_imp.msecSpeechInnerChange = kMsecSpeechInner;
    Agc_t_imp.msecSpeechOuterChange = kMsecSpeechOuter;
    Agc_t_imp.activeSpeech = 0;
    Agc_t_imp.Rxx16_LPw32Max = 0;
    Agc_t_imp.vadThreshold = kNormalVadThreshold;
    Agc_t_imp.inActive = 0;
    Agc_t_imp.Rxx16_vectorw32 = NaN(1,RXX_BUFFER_LEN);
    for i = 0:RXX_BUFFER_LEN-1
        Agc_t_imp.Rxx16_vectorw32(i) = 1000;
    end
    Agc_t_imp.Rxx160w32 = 125*RXX_BUFFER_LEN;
    Agc_t_imp.Rxx16pos = 0;
    Agc_t_imp.Rxx16_LPw32 = 16284;
    
    for i = 0:9
        Agc_t_imp.env(1,i) = 0;
        Agc_t_imp.env(2,i) = 0;
    end
    Agc_t_imp.inQueue = 0;
    stt.filterState = zeros(1,8);
    Agc_t_imp.initFlag = kInitCheck;

    Agc_t_imp.defaultConfig.limiterEnable = kAgcTrue;

    Agc_t_imp.defaultConfig.targetLevelDbfs = AGC_DEFAULT_TARGET_LEVEL;
    Agc_t_imp.defaultConfig.compressionGaindB = AGC_DEFAULT_COMP_GAIN;

    if(WebRtcAgc_set_config(Agc_t_imp.defaultConfig)==-1)
        Agc_t_imp.lastError = AGC_UNSPECIFIED_ERROR;
    end
    
    Agc_t_imp.Rxx160_LPw32 = Agc_t_imp.analogTargetLevel;
    Agc_t_imp.lowLevelSignal = 0;
    
    if ((minLevel >= maxLevel) || (maxLevel && hex2dec(FC000000)))
        y = -1;
    else
        y = 0;
    end
    
end