% initialization files for all the asm3 state variables + T +  dummy states

% This file has been created by Xavier Flores-Alsina
% July, 2010
% IEA, Lund University, Lund, Sweden

Qin0 = 18446;
Qintr = 3*Qin0;
Qin = Qin0;
Qw = 385;

% _ASin represents mass (g/d), flow is still m3/d, used by hydraulic delay

S_O2_ASin = 0.0001*(Qin+Qin0+Qintr);
S_I_ASin = 30*(Qin+Qin0+Qintr);
S_S_ASin = 69.50*(Qin+Qin0+Qintr);
S_NH4_ASin = 34.716*(Qin+Qin0+Qintr);
S_N2_ASin =0.0001* (Qin+Qin0+Qintr);
S_NOX_ASin = 0.0001*(Qin+Qin0+Qintr);
S_ALK_ASin = 7*(Qin+Qin0+Qintr);
X_I_ASin = 51.20*(Qin+Qin0+Qintr);
X_S_ASin = 202.32*(Qin+Qin0+Qintr);
X_H_ASin = 28.17*(Qin+Qin0+Qintr);
X_STO_ASin = 0.0001*(Qin+Qin0+Qintr);
X_A_ASin = 0.0001*(Qin+Qin0+Qintr);
X_SS_ASin = (0.75*X_S_ASin + 0.75*X_S_ASin + 0.90*X_H_ASin + 0.90*X_STO_ASin + 0.90*X_A_ASin) ;
Q_ASin = Qin+Qin0+Qintr;
T_ASin = 14.8581;
S_D1_ASin = 0;
S_D2_ASin = 0;
S_D3_ASin = 0;
X_D4_ASin = 0;
X_D5_ASin = 0;

S_O2_1 = 2;
S_I_1 = 30;
S_S_1 = 2;
S_NH4_1 = 20;
S_N2_1 = 0;
S_NOX_1 = 0;
S_ALK_1 = 5;
X_I_1 = 100;
X_S_1 = 40;
X_H_1 = 100;
X_STO_1 = 40;
X_A_1 = 1;
X_SS_1 = 200;
Q_1 = Qin+Qin0+Qintr;
T1 = 14.8581;
S_D1_1 = 0;
S_D2_1 = 0;
S_D3_1 = 0;
X_D4_1 = 0;
X_D5_1 = 0;

S_O2_2 = 2;
S_I_2 = 30;
S_S_2 = 2;
S_NH4_2 = 20;
S_N2_2 = 0;
S_NOX_2 = 0;
S_ALK_2 = 5;
X_I_2 = 100;
X_S_2 = 40;
X_H_2 = 100;
X_STO_2 = 40;
X_A_2 = 1;
X_SS_2 = 200;
Q_2 = Qin+Qin0+Qintr;
T2 = 14.8581;
S_D1_2 = 0;
S_D2_2 = 0;
S_D3_2 = 0;
X_D4_2 = 0;
X_D5_2 = 0;

S_O2_3 = 2;
S_I_3 = 30;
S_S_3 = 2;
S_NH4_3 = 20;
S_N2_3 = 0;
S_NOX_3 = 0;
S_ALK_3 = 5;
X_I_3 = 100;
X_S_3 = 40;
X_H_3 = 100;
X_STO_3 = 40;
X_A_3 = 1;
X_SS_3 = 200;
Q_3 = Qin+Qin0+Qintr;
T3 = 14.8581;
S_D1_3 = 0;
S_D2_3 = 0;
S_D3_3 = 0;
X_D4_3 = 0;
X_D5_3 = 0;

S_O2_4 = 2;
S_I_4 = 30;
S_S_4 = 2;
S_NH4_4 = 20;
S_N2_4 = 0;
S_NOX_4 = 0;
S_ALK_4 = 5;
X_I_4=  100;
X_S_4 = 40;
X_H_4 = 100;
X_STO_4 = 40;
X_A_4 = 1;
X_SS_4 = 200;
Q_4 = Qin+Qin0+Qintr;
T4 = 14.8581;
S_D1_4 = 0;
S_D2_4 = 0;
S_D3_4 = 0;
X_D4_4 = 0;
X_D5_4 = 0;

S_O2_5 = 2;
S_I_5 = 30;
S_S_5 = 2;
S_NH4_5 = 20;
S_N2_5 = 0;
S_NOX_5 = 0;
S_ALK_5 = 5;
X_I_5 = 100;
X_S_5 = 40;
X_H_5 = 100;
X_STO_5 = 40;
X_A_5 = 1;
X_SS_5 = 200;
Q_5 = Qin+Qin0+Qintr;
T5 = 14.8581;
S_D1_5 = 0;
S_D2_5 = 0;
S_D3_5 = 0;
X_D4_5 = 0;
X_D5_5 = 0;

