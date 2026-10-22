%% design_fit_optimize.m
% Reads design_runs_T<dr_T>_A<dr_A>.mat (from design_runs.m), fits quadratic response surfaces over KLa, Qintr, Qw,
% checks how good they are, then optimizes. Effluent solids (TSS95) are now a modelled response and a constraint,
% because with the calibrated clarifier (1225 m2) solids and ammonia pull against each other through Qw.
%   A) cheapest point meeting SNH95 <= 4, TN95 <= 18 and TSS95 <= 30        (all strict limits)
%   B) if none exists: the point with the smallest worst-case relative violation of those three limits
%   G) the lowest ammonia (SNH95) reachable while keeping TSS95 <= 30 and TN95 <= 18
%   D) cheapest point meeting AVERAGE ammonia <= 4, TN95 <= 18 and TSS95 <= 30  (practical target)
%   C) three-way trade-off OCI / SNH95 / TSS95 (NSGA-II), printed as a short table
% Everything printed here is a PREDICTION from the surfaces. Re-simulate each chosen point with the
% real model (verify_points.m) before reporting it. TSS95 is fitted on a log scale (it rises steeply at low Qw).
% v2: the solids surface (TSS95) is tried in three forms and the one with the best leave-one-out R2 is used:
%       1 quadratic in KLa, Qintr, Qw (as before)
%       2 quadratic in KLa, Qintr, 1/Qw (sludge age goes as 1/Qw)
%       3 cubic in 1/Qw plus KLa, KLa^2 and KLa*(1/Qw) (7 parameters; no Qintr, which does not reach the clarifier)
%     Form 3 was chosen after looking at the 30 C data, so its leave-one-out R2 is a little optimistic: check it at 24 C and on verification runs.
%     Results are saved under the usual name design_fit_T<dr_T>_A<dr_A>.mat (replacing the earlier file for that temperature).
clear; close all; clc;
dr_T = 30;                                   % 24 or 30
dr_A = 1225;                                 % clarifier area used in design_runs.m

S  = load(sprintf('design_runs_T%d_A%d.mat',dr_T,dr_A));
R  = S.dr_res;  R = R(~isnan(R(:,5)),:);     % finished runs only
fprintf('%d finished runs at %d C, clarifier %d m2\n',size(R,1),dr_T,dr_A);
% columns of dr_res: 1 T, 2 KLa, 3 Qintr, 4 Qw, 5 SNH95, 6 SNHavg, 7 DO, 8 XBA, 9 OCI, 10 EQI, 11 TN95, 12 TNavg, 13 TSS95, 14 TSSeav
lo = min(S.dr_D);  hi = max(S.dr_D);         % design bounds (KLa, Qintr, Qw)
Z  = (R(:,2:4)-lo)./(hi-lo);                 % variables coded 0 to 1
dec = @(z) z.*(hi-lo) + lo;                  % back to real units
zlb = [0 0 0];  zub = [1 1 1];

%% 1. fit one quadratic surface per response and check it
nm = {'SNH95','SNHavg','TN95','OCI','EQI','log TSS95'};
cl = [5 6 11 9 10 13];
nr = numel(nm);
M  = cell(1,nr);
fprintf('\nResponse  | R2    | R2 leave-one-out (honest test)\n');
ulo = 1/hi(3);  uhi = 1/lo(3);                % solids are also tried against 1/Qw, coded 0 to 1
Uc  = (1./R(:,4) - ulo)/(uhi-ulo);
tss_mode = 1;
for i = 1:nr
    y = R(:,cl(i));  if i == 6, y = log(y); end
    M{i} = fitlm(Z,y,'quadratic');
    h = M{i}.Diagnostics.Leverage;  e = M{i}.Residuals.Raw;
    q2 = 1 - sum((e./(1-h)).^2)/sum((y-mean(y)).^2);
    fprintf('%-9s | %.3f | %.3f\n',nm{i},M{i}.Rsquared.Ordinary,q2);
    if i == 6
        M2 = fitlm([Z(:,1:2) Uc],y,'quadratic');
        q22 = loo_r2(M2,y);
        fprintf('log TSS95 | %.3f | %.3f   (form 2: quadratic against 1/Qw)\n',M2.Rsquared.Ordinary,q22);
        M3 = fitlm(tssfeat(Z(:,1),Uc),y);
        q23 = loo_r2(M3,y);
        fprintf('log TSS95 | %.3f | %.3f   (form 3: cubic in 1/Qw plus aeration terms)\n',M3.Rsquared.Ordinary,q23);
        [~,ibest] = max([q2 q22 q23]);
        tss_mode = ibest;
        if ibest == 2, M{6} = M2; elseif ibest == 3, M{6} = M3; end
        fprintf('   -> form %d is used for solids\n',tss_mode);
    end
