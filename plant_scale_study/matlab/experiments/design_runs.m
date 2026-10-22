%% design_runs.m
% Latin-hypercube design over KLa, Qintr and Qw for the Anjana plant-scale model at ONE temperature.
% It runs the design at 24 C and then at 30 C (dr_Ts) for ONE clarifier area (dr_AREA), so one start does both temperatures.
% Results are saved after every run, so you can stop it and start it again: finished runs are skipped.
% This file replaces design_runs_30C.m (an identical copy with dr_T = 30), which you can delete.
% As supplied it is set for the larger-clarifier comparison (STEP 5): dr_AREA = 2566, dr_pilot = false, both temperatures.
%
% Set-up (same as the checks that matched Anjana):
%   influent 38,485 m3/d (Surat v3), tanks scaled to 26,250 m3 in BSM1 proportions, return flow 21,186 m3/d,
%   BSM1 layout (tanks 1-2 anoxic, tanks 3-5 aerobic), calibrated nitrifier growth (0.68 per day at 28 C,
%   standard temperature slope), dry weather, 100-day steady state then 14 days evaluated.
%   CLARIFIER: area dr_AREA (default 1225 m2, chosen with clarifier_calibration.m). The earlier runs used the unscaled
%   benchmark clarifier (1500 m2, settler_check.m). Results are saved under a name that
%   carries the area, so the old design_runs_T24/T30.mat files are neither overwritten nor resumed.
%
% Pilot (only if you change the set-up): dr_pilot = true does 3 test points per temperature (about 10 minutes). Check that
%         DO is not stuck near zero, ammonia is not 25+ everywhere, and no run errors out.
% Full design: dr_pilot = false. 30 runs per temperature (compare_area.m expects 25 to 35 minutes each at 2,566 m2; allow up to 2 hours).
% Output files: design_runs_T24_A2566.mat and design_runs_T30_A2566.mat (the area is part of the name).
% Needs run_plant_point.m with the rp_Qret return-flow patch and the rp_over block.
clear all; close all;
rp_quiet = true;
set(0,'DefaultFigureVisible','off');   % no figure windows while it runs (saves time)

%% ---- settings you may change -------------------------------------------------------------
dr_Ts    = [24 30];            % plant temperatures (C): done one after the other
dr_N     = 30;                 % number of design points
dr_pilot = false;              % false: the full 30-run design; true: test runs only (3 design points + the plant-as-operated point)
dr_AREA  = 2566;               % clarifier area in m2 for the larger-clarifier comparison. The calibrated area is 1225 (clarifier_calibration.m: (3,300 + 1,600 m3, paper Table 3) / 4 m depth); set 1225 to repeat the base case.
% decision variables:          KLa (1/d, tanks 3-5)   Qintr (m3/d)   Qw (m3/d)
% Bounds were revised after the first pilot at 24 C: DO was 3-5 mg/L (more air than needed) and
% ammonia was 12-38 mg N/L at Qw 480-1120 (sludge too young with two tanks unaerated), so aeration is
% lowered and Qw is pushed to much lower values (longer sludge age).
% Qw lower bound is now 100 for both temperatures: the old bound of 195 came from the undersized clarifier
% (effluent solids), and every optimum sat on that bound.
for dr_T = dr_Ts
fprintf('\n######## Temperature %d C, clarifier %.0f m2 ########\n',dr_T,dr_AREA);
if dr_T <= 26
    dr_lo = [ 50   20000   100];
    dr_hi = [180  110000   600];
else
    dr_lo = [ 50   20000   100];
    dr_hi = [180  110000  1100];   % 30 C: Qw range includes the plant value 1090
end
dr_file = sprintf('design_runs_T%d_A%d.mat', dr_T, round(dr_AREA));

%% ---- fixed plant-scale set-up -------------------------------------------------------------
dr_Qin = 38485;  dr_Qr = 21186;
dr_vs  = 26250/(2*3940+3*5253);                         % scale the five tank volumes to 26,250 m3
dr_mu28 = 0.68;                                         % calibrated effective mu_A at 28 C
dr_mu20 = dr_mu28*exp(-log(1/0.35)/10*8);               % same rate at 20 C with the standard slope (0.29)
dr_p    = dr_mu20^(10/(dr_T-10));                       % input value that makes asm3.c return the right rate

