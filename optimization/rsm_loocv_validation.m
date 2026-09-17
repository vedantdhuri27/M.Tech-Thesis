%% rsm_loocv_validation.m
% Answers the advisor's question: "training data only — what about testing?"
%
% Since the dataset is small (44 points across a structured KLa x Qintr
% grid), a single random train/test split would throw away data and be
% sensitive to which points happen to land in the test set by luck.
% Instead this uses Leave-One-Out Cross-Validation (LOOCV) via the PRESS
% statistic -- the standard validation method for small RSM designs
% (this is exactly what "Predicted R-squared" means in Design-Expert /
% Minitab output). It answers: "if this point had NOT been used to fit
% the model, how well would the model have predicted it?" -- for every
% point, without ever refitting 44 separate models by hand.
%
% Requires: your existing fitted models (mdl_SNH_v2, mdl_TN_v2,
% mdl_OCI_v2, mdl_EQI_v2) from final_models.mat -- the same objects used
% in constrained_rsm_optimum.m and pareto_front_OCI_EQI.m.

load final_models.mat mdl_SNH_v2 mdl_TN_v2 mdl_OCI_v2 mdl_EQI_v2

models = {mdl_SNH_v2, mdl_TN_v2, mdl_OCI_v2, mdl_EQI_v2};
names  = {'SNH95', 'TN avg', 'OCI', 'EQI'};

fprintf('%-10s %10s %10s %14s %14s\n', 'Response', 'Train R2', 'Pred R2 (LOOCV)', 'Train RMSE', 'LOOCV RMSE (PRESS)');
fprintf('%s\n', repmat('-', 1, 65));

for i = 1:length(models)
    mdl = models{i};

    % --- Standard (training) fit statistics -- what you already have ---
    R2_train   = mdl.Rsquared.Ordinary;
    RMSE_train = mdl.RMSE;

    % --- LOOCV via PRESS statistic ---
    % For linear (and linear-in-parameters, i.e. polynomial/RSM) models,
    % the leave-one-out predicted residual for point i can be computed
    % WITHOUT refitting, using the raw residual and the leverage (hat
    % value) of that point:
    %     e_(i) = e_i / (1 - h_ii)
    % This is a standard identity for OLS -- MATLAB's fitlm exposes both
    % residuals and leverage directly via mdl.Diagnostics.
    resid    = mdl.Residuals.Raw;
    leverage = mdl.Diagnostics.Leverage;

    press_resid = resid ./ (1 - leverage);   % leave-one-out residuals
    PRESS       = sum(press_resid.^2);       % PRESS statistic

    y      = mdl.Variables.(mdl.ResponseName);
    SST    = sum((y - mean(y)).^2);
    R2_pred = 1 - PRESS/SST;                 % "Predicted R-squared"
    n       = mdl.NumObservations;
    RMSE_loocv = sqrt(PRESS / n);

    fprintf('%-10s %10.4f %16.4f %14.3f %14.3f\n', ...
        names{i}, R2_train, R2_pred, RMSE_train, RMSE_loocv);
end

fprintf('\nInterpretation:\n');
fprintf('- "Pred R2 (LOOCV)" should be reasonably close to "Train R2".\n');
fprintf('  A large drop (e.g. Pred R2 much lower, or negative) means the\n');
fprintf('  model is overfitting -- it fits the 44 training points well but\n');
fprintf('  would predict new (KLa, Qintr) combinations poorly.\n');
fprintf('- A negative Predicted R2 means the model predicts new points\n');
fprintf('  WORSE than just guessing the mean -- a red flag worth reporting\n');
fprintf('  and investigating (usually too many terms for too few points,\n');
fprintf('  or a genuinely non-quadratic region like the KLa=50 cliff).\n');
fprintf('- Report both numbers side by side in your results table --\n');
fprintf('  this is standard practice in RSM/DOE literature and directly\n');
fprintf('  answers "what about testing data".\n');

%% ---- Optional: explicit new-point validation (stronger evidence) ----
% If you have time, the single strongest piece of evidence is picking a
% few (KLa, Qintr) combinations you have NEVER simulated, running BSM1 on
% them, and comparing to what these models predict. Example structure:
%
% new_points = table([65; 72; 55], [25000; 40000; 15000], 'VariableNames', {'KLa','Qintr'});
% predicted_OCI = predict(mdl_OCI_v2, new_points);
% % ...then compare predicted_OCI against your actual simulated OCI at
% % those points once you've run them.