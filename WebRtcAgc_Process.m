function [y, stt, out, outMicLevel, saturationWarning] = WebRtcAgc_Process(agcInst, in_near, num_bands, samples, inMicLevel, param)
        
     stt = agcInst;
    if (isempty(stt))
        y = -1;
        return;
    end
    if (stt.fs == 8000)
         if (samples ~= 80) 
            y = -1;
            return;
         end
     elseif (stt.fs == 16000 || stt.fs == 32000 || stt.fs == 48000) 
        if (samples ~= 160) 
               y = -1;
            return;
        end
     else
           y = -1;
            return;
    end
    
    saturationWarning = 0;
    outMicLevel = inMicLevel;

   [y, stt.digitalAgc, out] = WebRtcAgc_ProcessDigital(stt.digitalAgc, in_near, num_bands, stt.fs, stt.lowLevelSignal, param); 
    if(y == -1)
        return;
    end
%         /* update queue */
    if (stt.inQueue > 1)
          stt.env(1,1:10) = stt.env(2,1:10);
          stt.Rxx16w32_array(1,1:5) = stt.Rxx16w32_array(2,1:5);
    end

    if (stt.inQueue > 0)
        stt.inQueue = stt.inQueue - 1;
    end

    y = 0;
end