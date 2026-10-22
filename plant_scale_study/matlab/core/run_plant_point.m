%% run_plant_point.m -- ONE place for the simulation protocol (run as a script)
% FASTER VERSION (Oct 2026): the 100-day constant-influent stage now uses ode15s (stiff solver), the dynamic stages keep ode45.
% Timing test (V1, 24 C): 100 d stage 230 s -> 4.4 s, all results identical to the printed digits. Whole run about 5 times faster.
% To get the old behaviour set rp_sol2 = 'ode45' before the call. The time of each stage is left in
% rp_tm = [steady state, 100 d constant, 14 d dynamic, performance] (seconds). Nothing else changed from the previous runner.
% Set before calling:
%   rp_KLa, rp_Qintr   operating point
%   rp_T               plant temperature, deg C (written into influent column 16)
%   rp_scen            'const' | 'dry' | 'rain' | 'storm'
%   rp_infl            'standard' | 'surat'
%   rp_protocol        'sweep' (steady state -> 14 d -> 14 d, as in your grid sweep)
%                      'bsm1'  (steady state -> 100 d constant -> 14 d)
%   rp_quiet           true = suppress the long plant report (optional)
% Result: struct rp_R
% --- model guard: make sure the model reads CONSTINFLUENT, not a weather file directly
load_system('benchmark');
rp_sw = find_system('benchmark','SearchDepth',1,'BlockType','ManualSwitch');
if numel(rp_sw) ~= 7, error('Expected 7 manual switches, found %d', numel(rp_sw)); end
rp_target = [1 0 0 0 0 1 0];
for rp_gi = 1:7, set_param(rp_sw{rp_gi},'sw',num2str(rp_target(rp_gi))); end
benchmarkinit_noclear;                      % resets everything, loads standard influents

if strcmp(rp_infl,'surat')
    rp_S = load('surat_influents.mat');
    rp_INF = struct('const',rp_S.CONST_SURAT,'dry',rp_S.DRY_SURAT, ...
                    'rain',rp_S.RAIN_SURAT,'storm',rp_S.STORM_SURAT);
else
    rp_INF = struct('const',CONSTINFLUENT,'dry',DRYINFLUENT, ...
                    'rain',RAININFLUENT,'storm',STORMINFLUENT);
end
rp_fn = fieldnames(rp_INF);
for rp_k = 1:numel(rp_fn)
    rp_INF.(rp_fn{rp_k})(:,16) = rp_T;      % temperature travels with the influent file
end
if exist('rp_flowscale','var') && ~isempty(rp_flowscale)
    for rp_k = 1:numel(rp_fn), rp_INF.(rp_fn{rp_k})(:,15) = rp_INF.(rp_fn{rp_k})(:,15)*rp_flowscale; end
end
KLa3 = rp_KLa; KLa4 = rp_KLa; KLa5 = rp_KLa;
Qintr = rp_Qintr;
% optional parameter overrides, e.g. rp_over.mu_A = 0.8; rp_over.Qw = 600
if exist('rp_over','var') && ~isempty(rp_over)
    rp_nm = fieldnames(rp_over);
    for rp_k2 = 1:numel(rp_nm)
        eval([rp_nm{rp_k2} ' = rp_over.' rp_nm{rp_k2} ';']);
    end
    PAR1 = [ k_H K_X k_STO ny_NOX K_O2 K_NOX K_S K_STO mu_H K_NH4 K_ALK b_HO2 b_HNOX b_STOO2 b_STONOX mu_A K_ANH4 K_AO2 K_AALK b_AO2 b_ANOX f_SI Y_STOO2 Y_STONOX Y_HO2 Y_HNOX Y_A f_XI i_NSI i_NSS i_NXI i_NXS i_NBM i_SSXI i_SSXS i_SSBM i_SSSTO ];
    PAR2 = PAR1; PAR3 = PAR1; PAR4 = PAR1; PAR5 = PAR1;
end
% --- return flow: the Simulink constant 'Qr' reads Qin0 and ignores the workspace Qr ---
rp_qrval = 'Qin0';                                            % default = benchmark behaviour
if exist('rp_Qret','var') && ~isempty(rp_Qret), rp_qrval = num2str(rp_Qret); end
for rp_mdl = {'benchmark','benchmarkss'}
    try, load_system(rp_mdl{1}); set_param([rp_mdl{1} '/Qr'],'Value',rp_qrval); catch, end
end
if ~exist('rp_sol2','var') || isempty(rp_sol2), rp_sol2 = 'ode15s'; end   % 100-day constant-influent stage
if ~exist('rp_sol3','var') || isempty(rp_sol3), rp_sol3 = 'ode45';  end   % dynamic stages (14 d)
rp_tm = nan(1,4);
% 1) steady state, constant influent
CONSTINFLUENT = rp_INF.const;
rp_o1 = simset('solver','ode15s','Reltol',1e-5,'AbsTol',1e-8,'refine',1);
rp_t0 = tic; benchmarkss; sim('benchmarkss',[0 200],rp_o1); stateset; rp_tm(1) = toc(rp_t0);

rp_out = 0:(1/96):14;
rp_o3 = simset('solver',rp_sol3,'Reltol',1e-5,'AbsTol',1e-8,'outputpoints','specified');

if strcmp(rp_protocol,'bsm1')
    rp_o2 = simset('solver',rp_sol2,'Reltol',1e-5,'AbsTol',1e-8);
    rp_t0 = tic; benchmark; sim('benchmark',[0 100],rp_o2); stateset; rp_tm(2) = toc(rp_t0);
    CONSTINFLUENT = rp_INF.(rp_scen);
    rp_t0 = tic; sim('benchmark',rp_out,rp_o3); rp_tm(3) = toc(rp_t0);
else
    CONSTINFLUENT = rp_INF.(rp_scen);
    benchmark; sim('benchmark',rp_out,rp_o3); stateset;
    sim('benchmark',rp_out,rp_o3);
end

clear SNHviolation;
rp_t0 = tic;
if exist('rp_quiet','var') && rp_quiet, evalc('perf_plant;'); else, perf_plant; end
rp_tm(4) = toc(rp_t0);
fprintf('[runner] influent S_I mean=%.2f | effluent S_I=%.2f | T mean=%.1f\n', ...
    mean(CONSTINFLUENT(:,3)), SIeav, mean(CONSTINFLUENT(:,16)));

rp_TN = SNOeav + SNHeav + i_NSI*SIeav + i_NSS*SSeav + i_NXI*XIeav + i_NXS*XSeav + i_NBM*(XBHeav+XBAeav);
if exist('SNHviolation','var') && ~isempty(SNHviolation)
    rp_viol = min(totalt, length(SNHviolation)*sampletime);
else
    rp_viol = 0;
end
rp_R = struct('KLa',rp_KLa,'Qintr',rp_Qintr,'T',rp_T,'scen',rp_scen,'infl',rp_infl, ...
    'protocol',rp_protocol,'SNHavg',SNHeav,'SNH95',SNHeffprctile,'TNavg',rp_TN, ...
    'TN95',TNeffprctile,'OCI',OCI_new,'EQI',EQ_new,'DO',SOeav,'XBA',XBAeav, ...
    'SNHviol_days',rp_viol);

if exist('TSSeffprctile','var'), rp_R.TSS95 = TSSeffprctile; else, rp_R.TSS95 = NaN; end
rp_R.Qw = Qw;