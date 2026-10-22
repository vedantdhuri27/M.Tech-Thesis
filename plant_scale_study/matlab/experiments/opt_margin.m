%% opt_margin.m
% STEP 2 and STEP 3b of the optimisation plan. No simulations are run here (a few minutes of computing).
% It does three things with the runs you already have:
%   1. Fits the response surfaces of design_fit_optimize_v2.m and measures how well they predict runs they have not seen.
%      (Ammonia and TN95 are fitted on a square-root scale when that predicts better in leave-one-out; set mg_tf = 'plain' to reproduce
%       design_fit_optimize_v2.m exactly.)
%   2. Optimises with a SAFETY MARGIN. A margin of k means: every constrained response is tested at (prediction + k standard
%      errors of a new simulation), so a point only counts as "meeting the limit" if the surface is confident about it.
%      k = 0 is the plain optimum, k = 1 and 2 show what confidence costs in OCI.
%        A) cheapest point with SNH95 <= 4, TN95 <= 18, TSS95 <= 30                        (strict)
%        B) if A has no solution: the point with the smallest worst relative violation
%        D) cheapest point with SNHavg <= 4, TN95 <= 18, TSS95 <= 30                        (practical target)
%        E) if D has no solution: the point with the smallest worst relative violation
%        G) lowest SNH95 with TN95 <= 18 and TSS95 <= 30
%      "No solution" at k = 1 or 2 is a result, not a failure: it says the surfaces cannot certify any point, which is the argument for infill.
%   3. Proposes mg_nInfill extra simulations for infill_runs.m: the picks that have a real chance of meeting the practical target, plus
%      points in the uncertain region near the limits at low cost, spread out so each run adds new information.
% Use it twice per temperature:
%   first time: only design_runs_T<mg_T>_A<mg_A>.mat exists -> picks + a proposal for infill_runs.m
%   after infill_runs.m has finished: it refits WITHOUT the newest infill runs, compares what the surfaces predicted with what the
%   real model gave (an honest out-of-sample test), then refits WITH them and gives the improved picks and the next proposal.
% Needs the helper files dfo_fit.m, dfo_pred.m, dfo_all.m, dfo_solve.m, dfo_feat.m, dfo_tf.m in the same folder.
% Everything printed here is a PREDICTION from the surfaces until it has been simulated.
clear; close all; clc;

%% ---- settings you may change --------------------------------------------------------------
mg_T       = 24;                 % 24 or 30
mg_A       = 1225;               % clarifier area (m2) of the runs to use
mg_K       = [0 1 2];            % margins in standard errors (0 = plain optimum)
mg_nInfill = 12;                 % extra simulations to propose (0 = none)
mg_nstart  = 25;                 % random starts per optimisation (the margin runs take a few minutes in total)
mg_tf      = 'auto';             % 'auto' or 'plain' (see above)
lim = struct('snh95',4,'snhavg',4,'tn95',18,'tss95',30);