end
fprintf('(leave-one-out below about 0.8 means that surface is not trustworthy; tell me before using it)\n');
% i: 1 SNH95, 2 SNHavg, 3 TN95, 4 OCI, 5 EQI, 6 TSS95 (back in mg/L)
pred = @(i,z) predf(M,i,z,lo,hi,tss_mode);

%% 2. what the data already contains
okc = R(:,5)<=4 & R(:,11)<=18 & R(:,13)<=30;
fprintf('\nSimulated points meeting SNH95 <= 4, TN95 <= 18 and TSS95 <= 30: %d of %d\n',sum(okc),size(R,1));
[~,ib] = min(R(:,5));
fprintf('Lowest simulated SNH95: %.2f (KLa %.1f, Qintr %.0f, Qw %.0f, TN95 %.1f, TSS95 %.1f, OCI %.0f)\n', ...
    R(ib,5),R(ib,2),R(ib,3),R(ib,4),R(ib,11),R(ib,13),R(ib,9));
oks = R(:,13)<=30;
if any(oks)
    [~,jb] = min(R(:,5)+1e6*~oks);
    fprintf('Lowest simulated SNH95 with TSS95 <= 30: %.2f (KLa %.1f, Qintr %.0f, Qw %.0f, TN95 %.1f, TSS95 %.1f, OCI %.0f)\n', ...
        R(jb,5),R(jb,2),R(jb,3),R(jb,4),R(jb,11),R(jb,13),R(jb,9));
end

opt  = optimoptions('fmincon','Algorithm','sqp','Display','off');
f_oci = @(z) pred(4,z);

%% 3. A) cheapest point meeting the strict limits
nonA = @(z) ncon([pred(1,z)-4; pred(3,z)-18; pred(6,z)-30]);
rng(1);  best = [];  bf = inf;
for k = 1:60
    [z,f,ef] = fmincon(f_oci,zlb+rand(1,3).*(zub-zlb),[],[],[],[],zlb,zub,nonA,opt);
    if ef > 0 && max(nonA(z)) <= 1e-6 && f < bf, best = z; bf = f; end
end
if ~isempty(best)
    p = dec(best);
    fprintf('\nA) Cheapest point meeting SNH95<=4, TN95<=18, TSS95<=30 (predicted): KLa %.1f, Qintr %.0f, Qw %.0f\n',p);
    fprintf('   OCI %.0f, SNH95 %.2f, SNHavg %.2f, TN95 %.1f, TSS95 %.1f, EQI %.0f\n', ...
        pred(4,best),pred(1,best),pred(2,best),pred(3,best),pred(6,best),pred(5,best));
else
    fprintf('\nA) No point meets SNH95<=4, TN95<=18 and TSS95<=30 inside the bounds (according to the surfaces).\n');
    %% B) smallest worst-case relative violation: minimize t where each metric <= its limit*(1+t)
    nl2 = @(v) ncon([pred(1,v(1:3))/4-1-v(4); pred(3,v(1:3))/18-1-v(4); pred(6,v(1:3))/30-1-v(4)]);
    bv = []; bt = inf;
    for k = 1:60
        [v,t,ef] = fmincon(@(v) v(4),[zlb+rand(1,3).*(zub-zlb) 1],[],[],[],[],[zlb -1],[zub 10],nl2,opt);
        if ef > 0 && t < bt, bv = v; bt = t; end
    end
    z = bv(1:3);  p = dec(z);
    fprintf('B) Least-violation point (predicted): KLa %.1f, Qintr %.0f, Qw %.0f\n',p);
    fprintf('   SNH95 %.2f (limit 4), SNHavg %.2f, TN95 %.1f (limit 18), TSS95 %.1f (limit 30), OCI %.0f\n', ...
        pred(1,z),pred(2,z),pred(3,z),pred(6,z),pred(4,z));
    fprintf('   worst metric exceeds its limit by %.0f%%\n',100*bt);
end

%% 4. G) lowest ammonia while keeping solids and nitrogen within their limits
nonG = @(z) ncon([pred(3,z)-18; pred(6,z)-30]);
rng(3);  bestG = [];  bfG = inf;
for k = 1:60
    [z,f,ef] = fmincon(@(z) pred(1,z),zlb+rand(1,3).*(zub-zlb),[],[],[],[],zlb,zub,nonG,opt);
    if ef > 0 && max(nonG(z)) <= 1e-6 && f < bfG, bestG = z; bfG = f; end
