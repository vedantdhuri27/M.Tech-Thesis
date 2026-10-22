function [y, se, yup] = dfo_pred(F, i, Z, k)
%DFO_PRED  Prediction from one fitted surface, with an optional safety margin. Helper for the optimisation scripts.
%   F   struct from dfo_fit
%   i   response: 1 SNH95, 2 SNHavg, 3 TN95, 4 OCI, 5 EQI, 6 TSS95
%   Z   coded variables, n x 3 (0 to 1 between F.lo and F.hi)
%   k   margin in standard errors (default 0)
%   y   nominal prediction in natural units
%   se  standard error of ONE NEW SIMULATION at Z (prediction error, not just the error of the mean surface), widened by F.infl so it
%       is at least as large as the leave-one-out error. It is on the FITTED scale: natural units for OCI and EQI, square-root units
%       for a response fitted on the square-root scale, log units for TSS95 (so TSS95 is multiplied by exp(se)).
%   yup the value a limit is tested against when a margin is wanted: the fitted-scale prediction plus k standard errors, taken back
%       to natural units (so the margin is smaller where the response itself is small).
%   With one output only the nominal prediction is computed (faster; used inside the optimisers when k = 0).
if nargin < 4, k = 0; end
if i == 6
    X = dfo_feat(Z,F.lo,F.hi,F.tss_mode);
else
    X = Z;
end
M = F.M{i};
se = [];
if nargout <= 1
    yp = predict(M,X);
else
    try
        [yp,ci] = predict(M,X,'Alpha',0.05,'Prediction','observation');
        se = (ci(:,2)-ci(:,1))/2 / tinv(0.975,M.DFE) * F.infl(i);
    catch
        yp = predict(M,X);
        se = F.loo_rmse(i)*ones(size(yp));                  % fallback: one constant error for the whole surface
    end
end
y = dfo_tf(F.tf(i),yp,-1);
if nargout >= 3, yup = dfo_tf(F.tf(i),yp + k*se,-1); end
end
