% This file has been modified by Xavier Flores-Alsina
% July, 2010
% IEA, Lund University, Lund, Sweden

clc
clear

load sensornoise;
asm3init;
settler1dinit_asm3;
reginit_asm3;
sensorinit_asm3;

load dryinfluent;
load storminfluent;
load raininfluent;
load constinfluent;
load DYNINFLUENT_ASM3


SETTLER = [1];      % if SETTLER is 0 the settling model is non reactive
                    % if SETTLER IS 1 the settling model is reactive
                    
TEMPMODEL =[0];     % if TEMPM0DEL is 0 influent wastewater temperature is just passed through process reactors 
                    % if TEMPMODEL is 1 mass balance for the wastewater temperature is used in process reactors    
                    
ACTIVATE = [0];     % if ACTIVATE is 0 dummy states are 0 
                    % if ACTIVATE is 1 dummy states are activated