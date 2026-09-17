%% pareto_front_OCI_EQI.m
% Epsilon-constraint sweep to trace the OCI-vs-EQI Pareto front.
%
% Approach: for a range of EQI_max values, solve
%   min OCI(KLa,Qintr)
%   s.t. EQI(KLa,Qintr) <= EQI_max
%        TN_min <= TN(KLa,Qintr) <= TN_max
%        SNH95(KLa,Qintr) <= 4
% Sweeping EQI_max traces out the trade-off curve between OCI and EQI --
% this is your approximate Pareto front.
%
% Requires the same mdl_OCI_v2, mdl_EQI_v2, mdl_TN_v2, mdl_SNH_v2 objects
% used in constrained_rsm_optimum.m (loaded from final_models.mat).

load final_models.mat mdl_SNH_v2 mdl_TN_v2 mdl_OCI_v2 mdl_EQI_v2

%% ---- Fixed bounds (same as your single-point script) ----
TN_min  = -Inf;
TN_max  = 18;          % <<< set to 10 if sweeping the future/stricter limit instead
SNH95_max = 4;         % hard regulatory limit -- do not relax without reason

KLa_lb = 50;    KLa_ub = 80;
Qintr_lb = 9223; Qintr_ub = 55338;

lb = [KLa_lb, Qintr_lb];
ub = [KLa_ub, Qintr_ub];

%% ---- EDIT THESE: range of EQI targets to sweep across ----
% Pick this range based on what's achievable in your tested grid --
% e.g., run once with a very loose EQI_max first to see the unconstrained
% OCI-optimal EQI, and once with a very tight EQI_max to find the
% best-possible EQI, then set n_points values between those.
EQI_max_values = linspace(2000, 10000, 15);   % <<< PLACEHOLDER -- adjust range

%% ---- Sweep ----
n = length(EQI_max_values);
OCI_results   = nan(n,1);
EQI_results   = nan(n,1);
TN_results    = nan(n,1);
SNH95_results = nan(n,1);
KLa_results   = nan(n,1);
Qintr_results = nan(n,1);
exitflags     = nan(n,1);

objfun = @(x) predict(mdl_OCI_v2, table(x(1), x(2), 'VariableNames', {'KLa','Qintr'}));

options = optimoptions('fmincon', 'Algorithm', 'sqp', 'Display', 'off');

x0 = [57, 29070];   % initial guess -- reused each iteration; re-warm-started below

for i = 1:n
    EQI_max = EQI_max_values(i);

    confun = @(x) build_constraints(x, mdl_EQI_v2, mdl_TN_v2, mdl_SNH_v2, ...
                                     -Inf, EQI_max, TN_min, TN_max, SNH95_max);

    [x_opt, OCI_opt, exitflag] = fmincon(objfun, x0, [], [], [], [], lb, ub, confun, options);

    exitflags(i) = exitflag;
    if exitflag > 0
        xt_opt = table(x_opt(1), x_opt(2), 'VariableNames', {'KLa','Qintr'});
        OCI_results(i)   = OCI_opt;
        EQI_results(i)   = predict(mdl_EQI_v2, xt_opt);
        TN_results(i)    = predict(mdl_TN_v2, xt_opt);
        SNH95_results(i) = predict(mdl_SNH_v2, xt_opt);
        KLa_results(i)   = x_opt(1);
        Qintr_results(i) = x_opt(2);
        x0 = x_opt;   % warm-start next iteration from this solution -- faster & more stable
    else
        fprintf('EQI_max = %.1f: infeasible (exitflag=%d)\n', EQI_max, exitflag);
    end
end

%% ---- Collect into a table for easy inspection/export ----
ParetoTable = table(EQI_max_values(:), KLa_results, Qintr_results, ...
                     OCI_results, EQI_results, TN_results, SNH95_results, exitflags, ...
                     'VariableNames', {'EQI_max_target','KLa','Qintr', ...
                                        'OCI','EQI_achieved','TN','SNH95','exitflag'});
disp(ParetoTable);

% Optional: save results for your thesis writeup
% writetable(ParetoTable, 'pareto_front_results.csv');

%% ---- Plot the Pareto front ----
figure;
valid = exitflags > 0;
plot(EQI_results(valid), OCI_results(valid), 'o-', 'LineWidth', 1.5, 'MarkerFaceColor', 'auto');
xlabel('EQI');
ylabel('OCI');
title('Approximate Pareto Front: OCI vs. EQI');
grid on;

%% ---- Local function: build only the finite (active) constraint rows ----
function [c, ceq] = build_constraints(x, mdl_EQI, mdl_TN, mdl_SNH, ...
                                       EQI_min, EQI_max, TN_min, TN_max, SNH95_max)
    xt = table(x(1), x(2), 'VariableNames', {'KLa','Qintr'});
    EQI_pred   = predict(mdl_EQI, xt);
    TN_pred    = predict(mdl_TN,  xt);
    SNH95_pred = predict(mdl_SNH, xt);

    c = [];
    if isfinite(EQI_max), c = [c; EQI_pred - EQI_max]; end
    if isfinite(EQI_min), c = [c; EQI_min - EQI_pred]; end
    if isfinite(TN_max),  c = [c; TN_pred  - TN_max];  end
    if isfinite(TN_min),  c = [c; TN_min   - TN_pred]; end
    c = [c; SNH95_pred - SNH95_max];   % hard compliance -- always included

    ceq = [];
end