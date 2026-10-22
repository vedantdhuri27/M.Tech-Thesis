%% front_oci_eqi_tn.m
% STEP 6: the three-way trade-off between operating cost (OCI), effluent quality (EQI) and total nitrogen (TN95) at 24 C and 30 C.
% On the fitted surfaces (NSGA-II, gamultiobj) it finds the set of operating points where none of the three can be improved
% without making another worse, subject to the permit-type constraints below. Then, with fr_verify = true, it re-simulates the
% extreme points, the "knee" point and the plant as operated with the real model, so the numbers you report are simulated ones.
% Constraints: TSS95 <= fr_tss and average ammonia SNHavg <= fr_cap (set fr_cap = Inf to drop the ammonia constraint).
% If the ammonia cap cannot be met at a temperature, the script says so and relaxes it to the lowest SNHavg the surfaces can reach plus 0.5.
% Uses infill_T<T>_A<A>.mat as well when it exists. About 10 simulations (12 minutes) with fr_verify = true.
% Needs dfo_fit.m, dfo_pred.m, dfo_all.m, dfo_feat.m, dfo_tf.m, sim_point.m and run_plant_point.m in the same folder.
%
% NOTE ON THE 15 C REFERENCE: the 15 C numbers from the earlier BSM1-size study (OCI about 15.7-16.1 thousand, EQI about 3.1-3.6 thousand) are for
% 18,446 m3/d and 6,000 m3 of tank. The Anjana plant-scale runs here have 38,485 m3/d and 26,250 m3, so absolute OCI and EQI are NOT comparable.
% Compare each temperature with the plant as operated at that same temperature (the percentages this script prints), or run a plant-scale
% design at 15 C with design_runs.m (dr_T = 15) first.
clear all; close all; clc;
rp_quiet = true;
set(0,'DefaultFigureVisible','off');
fr_dir = fileparts(which('run_plant_point'));

%% ---- settings ---------------------------------------------------------------------------------
fr_Ts     = [24 30];
fr_A      = 1225;           % clarifier area (m2) of the runs to use
fr_cap    = 4;              % cap on average ammonia SNHavg (mg N/L); Inf = no cap
fr_tss    = 30;             % cap on TSS95 (mg/L)
fr_pop    = 150;            % NSGA-II population
fr_verify = true;           % re-simulate the key points with the real model
if fr_verify && isempty(fr_dir), error('run_plant_point.m not found: set the current folder to the folder that holds it, or set fr_verify = false.'); end

