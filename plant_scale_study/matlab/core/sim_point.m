%% sim_point.m  --  helper SCRIPT: one plant simulation with the Anjana plant-scale set-up
% Not run on its own. The scripts infill_runs.m, robust_check.m and front_oci_eqi_tn.m call it.
% It is a script (not a function) on purpose: run_plant_point.m and the Simulink model read their variables from the base workspace.
% Set before calling:
%   sp_KLa, sp_Qintr, sp_Qw   operating point (1/d, m3/d, m3/d)
%   sp_T                      temperature (C)
%   sp_A                      clarifier area (m2)
%   sp_scen                   'dry' (default), 'rain' or 'storm'
%   sp_mu                     effective nitrifier growth rate at sp_T in 1/d; [] or not set = standard slope (0.447 at 24 C, 0.68 at 28 C)
%   sp_dir                    folder that holds run_plant_point.m (optional; the script changes back to it before every run)
% Result:
%   sp_ok   true if the run finished with a number for SNH95
%   sp_row  [T KLa Qintr Qw SNH95 SNHavg DO XBA OCI EQI TN95 TNavg TSS95 TSSeav]   (same columns as dr_res in design_runs.m)
%   sp_msg  error text if it failed
% Same set-up as design_runs.m: influent 38,485 m3/d (Surat v3), tanks 26,250 m3, return flow 21,186 m3/d,
% BSM1 layout, 100-day steady state then 14 days evaluated. Effective mu_A is set the same way as in mu_slope_test.m:
%   mu20 = mu*exp(-s*(T-20)),  input p = mu20^(10/(T-10)),  s = log(1/0.35)/10.
if ~exist('sp_scen','var') || isempty(sp_scen), sp_scen = 'dry'; end
if ~exist('sp_mu','var'), sp_mu = []; end
sp_s = log(1/0.35)/10;
if isempty(sp_mu), sp_mu = 0.68*exp(sp_s*(sp_T-28)); end
sp_mu20 = sp_mu*exp(-sp_s*(sp_T-20));
sp_p    = sp_mu20^(10/(sp_T-10));
sp_vs   = 26250/(2*3940+3*5253);
rp_KLa = sp_KLa;  rp_Qintr = sp_Qintr;  rp_T = sp_T;
rp_scen = sp_scen;  rp_infl = 'surat';  rp_protocol = 'bsm1';
rp_flowscale = 38485/18446;  rp_Qret = 21186;
rp_over = struct('mu_A',sp_p,'Qw',sp_Qw, ...
    'VOL1',3940*sp_vs,'VOL2',3940*sp_vs,'VOL3',5253*sp_vs,'VOL4',5253*sp_vs,'VOL5',5253*sp_vs, ...
    'DIM',[sp_A 4]);
sp_ok = false;  sp_row = nan(1,14);  sp_msg = '';
try
    if exist('sp_dir','var') && ~isempty(sp_dir)
        cd(sp_dir);  addpath(sp_dir);                  % put the folder back in case something changed it after an earlier run
    end
    run_plant_point;
    sp_names = {'SNH95','SNHavg','DO','XBA','OCI','EQI','TN95','TNavg','TSS95'};
    sp_vals = nan(1,numel(sp_names));
    for sp_j = 1:numel(sp_names)
        if isfield(rp_R,sp_names{sp_j}), sp_vals(sp_j) = rp_R.(sp_names{sp_j}); end
    end
    if exist('TSSeav','var'), sp_tss = TSSeav; else, sp_tss = NaN; end
    sp_row = [sp_T sp_KLa sp_Qintr sp_Qw sp_vals sp_tss];
    sp_ok = ~isnan(sp_row(5));
catch sp_err
    sp_msg = sp_err.message;
end
