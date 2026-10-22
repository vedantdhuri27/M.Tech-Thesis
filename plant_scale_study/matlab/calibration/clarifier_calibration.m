%% clarifier_calibration.m
% Picks the clarifier (settler) area by comparing the model with what Lopez-Vazquez et al. (2013) measured at Anjana.
% The paper gives no clarifier area (only volumes), so the area is calibrated, not assumed.
%
% Set-up = the plant check you already ran (check_sludge_age_plant.m): influent 38,485 m3/d, tanks 26,250 m3 in BSM1
% proportions, return flow 21,186, all five tanks aerated (KLa 70), constant influent, 28 C, calibrated mu_A (0.68 at 28 C),
% waste flow = the plant value 1090 m3/d. ONLY the clarifier area changes between rows (depth stays 4 m).
%
% Measured at Anjana (paper Tables 1 and 5):
%   aeration-tank solids (MLSS) 1,430 mg/L | waste-sludge solids 4,066 mg/L | effluent solids 29 mg/L
%   effluent ammonia 14.7 mg N/L           | sludge age 7-8 days (paper, SRT_AER = 7 d)
%
% READ THE TABLE LIKE THIS: take the area whose MLSS, waste-sludge solids and effluent solids sit closest to the targets.
% Effluent ammonia will move a little with the area (more solids kept = more nitrifiers), so if the chosen area gives
% ammonia far from 14.7, adjust mu_A (as in plant_check_mu_A.m) and re-check; the areas are cheap to rerun.
% About 3 minutes per row, 6 rows (roughly 20 minutes). Needs run_plant_point.m with the rp_Qret and rp_over patches.
% Paste the whole printed table back. Results are also saved to clarifier_calibration.mat.
clear all; close all;
rp_quiet = true;
set(0,'DefaultFigureVisible','off');

cc_area = [600 825 1225 1500 2300 3135];      % m2: 825 and 1225 = paper volumes at 4 m depth (3,300 and 3,300+1,600 m3); 1500 = benchmark; 3135 = flow-scaled benchmark
cc_H    = 4;                                  % depth in m (as in the benchmark settler)
cc_Qin  = 38485;  cc_Qr = 21186;  cc_Qw = 1090;
cc_KLa  = 70;  cc_T = 28;
cc_vs   = 26250/(2*3940+3*5253);
cc_mu28 = 0.68;
cc_p    = (cc_mu28*exp(-log(1/0.35)/10*8))^(10/(cc_T-10));   % input value that makes asm3.c return mu_A = 0.68 at 28 C
cc_n    = 672;                                % last 7 days of 15-minute samples, as in check_sludge_age_plant.m

cc_out = nan(numel(cc_area),8);               % area, SOR, NH4, DO, MLSS, underflow TSS, effluent TSS, sludge age
fprintf('\nTargets (Anjana, measured): MLSS 1430 | waste-sludge solids 4066 | effluent TSS 29 | NH4 14.7 | sludge age 7-8 d\n');
fprintf('Plant as operated: influent %d, return %d, waste %d m3/d, KLa %d, %d C, mu_A input %.4f\n\n',cc_Qin,cc_Qr,cc_Qw,cc_KLa,cc_T,cc_p);
fprintf(' area m2 | SOR m/d |  NH4  |  DO  | MLSS | underflow TSS | effluent TSS | sludge age\n');
for cc_k = 1:numel(cc_area)
    rp_KLa = cc_KLa; rp_Qintr = 1; rp_T = cc_T; rp_scen = 'const'; rp_infl = 'surat'; rp_protocol = 'sweep';
    rp_flowscale = cc_Qin/18446; rp_Qret = cc_Qr;
    rp_over = struct('mu_A',cc_p,'Qw',cc_Qw, ...
        'VOL1',3940*cc_vs,'VOL2',3940*cc_vs,'VOL3',5253*cc_vs,'VOL4',5253*cc_vs,'VOL5',5253*cc_vs, ...
        'KLa1',rp_KLa,'KLa2',rp_KLa, 'DIM',[cc_area(cc_k) cc_H]);
    try
        run_plant_point;
    catch cc_err
        fprintf('%8.0f | run failed: %s\n',cc_area(cc_k),cc_err.message);
        continue;
    end
    % same bookkeeping as check_sludge_age_plant.m
    cc_X5  = mean(reac5(end-cc_n+1:end,13));                   % solids in the last tank (g/m3)
    cc_Qf  = mean(reac5(end-cc_n+1:end,14)) - Qintr;           % flow into the clarifier
    cc_Qi  = mean(CONSTINFLUENT(CONSTINFLUENT(:,1)>=7,15));    % influent flow
    cc_Qrr = cc_Qf - cc_Qi;                                    % return flow the model uses
    cc_Qe  = cc_Qi - Qw;                                       % effluent flow
    cc_Xu  = (cc_Qf*cc_X5 - cc_Qe*TSSeav)/(cc_Qrr + Qw);       % solids in the underflow / waste sludge (mass balance)
    cc_V   = VOL1+VOL2+VOL3+VOL4+VOL5;
    cc_SRT = cc_V*cc_X5/(Qw*cc_Xu + cc_Qe*TSSeav);
    cc_out(cc_k,:) = [cc_area(cc_k) cc_Qin/cc_area(cc_k) rp_R.SNHavg rp_R.DO cc_X5 cc_Xu TSSeav cc_SRT];
    fprintf('%8.0f | %7.1f | %5.2f | %4.2f | %4.0f | %13.0f | %12.1f | %7.1f d\n',cc_out(cc_k,:));
end
save('clarifier_calibration.mat','cc_out','cc_area','cc_H');
fprintf('\nSaved clarifier_calibration.mat\n');
