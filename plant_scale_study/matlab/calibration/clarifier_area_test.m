%% clarifier_area_test.m
% Sensitivity of the verified 24 C point V1 (KLa 154.5, Qintr 42,775, Qw 224) to the clarifier area:
%   1838 m2 = calibrated area +50%      2566 m2 = calibrated area +110%
% The real secondary clarifier area of the 2004 plant is NOT documented (the 33 m diameter in the Anjana project report is
% the PRIMARY clarifier), so this asks the other way round: how much settling area does V1 need to keep TSS95 under 30
% in dry, rain and storm weather? Prints results next to the 1225 m2 results from verify_and_weather.m.
% 6 runs (2 areas x dry, rain, storm), about 20 minutes. Same set-up as verify_and_weather.m.
% Replaces standby_clarifier_test.m.
clear all; close all;
rp_quiet = true;
set(0,'DefaultFigureVisible','off');

ca_T    = 24;
ca_area = [1838 2566];
ca_scen = {'dry','rain','storm'};
ca_X    = [154.5 42775 224];                       % V1: KLa, Qintr, Qw
% V1 at 1225 m2 (verify_and_weather.m): columns dry, rain, storm
ca_snh1225 = [6.85 8.03 7.49];
ca_tss1225 = [34.2 113.3 94.9];

ca_Qin = 38485;  ca_Qr = 21186;
ca_vs  = 26250/(2*3940+3*5253);
ca_mu20 = 0.68*exp(-log(1/0.35)/10*8);
ca_p    = ca_mu20^(10/(ca_T-10));

ca_out = nan(numel(ca_area),numel(ca_scen),5);   % SNH95 SNHavg TN95 TSS95 OCI
fprintf('\nT=%d C, V1 (KLa %.1f, Qintr %.0f, Qw %.0f) (limits: SNH95 4, TN95 18, TSS95 30)\n',ca_T,ca_X);
fprintf(' area m2 | weather | SNH95 | SNHavg |  TN95 | TSS95 | SNH95 at 1225 | TSS95 at 1225 |  OCI\n');
for ca_k = 1:numel(ca_area)
    for ca_s = 1:numel(ca_scen)
        rp_KLa = ca_X(1); rp_Qintr = ca_X(2); rp_T = ca_T;
        rp_scen = ca_scen{ca_s}; rp_infl = 'surat'; rp_protocol = 'bsm1';
        rp_flowscale = ca_Qin/18446; rp_Qret = ca_Qr;
        rp_over = struct('mu_A',ca_p,'Qw',ca_X(3), ...
            'VOL1',3940*ca_vs,'VOL2',3940*ca_vs,'VOL3',5253*ca_vs,'VOL4',5253*ca_vs,'VOL5',5253*ca_vs, ...
            'DIM',[ca_area(ca_k) 4]);
        try
            run_plant_point;
        catch ca_err
            fprintf('%8.0f | %-7s | run failed: %s\n',ca_area(ca_k),ca_scen{ca_s},ca_err.message);
            continue;
        end
        ca_out(ca_k,ca_s,:) = [rp_R.SNH95 rp_R.SNHavg rp_R.TN95 rp_R.TSS95 rp_R.OCI];
        fprintf('%8.0f | %-7s | %5.2f | %6.2f | %5.1f | %5.1f | %13.2f | %13.1f | %5.0f\n', ...
            ca_area(ca_k),ca_scen{ca_s},ca_out(ca_k,ca_s,1),ca_out(ca_k,ca_s,2),ca_out(ca_k,ca_s,3),ca_out(ca_k,ca_s,4), ...
            ca_snh1225(ca_s),ca_tss1225(ca_s),ca_out(ca_k,ca_s,5));
    end
end
save('clarifier_area_test_T24.mat','ca_out','ca_area','ca_X','ca_scen');
fprintf('\nSaved clarifier_area_test_T24.mat\n');
