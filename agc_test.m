% agc test
format long 

% clear;
% global ii
% ii = 0;
% global decay3_mb


agcConfig.compressionGaindB = 20;
agcConfig.limiterEnable     = 1;
agcConfig.targetLevelDbfs   = 3;

minLevel = 0;
maxLevel = 255;
agcMode = 2;
sampleRate = 8000;

param.kAgcModeFixedDigital = 3;
param.RXX_BUFFER_LEN = 10;
param.AGC_DEFAULT_TARGET_LEVEL = 3;
param.AGC_DEFAULT_COMP_GAIN = 9;
param.kInitCheck = 42;
param.kAgcFalse = 0;
param.kAgcTrue = 1;
param.kAgcModeFixedDigital = 3;
param.DIFF_REF_TO_ANALOG = 5;
param.ANALOG_TARGET_LEVEL_2 = 5;
param.ANALOG_TARGET_LEVEL = 11;
param.DIGITAL_REF_AT_0_COMP_GAIN = 4;
param.kGenFuncTableSize = 128;

param.kGenFuncTable = [
        256, 485, 786, 1126, 1484, 1849, 2217, 2586, 2955, 3324, 3693,...
        4063, 4432, 4801, 5171, 5540, 5909, 6279, 6648, 7017, 7387, 7756,...
        8125, 8495, 8864, 9233, 9603, 9972, 10341, 10711, 11080, 11449, 11819,...
        12188, 12557, 12927, 13296, 13665, 14035, 14404, 14773, 15143, 15512, 15881,...
        16251, 16620, 16989, 17359, 17728, 18097, 18466, 18836, 19205, 19574, 19944,...
        20313, 20682, 21052, 21421, 21790, 22160, 22529, 22898, 23268, 23637, 24006,...
        24376, 24745, 25114, 25484, 25853, 26222, 26592, 26961, 27330, 27700, 28069,...
        28438, 28808, 29177, 29546, 29916, 30285, 30654, 31024, 31393, 31762, 32132,...
        32501, 32870, 33240, 33609, 33978, 34348, 34717, 35086, 35456, 35825, 36194,...
        36564, 36933, 37302, 37672, 38041, 38410, 38780, 39149, 39518, 39888, 40257,...
        40626, 40996, 41365, 41734, 42104, 42473, 42842, 43212, 43581, 43950, 44320,...
        44689, 45058, 45428, 45797, 46166, 46536, 46905];
    
param.AGC_UNINITIALIZED_ERROR = 18002;
param.kAgcModeUnchanged = 0;
param.kAgcModeAdaptiveAnalog = 1;
param.kAgcModeAdaptiveDigital = 2;
param.kAgcModeFixedDigital = 3;
param.kTargetLevelTable = [
        134209536, 106606424, 84680493, 67264106, 53429779, 42440782, 33711911,...
        26778323, 21270778, 16895980, 13420954, 10660642, 8468049, 6726411,...
        5342978, 4244078, 3371191, 2677832, 2127078, 1689598, 1342095,...
        1066064, 846805, 672641, 534298, 424408, 337119, 267783,...
        212708, 168960, 134210, 106606, 84680, 67264, 53430,...
        42441, 33712, 26778, 21271, 16896, 13421, 10661,...
        8468, 6726, 5343, 4244, 3371, 2678, 2127,...
        1690, 1342, 1066, 847, 673, 534, 424,...
        337, 268, 213, 169, 134, 107, 85,...
        67];
    
param.kAvgDecayTime = 250;
param.OFFSET_ENV_TO_RMS = 9;

inMicLevel = 0;
echo = 0;
% fd = fopen('byby_8K_1C_16bit.pcm');
[input, fs] = audioread('byby_8K_1C_16bit.wav');
input = fix(784*input.'/input(1)); % notice here

agcInst = WebRtcAgc_Create;
[status, agcInst] = WebRtcAgc_Init(agcInst, minLevel, maxLevel, agcMode, fs, param);
if(status == -1)
    disp('error1');
end

% [status, agcInst] = WebRtcAgc_set_config(agcInst, agcConfig, param);
% if(status == -1)
%     disp('error2');
% end

agcInst.usedConfig.compressionGaindB = agcConfig.compressionGaindB;
agcInst.usedConfig.limiterEnable = agcConfig.limiterEnable;
agcInst.usedConfig.targetLevelDbfs = agcConfig.targetLevelDbfs;

num_bands = 1;
samples = 80;

out = NaN(size(input));

frms = round(size(input,2)/samples);
st = 0;
stt = agcInst;
for cnt = 1:frms
    [nAgcRet, stt, out(st + 1:st + samples), outMicLevel, saturationWarning] = WebRtcAgc_Process(stt, input(st + 1:st + samples), num_bands, samples,...
                                        inMicLevel, param);
    st = st + samples;
end
% audiowrite('byby_8K_1C_16bit.agc.mb.wav', out/max(out), fs);
soundsc(out,fs)
% audiowrite('byby_8K_1C_16bit.agc.mb.wav', out/max(out), fs);
fd = fopen('byby_8K_1C_16bit.agc.mb.pcm', 'w');
fwrite(fd, out, 'int16');
