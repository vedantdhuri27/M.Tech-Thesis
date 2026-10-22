%% compare_area.m
% STEP 4: what does a larger clarifier change? Compares the SAME 30 operating points simulated with two clarifier areas, then
% compares the optimum and the cost / ammonia trade-off on the fitted surfaces.
% Before running it, make the large-clarifier runs with design_runs.m:
%     dr_T = 24; dr_AREA = 2566; dr_pilot = false;  -> design_runs_T24_A2566.mat   (about 25-35 minutes)
%     dr_T = 30; dr_AREA = 2566; dr_pilot = false;  -> design_runs_T30_A2566.mat   (about 25-35 minutes)
% (rng(42) makes the 30 points identical for every area, so run k is the same operating point in both files.)
% No simulations here. Needs dfo_fit.m, dfo_pred.m, dfo_all.m, dfo_solve.m, dfo_feat.m, dfo_tf.m in the same folder.
% A larger clarifier costs money that OCI does not include: this script shows what the area buys, not whether it pays for itself.
clear; close all; clc;

ca_T = [24 30];
ca_A = [1225 2566];            % base area first, large area second
ca_nstart = 20;
ca_tf = 'sqrt';                % surface scale for ammonia and TN95, forced so BOTH areas are fitted in exactly the same way ('plain' reproduces design_fit_optimize_v2.m)
ca_lim = struct('snh95',4,'snhavg',4,'tn95',18,'tss95',30);

