%% robust_check.m
% STEP 5: is a chosen operating point still good when the weather or the nitrifier growth rate is not what the optimiser assumed?
% Takes the candidate points from opt_margin.m (the margin picks), plus the plant as operated for reference, and re-simulates each with the
% real model in:
%     dry, rain, storm weather                      (growth rate at its standard value)
%     dry weather with the growth rate x0.8 and x1.2 (at 24 C: 0.36 and 0.54 per day against the standard 0.447)
% Then reports, for every point, how far the WORST of those cases is from the limits, and picks the point whose worst case is best.
% 5 cases x (up to 5 candidates + the plant) = up to 30 runs, roughly 30 minutes. Saved after every run; finished runs are skipped on restart.
% Combined cases (rain AND a slow growth rate at the same time) are not simulated, so "worst" means worst of the cases listed.
% Needs run_plant_point.m (with the rp_Qret and rp_over patches) and sim_point.m in the same folder.
clear all; close all;
rp_quiet = true;
set(0,'DefaultFigureVisible','off');
rb_dir = fileparts(which('run_plant_point'));
if isempty(rb_dir), error('run_plant_point.m not found: set the current folder to the folder that holds it and run again.'); end

%% ---- settings ---------------------------------------------------------------------------------
rb_T     = 24;                 % 24 or 30
rb_A     = 1225;               % clarifier area (m2). Run it again with 2566 after the area runs to see what the larger clarifier does to wet weather.
rb_k     = 1;                  % use the picks made with these margins in opt_margin.m (e.g. [1 2] for more candidates)
rb_maxC  = 5;                  % at most this many candidates
rb_scen  = {'dry','rain','storm'};
rb_fac   = [0.8 1.2];          % extra dry-weather cases: effective growth rate x this factor
rb_plant = true;               % also run the plant as operated (KLa 167, Qintr 65000, Qw 1090) as a reference

%% ---- candidates --------------------------------------------------------------------------------
rb_X = zeros(0,3);  rb_lab = cell(0,1);
rb_src = sprintf('opt_margin_T%d_A%d.mat',rb_T,rb_A);
if exist(rb_src,'file')
    rb_M = load(rb_src);
    for rb_j = 1:numel(rb_M.picks)
        rb_p = rb_M.picks(rb_j);
        if ~rb_p.ok || ~ismember(rb_p.k,rb_k), continue; end
        rb_txt = sprintf('%s k=%g',rb_p.mode,rb_p.k);
        rb_hit = find(all(abs(rb_X - rb_p.x) < 1e-9,2),1);
        if isempty(rb_hit)
            rb_X(end+1,:) = rb_p.x;  rb_lab{end+1,1} = rb_txt;                 %#ok<SAGROW>
        else
            rb_lab{rb_hit} = [rb_lab{rb_hit} ' / ' rb_txt];
        end
    end
    fprintf('Candidates taken from %s (picks with k = %s)\n',rb_src,mat2str(rb_k));
end
if isempty(rb_X)
    fprintf('No candidates from opt_margin.m: using the points already verified earlier.\n');
    if rb_T == 24
        rb_X = [154.5 42775 224; 150.8 64486 315; 143.1 22425 460];  rb_lab = {'V1';'V2';'V3'};
    else
        rb_X = [151.4 38708 315; 150.1 44575 384; 122.1 55208 425];  rb_lab = {'V1';'V2';'V3'};
    end
end
if size(rb_X,1) > rb_maxC, rb_X = rb_X(1:rb_maxC,:);  rb_lab = rb_lab(1:rb_maxC); end
rb_isplant = false(size(rb_X,1),1);
if rb_plant
    rb_X(end+1,:) = [167 65000 1090];  rb_lab{end+1,1} = 'plant as operated';  rb_isplant(end+1,1) = true;
end
rb_nC = size(rb_X,1);