end
if ~isempty(bestG)
    p = dec(bestG);
    fprintf('\nG) Lowest SNH95 with TSS95<=30 and TN95<=18 (predicted): KLa %.1f, Qintr %.0f, Qw %.0f\n',p);
    fprintf('   SNH95 %.2f, SNHavg %.2f, TN95 %.1f, TSS95 %.1f, OCI %.0f, EQI %.0f\n', ...
        pred(1,bestG),pred(2,bestG),pred(3,bestG),pred(6,bestG),pred(4,bestG),pred(5,bestG));
else
    fprintf('\nG) No point keeps TSS95<=30 and TN95<=18 inside the bounds.\n');
end

%% 5. D) cheapest point meeting AVERAGE ammonia <= 4, TN95 <= 18, TSS95 <= 30
nonD = @(z) ncon([pred(2,z)-4; pred(3,z)-18; pred(6,z)-30]);
rng(2);  bestD = [];  bfD = inf;
for k = 1:60
    [z,f,ef] = fmincon(f_oci,zlb+rand(1,3).*(zub-zlb),[],[],[],[],zlb,zub,nonD,opt);
    if ef > 0 && max(nonD(z)) <= 1e-6 && f < bfD, bestD = z; bfD = f; end
end
if ~isempty(bestD)
    p = dec(bestD);
    fprintf('\nD) Cheapest point meeting SNHavg<=4, TN95<=18, TSS95<=30 (predicted): KLa %.1f, Qintr %.0f, Qw %.0f\n',p);
    fprintf('   OCI %.0f, SNHavg %.2f, SNH95 %.2f, TN95 %.1f, TSS95 %.1f, EQI %.0f\n', ...
        pred(4,bestD),pred(2,bestD),pred(1,bestD),pred(3,bestD),pred(6,bestD),pred(5,bestD));
else
    fprintf('\nD) No point meets SNHavg<=4, TN95<=18 and TSS95<=30 inside the bounds.\n');
end

%% 6. C) cost / ammonia / solids trade-off
rng(42);
go = optimoptions('gamultiobj','PopulationSize',150,'Display','off');
[zp,fp] = gamultiobj(@(z) [pred(4,z) pred(1,z) pred(6,z)],3,[],[],[],[],zlb,zub,[],go);
[~,ix] = sort(fp(:,2));  zp = zp(ix,:);  fp = fp(ix,:);   % sorted by ammonia
fprintf('\nC) Cost / ammonia / solids trade-off (predicted), %d points sorted by SNH95; about 10 shown\n',size(zp,1));
fprintf('   KLa   Qintr    Qw |   OCI  SNH95  SNHavg  TN95  TSS95\n');
for k = unique([1:max(1,round(size(zp,1)/10)):size(zp,1) size(zp,1)])
    p = dec(zp(k,:));
    fprintf('  %5.1f %6.0f %5.0f | %6.0f %5.2f %6.2f %5.1f %5.1f\n',p,fp(k,1),fp(k,2),pred(2,zp(k,:)),pred(3,zp(k,:)),fp(k,3));
end
save(sprintf('design_fit_T%d_A%d.mat',dr_T,dr_A),'M','lo','hi','zp','fp','best','bestD','bestG','tss_mode');
fprintf('\nSaved design_fit_T%d_A%d.mat\n',dr_T,dr_A);

%% ---------------- local helpers ----------------
function y = predf(M,i,z,lo,hi,tss_mode)
    if i == 6 && tss_mode > 1
        q  = z(:,3)*(hi(3)-lo(3)) + lo(3);                    % waste flow in m3/d
        u  = (1./q - 1/hi(3))/(1/lo(3) - 1/hi(3));            % 1/Qw coded 0 to 1
        if tss_mode == 2
            z6 = [z(:,1:2) u];
        else
            z6 = tssfeat(z(:,1),u);
        end
        y = exp(predict(M{6},z6));                            % TSS95 was fitted on a log scale
    else
        y = predict(M{i},z);
        if i == 6, y = exp(y); end                            % TSS95 was fitted on a log scale
    end
end
function F = tssfeat(k,u)
    F = [u u.^2 u.^3 k k.^2 k.*u];                            % form 3 for solids: k = coded KLa, u = coded 1/Qw
end
function q = loo_r2(Mdl,y)
    h = Mdl.Diagnostics.Leverage;  e = Mdl.Residuals.Raw;
    q = 1 - sum((e./(1-h)).^2)/sum((y-mean(y)).^2);
end
function [c,ceq] = ncon(c)
    c = c(:); ceq = [];          % inequality constraints c <= 0, no equalities
end
