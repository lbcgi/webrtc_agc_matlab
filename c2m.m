%c2m test
in = [1 2 3 4];
len =4;
filtState = zeros(1,8);
[out, filtState] = downsampleBy2(in, len, filtState);