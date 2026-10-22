%% plant_check_mu_A.m
% Option C: recalibrate the nitrifier growth rate (mu_A) against the Anjana plant data
% (Lopez-Vazquez et al. 2013, Tables 1 and 3). Needs run_plant_point.m with the flow-scale patch.
%
% Plant: influent 38,485 m3/d, return sludge 21,186, waste sludge 1,090 m3/d, aeration tank 26,250 m3,
%        about 28 C, effluent ammonia 14.7 mg N/L, nitrate 1.8 mg N/L, tank DO 0.5-1.0 mg/L.
% Model: five tanks scaled to 26,250 m3, all aerated, no internal recycle, constant Surat influent
%        scaled to the plant flow, standard ASM3 temperature slopes.
clear all; close all;
rp_quiet = true;

% ---- plant data ----
pc_T = 28;  pc_Qin = 38485;  pc_Qr = 21186;  pc_Qw = 1090;  pc_Vtot = 26250;
pc_NH4meas = 14.7;  pc_NO3meas = 1.8;  pc_DOtarget = 1.0;

% ---- setup shared by all runs ----
pc_vs = pc_Vtot/(2*3940+3*5253);                 % scale the five tank volumes to 26,250 m3
pc_a  = (pc_T-20)/10;
pc_mu_par = @(target) (target*0.35^pc_a)^(1/(1+pc_a));   % asm3.c parameter value that gives 'target' at pc_T
pc_over = @(KLa,mu_eff) struct('mu_A',pc_mu_par(mu_eff),'Qr',pc_Qr,'Qw',pc_Qw, ...
    'VOL1',3940*pc_vs,'VOL2',3940*pc_vs,'VOL3',5253*pc_vs,'VOL4',5253*pc_vs,'VOL5',5253*pc_vs, ...
    'KLa1',KLa,'KLa2',KLa);
rp_flowscale = pc_Qin/18446;
rp_T = pc_T; rp_scen = 'const'; rp_infl = 'surat'; rp_protocol = 'sweep'; rp_Qintr = 1;

% ---- Step 1: choose aeration so the tank DO is about 1 mg/L ----
fprintf('\n--- Step 1: aeration (mu_A effective 0.6 per day) ---\n');
pc_KLas = [20 40 60 80 120]; pc_DO = nan(size(pc_KLas));
for pc_i = 1:numel(pc_KLas)
    rp_KLa = pc_KLas(pc_i); rp_over = pc_over(rp_KLa,0.6);
    run_plant_point;
    pc_DO(pc_i) = rp_R.DO;
    fprintf('KLa=%4.0f | DO=%.2f  NH4=%.2f\n',rp_KLa,rp_R.DO,rp_R.SNHavg);
end
[~,pc_j] = min(abs(pc_DO-pc_DOtarget)); pc_KLa = pc_KLas(pc_j);
fprintf('Chosen KLa = %d (DO %.2f mg/L)\n',pc_KLa,pc_DO(pc_j));

% ---- Step 2: scan the effective mu_A at the plant temperature ----
fprintf('\n--- Step 2: mu_A scan at %d C (KLa %d) ---\n',pc_T,pc_KLa);
pc_mu = [0.35 0.45 0.55 0.65 0.80 1.00];
pc_res = nan(numel(pc_mu),6);
for pc_i = 1:numel(pc_mu)
    rp_KLa = pc_KLa; rp_over = pc_over(rp_KLa,pc_mu(pc_i));
    run_plant_point;
    pc_cod = SIeav+SSeav+XIeav+XSeav+XBHeav+XBAeav;
    if exist('XSTOeav','var'), pc_cod = pc_cod+XSTOeav; end
    if exist('TSSeav','var'), pc_tss = TSSeav; else, pc_tss = NaN; end
    pc_res(pc_i,:) = [pc_mu(pc_i) rp_R.SNHavg SNOeav rp_R.DO pc_cod pc_tss];
    fprintf('mu_A eff=%.2f | NH4=%.2f  NO3=%.2f  DO=%.2f  COD=%.1f  TSS=%.1f\n',pc_res(pc_i,:));
end

% ---- Result ----
[pc_s,pc_k] = sort(pc_res(:,2));
pc_mu_cal = interp1(pc_s,pc_res(pc_k,1),pc_NH4meas);
fprintf('\n=== Result ===\n');
if isnan(pc_mu_cal)
    fprintf('Measured ammonia %.1f is outside the scanned range: widen pc_mu and rerun.\n',pc_NH4meas);
else
    pc_mu20 = pc_mu_cal*exp(-log(1/0.35)/10*(pc_T-20));
    fprintf('Effective mu_A at %d C that reproduces NH4 = %.1f mg N/L: %.2f per day\n',pc_T,pc_NH4meas,pc_mu_cal);
    fprintf('Equivalent value at 20 C with the standard slope: %.2f per day\n',pc_mu20);
    fprintf('For comparison at %d C: option A (0.46 at 20 C) gives %.2f; the code as it stands gives %.2f\n', ...
        pc_T,0.46*exp(log(1/0.35)/10*(pc_T-20)),0.46*(0.46/0.35)^pc_a);
end
save plant_check_mu_A_results.mat pc_res pc_KLas pc_DO pc_KLa pc_mu_cal
