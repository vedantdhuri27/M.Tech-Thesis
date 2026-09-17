% save states to initialization files

% This file has been created by Xavier Flores-Alsina
% July, 2010
% IEA, Lund University, Lund, Sweden



[m n] = size(reac1);
Qin0 = 18446;

if (exist('in'))
  Qin = in(end,14);
else
  Qin = Qin0;
end

if (exist('rec'))
  Qintr = rec(end,14);
else
  Qintr = 3*Qin0;
end

% _ASin represents mass (g/d), flow is still m3/d, used by hydraulic delay

S_O2_ASin =ASinput(m,1);
S_I_ASin = ASinput(m,2);
S_S_ASin = ASinput(m,3);
S_NH4_ASin = ASinput(m,4);
S_N2_ASin =ASinput(m,5);
S_NOX_ASin = ASinput(m,6);
S_ALK_ASin = ASinput(m,7);
X_I_ASin = ASinput(m,8);
X_S_ASin = ASinput(m,9);
X_H_ASin = ASinput(m,10);
X_STO_ASin = ASinput(m,11);
X_A_ASin =ASinput(m,12);
X_SS_ASin = ASinput(m,13);
Q_ASin = ASinput(m,14);
T_ASin = ASinput(m,15);
S_D1_ASin = ASinput(m,16);
S_D2_ASin = ASinput(m,17);
S_D3_ASin = ASinput(m,18);
X_D4_ASin = ASinput(m,19);
X_D5_ASin = ASinput(m,20);

S_O2_1 = reac1(m,1);
S_I_1 = reac1(m,2);
S_S_1 = reac1(m,3);
S_NH4_1 = reac1(m,4);
S_N2_1 = reac1(m,5);
S_NOX_1 = reac1(m,6);
S_ALK_1 = reac1(m,7);
X_I_1 = reac1(m,8);
X_S_1 = reac1(m,9);
X_H_1 = reac1(m,10);
X_STO_1 = reac1(m,11);
X_A_1 = reac1(m,12);
X_SS_1 = reac1(m,13);
Q_1 =reac1(m,14);
T1 = reac1(m,15);
S_D1_1 = reac1(m,16);
S_D2_1 = reac1(m,17);
S_D3_1 = reac1(m,18);
X_D4_1 = reac1(m,19);
X_D5_1 = reac1(m,20);

S_O2_2= reac2(m,1);
S_I_2= reac2(m,2);
S_S_2= reac2(m,3);
S_NH4_2= reac2(m,4);
S_N2_2= reac2(m,5);
S_NOX_2= reac2(m,6);
S_ALK_2= reac2(m,7);
X_I_2= reac2(m,8);
X_S_2= reac2(m,9);
X_H_2= reac2(m,10);
X_STO_2= reac2(m,11);
X_A_2= reac2(m,12);
X_SS_2= reac2(m,13);
Q_2=reac2(m,14);
T2 = reac2(m,15);
S_D1_2 = reac2(m,16);
S_D2_2 = reac2(m,17);
S_D3_2 = reac2(m,18);
X_D4_2 = reac2(m,19);
X_D5_2 = reac2(m,20);

S_O2_3= reac3(m,1);
S_I_3= reac3(m,2);
S_S_3= reac3(m,3);
S_NH4_3= reac3(m,4);
S_N2_3= reac3(m,5);
S_NOX_3= reac3(m,6);
S_ALK_3= reac3(m,7);
X_I_3= reac3(m,8);
X_S_3= reac3(m,9);
X_H_3= reac3(m,10);
X_STO_3= reac3(m,11);
X_A_3= reac3(m,12);
X_SS_3= reac3(m,13);
Q_3=reac3(m,14);
T3 = reac3(m,15);
S_D1_3 = reac3(m,16);
S_D2_3 = reac3(m,17);
S_D3_3 = reac3(m,18);
X_D4_3 = reac3(m,19);
X_D5_3 = reac3(m,20);

S_O2_4= reac4(m,1);
S_I_4= reac4(m,2);
S_S_4= reac4(m,3);
S_NH4_4= reac4(m,4);
S_N2_4= reac4(m,5);
S_NOX_4= reac4(m,6);
S_ALK_4= reac4(m,7);
X_I_4= reac4(m,8);
X_S_4= reac4(m,9);
X_H_4= reac4(m,10);
X_STO_4= reac4(m,11);
X_A_4= reac4(m,12);
X_SS_4= reac4(m,13);
Q_4=reac4(m,14);
T4 = reac4(m,15);
S_D1_4 = reac4(m,16);
S_D2_4 = reac4(m,17);
S_D3_4 = reac4(m,18);
X_D4_4 = reac4(m,19);
X_D5_4 = reac4(m,20);

