function F = dfo_fit(R, lo, hi, verbose, tfmode)
%DFO_FIT  Fit the six response surfaces of design_fit_optimize_v2.m to a block of simulated runs.
%   R        rows in the dr_res layout: 1 T, 2 KLa, 3 Qintr, 4 Qw, 5 SNH95, 6 SNHavg, 7 DO, 8 XBA, 9 OCI, 10 EQI,
%            11 TN95, 12 TNavg, 13 TSS95, 14 TSSeav   (rows with NaN in column 5 are dropped)
%   lo, hi   design bounds [KLa Qintr Qw] = min and max of the ORIGINAL 30-run design, so the coding of the variables
%            never changes when runs are added
%   verbose  true (default) prints the fit table
%   tfmode   'auto' (default): SNH95, SNHavg and TN95 are fitted on the square-root scale when that predicts better in leave-one-out
%                              (judged on the original scale), otherwise as in design_fit_optimize_v2.m
%            'plain'          : never use the square root (reproduces design_fit_optimize_v2.m)
%            'sqrt'           : always use it for those three (so two data sets are fitted in the same way)
%   F        struct with M (six models), tf (transform code per response), tss_mode, lo, hi, loo_r2, loo_rmse (fitted scale),
%            loo_rmso (natural units), infl, n, nm, qcmp, tfmode
%   Responses, in this order everywhere: 1 SNH95, 2 SNHavg, 3 TN95, 4 OCI, 5 EQI, 6 TSS95.
%   Surfaces: quadratic for 1 to 5 (OCI, EQI plain); TSS95 on the log scale, best of three forms by leave-one-out R2 (see dfo_feat.m).
%   Why a square-root scale: near the limits ammonia is 2 to 8 mg/L, but the corners of the design reach 38. On the plain scale the large
%   corner values dominate the fit error, so the surface looks less certain near the limits than it is. The square root evens the error out.
%   infl = max(1, leave-one-out error / in-sample error): the factor by which dfo_pred widens its standard error,
%   so a margin reflects how well the surface predicts runs it has NOT seen.
if nargin < 4 || isempty(verbose), verbose = true; end
if nargin < 5 || isempty(tfmode), tfmode = 'auto'; end
R = R(~isnan(R(:,5)),:);
Z = (R(:,2:4)-lo)./(hi-lo);
nm = {'SNH95','SNHavg','TN95','OCI','EQI','TSS95'};
cl = [5 6 11 9 10 13];
tf = [0 0 0 0 0 1];
M = cell(1,6);  q2 = nan(1,6);  rm = nan(1,6);  rmo = nan(1,6);  infl = ones(1,6);  tss_mode = 1;  qq = nan(1,3);  qcmp = nan(3,2);  nuse = nan(1,6);
Zfull = Z;
for i = 1:6
    % a run that lacks one response (e.g. a verification run without EQI) is simply left out of THAT surface
    okr = ~isnan(R(:,cl(i)));
    Z  = Zfull(okr,:);  y0 = R(okr,cl(i));  nuse(i) = sum(okr);
    y  = dfo_tf(tf(i),y0,1);
    Mi = fitlm(Z,y,'quadratic');
    if i == 6, qi = loo_r2(Mi,y); else, qi = loo_r2o(Mi,y0,tf(i)); end
    if i <= 3 && ~strcmp(tfmode,'plain')
        Ms = fitlm(Z,dfo_tf(2,y0,1),'quadratic');
        qs = loo_r2o(Ms,y0,2);
        qcmp(i,:) = [qi qs];
        if strcmp(tfmode,'sqrt') || qs > qi
            Mi = Ms;  qi = qs;  tf(i) = 2;
        end
    end
    if i == 6
        M2 = fitlm(dfo_feat(Z,lo,hi,2),y,'quadratic');
        M3 = fitlm(dfo_feat(Z,lo,hi,3),y);
        qq = [qi loo_r2(M2,y) loo_r2(M3,y)];
        [~,tss_mode] = max(qq);
        if tss_mode == 2, Mi = M2; elseif tss_mode == 3, Mi = M3; end
        qi = qq(tss_mode);
    end
    M{i} = Mi;  q2(i) = qi;
    rm(i)  = loo_rmse(Mi);
    rmo(i) = loo_rmso(Mi,y0,tf(i));
    infl(i) = max(1, rm(i)/Mi.RMSE);
end
F = struct('M',{M},'tf',tf,'tss_mode',tss_mode,'lo',lo,'hi',hi,'loo_r2',q2,'loo_rmse',rm,'loo_rmso',rmo,'infl',infl, ...
    'n',size(R,1),'nm',{nm},'qcmp',qcmp,'tfmode',tfmode);
if verbose
    sc = {'plain','sqrt','log'};  scl = @(c) sc{1 + (c==2) + 2*(c==1)};
    fprintf('\nSurfaces fitted to %d runs (leave-one-out = honest test; below about 0.8 a surface is not trustworthy)\n',size(R,1));
    fprintf('Response | scale | R2    | LOO R2 | LOO error (natural units) | margin widening | runs used\n');
    for i = 1:6
        fprintf('%-8s | %-5s | %.3f | %.3f  | %-25.3g | %-15.2f | %d\n',nm{i},scl(tf(i)),M{i}.Rsquared.Ordinary,q2(i),rmo(i),infl(i),nuse(i));
    end
    for i = 1:3
        if ~isnan(qcmp(i,1))
            fprintf('  %s: leave-one-out R2 (natural units) plain %.3f, square-root %.3f -> %s used\n',nm{i},qcmp(i,1),qcmp(i,2),scl(tf(i)));
        end
    end
    fprintf('Solids: form %d used (leave-one-out R2 on the log scale: form 1 %.3f, form 2 %.3f, form 3 %.3f)\n',tss_mode,qq);
end
end

function q = loo_r2(Mdl,y)
    h = Mdl.Diagnostics.Leverage;  e = Mdl.Residuals.Raw;
    q = 1 - sum((e./(1-h)).^2)/sum((y-mean(y)).^2);
end

function q = loo_r2o(Mdl,y0,code)
    % leave-one-out R2 on the natural scale for a model fitted on the transformed scale
    h = Mdl.Diagnostics.Leverage;  e = Mdl.Residuals.Raw;
    yl = dfo_tf(code, dfo_tf(code,y0,1) - e./(1-h), -1);
    q = 1 - sum((y0-yl).^2)/sum((y0-mean(y0)).^2);
end

function r = loo_rmse(Mdl)
    h = Mdl.Diagnostics.Leverage;  e = Mdl.Residuals.Raw;
    r = sqrt(mean((e./(1-h)).^2));
end

function r = loo_rmso(Mdl,y0,code)
    h = Mdl.Diagnostics.Leverage;  e = Mdl.Residuals.Raw;
    yl = dfo_tf(code, dfo_tf(code,y0,1) - e./(1-h), -1);
    r = sqrt(mean((y0-yl).^2));
end
