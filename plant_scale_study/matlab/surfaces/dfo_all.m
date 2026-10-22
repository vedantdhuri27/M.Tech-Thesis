function [y, yup, se] = dfo_all(F, Z, k)
%DFO_ALL  All six responses at coded points Z (n x 3), in the order used everywhere:
%   columns  1 SNH95, 2 SNHavg, 3 TN95, 4 OCI, 5 EQI, 6 TSS95
%   y    nominal predictions
%   yup  predictions with k standard errors of margin added on each response's fitted scale and taken back to natural units; OCI and EQI carry it too, but it is not used
%   se   standard errors of a new simulation on the fitted scale (natural units, square-root units or log units, see dfo_fit), see dfo_pred
if nargin < 3, k = 0; end
n = size(Z,1);
y = nan(n,6);  yup = nan(n,6);  se = nan(n,6);
for i = 1:6
    [y(:,i), se(:,i), yup(:,i)] = dfo_pred(F,i,Z,k);
end
end