%% ---- scenarios ---------------------------------------------------------------------------------
rb_sw = {};  rb_sf = [];  rb_sn = {};
for rb_j = 1:numel(rb_scen)
    rb_sw{end+1} = rb_scen{rb_j};  rb_sf(end+1) = 1;  rb_sn{end+1} = rb_scen{rb_j};                                       %#ok<SAGROW>
end
for rb_j = 1:numel(rb_fac)
    rb_sw{end+1} = 'dry';  rb_sf(end+1) = rb_fac(rb_j);  rb_sn{end+1} = sprintf('mu x%.1f',rb_fac(rb_j));                  %#ok<SAGROW>
end
rb_nS = numel(rb_sw);
rb_mu0 = 0.68*exp(log(1/0.35)/10*(rb_T-28));              % standard effective growth rate at this temperature

%% ---- resume ------------------------------------------------------------------------------------
rb_file = sprintf('robust_T%d_A%d.mat',rb_T,rb_A);
rb_out = nan(rb_nC,rb_nS,6);                              % SNH95 SNHavg TN95 TSS95 OCI DO
if exist(rb_file,'file')
    rb_O = load(rb_file);
    if isequal(size(rb_O.rb_X),size(rb_X)) && all(abs(rb_O.rb_X(:)-rb_X(:)) < 1e-9) && isequal(rb_O.rb_sn,rb_sn)
        rb_out = rb_O.rb_out;
        fprintf('Resuming: %d of %d runs already done.\n',nnz(~isnan(rb_out(:,:,1))),rb_nC*rb_nS);
    end
end

%% ---- run ---------------------------------------------------------------------------------------
fprintf('\nT=%d C, clarifier %d m2, standard effective mu_A %.3f   (limits: SNH95 4, SNHavg 4, TN95 18, TSS95 30)\n',rb_T,rb_A,rb_mu0);
fprintf(' point                    | case     |  KLa  | Qintr |  Qw | SNH95 | SNHavg |  TN95 | TSS95 |   DO |  OCI\n');
for rb_c = 1:rb_nC
    for rb_s = 1:rb_nS
        if ~isnan(rb_out(rb_c,rb_s,1)), continue; end
        sp_KLa = rb_X(rb_c,1);  sp_Qintr = rb_X(rb_c,2);  sp_Qw = rb_X(rb_c,3);
        sp_T = rb_T;  sp_A = rb_A;  sp_scen = rb_sw{rb_s};  sp_mu = rb_mu0*rb_sf(rb_s);  sp_dir = rb_dir;
        sim_point;
        if ~sp_ok
            fprintf(' %-24s | %-8s | run failed: %s\n',rb_lab{rb_c},rb_sn{rb_s},sp_msg);
            fprintf('      pwd = %s | which run_plant_point = %s\n',pwd,which('run_plant_point'));
            continue;
        end
        rb_out(rb_c,rb_s,:) = [sp_row(5) sp_row(6) sp_row(11) sp_row(13) sp_row(9) sp_row(7)];
        fprintf(' %-24s | %-8s | %5.1f | %5.0f | %3.0f | %5.2f | %6.2f | %5.1f | %5.1f | %4.2f | %5.0f\n', ...
            rb_lab{rb_c},rb_sn{rb_s},rb_X(rb_c,:),rb_out(rb_c,rb_s,1),rb_out(rb_c,rb_s,2),rb_out(rb_c,rb_s,3), ...
            rb_out(rb_c,rb_s,4),rb_out(rb_c,rb_s,6),rb_out(rb_c,rb_s,5));
        save(rb_file,'rb_out','rb_X','rb_lab','rb_sn','rb_sw','rb_sf','rb_T','rb_A','rb_isplant');
    end
end