%% ---- 1. load the runs ----------------------------------------------------------------------
S  = load(sprintf('design_runs_T%d_A%d.mat',mg_T,mg_A));
Rb = S.dr_res(~isnan(S.dr_res(:,5)),:);
lo = min(S.dr_D);  hi = max(S.dr_D);
fprintf('T = %d C, clarifier %d m2: %d runs from the original design\n',mg_T,mg_A,size(Rb,1));
infile = sprintf('infill_T%d_A%d.mat',mg_T,mg_A);
Ri = zeros(0,14);  rnd = zeros(0,1);
if exist(infile,'file')
    I = load(infile);
    keep = ~isnan(I.ir_res(:,5));
    Ri = I.ir_res(keep,:);  rnd = I.ir_round(keep);
    fprintf('%d infill runs found in %s (rounds %s)\n',size(Ri,1),infile,mat2str(unique(rnd(:))'));
end

%% ---- 2. hold-out test: how well did the surfaces predict the newest infill runs? ------------
if ~isempty(Ri)
    last  = max(rnd);
    Rtest = Ri(rnd==last,:);
    F0 = dfo_fit([Rb; Ri(rnd<last,:)],lo,hi,false,mg_tf);
    yt = dfo_all(F0,(Rtest(:,2:4)-lo)./(hi-lo),0);
    simv = [Rtest(:,5) Rtest(:,6) Rtest(:,11) Rtest(:,9) Rtest(:,10) Rtest(:,13)];   % same order as dfo_all
    fprintf('\nHOLD-OUT TEST: infill round %g (%d runs). The surfaces were fitted WITHOUT these runs, then the real model was run.\n',last,size(Rtest,1));
    fprintf(' #  |  KLa Qintr   Qw |     SNH95      |     SNHavg     |      TN95      |      TSS95     |      OCI\n');
    fprintf('    |                 |  sim /  pred   |  sim /  pred   |  sim /  pred   |  sim /  pred   |  sim /  pred\n');
    for j = 1:size(Rtest,1)
        fprintf('%2d  | %5.1f %5.0f %4.0f | %5.2f / %5.2f | %5.2f / %5.2f | %5.1f / %5.1f | %5.1f / %5.1f | %6.0f / %6.0f\n', ...
            j,Rtest(j,2:4),simv(j,1),yt(j,1),simv(j,2),yt(j,2),simv(j,3),yt(j,3),simv(j,6),yt(j,6),simv(j,4),yt(j,4));
    end
    nmx = {'SNH95','SNHavg','TN95','OCI','EQI','TSS95'};
    fprintf('\n response | bias, sim - pred (natural units) | rms error (natural units) | R2 on these unseen runs | rms error (fitted scale) | leave-one-out error before | verdict\n');
    for i = [1 2 3 4 6]
        ef = dfo_tf(F0.tf(i),simv(:,i),1) - dfo_tf(F0.tf(i),yt(:,i),1);
        rmsE = sqrt(mean(ef.^2));  bias = mean(simv(:,i) - yt(:,i));
        rmsN = sqrt(mean((simv(:,i) - yt(:,i)).^2));
        r2u  = 1 - sum((simv(:,i) - yt(:,i)).^2) / sum((simv(:,i) - mean(simv(:,i))).^2);   % out-of-sample R2 on the new runs, natural units
        if rmsE <= 1.5*F0.loo_rmse(i), vd = 'as good as the leave-one-out test said';
        else, vd = 'WORSE than the leave-one-out test said'; end
        fprintf(' %-8s | %32.3g | %25.3g | %23.3f | %24.3g | %26.3g | %s\n',nmx{i},bias,rmsN,r2u,rmsE,F0.loo_rmse(i),vd);
    end
    fprintf('(R2 on unseen runs = 1 - sum of squared errors / spread of the simulated values of these runs. These runs were picked near the limits,\n');
    fprintf(' where the responses vary less than over the whole design, so this R2 is a harder test than the leave-one-out R2: judge it with the rms error too;\n');
    fprintf(' a negative value means the surface did worse than simply using the average of these runs.)\n');
    fprintf('(a bias with the same sign on most rows means the surface is systematically optimistic or pessimistic near the limits;\n');
    fprintf(' errors are on the fitted scale: square-root units for ammonia and TN95 if that scale was used, log units for TSS95)\n');
end

%% ---- 3. fit with everything and look at the data ---------------------------------------------
Rall = [Rb; Ri];
F = dfo_fit(Rall,lo,hi,true,mg_tf);
okc = Rall(:,5)<=lim.snh95 & Rall(:,11)<=lim.tn95 & Rall(:,13)<=lim.tss95;
okp = Rall(:,6)<=lim.snhavg & Rall(:,11)<=lim.tn95 & Rall(:,13)<=lim.tss95;
fprintf('\nSimulated runs meeting the strict limits (SNH95<=4, TN95<=18, TSS95<=30): %d of %d\n',sum(okc),size(Rall,1));
fprintf('Simulated runs meeting the practical target (SNHavg<=4, TN95<=18, TSS95<=30): %d of %d\n',sum(okp),size(Rall,1));
if any(okp)
    [~,jb] = min(Rall(:,9)+1e9*~okp);
    fprintf('  cheapest of them: KLa %.1f, Qintr %.0f, Qw %.0f, OCI %.0f, SNH95 %.2f, SNHavg %.2f, TN95 %.1f, TSS95 %.1f\n', ...
        Rall(jb,[2 3 4 9 5 6 11 13]));
end
oks = Rall(:,13)<=lim.tss95;
if any(oks)
    [~,jb] = min(Rall(:,5)+1e9*~oks);
    fprintf('Lowest simulated SNH95 with TSS95 <= 30: %.2f (KLa %.1f, Qintr %.0f, Qw %.0f, TN95 %.1f, OCI %.0f)\n', ...
        Rall(jb,5),Rall(jb,2),Rall(jb,3),Rall(jb,4),Rall(jb,11),Rall(jb,9));
end

%% ---- 4. optimise with margins ------------------------------------------------------------------
fam = {'A','B','strict: SNH95<=4, TN95<=18, TSS95<=30';
       'D','E','practical: SNHavg<=4, TN95<=18, TSS95<=30';
       'G','G','lowest SNH95 with TN95<=18, TSS95<=30'};
picks = [];
fprintf('\nOPTIMUM WITH SAFETY MARGIN (predictions; "+margin" = value the limit is tested against)\n');
for ik = 1:numel(mg_K)
    kk = mg_K(ik);
    fprintf('\nk = %g standard errors\n',kk);
    fprintf(' target                                    | mode |  KLa  Qintr   Qw |   OCI | SNH95 SNHavg  TN95 TSS95 | +margin: SNH95 SNHavg  TN95 TSS95 | status\n');
    for f = 1:size(fam,1)
        o = dfo_solve(F,fam{f,1},kk,mg_nstart,f,lim);
        if ~o.ok && ~strcmp(fam{f,1},fam{f,2})
            o = dfo_solve(F,fam{f,2},kk,mg_nstart,f,lim);
        end
        p = mkpick(F,o,fam{f,3});
        if isempty(picks), picks = p; else, picks(end+1) = p; end %#ok<SAGROW>
        if ~p.ok
            fprintf(' %-41s |  %s   | no solution inside the bounds: the surfaces cannot certify any point at this margin\n',p.fam,p.mode);
            continue;
        end
        if any(p.mode == 'BE')
            if p.t > 1e-6, st = sprintf('NOT met: worst metric %.0f%% over its limit',100*p.t);
            else,          st = sprintf('met, worst metric %.0f%% under its limit',-100*p.t); end
        else
            st = 'met with margin';
        end
        fprintf(' %-41s |  %s   | %5.1f %6.0f %4.0f | %5.0f | %5.2f %6.2f %5.1f %5.1f |         %5.2f %6.2f %5.1f %5.1f | %s\n', ...
            p.fam,p.mode,p.x,p.y(4),p.y(1),p.y(2),p.y(3),p.y(6),p.yup(1),p.yup(2),p.yup(3),p.yup(6),st);
    end
end
fprintf('\nHow to read it: going from k = 0 to k = 2 shows how much OCI you pay (or how far from the limits you end up) to be\n');
fprintf('confident that the real model, not just the surface, meets the limit.\n');

%% ---- 5. paste-ready block for verify_and_weather.m ----------------------------------------------
kshow = mg_K(min(2,numel(mg_K)));
fprintf('\nPASTE-READY for verify_and_weather.m (picks made with k = %g; replace vw_X and vw_P and set vw_T = %d):\n',kshow,mg_T);
ll = {};
for j = 1:numel(picks)
    if picks(j).ok && picks(j).k == kshow
        ll{end+1} = sprintf('%6.1f %8.0f %5.0f',picks(j).x);                                  %#ok<SAGROW>
    end
end
fprintf('    vw_X = [%s];\n',strjoin(ll,'; '));
ll = {};
for j = 1:numel(picks)
    if picks(j).ok && picks(j).k == kshow
        ll{end+1} = sprintf('%5.2f %6.2f %5.1f %5.1f %6.0f',picks(j).y(1),picks(j).y(2),picks(j).y(3),picks(j).y(6),picks(j).y(4)); %#ok<SAGROW>
    end
end
fprintf('    vw_P = [%s];\n',strjoin(ll,'; '));

%% ---- 6. proposal for extra simulations (infill) --------------------------------------------------
mg_infill = zeros(0,3);  mg_infill_lab = cell(0,1);  mg_infill_pred = zeros(0,6);
mg_round_next = floor(max([0; rnd])) + 1;      % verification runs added by add_verify_to_infill.m count as round 0.5
if mg_nInfill > 0
    Zall = (Rall(:,2:4)-lo)./(hi-lo);
    rng(7);
    Zc = rand(8000,3);
    [yc,~,sc] = dfo_all(F,Zc,0);
    pf = chance(F,yc,sc,lim);        % chance (independent-errors approximation) that a new simulation meets the practical target
    cand = [];
    for thr = [0.2 0.05 0.01 0]
        cand = find(pf >= thr);
        if numel(cand) >= 5*mg_nInfill, break; end
    end
    ocs  = yc(cand,4);
    cand = cand(ocs <= median(ocs));                         % the cheaper half of the uncertain region
    Zcand = Zc(cand,:);
    chosen = zeros(0,3);  clab = cell(0,1);
    kord = abs([picks.k] - 1);  [~,ix] = sort(kord);        % margin picks first (k = 1 before 0 and 2)
    for j = ix(:)'
        p = picks(j);
        if ~p.ok, continue; end
        [yy,~,ss] = dfo_all(F,p.z,0);
        if chance(F,yy,ss,lim) < 0.02 && p.k ~= 0, continue; end              % skip picks with no real chance (corner points), except plain optima
        dE = min(sqrt(sum((Zall - p.z).^2,2)));                                % distance to the nearest run already simulated
        dC = inf;  if ~isempty(chosen), dC = min(sqrt(sum((chosen - p.z).^2,2))); end
        if dE >= 0.03 && dC >= 0.05 && size(chosen,1) < ceil(mg_nInfill/2)
            chosen(end+1,:) = p.z;                                              %#ok<SAGROW>
            clab{end+1,1} = sprintf('pick %s, k=%g',p.mode,p.k);                %#ok<SAGROW>
        end
    end
    while size(chosen,1) < mg_nInfill && ~isempty(Zcand)
        ref  = [Zall; chosen];
        dmin = inf(size(Zcand,1),1);
        for j = 1:size(ref,1)
            dmin = min(dmin, sqrt(sum((Zcand - ref(j,:)).^2,2)));
        end
        [dbest,jb] = max(dmin);
        if dbest < 0.06, break; end
        chosen(end+1,:) = Zcand(jb,:);                                          %#ok<SAGROW>
        clab{end+1,1} = 'uncertain region near the limits';                     %#ok<SAGROW>
    end
    % back to real units, rounded as in design_runs.m, then predictions at the rounded points
    xr = lo + chosen.*(hi-lo);
    xr = [round(xr(:,1),1) round(xr(:,2),-2) round(xr(:,3))];
    zr = min(max((xr-lo)./(hi-lo),0),1);
    mg_infill = xr;  mg_infill_lab = clab;
    if ~isempty(zr)
        [yy,~,ss] = dfo_all(F,zr,0);
        mg_infill_pred = yy;
        pj = chance(F,yy,ss,lim);
        fprintf('\nPROPOSED INFILL (round %d): %d simulations for infill_runs.m\n',mg_round_next,size(xr,1));
        fprintf(' #  |  KLa  Qintr   Qw | predicted: SNH95 SNHavg  TN95 TSS95 (x factor)   OCI | chance of meeting practical target | why\n');
        for j = 1:size(xr,1)
            fprintf('%2d  | %5.1f %6.0f %4.0f |            %5.2f %6.2f %5.1f %5.1f (x%.2f)  %6.0f | %4.0f%% | %s\n', ...
                j,xr(j,:),yy(j,1),yy(j,2),yy(j,3),yy(j,6),exp(ss(j,6)),yy(j,4),100*pj(j),clab{j});
        end
    end
end

%% ---- 7. save ---------------------------------------------------------------------------------------
mg_F = F;  mg_lo = lo;  mg_hi = hi;
save(sprintf('opt_margin_T%d_A%d.mat',mg_T,mg_A),'picks','mg_infill','mg_infill_lab','mg_infill_pred','mg_round_next','mg_F','mg_lo','mg_hi','mg_K','mg_T','mg_A');
fprintf('\nSaved opt_margin_T%d_A%d.mat\n',mg_T,mg_A);
if mg_nInfill > 0 && ~isempty(mg_infill)
    fprintf('Next: run infill_runs.m with ir_T = %d and ir_A = %d (%d simulations), then run this script again.\n',mg_T,mg_A,size(mg_infill,1));
end

%% ---------------- local helpers ----------------
function p = mkpick(F,o,famtxt)
    p = struct('ok',o.ok,'mode',o.mode,'k',o.k,'fam',famtxt,'x',nan(1,3),'z',nan(1,3),'y',nan(1,6),'yup',nan(1,6),'t',o.t);
    if ~o.ok, return; end
    x = F.lo + o.z.*(F.hi-F.lo);
    x = [round(x(1),1) round(x(2),-2) round(x(3))];             % rounded as in design_runs.m; predictions are recomputed at the rounded point
    z = min(max((x-F.lo)./(F.hi-F.lo),0),1);
    [y,yup] = dfo_all(F,z,o.k);
    p.x = x;  p.z = z;  p.y = y;  p.yup = yup;
end

function pf = chance(F,y,s,lim)
    % approximate chance that a NEW simulation meets SNHavg <= lim.snhavg, TN95 <= lim.tn95 and TSS95 <= lim.tss95,
    % treating the three prediction errors as independent normal errors on each response's fitted scale
    Phi = @(x) 0.5*erfc(-x/sqrt(2));
    z2 = (dfo_tf(F.tf(2),lim.snhavg,1) - dfo_tf(F.tf(2),y(:,2),1))./s(:,2);
    z3 = (dfo_tf(F.tf(3),lim.tn95,1)   - dfo_tf(F.tf(3),y(:,3),1))./s(:,3);
    z6 = (dfo_tf(F.tf(6),lim.tss95,1)  - dfo_tf(F.tf(6),y(:,6),1))./s(:,6);
    pf = Phi(z2).*Phi(z3).*Phi(z6);
end