fr_fig = figure('Visible','off','Position',[100 100 1250 400]);
fr_col = {'b','r'};
fr_sum = struct('T',{},'name',{},'x',{},'f',{},'y',{});
for fr_i = 1:numel(fr_Ts)
    fr_T = fr_Ts(fr_i);
    fr_S  = load(sprintf('design_runs_T%d_A%d.mat',fr_T,fr_A));
    fr_R  = fr_S.dr_res(~isnan(fr_S.dr_res(:,5)),:);
    fr_lo = min(fr_S.dr_D);  fr_hi = max(fr_S.dr_D);
    fr_if = sprintf('infill_T%d_A%d.mat',fr_T,fr_A);
    if exist(fr_if,'file')
        fr_I = load(fr_if);  fr_R = [fr_R; fr_I.ir_res(~isnan(fr_I.ir_res(:,5)),:)];
        fprintf('\nT = %d C: %d original runs + %d infill runs\n',fr_T,size(fr_S.dr_res,1),size(fr_R,1)-sum(~isnan(fr_S.dr_res(:,5))));
    else
        fprintf('\nT = %d C: %d runs\n',fr_T,size(fr_R,1));
    end
    fr_F = dfo_fit(fr_R,fr_lo,fr_hi,true);

    %% front
    [fr_z,fr_f,fr_capu] = run_front(fr_F,fr_cap,fr_tss,fr_pop);
    if isempty(fr_z)
        fprintf('No feasible points found at %d C even after relaxing the ammonia cap; skipping.\n',fr_T);
        continue;
    end
    if fr_capu ~= fr_cap
        fprintf('The surfaces cannot reach SNHavg <= %g with TSS95 <= %g at %d C. Cap relaxed to SNHavg <= %.1f for this front.\n',fr_cap,fr_tss,fr_T,fr_capu);
    end
    fr_y = dfo_all(fr_F,fr_z,0);                                  % SNH95 SNHavg TN95 OCI EQI TSS95
    fr_x = fr_lo + fr_z.*(fr_hi-fr_lo);
    fr_n = (fr_f - min(fr_f))./max(max(fr_f)-min(fr_f),eps);      % each objective scaled 0 to 1
    [~,fr_kn] = min(sqrt(sum(fr_n.^2,2)));                        % knee: closest to the ideal point
    [~,fr_a] = min(fr_f(:,1));  [~,fr_b] = min(fr_f(:,2));  [~,fr_c] = min(fr_f(:,3));
    fr_pick = [fr_a fr_kn fr_b fr_c];
    fr_nm   = {'min OCI','knee','min EQI','min TN95'};
    fprintf('\nFRONT at %d C (predicted): %d points, ammonia cap SNHavg <= %g, TSS95 <= %g\n',fr_T,size(fr_z,1),fr_capu,fr_tss);
    fprintf(' point     |  KLa  Qintr   Qw |   OCI    EQI  TN95 | SNH95 SNHavg TSS95\n');
    for fr_j = 1:numel(fr_pick)
        fr_q = fr_pick(fr_j);
        fprintf(' %-9s | %5.1f %6.0f %4.0f | %5.0f %6.0f %5.1f | %5.2f %6.2f %5.1f\n',fr_nm{fr_j},fr_x(fr_q,:),fr_f(fr_q,1),fr_f(fr_q,2),fr_f(fr_q,3),fr_y(fr_q,1),fr_y(fr_q,2),fr_y(fr_q,6));
    end
    fprintf('  ranges over the front:  OCI %.0f to %.0f,  EQI %.0f to %.0f,  TN95 %.1f to %.1f\n',min(fr_f(:,1)),max(fr_f(:,1)),min(fr_f(:,2)),max(fr_f(:,2)),min(fr_f(:,3)),max(fr_f(:,3)));
    fprintf('  points on the front with TN95 <= 18: %d of %d\n',sum(fr_f(:,3)<=18),size(fr_f,1));
    [~,fr_o] = sort(fr_f(:,1));
    fprintf('  about 10 points sorted by OCI:\n     KLa  Qintr   Qw |   OCI    EQI  TN95\n');
    for fr_j = unique(round(linspace(1,numel(fr_o),min(10,numel(fr_o)))))
        fr_q = fr_o(fr_j);
        fprintf('   %5.1f %6.0f %4.0f | %5.0f %6.0f %5.1f\n',fr_x(fr_q,:),fr_f(fr_q,1),fr_f(fr_q,2),fr_f(fr_q,3));
    end

    %% plots
    figure(fr_fig);
    subplot(1,3,1); hold on; plot(fr_f(:,1),fr_f(:,2),[fr_col{fr_i} 'o'],'DisplayName',sprintf('%d C',fr_T)); xlabel('OCI'); ylabel('EQI'); grid on;
    subplot(1,3,2); hold on; plot(fr_f(:,1),fr_f(:,3),[fr_col{fr_i} 'o'],'DisplayName',sprintf('%d C',fr_T)); xlabel('OCI'); ylabel('TN95, mg N/L'); grid on;
    subplot(1,3,3); hold on; plot(fr_f(:,2),fr_f(:,3),[fr_col{fr_i} 'o'],'DisplayName',sprintf('%d C',fr_T)); xlabel('EQI'); ylabel('TN95, mg N/L'); grid on;

    %% verification with the real model
    fr_chk = nan(numel(fr_pick)+1,5);  fr_chkx = zeros(numel(fr_pick)+1,3);
    if fr_verify
        fprintf('\nCHECK WITH THE REAL MODEL, %d C, dry weather (simulated / predicted)\n',fr_T);
        fprintf(' point            |  KLa  Qintr   Qw |       OCI       |       EQI       |     TN95      |    SNHavg     |    TSS95\n');
        for fr_j = 1:numel(fr_pick)+1
            if fr_j <= numel(fr_pick)
                fr_q = fr_pick(fr_j);
                fr_xr = [round(fr_x(fr_q,1),1) round(fr_x(fr_q,2),-2) round(fr_x(fr_q,3))];
                fr_zz = min(max((fr_xr-fr_lo)./(fr_hi-fr_lo),0),1);
                fr_yy = dfo_all(fr_F,fr_zz,0);
                fr_pr = [fr_yy(4) fr_yy(5) fr_yy(3) fr_yy(2) fr_yy(6)];  fr_lab = fr_nm{fr_j};
            else
                fr_xr = [167 65000 1090];  fr_pr = nan(1,5);  fr_lab = 'plant as operated';
            end
            sp_KLa = fr_xr(1);  sp_Qintr = fr_xr(2);  sp_Qw = fr_xr(3);  sp_T = fr_T;  sp_A = fr_A;  sp_scen = 'dry';  sp_mu = [];  sp_dir = fr_dir;
            sim_point;
            fr_chkx(fr_j,:) = fr_xr;
            if ~sp_ok
                fprintf(' %-16s | run failed: %s\n',fr_lab,sp_msg);
                fprintf('      pwd = %s | which run_plant_point = %s\n',pwd,which('run_plant_point'));
                continue;
            end
            fr_chk(fr_j,:) = [sp_row(9) sp_row(10) sp_row(11) sp_row(6) sp_row(13)];
            fprintf(' %-16s | %5.1f %6.0f %4.0f | %6.0f / %6.0f | %6.0f / %6.0f | %5.1f / %5.1f | %5.2f / %5.2f | %5.1f / %5.1f\n', ...
                fr_lab,fr_xr,fr_chk(fr_j,1),fr_pr(1),fr_chk(fr_j,2),fr_pr(2),fr_chk(fr_j,3),fr_pr(3),fr_chk(fr_j,4),fr_pr(4),fr_chk(fr_j,5),fr_pr(5));
        end
        fprintf('  (the plant row has no prediction: Qw 1090 lies outside the design range of the surfaces)\n');
        fr_pl = fr_chk(end,:);
        if ~any(isnan(fr_pl))
            fprintf('  Against the plant as operated at %d C (simulated):\n',fr_T);
            for fr_j = 1:numel(fr_pick)
                if any(isnan(fr_chk(fr_j,:))), continue; end
                fprintf('    %-9s OCI %+5.1f%%   EQI %+5.1f%%   TN95 %+5.1f%%   (SNHavg %.2f against %.2f, TSS95 %.1f against %.1f)\n',fr_nm{fr_j}, ...
                    100*(fr_chk(fr_j,1)/fr_pl(1)-1),100*(fr_chk(fr_j,2)/fr_pl(2)-1),100*(fr_chk(fr_j,3)/fr_pl(3)-1),fr_chk(fr_j,4),fr_pl(4),fr_chk(fr_j,5),fr_pl(5));
            end
        end
    end
    fr_sum(end+1) = struct('T',fr_T,'name',{fr_nm},'x',fr_x(fr_pick,:),'f',fr_f(fr_pick,:),'y',fr_y(fr_pick,:)); %#ok<SAGROW>
    save(sprintf('front_T%d_A%d.mat',fr_T,fr_A),'fr_z','fr_f','fr_x','fr_y','fr_pick','fr_nm','fr_chk','fr_chkx','fr_capu','fr_tss','fr_T','fr_A');
