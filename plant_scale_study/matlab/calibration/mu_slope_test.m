%% mu_slope_test.m
% How much does the 24 C conclusion depend on the assumed nitrifier temperature slope?
% The model gives an effective nitrifier growth rate mu_A of about 0.45 per day at 24 C (standard slope 0.105 per C,
% calibrated to 0.68 at 28 C). A gentler slope would leave mu_A higher at 24 C. This script sets the effective mu_A at
% 24 C directly and re-runs the plant as operated and V1-V3 in dry weather:
%     0.36  the 0.68 was really measured at 30 C, not 28 C (standard slope, so lower at 24 C)
%     0.45  standard slope (what every 24 C result so far used)
%     0.50  and 0.55  gentler slopes
%     0.68  no temperature penalty at all (same as at 28 C)
% Decay b_A is left at its standard 24 C value, so only the growth rate changes.
% 20 runs (4 points x 5 growth rates), about 1 hour 15 minutes. Same plant-scale set-up as verify_and_weather.m.
% Needs run_plant_point.m with the rp_Qret and rp_over patches. Paste the whole printed output back.
clear all; close all;
rp_quiet = true;
set(0,'DefaultFigureVisible','off');

ms_T    = 24;
ms_A    = 1225;                                % clarifier area (m2), calibrated
ms_mu   = [0.36 0.45 0.50 0.55 0.68];          % effective mu_A at 24 C (per day)
ms_lab  = {'plant as operated','V1','V2','V3'};
%         KLa     Qintr    Qw
ms_X = [ 167.0    65000   1090;                % plant as operated (the pilot point of design_runs.m)
         154.5    42775    224;                % V1
         150.8    64486    315;                % V2
         143.1    22425    460];               % V3

ms_Qin = 38485;  ms_Qr = 21186;
ms_vs  = 26250/(2*3940+3*5253);
ms_s   = log(1/0.35)/10;                       % standard growth slope per C (0.105), same as the other scripts
ms_bA  = 0.15*exp(log(3)/10*(ms_T-20));        % decay b_A at 24 C

fprintf('\nT=%d C, clarifier %d m2, dry weather   (limits: SNH95 4, TN95 18, TSS95 30)\n',ms_T,ms_A);
fprintf('Effective mu_A at %d C against the nitrifier decay %.3f per day:\n',ms_T,ms_bA);
for ms_j = 1:numel(ms_mu)
    fprintf('  mu_A %.2f -> net growth %.3f per day (aerobic sludge age needed about %.1f d, before ammonia and oxygen limits)\n', ...
        ms_mu(ms_j),ms_mu(ms_j)-ms_bA,1/(ms_mu(ms_j)-ms_bA));
end
fprintf('\n point                | mu_A |  KLa  | Qintr |  Qw | SNH95 | SNHavg |  TN95 | TSS95 |   DO |  OCI\n');

ms_out = nan(size(ms_X,1),numel(ms_mu),6);     % SNH95 SNHavg TN95 TSS95 DO OCI
for ms_k = 1:size(ms_X,1)
    for ms_j = 1:numel(ms_mu)
        ms_mu20 = ms_mu(ms_j)*exp(-ms_s*(ms_T-20));        % same rate at 20 C with the standard slope
        ms_p    = ms_mu20^(10/(ms_T-10));                  % input value that makes asm3.c return the wanted rate
        rp_KLa = ms_X(ms_k,1); rp_Qintr = ms_X(ms_k,2); rp_T = ms_T;
        rp_scen = 'dry'; rp_infl = 'surat'; rp_protocol = 'bsm1';
        rp_flowscale = ms_Qin/18446; rp_Qret = ms_Qr;
        rp_over = struct('mu_A',ms_p,'Qw',ms_X(ms_k,3), ...
            'VOL1',3940*ms_vs,'VOL2',3940*ms_vs,'VOL3',5253*ms_vs,'VOL4',5253*ms_vs,'VOL5',5253*ms_vs, ...
            'DIM',[ms_A 4]);
        try
            run_plant_point;
        catch ms_err
            fprintf(' %-20s | %4.2f | run failed: %s\n',ms_lab{ms_k},ms_mu(ms_j),ms_err.message);
            continue;
        end
        ms_out(ms_k,ms_j,:) = [rp_R.SNH95 rp_R.SNHavg rp_R.TN95 rp_R.TSS95 rp_R.DO rp_R.OCI];
        fprintf(' %-20s | %4.2f | %5.1f | %5.0f | %3.0f | %5.2f | %6.2f | %5.1f | %5.1f | %4.2f | %5.0f\n', ...
            ms_lab{ms_k},ms_mu(ms_j),ms_X(ms_k,:),ms_out(ms_k,ms_j,1),ms_out(ms_k,ms_j,2),ms_out(ms_k,ms_j,3), ...
            ms_out(ms_k,ms_j,4),ms_out(ms_k,ms_j,5),ms_out(ms_k,ms_j,6));
        save(sprintf('mu_slope_test_T%d_A%d.mat',ms_T,ms_A),'ms_out','ms_X','ms_mu','ms_lab','ms_T','ms_A');
    end
end

fprintf('\nSNH95 (mg N/L, limit 4) by effective mu_A at %d C:\n',ms_T);
fprintf(' point                |'); fprintf('   %.2f |',ms_mu); fprintf('\n');
for ms_k = 1:size(ms_X,1)
    fprintf(' %-20s |',ms_lab{ms_k}); fprintf(' %6.2f |',ms_out(ms_k,:,1)); fprintf('\n');
end
fprintf('\nSNHavg (mg N/L) by effective mu_A at %d C:\n',ms_T);
fprintf(' point                |'); fprintf('   %.2f |',ms_mu); fprintf('\n');
for ms_k = 1:size(ms_X,1)
    fprintf(' %-20s |',ms_lab{ms_k}); fprintf(' %6.2f |',ms_out(ms_k,:,2)); fprintf('\n');
end
fprintf('\nSaved mu_slope_test_T%d_A%d.mat\n',ms_T,ms_A);
