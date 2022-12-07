function WebRtcAgc_InitVad(flag)
   
    global Agc_t_imp
    
    Agc_t_imp.DigitalAgc_t.AgcVad_t(flag).HPstate = 0;
    Agc_t_imp.DigitalAgc_t.AgcVad_t(flag).logRatio = 0;
    Agc_t_imp.DigitalAgc_t.AgcVad_t(flag).meanLongTerm = 15*2^10;
    Agc_t_imp.DigitalAgc_t.AgcVad_t(flag).varianceLongTerm = 500*2^8;
    Agc_t_imp.DigitalAgc_t.AgcVad_t(flag).stdLongTerm = 0;
    Agc_t_imp.DigitalAgc_t.AgcVad_t(flag).meanShortTerm = 15*2^10;
    Agc_t_imp.DigitalAgc_t.AgcVad_t(flag).varianceShortTerm = 500*2^8;
    Agc_t_imp.DigitalAgc_t.AgcVad_t(flag).stdShortTerm = 0;
    Agc_t_imp.DigitalAgc_t.AgcVad_t(flag).counter = 3;
    
    for k = 0:7
         Agc_t_imp.DigitalAgc_t.AgcVad_t(flag).downState(k) = 0;
    end

end