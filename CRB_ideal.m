%% 本文件用于求解克拉美罗下界
%% 复现程序存在问题 界值范围不太符合预期

clc;clear;close all;

f0 = 77e6; % 频率
c = 3e8; % 光速
lambda = c / f0; % 波长
d = 0.5 * lambda; % 阵元间距

M = 8; % 阵元数目
P = 5; % 信号源数目
thetas = [-30 5 10 30 50]; % 信号源方向
u = [5 15 25 35 45]'; % 调频斜率

a = [0 : M-1]'; % 阵元序号
snr_set = 0:30; % 信噪比
snap = 100; % 快拍数
fs = 1000; % 采样频率
t = 1 / fs * (0:snap-1);  % 时间
s = exp(-1j * 2 * pi * (repmat(f0*t, P, 1) + 1 / 2 * u(1:P) * t .^ 2)); % 本振信号

atheta = exp(-1j * a * 2 * pi * d / lambda * sind(thetas(1:P))); % 导向矢量
dtheta = zeros(M, P); % 导向矢量求导
for i = 1 :length(thetas)
    dtheta(:, i) = -1j * 2 * pi * cosd(thetas(i)) * diag(a) * exp(-1j * a * 2 * pi * d / lambda * sind(thetas(i))); % 求导数
end

crbMatrix = zeros(1, length(snr_set));
for j = 1 : length(snr_set)
   snr = snr_set(j); % 信噪比
   X0 = atheta * s; % 载波信号
   X = awgn(X0, snr, 'measured'); % 完整基带信号
   
   sigma2 = X * X' / snap - X0 * X0' / snap;
   sigma2 = trace(sigma2)/M;
   
   H = dtheta(:,1:P)' * (eye(M) - atheta * (atheta' * atheta)^(-1) * atheta') * dtheta(:,1:P);

   out = 0;
   for snap_id = 1 : snap
       out = out + real(diag(s(:, snap_id))' * H * diag(s(:, snap_id)));
   end
   CRB = out^(-1) / 2 * sigma2;
   crbMatrix(j) = sum(diag(CRB));
end
plot(snr_set, crbMatrix);
xlabel('\fontname{Times New Roman}SNR(dB)');ylabel('\fontname{Times New Roman}CRB');