S_O2_5= reac5(m,1);
S_I_5= reac5(m,2);
S_S_5= reac5(m,3);
S_NH4_5= reac5(m,4);
S_N2_5= reac5(m,5);
S_NOX_5= reac5(m,6);
S_ALK_5= reac5(m,7);
X_I_5= reac5(m,8);
X_S_5= reac5(m,9);
X_H_5= reac5(m,10);
X_STO_5= reac5(m,11);
X_A_5= reac5(m,12);
X_SS_5= reac5(m,13);
Q_5=reac5(m,14);
T5 = reac5(m,15);
S_D1_5 = reac5(m,16);
S_D2_5 = reac5(m,17);
S_D3_5 = reac5(m,18);
X_D4_5 = reac5(m,19);
X_D5_5 = reac5(m,20);

XINITDELAY = [ S_O2_ASin S_I_ASin S_S_ASin S_NH4_ASin S_N2_ASin S_NOX_ASin S_ALK_ASin X_I_ASin X_S_ASin X_H_ASin X_STO_ASin X_A_ASin X_SS_ASin Q_ASin T_ASin S_D1_ASin S_D2_ASin S_D3_ASin X_D4_ASin X_D5_ASin ];
XINIT1 = [ S_O2_1 S_I_1 S_S_1 S_NH4_1 S_N2_1 S_NOX_1 S_ALK_1 X_I_1 X_S_1 X_H_1 X_STO_1 X_A_1 X_SS_1 Q_1 T1 S_D1_1 S_D2_1 S_D3_1 X_D4_1 X_D5_1];
XINIT2 = [ S_O2_2 S_I_2 S_S_2 S_NH4_2 S_N2_2 S_NOX_2 S_ALK_2 X_I_2 X_S_2 X_H_2 X_STO_2 X_A_2 X_SS_2 Q_2 T2 S_D1_2 S_D2_2 S_D3_2 X_D4_2 X_D5_2];
XINIT3 = [ S_O2_3 S_I_3 S_S_3 S_NH4_3 S_N2_3 S_NOX_3 S_ALK_3 X_I_3 X_S_3 X_H_3 X_STO_3 X_A_3 X_SS_3 Q_3 T3 S_D1_3 S_D2_3 S_D3_3 X_D4_3 X_D5_3];
XINIT4 = [ S_O2_4 S_I_4 S_S_4 S_NH4_4 S_N2_4 S_NOX_4 S_ALK_4 X_I_4 X_S_4 X_H_4 X_STO_4 X_A_4 X_SS_4 Q_4 T4 S_D1_4 S_D2_4 S_D3_4 X_D4_4 X_D5_4];
XINIT5 = [ S_O2_5 S_I_5 S_S_5 S_NH4_5 S_N2_5 S_NOX_5 S_ALK_5 X_I_5 X_S_5 X_H_5 X_STO_5 X_A_5 X_SS_5 Q_5 T5 S_D1_5 S_D2_5 S_D3_5 X_D4_5 X_D5_5];

SO_1 =  settler(m,54);
SI_1 =  settler(m,55);
SS_1 =  settler(m,56);
SNH_1 = settler(m,57);
SN2_1 = settler(m,58);
SNO3_1 = settler(m,59);
SALK_1 = settler(m,60);
XI_1 =  settler(m,61);
XS_1 =  settler(m,62);
XBH_1 = settler(m,63);
XSTO_1 =settler(m,64);
XBA_1 = settler(m,65);
TSS_1 = settler(m,66);
T_1 =   settler(m,67);
SD1_1 = settler(m,68);
SD2_1 = settler(m,69);
SD3_1 = settler(m,70);
XD4_1 = settler(m,71);
XD5_1 = settler(m,72);

SO_2 =  settler(m,73);
SI_2 =  settler(m,74);
SS_2 =  settler(m,75);
SNH_2 = settler(m,76);
SN2_2 = settler(m,77);
SNO3_2 = settler(m,78);
SALK_2 = settler(m,79);
XI_2 =  settler(m,80);
XS_2 =  settler(m,81);
XBH_2 = settler(m,82);
XSTO_2 =settler(m,83);
XBA_2 = settler(m,84);
TSS_2 = settler(m,85);
T_2 =   settler(m,86);
SD1_2 = settler(m,87);
SD2_2 = settler(m,88);
SD3_2 = settler(m,89);
XD4_2 = settler(m,90);
XD5_2 = settler(m,91);

