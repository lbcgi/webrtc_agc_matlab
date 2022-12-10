function state = WebRtcAgc_InitVad
  
   state.HPstate = 0;   %// state of high pass filter
    state.logRatio = 0;  %// log( P(active) / P(inactive) )
%     // average input level (Q10)
    state.meanLongTerm = bitshift(15 , 10);

%     // variance of input level (Q8)
    state.varianceLongTerm = bitshift(500 , 8);

    state.stdLongTerm = 0; % // standard deviation of input level in dB
%     // short-term average input level (Q10)
    state.meanShortTerm = bitshift(15 , 10);

%     // short-term variance of input level (Q8)
    state.varianceShortTerm = bitshift(500 , 8);

    state.stdShortTerm =...
            0;              % // short-term standard deviation of input level in dB
    state.counter = 3;  %// counts updates
    for k = 0:7 
       % // downsampling filter
        state.downState(k + 1) = 0;
    end

end