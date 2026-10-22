%% verify_and_weather.m
% One script for the last two steps at one temperature: (1) re-simulate the three chosen points with the REAL model in dry
% weather and compare with the surface predictions, (2) run the same points in rain and storm.
% Replaces verify_points.m, verify_points_T30.m and weather_test_points.m for the 1225 m2 clarifier.
% 9 runs (3 points x dry, rain, storm), roughly 35 minutes. Same plant-scale set-up as design_runs.m.
% Needs run_plant_point.m with the rp_Qret and rp_over patches. Paste the whole printed output back.
clear all; close all;
rp_quiet = true;
set(0,'DefaultFigureVisible','off');
% remember the folder that holds run_plant_point.m: in the first 30 C run the first simulation worked and the later ones lost it
vw_dir = fileparts(which('run_plant_point'));
if isempty(vw_dir), error('run_plant_point.m not found: set the current folder to the folder that holds it and run again.'); end

vw_T    = 30;                         % 24 or 30 (the 24 C points were verified earlier; 30 C points filled in from design_fit_optimize_v2 at 30 C)
vw_A    = 1225;                        % clarifier area (m2), same as design_runs.m
vw_scen = {'dry','rain','storm'};

if vw_T == 24
    % points chosen from design_fit_optimize.m output at 24 C, clarifier 1225 m2
    %         KLa     Qintr    Qw
    vw_X = [ 154.5    42775   224;     % V1  least violation (lowest ammonia the surfaces reach; solids over the limit)
             150.8    64486   315;     % V2  lowest ammonia with TSS95 <= 30 and TN95 <= 18
             143.1    22425   460];    % V3  solids-safe end of the trade-off (long waste flow, ammonia high)
    % what the surfaces predict:  SNH95  SNHavg  TN95  TSS95   OCI
    vw_P = [ 5.43   2.17   18.9   40.8   20433;
             7.10   3.67   18.0   30.0   21898;
            12.38   9.37   24.4   25.3   23032];
elseif vw_T == 30
    % points chosen from design_fit_optimize_v2.m output at 30 C, clarifier 1225 m2 (all PREDICTIONS from the surfaces)
    % solids surface refitted with form 3 (leave-one-out R2 0.86); none of these exact points was simulated before
    %         KLa     Qintr    Qw
    vw_X = [ 151.4    38708   315;     % V1  least violation (worst metric 2% over its limit)
             150.1    44575   384;     % V2  lowest ammonia with TSS95 <= 30 and TN95 <= 18
             122.1    55208   425];    % V3  cheapest point meeting the practical target (average ammonia <= 4, TN95 <= 18, TSS95 <= 30)
    % what the surfaces predict:  SNH95  SNHavg  TN95  TSS95   OCI
    vw_P = [ 4.09   1.07   18.4   30.7   20374;
             4.48   1.30   18.0   30.0   20958;
             7.40   4.00   18.0   30.0   19240];
else
    error('No points defined for T = %d C. Add them after running design_fit_optimize.m with that dr_T.',vw_T);
end

vw_Qin = 38485;  vw_Qr = 21186;
vw_vs  = 26250/(2*3940+3*5253);
vw_mu20 = 0.68*exp(-log(1/0.35)/10*8);
vw_p    = vw_mu20^(10/(vw_T-10));

vw_out = nan(size(vw_X,1),numel(vw_scen),5);   % SNH95 SNHavg TN95 TSS95 OCI
fprintf('\nT=%d C, clarifier %d m2   (limits: SNH95 4, TN95 18, TSS95 30)\n',vw_T,vw_A);
fprintf(' pt | weather |  KLa  | Qintr |  Qw | SNH95 | SNHavg |  TN95 | TSS95 |  OCI\n');
for vw_k = 1:size(vw_X,1)
    for vw_s = 1:numel(vw_scen)
        rp_KLa = vw_X(vw_k,1); rp_Qintr = vw_X(vw_k,2); rp_T = vw_T;
        rp_scen = vw_scen{vw_s}; rp_infl = 'surat'; rp_protocol = 'bsm1';
        rp_flowscale = vw_Qin/18446; rp_Qret = vw_Qr;
        rp_over = struct('mu_A',vw_p,'Qw',vw_X(vw_k,3), ...
            'VOL1',3940*vw_vs,'VOL2',3940*vw_vs,'VOL3',5253*vw_vs,'VOL4',5253*vw_vs,'VOL5',5253*vw_vs, ...
            'DIM',[vw_A 4]);
        try
            cd(vw_dir); addpath(vw_dir);        % put the folder back in case something changed it after the first run
            run_plant_point;
        catch vw_err
            fprintf('V%d | %-7s | run failed: %s\n',vw_k,vw_scen{vw_s},vw_err.message);
            fprintf('      pwd = %s | which run_plant_point = %s\n',pwd,which('run_plant_point'));   % paste this line back if it fails again
            continue;
        end
        vw_out(vw_k,vw_s,:) = [rp_R.SNH95 rp_R.SNHavg rp_R.TN95 rp_R.TSS95 rp_R.OCI];
        fprintf('V%d | %-7s | %5.1f | %5.0f | %3.0f | %5.2f | %6.2f | %5.1f | %5.1f | %5.0f\n', ...
            vw_k,vw_scen{vw_s},vw_X(vw_k,:),vw_out(vw_k,vw_s,1),vw_out(vw_k,vw_s,2),vw_out(vw_k,vw_s,3),vw_out(vw_k,vw_s,4),vw_out(vw_k,vw_s,5));
    end
end

fprintf('\nDry weather, predicted / simulated:\n');
fprintf(' pt |      SNH95      |     SNHavg      |      TN95       |      TSS95      |       OCI\n');
for vw_k = 1:size(vw_X,1)
    fprintf('V%d  | %5.2f / %5.2f | %5.2f / %5.2f | %5.1f / %5.1f | %5.1f / %5.1f | %6.0f / %6.0f\n',vw_k, ...
        vw_P(vw_k,1),vw_out(vw_k,1,1), vw_P(vw_k,2),vw_out(vw_k,1,2), vw_P(vw_k,3),vw_out(vw_k,1,3), ...
        vw_P(vw_k,4),vw_out(vw_k,1,4), vw_P(vw_k,5),vw_out(vw_k,1,5));
end
save(sprintf('verify_weather_T%d_A%d.mat',vw_T,vw_A),'vw_out','vw_X','vw_P','vw_scen','vw_T','vw_A');
fprintf('\nSaved verify_weather_T%d_A%d.mat\n',vw_T,vw_A);