ca_fig = figure('Visible','off','Position',[100 100 1000 420]);
for ca_ti = 1:numel(ca_T)
    T = ca_T(ca_ti);
    R = cell(1,2);  D = cell(1,2);  have = true;
    for a = 1:2
        fn = sprintf('design_runs_T%d_A%d.mat',T,ca_A(a));
        if ~exist(fn,'file'), fprintf('\n%s not found: skipping T = %d C (run design_runs.m for that area first).\n',fn,T); have = false; break; end
        S = load(fn);  R{a} = S.dr_res;  D{a} = S.dr_D;
    end
    if ~have, continue; end
    n = min(size(R{1},1),size(R{2},1));
    if any(any(abs(D{1}(1:n,:)-D{2}(1:n,:)) > 1e-9))
        warning('The design points of the two files differ: the paired comparison below is NOT like for like.');
    end
    both = ~isnan(R{1}(1:n,5)) & ~isnan(R{2}(1:n,5));
    fprintf('\n=================== T = %d C: clarifier %d m2 against %d m2 (%d paired runs) ===================\n',T,ca_A(1),ca_A(2),sum(both));
    fprintf('  #  |  KLa  Qintr   Qw | SNH95 %d->%d | SNHavg %d->%d | TN95 %d->%d | TSS95 %d->%d | OCI %d->%d\n',ca_A(1),ca_A(2),ca_A(1),ca_A(2),ca_A(1),ca_A(2),ca_A(1),ca_A(2),ca_A(1),ca_A(2));
    for j = find(both)'
        r1 = R{1}(j,:);  r2 = R{2}(j,:);
        fprintf(' %2d  | %5.1f %6.0f %4.0f | %5.2f->%5.2f | %5.2f->%5.2f | %4.1f->%4.1f | %5.1f->%5.1f | %5.0f->%5.0f\n', ...
            j,r1(2:4),r1(5),r2(5),r1(6),r2(6),r1(11),r2(11),r1(13),r2(13),r1(9),r2(9));
    end
    dS = R{2}(both,5)-R{1}(both,5);  dT = R{2}(both,13)-R{1}(both,13);  dO = R{2}(both,9)-R{1}(both,9);
    fprintf('\nChange from the larger clarifier (median, range over the paired runs):\n');
    fprintf('  SNH95 %+.2f (%+.2f to %+.2f) mg N/L     TSS95 %+.1f (%+.1f to %+.1f) mg/L     OCI %+.0f (%+.0f to %+.0f)\n', ...
        median(dS),min(dS),max(dS),median(dT),min(dT),max(dT),median(dO),min(dO),max(dO));
    fprintf('Compliance counts out of %d runs:                                  %d m2   %d m2\n',sum(both),ca_A(1),ca_A(2));
    for a = 1:2, Rb{a} = R{a}(both,:); end %#ok<SAGROW>
    tests = {'TSS95 <= 30', @(r) r(:,13)<=30;
             'TN95 <= 18 and SNHavg <= 4', @(r) r(:,11)<=18 & r(:,6)<=4;
             'practical target (SNHavg<=4, TN95<=18, TSS95<=30)', @(r) r(:,6)<=4 & r(:,11)<=18 & r(:,13)<=30;
             'strict limits (SNH95<=4, TN95<=18, TSS95<=30)', @(r) r(:,5)<=4 & r(:,11)<=18 & r(:,13)<=30};
    for q = 1:size(tests,1)
        fprintf('  %-52s %8d %8d\n',tests{q,1},sum(tests{q,2}(Rb{1})),sum(tests{q,2}(Rb{2})));
    end
    for a = 1:2
        ok = Rb{a}(:,13)<=30;
        if any(ok)
            [v,jb] = min(Rb{a}(:,5)+1e9*~ok);
            fprintf('  Lowest simulated SNH95 with TSS95 <= 30 at %d m2: %.2f (KLa %.1f, Qintr %.0f, Qw %.0f, TN95 %.1f, OCI %.0f)\n', ...
                ca_A(a),v,Rb{a}(jb,2),Rb{a}(jb,3),Rb{a}(jb,4),Rb{a}(jb,11),Rb{a}(jb,9));
        end
    end

    % ---- surfaces and optima for each area ----
    Fa = cell(1,2);
    for a = 1:2
        fprintf('\n--- surfaces, clarifier %d m2, T = %d C ---',ca_A(a),T);
        Fa{a} = dfo_fit(R{a}(~isnan(R{a}(:,5)),:),min(D{a}),max(D{a}),true,ca_tf);
    end
    fam = {'A','B','strict';'D','E','practical';'G','G','lowest SNH95'};
    fprintf('\nOptimum on the surfaces (k = 0 plain, k = 1 with one standard error of margin):\n');
    fprintf(' area | k | target    | mode |  KLa  Qintr   Qw |   OCI | SNH95 SNHavg  TN95 TSS95 | +margin SNH95 SNHavg TN95 TSS95\n');
    for a = 1:2
        for kk = [0 1]
            for f = 1:size(fam,1)
                o = dfo_solve(Fa{a},fam{f,1},kk,ca_nstart,f,ca_lim);
                if ~o.ok && ~strcmp(fam{f,1},fam{f,2}), o = dfo_solve(Fa{a},fam{f,2},kk,ca_nstart,f,ca_lim); end
                if ~o.ok
                    fprintf(' %4d | %g | %-9s |  %s   | no solution inside the bounds\n',ca_A(a),kk,fam{f,3},o.mode);
                else
                    fprintf(' %4d | %g | %-9s |  %s   | %5.1f %6.0f %4.0f | %5.0f | %5.2f %6.2f %5.1f %5.1f |        %5.2f %6.2f %5.1f %5.1f\n', ...
                        ca_A(a),kk,fam{f,3},o.mode,o.x,o.y(4),o.y(1),o.y(2),o.y(3),o.y(6),o.yup(1),o.yup(2),o.yup(3),o.yup(6));
                end
            end
        end
    end

    % ---- cost / ammonia front with solids and nitrogen held at their limits ----
    fprintf('\nOCI against SNH95 with TSS95 <= 30 and TN95 <= 18 held (gamultiobj, predictions):\n');
    go = optimoptions('gamultiobj','PopulationSize',100,'Display','off');
    subplot(1,numel(ca_T),ca_ti);  hold on;  mk = {'o-','s-'};
    for a = 1:2
        rng(42);
        nlf = @(z) frcon(Fa{a},z,ca_lim);
        [zp,fp] = gamultiobj(@(z) [dfo_pred(Fa{a},4,z) dfo_pred(Fa{a},1,z)],3,[],[],[],[],[0 0 0],[1 1 1],nlf,go);
        if isempty(zp), fprintf('  %d m2: no feasible point found\n',ca_A(a)); continue; end
        [~,ix] = sort(fp(:,1));  zp = zp(ix,:);  fp = fp(ix,:);
        fprintf('  clarifier %d m2: %d points; about 8 shown (sorted by OCI)\n',ca_A(a),size(zp,1));
        fprintf('     KLa  Qintr   Qw |   OCI  SNH95\n');
        for j = unique(round(linspace(1,size(zp,1),8)))
            x = Fa{a}.lo + zp(j,:).*(Fa{a}.hi-Fa{a}.lo);
            fprintf('   %5.1f %6.0f %4.0f | %5.0f %6.2f\n',x,fp(j,1),fp(j,2));
        end
        plot(fp(:,1),fp(:,2),mk{a},'DisplayName',sprintf('%d m^2',ca_A(a)));
    end
    plot(xlim,[4 4],'k--','DisplayName','SNH95 limit 4');
    xlabel('OCI (predicted)');  ylabel('SNH95, mg N/L (predicted)');  title(sprintf('%d C, TSS95 <= 30, TN95 <= 18',T));  legend('Location','best');  grid on;  hold off;
end
saveas(ca_fig,'compare_area_fronts.png');
fprintf('\nSaved compare_area_fronts.png\n');

%% ---------------- local helpers ----------------
function [c,ceq] = frcon(F,z,lim)
    c = [dfo_pred(F,6,z) - lim.tss95; dfo_pred(F,3,z) - lim.tn95];
    ceq = [];
end