%% ---- the design ----------------------------------------------------------------------------
rng(42);
if dr_pilot
    dr_X = [0.5 0.5 0.5; 0.9 0.5 0.1; 0.9 0.5 0.9];     % middle, high aeration/low Qw, high aeration/high Qw
else
    dr_U = lhsdesign(dr_N,3,'criterion','maximin','iterations',100);
    dr_X = dr_U;
end
dr_D = dr_lo + dr_X.*(dr_hi-dr_lo);
dr_D(:,1) = round(dr_D(:,1),1); dr_D(:,2) = round(dr_D(:,2),-2); dr_D(:,3) = round(dr_D(:,3));
if dr_pilot
    % pilot row 4 = plant as operated (KLa 167, Qintr 65,000, Qw 1090). With the benchmark-size clarifier it gave
    % SNH95 37.9 at 24 C and 17.8 at 30 C, so this row shows whether "nitrification fails at the plant's Qw" survives.
    dr_D(end+1,:) = [167 65000 1090];
end

%% ---- resume if a results file exists -------------------------------------------------------
dr_res = nan(size(dr_D,1),14);   % T KLa Qintr Qw SNH95 SNHavg DO XBA OCI EQI TN95 TNavg TSS95 TSSeav
dr_R = cell(size(dr_D,1),1);
if ~dr_pilot && exist(dr_file,'file')
    dr_old = load(dr_file);
    if isequal(size(dr_old.dr_D),size(dr_D)) && all(abs(dr_old.dr_D(:)-dr_D(:))<1e-9)
        dr_res = dr_old.dr_res; dr_R = dr_old.dr_R;
        fprintf('Resuming: %d of %d runs already done.\n',sum(~isnan(dr_res(:,5))),size(dr_D,1));
    end
end

%% ---- run -----------------------------------------------------------------------------------
fprintf('\nT=%d C, mu_A input %.4f, clarifier %.0f m2\n',dr_T,dr_p,dr_AREA);
fprintf(' #  |  KLa  | Qintr  |  Qw  | SNH95 | SNHavg |  DO  |  TN95 | TSS95 |  OCI  |  EQI\n');
for dr_k = 1:size(dr_D,1)
    if ~isnan(dr_res(dr_k,5)), continue; end
    rp_KLa = dr_D(dr_k,1); rp_Qintr = dr_D(dr_k,2); rp_T = dr_T;
    rp_scen = 'dry'; rp_infl = 'surat'; rp_protocol = 'bsm1';
    rp_flowscale = dr_Qin/18446; rp_Qret = dr_Qr;
    rp_over = struct('mu_A',dr_p,'Qw',dr_D(dr_k,3), ...
        'VOL1',3940*dr_vs,'VOL2',3940*dr_vs,'VOL3',5253*dr_vs,'VOL4',5253*dr_vs,'VOL5',5253*dr_vs, ...
        'DIM',[dr_AREA 4]);
    try
        run_plant_point;
    catch dr_err
        fprintf('%2d  | run failed: %s\n',dr_k,dr_err.message);
        continue;
    end
    if dr_k == 1 && dr_pilot, disp('Fields in rp_R:'); disp(fieldnames(rp_R)'); end
    dr_names = {'SNH95','SNHavg','DO','XBA','OCI','EQI','TN95','TNavg','TSS95'};
    dr_vals = nan(1,numel(dr_names));
    for dr_j = 1:numel(dr_names)
        if isfield(rp_R,dr_names{dr_j}), dr_vals(dr_j) = rp_R.(dr_names{dr_j}); end
    end
    if exist('TSSeav','var'), dr_tss = TSSeav; else, dr_tss = NaN; end
    dr_res(dr_k,:) = [dr_T dr_D(dr_k,:) dr_vals(1:9) dr_tss];
    dr_R{dr_k} = rp_R;
    fprintf('%2d  | %5.1f | %6.0f | %4.0f | %5.2f | %6.2f | %4.2f | %5.1f | %5.1f | %5.0f | %5.0f\n', ...
        dr_k,dr_D(dr_k,1),dr_D(dr_k,2),dr_D(dr_k,3),dr_vals(1),dr_vals(2),dr_vals(3),dr_vals(7),dr_vals(9),dr_vals(5),dr_vals(6));
    if ~dr_pilot, save(dr_file,'dr_res','dr_R','dr_D','dr_T'); end
end
if ~dr_pilot, fprintf('\nSaved %s\n',dr_file); end
end   % temperature loop
