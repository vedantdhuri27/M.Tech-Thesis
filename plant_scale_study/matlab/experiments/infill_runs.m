%% infill_runs.m
% STEP 3a: simulate the extra operating points proposed by opt_margin.m, with the real model.
% Order of work:  opt_margin.m  ->  this script  ->  opt_margin.m again (hold-out test, refit, better picks).
% Results go to a NEW file infill_T<ir_T>_A<ir_A>.mat (the 30-run design_runs file is never touched). Saved after every run,
% so you can stop and start it again: finished points are skipped.
% About 1 minute per run with the faster runner (12 runs = roughly 15 minutes).
% Needs run_plant_point.m (with the rp_Qret and rp_over patches) and sim_point.m in the same folder.
clear all; close all;
rp_quiet = true;
set(0,'DefaultFigureVisible','off');
ir_dir = fileparts(which('run_plant_point'));
if isempty(ir_dir), error('run_plant_point.m not found: set the current folder to the folder that holds it and run again.'); end

%% ---- settings ---------------------------------------------------------------------------------
ir_T = 24;                 % 24 or 30: must match the opt_margin.m run that made the proposal
ir_A = 1225;               % clarifier area (m2): same

ir_src  = sprintf('opt_margin_T%d_A%d.mat',ir_T,ir_A);
ir_file = sprintf('infill_T%d_A%d.mat',ir_T,ir_A);
if ~exist(ir_src,'file'), error('%s not found: run opt_margin.m first (same temperature and area).',ir_src); end
ir_M = load(ir_src);
ir_X = ir_M.mg_infill;  ir_lab0 = ir_M.mg_infill_lab;  ir_P = ir_M.mg_infill_pred;  ir_rnd = ir_M.mg_round_next;
if isempty(ir_X), error('opt_margin.m proposed no infill points (all candidates too close to existing runs).'); end

%% ---- resume ----------------------------------------------------------------------------------
ir_res = zeros(0,14);  ir_round = zeros(0,1);  ir_lab = cell(0,1);
if exist(ir_file,'file')
    ir_O = load(ir_file);
    ir_res = ir_O.ir_res;  ir_round = ir_O.ir_round;  ir_lab = ir_O.ir_lab;
    fprintf('Resuming: %d infill runs already in %s\n',size(ir_res,1),ir_file);
end

%% ---- run -------------------------------------------------------------------------------------
fprintf('\nT=%d C, clarifier %d m2, dry weather, infill round %d: %d points   (limits: SNH95 4, SNHavg 4, TN95 18, TSS95 30)\n', ...
    ir_T,ir_A,ir_rnd,size(ir_X,1));
fprintf(' #  |  KLa  | Qintr  |  Qw  |  SNH95 sim/pred | SNHavg sim/pred |  TN95 sim/pred  | TSS95 sim/pred  |   OCI sim/pred  | why\n');
for ir_k = 1:size(ir_X,1)
    if ~isempty(ir_res) && any(all(abs(ir_res(:,2:4) - ir_X(ir_k,:)) < 1e-9,2)), continue; end
    sp_KLa = ir_X(ir_k,1);  sp_Qintr = ir_X(ir_k,2);  sp_Qw = ir_X(ir_k,3);
    sp_T = ir_T;  sp_A = ir_A;  sp_scen = 'dry';  sp_mu = [];  sp_dir = ir_dir;
    sim_point;
    if ~sp_ok
        fprintf('%2d  | run failed: %s\n',ir_k,sp_msg);
        fprintf('      pwd = %s | which run_plant_point = %s\n',pwd,which('run_plant_point'));
        continue;
    end
    ir_res(end+1,:) = sp_row;                 %#ok<SAGROW>
    ir_round(end+1,1) = ir_rnd;               %#ok<SAGROW>
    ir_lab{end+1,1} = ir_lab0{ir_k};          %#ok<SAGROW>
    save(ir_file,'ir_res','ir_round','ir_lab','ir_T','ir_A');
    fprintf('%2d  | %5.1f | %6.0f | %4.0f | %5.2f / %5.2f | %5.2f / %5.2f | %5.1f / %5.1f | %5.1f / %5.1f | %6.0f / %6.0f | %s\n', ...
        ir_k,ir_X(ir_k,:),sp_row(5),ir_P(ir_k,1),sp_row(6),ir_P(ir_k,2),sp_row(11),ir_P(ir_k,3), ...
        sp_row(13),ir_P(ir_k,6),sp_row(9),ir_P(ir_k,4),ir_lab0{ir_k});
end

ir_now = ir_res(ir_round==ir_rnd,:);
fprintf('\nRound %d finished: %d of %d points simulated.\n',ir_rnd,size(ir_now,1),size(ir_X,1));
if ~isempty(ir_now)
    ir_okp = ir_now(:,6)<=4 & ir_now(:,11)<=18 & ir_now(:,13)<=30;
    ir_oks = ir_now(:,5)<=4 & ir_now(:,11)<=18 & ir_now(:,13)<=30;
    fprintf('Meeting the practical target (SNHavg<=4, TN95<=18, TSS95<=30): %d of %d.   Meeting the strict limits (SNH95<=4 too): %d of %d.\n', ...
        sum(ir_okp),size(ir_now,1),sum(ir_oks),size(ir_now,1));
end
fprintf('Saved %s\nNext: run opt_margin.m again with the same mg_T and mg_A. It tests the old surfaces on these runs and refits.\n',ir_file);
