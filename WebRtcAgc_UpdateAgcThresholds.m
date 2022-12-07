function stt = WebRtcAgc_UpdateAgcThresholds(stt, param)

%     /* Set analog target level in envelope dBOv scale */
    tmp16 = (param.DIFF_REF_TO_ANALOG * stt.compressionGaindB) + param.ANALOG_TARGET_LEVEL_2;
    tmp16 = DivW32W16ResW16(tmp16, param.ANALOG_TARGET_LEVEL);
    stt.analogTarget = param.DIGITAL_REF_AT_0_COMP_GAIN + tmp16;
    if (stt.analogTarget < param.DIGITAL_REF_AT_0_COMP_GAIN)
    
        stt.analogTarget = param.DIGITAL_REF_AT_0_COMP_GAIN;
    end
    if (stt.agcMode == param.kAgcModeFixedDigital)
    
%         /* Adjust for different parameter interpretation in FixedDigital mode */
        stt.analogTarget = stt.compressionGaindB;
    end

%     /* Since the offset between RMS and ENV is not constant, we should make this into a
%      * table, but for now, we'll stick with a constant, tuned for the chosen analog
%      * target level.
%      */
    stt.targetIdx = param.ANALOG_TARGET_LEVEL + param.OFFSET_ENV_TO_RMS;

%     /* Analog adaptation limits */
%     /* analogTargetLevel = round((32767*10^(-targetIdx/20))^2*16/2^7) */
    stt.analogTargetLevel = param.RXX_BUFFER_LEN * param.kTargetLevelTable(stt.targetIdx);
    stt.startUpperLimit = param.RXX_BUFFER_LEN * param.kTargetLevelTable(stt.targetIdx - 1);
    stt.startLowerLimit = param.RXX_BUFFER_LEN * param.kTargetLevelTable(stt.targetIdx + 1);
    stt.upperPrimaryLimit = param.RXX_BUFFER_LEN * param.kTargetLevelTable(stt.targetIdx - 2);
    stt.lowerPrimaryLimit = param.RXX_BUFFER_LEN * param.kTargetLevelTable(stt.targetIdx + 2);
    stt.upperSecondaryLimit = param.RXX_BUFFER_LEN * param.kTargetLevelTable(stt.targetIdx - 5);
    stt.lowerSecondaryLimit = param.RXX_BUFFER_LEN * param.kTargetLevelTable(stt.targetIdx + 5);
    stt.upperLimit = stt.startUpperLimit;
    stt.lowerLimit = stt.startLowerLimit;
