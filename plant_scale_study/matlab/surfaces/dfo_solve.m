function out = dfo_solve(F, mode, k, nstart, seed, lim)
%DFO_SOLVE  Constrained optimum on the fitted surfaces (fmincon sqp, random multistart), with an optional safety margin.
%   F       struct from dfo_fit
%   mode    'A'  cheapest (lowest OCI) point with SNH95 <= 4, TN95 <= 18, TSS95 <= 30                (strict limits)
%           'B'  point with the smallest worst relative violation of those three limits               (if A has no solution)
%           'D'  cheapest point with SNHavg <= 4, TN95 <= 18, TSS95 <= 30                             (practical target)
%           'E'  point with the smallest worst relative violation of the practical target              (if D has no solution)
%           'G'  lowest SNH95 with TN95 <= 18 and TSS95 <= 30
%   k       margin in standard errors added to every CONSTRAINED response (0 = nominal; the objective is always nominal)
%   nstart  random starts (default 40)      seed  random seed (default 1)
%   lim     optional struct with fields snh95, snhavg, tn95, tss95 to change the limits (defaults 4, 4, 18, 30)
%   out     struct: ok, mode, k, z (coded), x (KLa Qintr Qw in real units), y (nominal, 1x6), yup (with margin, 1x6),
%           t (B and E only: worst relative violation with margin, negative = limits met with room to spare)
%   y and yup have the column order of dfo_all: SNH95 SNHavg TN95 OCI EQI TSS95.
if nargin < 3 || isempty(k), k = 0; end
if nargin < 4 || isempty(nstart), nstart = 40; end
if nargin < 5 || isempty(seed), seed = 1; end
L = struct('snh95',4,'snhavg',4,'tn95',18,'tss95',30);
if nargin >= 6 && ~isempty(lim)
    fn = fieldnames(lim);
    for j = 1:numel(fn), L.(fn{j}) = lim.(fn{j}); end
end
switch mode
    case {'A','B'}, idx = [1 3 6]; lm = [L.snh95  L.tn95 L.tss95]; fobj = 4;
    case {'D','E'}, idx = [2 3 6]; lm = [L.snhavg L.tn95 L.tss95]; fobj = 4;
    case 'G',       idx = [3 6];   lm = [L.tn95 L.tss95];          fobj = 1;
    otherwise, error('dfo_solve: mode must be A, B, D, E or G');
end
least = any(mode == 'BE');
zlb = [0 0 0];  zub = [1 1 1];
opt = optimoptions('fmincon','Algorithm','sqp','Display','off');
rng(seed);
bz = [];  bf = inf;  bt = NaN;
for s = 1:nstart
    z0 = zlb + rand(1,3).*(zub-zlb);
    if least
        nl = @(v) ncon(rel_con(F,idx,lm,v(1:3),k) - v(4));
        [v,~,ef] = fmincon(@(v) v(4),[z0 1],[],[],[],[],[zlb -1],[zub 10],nl,opt);
        if ef > 0 && max(rel_con(F,idx,lm,v(1:3),k) - v(4)) <= 1e-6 && v(4) < bf
            bf = v(4);  bz = v(1:3);  bt = v(4);
        end
    else
        nl = @(z) ncon(abs_con(F,idx,lm,z,k));
        [z,f,ef] = fmincon(@(z) dfo_pred(F,fobj,z),z0,[],[],[],[],zlb,zub,nl,opt);
        if ef > 0 && max(abs_con(F,idx,lm,z,k)) <= 1e-6 && f < bf
            bf = f;  bz = z;
        end
    end
end
out = struct('ok',~isempty(bz),'mode',mode,'k',k,'z',nan(1,3),'x',nan(1,3),'y',nan(1,6),'yup',nan(1,6),'t',bt);
if out.ok
    out.z = bz;
    out.x = F.lo + bz.*(F.hi-F.lo);
    [out.y,out.yup] = dfo_all(F,bz,k);
end
end

function c = abs_con(F,idx,lm,z,k)
    c = zeros(numel(idx),1);
    for j = 1:numel(idx)
        if k == 0
            yu = dfo_pred(F,idx(j),z);
        else
            [~,~,yu] = dfo_pred(F,idx(j),z,k);
        end
        c(j) = yu - lm(j);
    end
end

function c = rel_con(F,idx,lm,z,k)
    c = zeros(numel(idx),1);
    for j = 1:numel(idx)
        if k == 0
            yu = dfo_pred(F,idx(j),z);
        else
            [~,~,yu] = dfo_pred(F,idx(j),z,k);
        end
        c(j) = yu/lm(j) - 1;
    end
end

function [c,ceq] = ncon(c)
    c = c(:);  ceq = [];          % inequality constraints c <= 0, no equalities
end
