function v = dfo_tf(code, v, dirn)
%DFO_TF  Response transform used by the fitted surfaces. Helper for dfo_fit / dfo_pred.
%   code  0 = none, 1 = natural log, 2 = square root
%   dirn  1 = to the fitted scale, -1 = back to natural units
%   Solids (TSS95) are always fitted on the log scale, as in design_fit_optimize_v2.m. Ammonia and TN95 use the square-root scale only
%   when it predicts better in leave-one-out (see dfo_fit).
switch code
    case 0
        return
    case 1
        if dirn > 0, v = log(v); else, v = exp(v); end
    case 2
        if dirn > 0, v = sqrt(max(v,0)); else, v = max(v,0).^2; end
    otherwise
        error('dfo_tf: unknown transform code %d',code);
end
end
