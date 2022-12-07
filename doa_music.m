% DOA estimation by MUSIC 

% EMAIL:zhangxiaofei@nuaa.edu.cn
clear all
close all
derad = pi/180;        % deg -> rad
radeg = 180/pi;
twpi = 2*pi;
dd = 0.5;               % space 
d=0:dd:(22-1)*dd;     % 
% d = [0 1  4 5 6 7 8 11 13]*dd;
kelm = length(d);               % ’Û¡– ˝¡ø
iwave = 2;              % number of DOA
theta = [51 55];     % Ω«∂»
snr = -8;               % input SNR (dB)
n = 250;                 % 
A=exp(-1j*twpi*d.'*sin(theta*derad));%%%% direction matrix
S=randn(iwave,n);
X=A*S;
X1=awgn(X,snr,'measured');
% InvS=inv(Rxx); %%%%
Rxx=X1*X1'/n;

M = size(Rxx,1);

% opts.loss = 'l1'; 
% opts.DEBUG = 1;
% A = randn(22,22);
% B = eye(M);
% MM = rand(10);
% lambda = 1/sqrt(size(Rxx,1));
% [R0,Rn,obj,err,iter] = rpca(Rxx,lambda,opts);
% 
L0 = n;
p = 0.999;
Cest = (1/L0)*kron(Rxx.',Rxx);
eta = chi2inv(p,M^2);
beta = 1/sqrt(M);
cvx_solver sedumi
cvx_begin
% hermitian toeplitz nonnegative
    variable t
    variable nn(M,1)  
%     variable Rn(M,M)     hermitian    toeplitz                                          
    variable R0(M,M)     hermitian    toeplitz
%     minimize t
    minimize t

    subject to
%                 (norm(Cest^(-1/2)*vec(Rxx-R0-Rn),2))<sqrt(eta);
%                 trace(R0)<t;
%                 (trace(R0) + 3*beta*norm(toeplitz(nn),1))<t;
                    norm(nn,1)<t
                (norm((Cest^(-1/2))*vec(Rxx-R0-toeplitz(nn)),2))<sqrt(eta);
                
                %                 trace(R0)<t;
                %                  R0>0;
%                 nn>0;
%                 Rn>0;
cvx_end
norm(Rxx-R0-toeplitz(nn),2)
norm(toeplitz(nn),1)
norm((Cest^(-1/2))*vec(Rxx-R0-toeplitz(nn)),2)
% norm(Rxx-R0-Rn,2)
% norm(Rn,1)

t
rank(R0)

[EV,D]=eig(R0);%%%% 

EVA=diag(D)';
[EVA,I]=sort(EVA);
EVA=fliplr(EVA);
EV=fliplr(EV(:,I));

% MUSIC
for iang = 1:361
        angle(iang)=(iang-181)/2;
        phim=derad*angle(iang);
        a=exp(-1j*twpi*d*sin(phim)).';
        L=iwave;    
        En=EV(:,L+1:kelm);
        SP(iang)=(a'*a)/(a'*En*En'*a);
end
   
[EV,D]=eig(Rxx);%%%% 
EVA=diag(D)';
[EVA,I]=sort(EVA);
EVA=fliplr(EVA);
EV=fliplr(EV(:,I));

% MUSIC2
for iang = 1:361
        angle(iang)=(iang-181)/2;
        phim=derad*angle(iang);
        a=exp(-1j*twpi*d*sin(phim)).';
        L=iwave;    
        En=EV(:,L+1:kelm);
        SP2(iang)=(a'*a)/(a'*En*En'*a);
end
figure(1)
% 
SP=abs(SP);
SPmax=max(SP);
SP=10*log10(SP/SPmax);
h=plot(angle,SP,'b');
set(h,'Linewidth',2)
xlabel('angle (degree)')
ylabel('magnitude (dB)')
title('µÕ÷»ª÷∏¥ ‘—È');
axis([-90 90 -60 0])
set(gca, 'XTick',[-90:30:90])
grid on  

SP2=abs(SP2);
SPmax2=max(SP2);
SP2=10*log10(SP2/SPmax2);
hold on
h=plot(angle,SP2,'r');

legend('µÕ÷»ª÷∏¥∫Û','‘≠ º–≈∫≈');

