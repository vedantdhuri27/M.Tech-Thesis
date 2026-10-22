%% check_sludge_age_plant.m
% Anjana at plant scale (influent 38,485 m3/d, tanks 26,250 m3 in BSM1 proportions, return flow 21,186,
% all tanks aerated as in the plant check, 28 C, KLa 70), calibrated nitrifier growth.
% Prints ammonia, oxygen, tank solids and sludge age for several waste-sludge flows, so the sludge age can be
% compared with the plant's 7-8 days. Needs run_plant_point.m with the rp_Qret return-flow patch. About 12 minutes.
clear all; close all;
rp_quiet = true;

cs_mu28 = 0.68;                                   % calibrated effective mu_A at 28 C (plant check with return flow 21,186, KLa 70)
cs_p    = (cs_mu28*exp(-log(1/0.35)/10*8))^(10/18);   % input value for asm3.c at 28 C (about 0.51)
cs_Qin  = 38485;  cs_Qr = 21186;
cs_vs   = 26250/(2*3940+3*5253);                  % scale the five tank volumes to the plant volume
cs_Qw   = [600 800 1090 1500];
cs_n    = 672;
fprintf('\nQw | NH4 | DO | MLSS | return flow | underflow TSS | sludge age\n');
for cs_k = 1:numel(cs_Qw)
    rp_KLa = 70; rp_Qintr = 1; rp_T = 28; rp_scen = 'const'; rp_infl = 'surat'; rp_protocol = 'sweep';
    rp_flowscale = cs_Qin/18446; rp_Qret = cs_Qr;
    rp_over = struct('mu_A',cs_p,'Qw',cs_Qw(cs_k), ...
        'VOL1',3940*cs_vs,'VOL2',3940*cs_vs,'VOL3',5253*cs_vs,'VOL4',5253*cs_vs,'VOL5',5253*cs_vs, ...
        'KLa1',rp_KLa,'KLa2',rp_KLa);
    run_plant_point;

    cs_X5  = mean(reac5(end-cs_n+1:end,13));                    % solids in the last tank (g/m3)
    cs_Qf  = mean(reac5(end-cs_n+1:end,14)) - Qintr;            % flow to the clarifier
    cs_Qi  = mean(CONSTINFLUENT(CONSTINFLUENT(:,1)>=7,15));     % influent flow
    cs_Qrr = cs_Qf - cs_Qi;                                     % return flow the model uses
    cs_Qe  = cs_Qi - Qw;
    cs_Xu  = (cs_Qf*cs_X5 - cs_Qe*TSSeav)/(cs_Qrr + Qw);
    cs_V   = VOL1+VOL2+VOL3+VOL4+VOL5;
    cs_SRT = cs_V*cs_X5/(Qw*cs_Xu + cs_Qe*TSSeav);
    fprintf('%4d | %5.2f | %4.2f | %5.0f | %6.0f | %6.0f | %5.1f d\n', ...
        Qw, rp_R.SNHavg, rp_R.DO, cs_X5, cs_Qrr, cs_Xu, cs_SRT);
end
