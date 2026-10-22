function X = dfo_feat(Z, lo, hi, mode)
%DFO_FEAT  Predictors for the effluent-solids (TSS95) surface. Helper for dfo_fit / dfo_pred.
%   Z    coded variables, n x 3 (KLa, Qintr, Qw), each scaled 0 to 1 between lo and hi
%   mode 1: Z itself                         (quadratic in KLa, Qintr, Qw)
%        2: [KLa Qintr 1/Qw]                 (quadratic; sludge age goes as 1/Qw)
%        3: [u u^2 u^3 k k^2 k*u]            (u = coded 1/Qw, k = coded KLa; cubic in 1/Qw plus aeration terms, fitted as a linear model)
%   Same three forms as design_fit_optimize_v2.m.
q = Z(:,3)*(hi(3)-lo(3)) + lo(3);                     % waste flow in m3/d
u = (1./q - 1/hi(3)) / (1/lo(3) - 1/hi(3));            % 1/Qw coded 0 to 1
switch mode
    case 1
        X = Z;
    case 2
        X = [Z(:,1:2) u];
    otherwise
        k = Z(:,1);
        X = [u u.^2 u.^3 k k.^2 k.*u];
end
end