end

%% ---- comparison across temperature -------------------------------------------------------------------
if numel(fr_sum) == 2
    fprintf('\nCOMPARISON, %d C against %d C (predicted, same constraints):\n',fr_sum(2).T,fr_sum(1).T);
    fprintf(' point     |  OCI %d -> %d |  EQI %d -> %d | TN95 %d -> %d\n',fr_sum(1).T,fr_sum(2).T,fr_sum(1).T,fr_sum(2).T,fr_sum(1).T,fr_sum(2).T);
    for fr_j = 1:4
        fr_pa = fr_sum(1).f(fr_j,:);  fr_pb = fr_sum(2).f(fr_j,:);
        fprintf(' %-9s | %6.0f -> %6.0f (%+.0f%%) | %6.0f -> %6.0f (%+.0f%%) | %5.1f -> %5.1f\n',fr_sum(1).name{fr_j},fr_pa(1),fr_pb(1),100*(fr_pb(1)/fr_pa(1)-1),fr_pa(2),fr_pb(2),100*(fr_pb(2)/fr_pa(2)-1),fr_pa(3),fr_pb(3));
    end
end
figure(fr_fig);
for fr_p = 1:3, subplot(1,3,fr_p); legend('Location','best'); end
saveas(fr_fig,'front_oci_eqi_tn.png');
fprintf('\nSaved front_oci_eqi_tn.png and front_T*_A%d.mat\n',fr_A);
fprintf('Reminder: do not compare these absolute OCI/EQI values with the 15 C BSM1-size numbers (see the note at the top of this script).\n');

%% ---------------- local helpers ----------------
function [zp,fp,cap] = run_front(F,cap,tss,pop)
    go = optimoptions('gamultiobj','PopulationSize',pop,'ParetoFraction',0.8,'Display','off');
    [zp,fp] = front_once(F,cap,tss,go);
    if isempty(zp)
        % the ammonia cap cannot be met: find the lowest SNHavg the surfaces reach with TSS95 <= tss, and cap there + 0.5
        opt = optimoptions('fmincon','Algorithm','sqp','Display','off');
        rng(5);  best = inf;
        for s = 1:30
            [~,f,ef] = fmincon(@(z) dfo_pred(F,2,z),rand(1,3),[],[],[],[],[0 0 0],[1 1 1],@(z) tcon(F,z,tss),opt);
            if ef > 0 && f < best, best = f; end
        end
        if isfinite(best)
            cap = best + 0.5;
            [zp,fp] = front_once(F,cap,tss,go);
        end
    end
end

function [zp,fp] = front_once(F,cap,tss,go)
    rng(42);
    [zp,fp] = gamultiobj(@(z) frobj(F,z),3,[],[],[],[],[0 0 0],[1 1 1],@(z) frcon(F,z,cap,tss),go);
    ok = false(size(zp,1),1);
    for j = 1:size(zp,1)
        ok(j) = all(frcon(F,zp(j,:),cap,tss) <= 1e-6);
    end
    zp = zp(ok,:);  fp = fp(ok,:);
end

function f = frobj(F,z)
    f = [dfo_pred(F,4,z) dfo_pred(F,5,z) dfo_pred(F,3,z)];        % OCI, EQI, TN95
end

function [c,ceq] = frcon(F,z,cap,tss)
    c = dfo_pred(F,6,z) - tss;
    if isfinite(cap), c = [c; dfo_pred(F,2,z) - cap]; end
    ceq = [];
end

function [c,ceq] = tcon(F,z,tss)
    c = dfo_pred(F,6,z) - tss;
    ceq = [];
end
