%% add_verify_to_infill.m
% Puts the dry-weather results of the three verification points (V1, V2, V3 from verify_and_weather.m) into
% infill_T<av_T>_A<av_A>.mat as "round 0.5", so that the next opt_margin.m run
%   (1) uses them as a free out-of-sample test of the surfaces (they were chosen with older surfaces, and not used in these fits), and
%   (2) fits with them: they lie right at the edge of the feasible region, which is where the surfaces need the data most.
% No simulations here. Run it once per temperature, BEFORE infill_runs.m, then run opt_margin.m again.
% For 24 C it uses verify_weather_T24_A1225.mat if that file exists; otherwise the dry-weather values recorded in the handoff notes
% (SNH95, SNHavg, TN95, TSS95, OCI at 1 decimal as printed).
% Runs added this way have no EQI value: dfo_fit simply leaves them out of the EQI surface.
clear; close all; clc;

av_T = 30;                 % 24 or 30
av_A = 1225;

vfile = sprintf('verify_weather_T%d_A%d.mat',av_T,av_A);
if exist(vfile,'file')
    V = load(vfile);
    X = V.vw_X;
    id = find(strcmp(V.vw_scen,'dry'),1);
    out = reshape(V.vw_out(:,id,:),size(V.vw_out,1),[]);        % SNH95 SNHavg TN95 TSS95 OCI
    src = vfile;
elseif av_T == 24 && av_A == 1225
    X   = [154.5 42775 224; 150.8 64486 315; 143.1 22425 460];
    out = [ 6.85  3.80 20.1 34.2 21014;
            9.18  5.99 19.7 32.2 21924;
           12.40  9.41 25.2 30.6 22877];
    src = 'values recorded in the handoff notes (24 C verification, dry weather)';
else
    error('%s not found: run verify_and_weather.m for T = %d first.',vfile,av_T);
end
n = size(X,1);
R = nan(n,14);
R(:,1) = av_T;  R(:,2:4) = X;
R(:,5) = out(:,1);  R(:,6) = out(:,2);  R(:,11) = out(:,3);  R(:,13) = out(:,4);  R(:,9) = out(:,5);
lab = arrayfun(@(j) sprintf('verification V%d',j),(1:n)','UniformOutput',false);

ifile = sprintf('infill_T%d_A%d.mat',av_T,av_A);
ir_res = zeros(0,14);  ir_round = zeros(0,1);  ir_lab = cell(0,1);
if exist(ifile,'file')
    O = load(ifile);
    ir_res = O.ir_res;  ir_round = O.ir_round;  ir_lab = O.ir_lab;
end
added = 0;
for j = 1:n
    if ~isempty(ir_res) && any(all(abs(ir_res(:,2:4) - X(j,:)) < 1e-9,2)), continue; end    % already there
    ir_res(end+1,:) = R(j,:);                %#ok<SAGROW>
    ir_round(end+1,1) = 0.5;                 %#ok<SAGROW>
    ir_lab{end+1,1} = lab{j};                %#ok<SAGROW>
    added = added + 1;
end
ir_T = av_T;  ir_A = av_A;
save(ifile,'ir_res','ir_round','ir_lab','ir_T','ir_A');
fprintf('%d verification runs added to %s (source: %s); %d rows in the file now.\n',added,ifile,src,size(ir_res,1));
fprintf(' point |  KLa  Qintr   Qw | SNH95 SNHavg  TN95 TSS95    OCI\n');
for j = 1:n
    fprintf('  V%d   | %5.1f %6.0f %4.0f | %5.2f %6.2f %5.1f %5.1f %6.0f\n',j,X(j,:),out(j,:));
end
fprintf('Next: run opt_margin.m with mg_T = %d. It will test the new surfaces on these three points first, then refit with them.\n',av_T);
