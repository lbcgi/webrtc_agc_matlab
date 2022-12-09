function [y, stt] = WebRtcAgc_set_config(agcInst, agcConfig, param)

    stt = agcInst;
    
    if (stt.initFlag ~= param.kInitCheck)
        stt.lastError = param.AGC_UNINITIALIZED_ERROR;
        y = -1;
    end
    if (agcConfig.limiterEnable ~= param.kAgcFalse && agcConfig.limiterEnable ~= param.kAgcTrue)
    
        stt.lastError = param.AGC_UNINITIALIZED_ERROR;
        y = -1;
    end

    stt.limiterEnable = agcConfig.limiterEnable;
    stt.compressionGaindB = agcConfig.compressionGaindB;
    if ((agcConfig.targetLevelDbfs < 0) || (agcConfig.targetLevelDbfs > 31))
    
        stt.lastError = param.AGC_BAD_PARAMETER_ERROR;
        y =  -1;
    end
    stt.targetLevelDbfs = agcConfig.targetLevelDbfs;
    
   if (stt.agcMode == param.kAgcModeFixedDigital)
    
%         /* Adjust for different parameter interpretation in FixedDigital mode */
        stt.compressionGaindB = stt.compressionGaindB + agcConfig.targetLevelDbfs;
   end
   
    stt = WebRtcAgc_UpdateAgcThresholds(stt, param);
    [~, stt.digitalAgc.gainTable] = WebRtcAgc_CalculateGainTable(stt.compressionGaindB,stt.targetLevelDbfs, stt.limiterEnable, stt.analogTarget, param);
% #ifdef AGC_DEBUG//test log
%         fprintf(stt->fpt, "AGC->set_config, frame %d: Error from calcGainTable\n\n", stt->fcount);
% #endif

% %     
% % 
%   /* Store the config in a WebRtcAgc_config_t */
    stt.usedConfig.compressionGaindB = agcConfig.compressionGaindB;
    stt.usedConfig.limiterEnable = agcConfig.limiterEnable;
    stt.usedConfig.targetLevelDbfs = agcConfig.targetLevelDbfs;
    y = 0;
end