SO_3 =  settler(m,92);
SI_3=  settler(m,93);
SS_3=  settler(m,94);
SNH_3= settler(m,95);
SN2_3= settler(m,96);
SNO3_3= settler(m,97);
SALK_3= settler(m,98);
XI_3=  settler(m,99);
XS_3=  settler(m,100);
XBH_3= settler(m,101);
XSTO_3=settler(m,102);
XBA_3= settler(m,103);
TSS_3= settler(m,104);
T_3=   settler(m,105);
SD1_3= settler(m,106);
SD2_3= settler(m,107);
SD3_3= settler(m,108);
XD4_3= settler(m,109);
XD5_3= settler(m,110);

SO_4 =  settler(m,111);
SI_4=  settler(m,112);
SS_4=  settler(m,113);
SNH_4= settler(m,114);
SN2_4= settler(m,115);
SNO3_4= settler(m,116);
SALK_4= settler(m,117);
XI_4=  settler(m,118);
XS_4=  settler(m,119);
XBH_4= settler(m,120);
XSTO_4=settler(m,121);
XBA_4= settler(m,122);
TSS_4= settler(m,123);
T_4=   settler(m,124);
SD1_4= settler(m,125);
SD2_4= settler(m,126);
SD3_4= settler(m,127);
XD4_4= settler(m,128);
XD5_4= settler(m,129);

SO_5 =  settler(m,130);
SI_5 =  settler(m,131);
SS_5 =  settler(m,132);
SNH_5 = settler(m,133);
SN2_5 = settler(m,134);
SNO3_5 = settler(m,135);
SALK_5 = settler(m,136);
XI_5 =  settler(m,127);
XS_5 =  settler(m,138);
XBH_5 = settler(m,139);
XSTO_5 =settler(m,140);
XBA_5 = settler(m,141);
TSS_5 = settler(m,142);
T_5 =   settler(m,143);
SD1_5 = settler(m,144);
SD2_5 = settler(m,145);
SD3_5 = settler(m,146);
XD4_5 = settler(m,147);
XD5_5 = settler(m,148);

SO_6 =  settler(m,149);
SI_6 =  settler(m,150);
SS_6 =  settler(m,151);
SNH_6 = settler(m,152);
SN2_6 = settler(m,153);
SNO3_6 = settler(m,154);
SALK_6 = settler(m,155);
XI_6 =  settler(m,156);
XS_6 =  settler(m,157);
XBH_6 = settler(m,158);
XSTO_6 =settler(m,159);
XBA_6 = settler(m,160);
TSS_6 = settler(m,161);
T_6 =   settler(m,162);
SD1_6 = settler(m,163);
SD2_6 = settler(m,164);
SD3_6 = settler(m,165);
XD4_6 = settler(m,166);
XD5_6 = settler(m,167);

SO_7 =  settler(m,168);
SI_7 =  settler(m,169);
SS_7 =  settler(m,170);
SNH_7 = settler(m,171);
SN2_7 = settler(m,172);
SNO3_7 = settler(m,173);
SALK_7 = settler(m,174);
XI_7 =  settler(m,175);
XS_7 =  settler(m,176);
XBH_7 = settler(m,177);
XSTO_7 =settler(m,178);
XBA_7 = settler(m,179);
TSS_7 = settler(m,180);
T_7 =   settler(m,181);
SD1_7 = settler(m,182);
SD2_7 = settler(m,183);
SD3_7 = settler(m,184);
XD4_7 = settler(m,185);
XD5_7 = settler(m,186);

SO_8 =  settler(m,187);
SI_8 =  settler(m,188);
SS_8 =  settler(m,189);
SNH_8 = settler(m,190);
SN2_8 = settler(m,191);
SNO3_8 = settler(m,192);
SALK_8 = settler(m,193);
XI_8 =  settler(m,194);
XS_8 =  settler(m,195);
XBH_8 = settler(m,196);
XSTO_8 =settler(m,197);
XBA_8 = settler(m,198);
TSS_8 = settler(m,199);
T_8 =   settler(m,200);
SD1_8 = settler(m,201);
SD2_8 = settler(m,202);
SD3_8 = settler(m,203);
XD4_8 = settler(m,204);
XD5_8 = settler(m,205);

