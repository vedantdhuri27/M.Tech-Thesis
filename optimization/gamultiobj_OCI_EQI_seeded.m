%% gamultiobj_OCI_EQI.m
% Global multi-objective search for the OCI-EQI Pareto front using NSGA-II
% (via gamultiobj), with a FIXED RNG SEED for reproducibility and an
% explicit, programmatic extraction of the three representative points
% (EQI-optimal end, knee point, OCI-optimal end) used in the summary table.

rng(42);   % <-- FIXED SEED: without this, gamultiobj's random population
           % init/crossover/mutation gives a different front every run,
           % which is why earlier runs didn't reproduce the same table.

load final_models.mat mdl_SNH_v2 mdl_TN_v2 mdl_OCI_v2 mdl_EQI_v2

%% ---- Baseline (fixed aeration, no optimization) ----
% Used only for the Delta-OCI / Delta-EQI columns in the summary table.
OCI_baseline = 31570;
EQI_baseline = 2423;

%% ---- Bounds (same as before) ----
KLa_lb = 50;    KLa_ub = 80;
Qintr_lb = 9223; Qintr_ub = 55338;
lb = [KLa_lb, Qintr_lb];
ub = [KLa_ub, Qintr_ub];
TN_max = 18;
SNH95_max = 4;

%% ---- Objective: both OCI and EQI, returned together ----
objfun = @(x) [ ...
    predict(mdl_OCI_v2, table(x(1), x(2), 'VariableNames', {'KLa','Qintr'})), ...
    predict(mdl_EQI_v2, table(x(1), x(2), 'VariableNames', {'KLa','Qintr'})) ...
];

%% ---- Constraints: SNH95 <= 4 (hard), TN <= 18 ----
nonlcon = @(x) deal([ ...
    predict(mdl_SNH_v2, table(x(1), x(2), 'VariableNames', {'KLa','Qintr'})) - SNH95_max; ...
    predict(mdl_TN_v2,  table(x(1), x(2), 'VariableNames', {'KLa','Qintr'})) - TN_max ...
], []);

%% ---- Run NSGA-II ----
options = optimoptions('gamultiobj', ...
'PopulationSize', 200, ...     % larger pop = better front coverage, slower run
'ParetoFraction', 0.5, ...     % fraction of population kept on the front each gen
'MaxGenerations', 300, ...
'FunctionTolerance', 1e-6, ...
'Display', 'iter', ...
'PlotFcn', @gaplotpareto);     % live plot of the front as it converges

[x_pareto, f_pareto, exitflag, output] = gamultiobj(objfun, 2, [], [], [], [], lb, ub, nonlcon, options);

%% ---- Collect results ----
KLa_p   = x_pareto(:,1);
Qintr_p = x_pareto(:,2);
OCI_p   = f_pareto(:,1);
EQI_p   = f_pareto(:,2);

SNH95_p = arrayfun(@(i) predict(mdl_SNH_v2, table(KLa_p(i), Qintr_p(i), 'VariableNames', {'KLa','Qintr'})), 1:length(KLa_p))';
TN_p    = arrayfun(@(i) predict(mdl_TN_v2,  table(KLa_p(i), Qintr_p(i), 'VariableNames', {'KLa','Qintr'})), 1:length(KLa_p))';

ParetoTable = table(KLa_p, Qintr_p, OCI_p, EQI_p, SNH95_p, TN_p, ...
'VariableNames', {'KLa','Qintr','OCI','EQI','SNH95','TN'});
ParetoTable = sortrows(ParetoTable, 'EQI');   % sort by EQI for easy reading
disp(ParetoTable)
writetable(ParetoTable, 'gamultiobj_pareto_results.csv');

%% ---- Extract the three representative points programmatically ----
% 1) EQI-optimal end  : minimum EQI on the front (first row once sorted by EQI)
% 2) OCI-optimal end  : minimum OCI on the front (last row once sorted by EQI,
%                        since OCI and EQI trade off monotonically along a
%                        well-formed front)
% 3) Knee point       : point of maximum trade-off curvature, found by
%                        min-max normalizing both objectives to [0,1] using
%                        the front's own range, then picking the point
%                        closest to the ideal/utopia corner (0,0). This is
%                        the standard "distance-to-utopia" knee criterion
%                        and is deterministic given a fixed front.

OCI_n = (OCI_p - min(OCI_p)) / (max(OCI_p) - min(OCI_p));
EQI_n = (EQI_p - min(EQI_p)) / (max(EQI_p) - min(EQI_p));
dist_utopia = sqrt(OCI_n.^2 + EQI_n.^2);
[~, idx_knee] = min(dist_utopia);

idx_eqi_opt = 1;                 % first row after sortrows(...,'EQI') ascending
idx_oci_opt = height(ParetoTable);  % last row

rows = [idx_eqi_opt, idx_knee, idx_oci_opt];
labels = {'NSGA-II Pareto front -- EQI-optimal end', ...
          'NSGA-II Pareto front -- recommended knee point', ...
          'NSGA-II Pareto front -- OCI-optimal end'};

SummaryTable = ParetoTable(rows, {'KLa','Qintr','OCI','EQI'});
SummaryTable.Method = labels';
SummaryTable.DeltaOCI_pct = 100 * (SummaryTable.OCI - OCI_baseline) / OCI_baseline;
SummaryTable.DeltaEQI_pct = 100 * (SummaryTable.EQI - EQI_baseline) / EQI_baseline;
SummaryTable = SummaryTable(:, {'Method','KLa','Qintr','OCI','DeltaOCI_pct','EQI','DeltaEQI_pct'});

disp(SummaryTable)
writetable(SummaryTable, 'gamultiobj_summary_table.csv');

%% ---- Plot: front with the three selected points highlighted ----
figure;
scatter(EQI_p, OCI_p, 40, 'filled'); hold on
scatter(EQI_p(idx_eqi_opt), OCI_p(idx_eqi_opt), 120, 'g', 'filled', 'p');
scatter(EQI_p(idx_knee),    OCI_p(idx_knee),    120, 'b', 'filled', 'p');
scatter(EQI_p(idx_oci_opt), OCI_p(idx_oci_opt), 120, 'r', 'filled', 'p');
xlabel('EQI'); ylabel('OCI');
title('NSGA-II Pareto Front with Selected Representative Points');
legend('Full front', 'EQI-optimal end', 'Knee point', 'OCI-optimal end', 'Location','best');
grid on