%% ---- summary: distance of the worst case from the limits -----------------------------------------
rb_bn = {'SNHavg','TN95','TSS95'};  rb_bs = {'SNH95','TN95','TSS95'};
rb_vp = nan(rb_nC,rb_nS);  rb_vs = nan(rb_nC,rb_nS);  rb_ip = nan(rb_nC,rb_nS);  rb_is = nan(rb_nC,rb_nS);
for rb_c = 1:rb_nC
    for rb_s = 1:rb_nS
        rb_a = [rb_out(rb_c,rb_s,2)/4  rb_out(rb_c,rb_s,3)/18  rb_out(rb_c,rb_s,4)/30];
        [rb_m,rb_i] = max(rb_a);  rb_vp(rb_c,rb_s) = rb_m - 1;  rb_ip(rb_c,rb_s) = rb_i;
        rb_a = [rb_out(rb_c,rb_s,1)/4  rb_out(rb_c,rb_s,3)/18  rb_out(rb_c,rb_s,4)/30];
        [rb_m,rb_i] = max(rb_a);  rb_vs(rb_c,rb_s) = rb_m - 1;  rb_is(rb_c,rb_s) = rb_i;
    end
end
rb_dm = find(strcmp(rb_sw,'dry'));                         % dry-weather cases (standard growth rate and the two growth-rate cases)
if any(isnan(rb_out(:))), fprintf('\nWARNING: %d of %d runs are missing; the worst cases below ignore them. Run the script again to fill them in.\n',nnz(isnan(rb_out(:,:,1))),rb_nC*rb_nS); end
for rb_form = 1:2
    if rb_form == 1
        rb_v = rb_vp;  rb_ii = rb_ip;  rb_nmx = rb_bn;
        fprintf('\nPRACTICAL TARGET (SNHavg<=4, TN95<=18, TSS95<=30): worst metric against its limit, %% over (+) or under (-), and which metric it is\n');
    else
        rb_v = rb_vs;  rb_ii = rb_is;  rb_nmx = rb_bs;
        fprintf('\nSTRICT LIMITS (SNH95<=4, TN95<=18, TSS95<=30): worst metric against its limit, %% over (+) or under (-), and which metric it is\n');
    end
    fprintf(' %-24s |',' point');  fprintf(' %-13s |',rb_sn{:});  fprintf(' worst, all | worst, dry only\n');
    for rb_c = 1:rb_nC
        fprintf(' %-24s |',rb_lab{rb_c});
        for rb_s = 1:rb_nS
            fprintf(' %+5.0f%% %-6s |',100*rb_v(rb_c,rb_s),rb_nmx{rb_ii(rb_c,rb_s)});
        end
        fprintf(' %+7.0f%%   | %+7.0f%%\n',100*max(rb_v(rb_c,:)),100*max(rb_v(rb_c,rb_dm)));
    end
    rb_cand = find(~rb_isplant);
    if ~isempty(rb_cand)
        [~,rb_b1] = min(max(rb_v(rb_cand,:),[],2));
        [~,rb_b2] = min(max(rb_v(rb_cand,rb_dm),[],2));
        rb_c1 = rb_cand(rb_b1);  rb_c2 = rb_cand(rb_b2);
        fprintf('  Best worst case over ALL cases:            %s  (KLa %.1f, Qintr %.0f, Qw %.0f), worst metric %+.0f%%\n',rb_lab{rb_c1},rb_X(rb_c1,:),100*max(rb_v(rb_c1,:)));
        fprintf('  Best worst case over DRY-weather cases:    %s  (KLa %.1f, Qintr %.0f, Qw %.0f), worst metric %+.0f%%\n',rb_lab{rb_c2},rb_X(rb_c2,:),100*max(rb_v(rb_c2,rb_dm)));
    end
end
fprintf('\n0%% means exactly on a limit, negative means inside all three limits. If every candidate fails in rain and storm because of TSS95 while the\n');
fprintf('dry-weather and growth-rate cases pass, the weakness is the clarifier area, not the operating point: repeat with rb_A = 2566.\n');
fprintf('\nSaved %s\n',rb_file);