SO_9 =  settler(m,206);
SI_9 =  settler(m,207);
SS_9 =  settler(m,208);
SNH_9 = settler(m,209);
SN2_9 = settler(m,210);
SNO3_9 = settler(m,211);
SALK_9 = settler(m,212);
XI_9 =  settler(m,213);
XS_9 =  settler(m,214);
XBH_9 = settler(m,215);
XSTO_9 =settler(m,216);
XBA_9 = settler(m,217);
TSS_9 = settler(m,218);
T_9 =   settler(m,219);
SD1_9 = settler(m,220);
SD2_9 = settler(m,221);
SD3_9 = settler(m,222);
XD4_9 = settler(m,223);
XD5_9 = settler(m,224);

SO_10 =  settler(m,225);
SI_10 =  settler(m,226);
SS_10 =  settler(m,227);
SNH_10 = settler(m,228);
SN2_10 = settler(m,229);
SNO3_10 = settler(m,230);
SALK_10 = settler(m,231);
XI_10 =  settler(m,232);
XS_10 =  settler(m,233);
XBH_10 = settler(m,234);
XSTO_10 =settler(m,235);
XBA_10 = settler(m,236);
TSS_10 = settler(m,237);
T_10 =   settler(m,238);
SD1_10 = settler(m,239);
SD2_10 = settler(m,240);
SD3_10 = settler(m,241);
XD4_10 = settler(m,242);
XD5_10 = settler(m,243);

SETTLERINIT = [ SO_1 SO_2 SO_3 SO_4 SO_5 SO_6 SO_7 SO_8 SO_9 SO_10   SI_1 SI_2 SI_3 SI_4 SI_5 SI_6 SI_7 SI_8 SI_9 SI_10   SS_1 SS_2 SS_3 SS_4 SS_5 SS_6 SS_7 SS_8 SS_9 SS_10    SNH_1 SNH_2 SNH_3 SNH_4 SNH_5 SNH_6 SNH_7 SNH_8 SNH_9 SNH_10   SN2_1 SN2_2 SN2_3 SN2_4 SN2_5 SN2_6 SN2_7 SN2_8 SN2_9 SN2_10  SNO3_1 SNO3_2 SNO3_3 SNO3_4 SNO3_5 SNO3_6 SNO3_7 SNO3_8 SNO3_9 SNO3_10     SALK_1 SALK_2 SALK_3 SALK_4 SALK_5 SALK_6 SALK_7 SALK_8 SALK_9 SALK_10   XI_1 XI_2 XI_3 XI_4 XI_5 XI_6 XI_7 XI_8 XI_9 XI_10    XS_1 XS_2 XS_3 XS_4 XS_5 XS_6 XS_7 XS_8 XS_9 XS_10    XBH_1 XBH_2 XBH_3 XBH_4 XBH_5 XBH_6 XBH_7 XBH_8 XBH_9 XBH_10   XSTO_1 XSTO_2 XSTO_3 XSTO_4 XSTO_5 XSTO_6 XSTO_7 XSTO_8 XSTO_9 XSTO_10     XBA_1 XBA_2 XBA_3 XBA_4 XBA_5 XBA_6 XBA_7 XBA_8 XBA_9 XBA_10        TSS_1 TSS_2 TSS_3 TSS_4 TSS_5 TSS_6 TSS_7 TSS_8 TSS_9 TSS_10    T_1 T_2 T_3 T_4 T_5 T_6 T_7 T_8 T_9 T_10        SD1_1 SD1_2 SD1_3 SD1_4 SD1_5 SD1_6 SD1_7 SD1_8 SD1_9 SD1_10 SD2_1 SD2_2 SD2_3 SD2_4 SD2_5 SD2_6 SD2_7 SD2_8 SD2_9 SD2_10 SD3_1 SD3_2 SD3_3 SD3_4 SD3_5 SD3_6 SD3_7 SD3_8 SD3_9 SD3_10   XD4_1 XD4_2 XD4_3 XD4_4 XD4_5 XD4_6 XD4_7 XD4_8 XD4_9 XD4_10       XD5_1 XD5_1 XD5_2 XD5_3 XD5_4 XD5_5 XD5_6 XD5_7 XD5_8 XD5_9 XD5_10 ];


