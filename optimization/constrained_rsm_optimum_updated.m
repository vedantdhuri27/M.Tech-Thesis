%% constrained_rsm_optimum.m
% Solves: min OCI(KLa,Qintr)
%         s.t. EQI_min <= EQI(KLa,Qintr) <= EQI_max
%              TN_min  <= TN(KLa,Qintr)  <= TN_max
%              SNH95(KLa,Qintr) <= 4          (hard compliance -- always enforced)
%              KLa, Qintr within the TESTED range (avoids extrapolating
%              the quadratic RSM surfaces beyond where they were fit)
%
% Requires mdl_OCI_v2, mdl_EQI_v2, mdl_TN_v2 (or _avg), mdl_SNH_v2 -- the
% fitlm() model objects from your RSM fitting script (final_family_of_optima
% / run_final_surfaces_and_optimum.m). Load or re-fit them before running this.

load final_models.mat mdl_SNH_v2 mdl_TN_v2 mdl_OCI_v2 mdl_EQI_v2
% ^ if this line errors with "file not found", re-run the script that
%   creates final_models.mat first (the one loading backfill_results,
%   deep_refinement_results, and gap_fill_results, then fitting the 4
%   models and saving them to final_models.mat).

%% ---- EDIT THESE: bounds your advisor specifies ----
EQI_min = -Inf;      % likely just leave at -Inf if no real lower bound applies
EQI_max = 4000;       % <<< PLACEHOLDER -- replace with his actual target
TN_min  = -Inf;       % likely -Inf (no reason to force TN artificially high)
TN_max  = 18;         % <<< current compliance limit; use 10 for the future limit
SNH95_max = 4;        % hard regulatory limit -- do not relax this without reason

%% ---- Search bounds: MUST match your tested grid (no extrapolation) ----
KLa_lb = 50;    KLa_ub = 80;
Qintr_lb = 9223; Qintr_ub = 55338;

%% ---- Objective: minimize predicted OCI ----
objfun = @(x) predict(mdl_OCI_v2, table(x(1), x(2), 'VariableNames', {'KLa','Qintr'}));

%% ---- Nonlinear constraints ----
% IMPORTANT: fmincon's SQP algorithm cannot handle literal -Inf/+Inf values
% inside the constraint vector -- it needs every row to be a finite number,
% even ones that are trivially satisfied. Using EQI_min=-Inf directly in
% arithmetic (EQI_min - predict(...)) produces a literal -Inf entry, which
% breaks the solver's internal gradient calculations. Fix: only add a
% constraint row when the corresponding bound is actually finite.
confun = @(x) build_constraints(x, mdl_EQI_v2, mdl_TN_v2, mdl_SNH_v2, ...
                                 EQI_min, EQI_max, TN_min, TN_max, SNH95_max);

%% ---- Solve ----
x0 = [57, 29070];   % start from your known OCI-optimal-ish point -- reasonable initial guess
lb = [KLa_lb, Qintr_lb];
ub = [KLa_ub, Qintr_ub];

options = optimoptions('fmincon', 'Algorithm', 'sqp', 'Display', 'iter');
[x_opt, OCI_opt, exitflag, output] = fmincon(objfun, x0, [], [], [], [], lb, ub, confun, options);

fprintf('\n--- Constrained optimum ---\n');
if exitflag > 0
    fprintf('FEASIBLE solution found.\n');
    fprintf('KLa = %.2f, Qintr = %.0f\n', x_opt(1), x_opt(2));
    fprintf('OCI = %.2f\n', OCI_opt);

    xt_opt = table(x_opt(1), x_opt(2), 'VariableNames', {'KLa','Qintr'});
    fprintf('EQI = %.2f, TN = %.2f, SNH95 = %.3f\n', ...
        predict(mdl_EQI_v2, xt_opt), predict(mdl_TN_v2, xt_opt), predict(mdl_SNH_v2, xt_opt));
else
    fprintf('NO FEASIBLE SOLUTION found within the tested KLa/Qintr range (exitflag=%d).\n', exitflag);
    fprintf('This means the constraints (as specified) cannot all be satisfied simultaneously\n');
    fprintf('inside the region your RSM surfaces are actually validated for -- worth reporting\n');
    fprintf('to your advisor as a finding in itself, not just a coding problem to fix.\n');
end

%% ---- Local function: build only the finite (active) constraint rows ----
% NOTE: MATLAB requires local function definitions to appear at the end
% of a script file, which is why this is placed here rather than near
% its first use above.
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