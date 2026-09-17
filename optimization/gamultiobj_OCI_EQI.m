%% gamultiobj_OCI_EQI.m
% Global multi-objective search for the OCI-EQI Pareto front using NSGA-II
% (via gamultiobj), replacing the manual epsilon-constraint sweep.

rng(42);   % <-- FIXED SEED: without this, gamultiobj's random population
           % init/crossover/mutation gives a different front every run,
           % which is why earlier runs didn't reproduce the same table.
load final_models.mat mdl_SNH_v2 mdl_TN_v2 mdl_OCI_v2 mdl_EQI_v2

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

% Also compute SNH95/TN at each front point for the diagnostic check
SNH95_p = arrayfun(@(i) predict(mdl_SNH_v2, table(KLa_p(i), Qintr_p(i), 'VariableNames', {'KLa','Qintr'})), 1:length(KLa_p))';
TN_p    = arrayfun(@(i) predict(mdl_TN_v2,  table(KLa_p(i), Qintr_p(i), 'VariableNames', {'KLa','Qintr'})), 1:length(KLa_p))';

ParetoTable = table(KLa_p, Qintr_p, OCI_p, EQI_p, SNH95_p, TN_p, ...
    'VariableNames', {'KLa','Qintr','OCI','EQI','SNH95','TN'});
ParetoTable = sortrows(ParetoTable, 'EQI');   % sort by EQI for easy reading
disp(ParetoTable)

writetable(ParetoTable, 'gamultiobj_pareto_results.csv');

%% ---- Plot: compare against your epsilon-constraint result ----
figure;
scatter(EQI_p, OCI_p, 40, 'filled'); hold on
scatter(3624.9, 15702, 100, 'r', 'filled', 'p');   % your earlier OCI-optimal
scatter(3142.9, 16091, 100, 'm', 'filled', 'p');   % your earlier interior point
xlabel('EQI'); ylabel('OCI');
title('NSGA-II Pareto Front vs. Earlier Epsilon-Constraint Points');
legend('gamultiobj front', 'Earlier OCI-optimal', 'Earlier interior point', 'Location','best');
grid on