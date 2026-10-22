%% build_surat_influent_v3.m
% Surat influent with the CALIBRATED COD fractions of Lopez-Vazquez et al. (2013).
% Difference from v2: X_I and X_S use the calibrated fractions (Table 6: X_I 0.14, X_S 0.42 of the
% 357 g COD/m3 settled sewage) instead of the pre-calibration values printed in Table 2
% (X_I 37.56, X_S 162.74). S_S, S_I, S_NH4 and S_ALK are the Table 2 values, as before.
% Run it in your BSM1 folder. The previous file is kept as surat_influents_v2_backup.mat.
clear all;
if exist('surat_influents.mat','file'), copyfile('surat_influents.mat','surat_influents_v2_backup.mat'); end
benchmarkinit_noclear;                 % loads the standard influent files

CODtot = 357;                          % g COD/m3, settled sewage (Table 1, point 2)
SS = 107.36;  SI = 49.06;              % Table 2
XI = 0.14*CODtot;                      % calibrated influent X_I fraction (Table 6 and calibration step 1)
XS = CODtot - SS - SI - XI;            % closes the COD balance (about 150.6)
fprintf('COD check: S_S %.2f + S_I %.2f + X_I %.2f + X_S %.2f = %.2f\n',SS,SI,XI,XS,SS+SI+XI+XS);

% columns: 2 S_O, 3 S_I, 4 S_S, 5 S_NH4, 7 S_NO, 8 S_ALK, 9 X_I, 10 X_S, 11 X_H, 12 X_STO, 13 X_A, 14 TSS
scale_cols = [3 4 5 8 9 10];
paper      = [SI SS 31.17 6.44 XI XS];
ratio = paper ./ CONSTINFLUENT(1,scale_cols);

names = {'CONSTINFLUENT','DRYINFLUENT','RAININFLUENT','STORMINFLUENT'};
out = struct();
for k = 1:numel(names)
    D = eval(names{k});
    D(:,scale_cols) = D(:,scale_cols) .* ratio;      % keeps the daily pattern
    D(:,2)  = 1.80;                                  % S_O  (Table 2)
    D(:,7)  = 1.81;                                  % S_NO (Table 2)
    D(:,11) = 0; D(:,12) = 0; D(:,13) = 0;           % X_H, X_STO, X_A = 0 (Table 2)
    D(:,14) = i_SSXI*D(:,9) + i_SSXS*D(:,10) + i_SSBM*(D(:,11)+D(:,13)) + i_SSSTO*D(:,12);
    out.(names{k}) = D;
end
CONST_SURAT = out.CONSTINFLUENT; DRY_SURAT = out.DRYINFLUENT;
RAIN_SURAT  = out.RAININFLUENT;  STORM_SURAT = out.STORMINFLUENT;
disp(CONST_SURAT(1,[2 3 4 5 7 8 9 10 11 14 15 16]))
save('surat_influents.mat','CONST_SURAT','DRY_SURAT','RAIN_SURAT','STORM_SURAT');