XINITDELAY = [ S_O2_ASin S_I_ASin S_S_ASin S_NH4_ASin S_N2_ASin S_NOX_ASin S_ALK_ASin X_I_ASin X_S_ASin X_H_ASin X_STO_ASin X_A_ASin X_SS_ASin Q_ASin T_ASin S_D1_ASin S_D2_ASin S_D3_ASin X_D4_ASin X_D5_ASin ];
XINIT1 = [ S_O2_1 S_I_1 S_S_1 S_NH4_1 S_N2_1 S_NOX_1 S_ALK_1 X_I_1 X_S_1 X_H_1 X_STO_1 X_A_1 X_SS_1 Q_1 T1 S_D1_1 S_D2_1 S_D3_1 X_D4_1 X_D5_1];
XINIT2 = [ S_O2_2 S_I_2 S_S_2 S_NH4_2 S_N2_2 S_NOX_2 S_ALK_2 X_I_2 X_S_2 X_H_2 X_STO_2 X_A_2 X_SS_2 Q_2 T2 S_D1_2 S_D2_2 S_D3_2 X_D4_2 X_D5_2];
XINIT3 = [ S_O2_3 S_I_3 S_S_3 S_NH4_3 S_N2_3 S_NOX_3 S_ALK_3 X_I_3 X_S_3 X_H_3 X_STO_3 X_A_3 X_SS_3 Q_3 T3 S_D1_3 S_D2_3 S_D3_3 X_D4_3 X_D5_3];
XINIT4 = [ S_O2_4 S_I_4 S_S_4 S_NH4_4 S_N2_4 S_NOX_4 S_ALK_4 X_I_4 X_S_4 X_H_4 X_STO_4 X_A_4 X_SS_4 Q_4 T4 S_D1_4 S_D2_4 S_D3_4 X_D4_4 X_D5_4];
XINIT5 = [ S_O2_2 S_I_5 S_S_5 S_NH4_5 S_N2_5 S_NOX_5 S_ALK_5 X_I_5 X_S_5 X_H_5 X_STO_5 X_A_5 X_SS_5 Q_5 T5 S_D1_5 S_D2_5 S_D3_5 X_D4_5 X_D5_5];

% XINIT1 = XINIT1.*(rand(1, 20)/2);
% XINIT2 = XINIT2.*(rand(1, 20)/2);
% XINIT3 = XINIT3.*(rand(1, 20)/2);
% XINIT4 = XINIT4.*(rand(1, 20)/2);
% XINIT5 = XINIT5.*(rand(1, 20)/2);

%XINIT5(1) = 2; % just to avoid antiwindupeffect the first sample time

k_H = 3;
K_X = 1;
k_STO = 5;
ny_NOX = 0.6;
K_O2 = 0.2;
K_NOX = 0.5;
K_S = 2;
K_STO = 1;
mu_H = 2;
K_NH4 = 0.01;
K_ALK = 0.1;
b_HO2 = 0.2;
b_HNOX = 0.1;
b_STOO2 = 0.2;
b_STONOX = 0.1;
mu_A = 1.0;
K_ANH4 = 1;
K_AO2 = 0.5;
K_AALK = 0.5;
b_AO2 = 0.15;
b_ANOX = 0.05;
f_SI = 0;
Y_STOO2 = 0.85;
Y_STONOX = 0.80;
Y_HO2 = 0.63;
Y_HNOX = 0.54;
Y_A = 0.24;
f_XI = 0.20;
i_NSI = 0.01;
i_NSS = 0.03;
i_NXI = 0.02;
i_NXS = 0.04;
i_NBM = 0.07;
i_SSXI = 0.75;
i_SSXS = 0.75;
i_SSBM = 0.90;
i_SSSTO = 0.60;  %not properly defined in ASM3 report
f_P = 0.08;

PAR1 = [ k_H K_X k_STO ny_NOX K_O2 K_NOX K_S K_STO mu_H K_NH4 K_ALK b_HO2 b_HNOX b_STOO2 b_STONOX mu_A K_ANH4 K_AO2 K_AALK b_AO2 b_ANOX f_SI Y_STOO2 Y_STONOX Y_HO2 Y_HNOX Y_A f_XI i_NSI i_NSS i_NXI i_NXS i_NBM i_SSXI i_SSXS i_SSBM i_SSSTO ];
PAR2 = PAR1;
PAR3 = PAR1;
PAR4 = PAR1;
PAR5 = PAR1;


VOL1 = 1000;
VOL2 = VOL1;
VOL3 = 1333;
VOL4 = VOL3;
VOL5 = VOL3;


SOSAT1 = 8;
SOSAT2 = SOSAT1;
SOSAT3 = SOSAT1;
SOSAT4 = SOSAT1;
SOSAT5 = SOSAT1;


KLa1 = 0;
KLa2 = 0;
KLa3 = 240;
KLa4 = 240;
KLa5 = 240;


carb1 = 0; % external carbon flow rate to reactor 1
carb2 = 0; % external carbon flow rate to reactor 2
carb3 = 0; % external carbon flow rate to reactor 3
carb4 = 0; % external carbon flow rate to reactor 4
carb5 = 0; % external carbon flow rate to reactor 5
CARBONSOURCECONC = 400000; % external carbon source concentration = 400000 mg COD/l


T = 0.0001; % used by hydraulic delays
QintrT = T*10;
