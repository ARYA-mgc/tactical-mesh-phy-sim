%% build_cqb_mission_simulink.m
%  CQB Mission Timeline — Realistic SNR profile in Simulink
%  Tactical PHY Mesh — ARYA-mgc
%
%  Usage: >> build_cqb_mission_simulink

clc;
fprintf('=================================================================\n');
fprintf('  CQB MISSION TIMELINE — Simulink Model\n');
fprintf('  Tactical PHY Mesh — ARYA-mgc\n');
fprintf('=================================================================\n\n');

modelName = 'CQB_Mission_AdaptiveMod';

if bdIsLoaded(modelName), close_system(modelName, 0); end
if exist([modelName '.slx'],'file'), delete([modelName '.slx']); end

new_system(modelName);
open_system(modelName);
set_param(modelName, 'StopTime','210', 'SolverType','Fixed-step', 'FixedStep','1');
fprintf('[OK] Model created (210 seconds mission)\n');

%% ============================================================
%%  MISSION SNR PROFILE (Lookup Table: time → SNR)
%% ============================================================
% Mission phases:
%   0-30s:   Approach (outdoor)          SNR=30
%   30-45s:  Breach entry               SNR=20
%   45-70s:  Ground floor corridor      SNR=15
%   70-90s:  Stairwell descent          SNR=8
%   90-120s: Basement room clear        SNR=5
%   120-140s: Target engagement         SNR=10
%   140-160s: Extract via stairs        SNR=12
%   160-180s: Ground floor exit         SNR=18
%   180-210s: Outside extraction        SNR=30

missionTime = '[0 29 30 44 45 69 70 89 90 119 120 139 140 159 160 179 180 210]';
missionSNR  = '[30 30 20 20 15 15 8  8  5  5   10  10  12  12  18  18  30  30]';

add_block('simulink/Sources/Clock', [modelName '/Mission_Clock'], ...
    'Position', [30 170 60 200]);

add_block('simulink/Lookup Tables/1-D Lookup Table', [modelName '/Mission_Profile'], ...
    'Position', [100 160 220 210], ...
    'Table', missionSNR, ...
    'BreakpointsForDimension1', missionTime);
fprintf('[OK] Mission SNR profile (Lookup Table)\n');

%% ============================================================
%%  PHY SIMULATOR (MATLAB Function Block)
%% ============================================================
add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [modelName '/PHY_Engine'], ...
    'Position', [290 140 460 230]);
fprintf('[OK] PHY Engine block\n');

%% ============================================================
%%  DISPLAYS
%% ============================================================
add_block('simulink/Sinks/Display', [modelName '/SNR_Value'], ...
    'Position', [100 260 190 290]);
add_block('simulink/Sinks/Display', [modelName '/BER_Value'], ...
    'Position', [530 120 640 150]);
add_block('simulink/Sinks/Display', [modelName '/MER_Value'], ...
    'Position', [530 170 640 200]);
add_block('simulink/Sinks/Display', [modelName '/MCS_Value'], ...
    'Position', [530 220 640 250]);
add_block('simulink/Sinks/Display', [modelName '/Throughput_Value'], ...
    'Position', [530 270 640 300]);
add_block('simulink/Sinks/Display', [modelName '/Phase_Name'], ...
    'Position', [530 320 640 350]);
fprintf('[OK] Display blocks\n');

%% ============================================================
%%  SCOPE (4 inputs: SNR, BER, MCS, Throughput)
%% ============================================================
add_block('simulink/Sinks/Scope', [modelName '/Mission_Scope'], ...
    'Position', [530 380 580 420], 'NumInputPorts', '4');
fprintf('[OK] Scope\n');

%% ============================================================
%%  TO WORKSPACE (for post-sim figures)
%% ============================================================
add_block('simulink/Sinks/To Workspace', [modelName '/Log_SNR'], ...
    'Position', [530 440 630 470], 'VariableName','cqb_snr', 'SaveFormat','Array');
add_block('simulink/Sinks/To Workspace', [modelName '/Log_BER'], ...
    'Position', [530 490 630 520], 'VariableName','cqb_ber', 'SaveFormat','Array');
add_block('simulink/Sinks/To Workspace', [modelName '/Log_MCS'], ...
    'Position', [530 540 630 570], 'VariableName','cqb_mcs', 'SaveFormat','Array');
add_block('simulink/Sinks/To Workspace', [modelName '/Log_Tput'], ...
    'Position', [530 590 630 620], 'VariableName','cqb_tput', 'SaveFormat','Array');
add_block('simulink/Sinks/To Workspace', [modelName '/Log_Phase'], ...
    'Position', [530 640 630 670], 'VariableName','cqb_phase', 'SaveFormat','Array');
fprintf('[OK] To Workspace blocks\n');

%% ============================================================
%%  CONNECT INPUT CHAIN
%% ============================================================
add_line(modelName, 'Mission_Clock/1', 'Mission_Profile/1', 'autorouting','smart');
add_line(modelName, 'Mission_Profile/1', 'PHY_Engine/1', 'autorouting','smart');
add_line(modelName, 'Mission_Profile/1', 'SNR_Value/1', 'autorouting','smart');
fprintf('[OK] Input connected\n');

%% ============================================================
%%  ANNOTATIONS — Mission Phase Labels
%% ============================================================
a1 = Simulink.Annotation([modelName '/CQB MISSION TIMELINE — ADAPTIVE MODULATION']);
a1.Position = [380 20]; a1.FontSize = 18; a1.FontWeight = 'bold'; a1.ForegroundColor = 'blue';

a2 = Simulink.Annotation([modelName '/Tactical PHY Mesh — ARYA-mgc — NSG Helmet Antenna System']);
a2.Position = [380 50]; a2.FontSize = 12; a2.ForegroundColor = 'black';

a3 = Simulink.Annotation([modelName '/Mission: Approach(30dB) > Breach(20dB) > Corridor(15dB) > Stairs(8dB) > Basement(5dB) > Target(10dB) > Extract(12dB) > Exit(18dB) > Outside(30dB)']);
a3.Position = [380 690]; a3.FontSize = 9; a3.ForegroundColor = 'red';

fprintf('[OK] Annotations\n');

%% ============================================================
%%  COLORS
%% ============================================================
try
    set_param([modelName '/Mission_Profile'], 'BackgroundColor', 'yellow');
    set_param([modelName '/PHY_Engine'], 'BackgroundColor', 'cyan');
    set_param([modelName '/Mission_Clock'], 'BackgroundColor', 'lightBlue');
    fprintf('[OK] Colors\n');
catch
end

%% ============================================================
%%  SAVE
%% ============================================================
save_system(modelName);
fprintf('\n[OK] Model saved: %s.slx\n\n', modelName);

%% ============================================================
%%  INSTRUCTIONS
%% ============================================================
fprintf('=================================================================\n');
fprintf('  NOW DO THIS:\n');
fprintf('=================================================================\n');
fprintf('\n  1. Double-click the cyan "PHY_Engine" block\n');
fprintf('  2. Delete default code, paste the code below:\n');
fprintf('  3. Press Ctrl+S, close editor\n');
fprintf('  4. Run: >> connect_cqb_outputs\n');
fprintf('  5. Press Run in Simulink\n');
fprintf('  6. Run: >> plot_cqb_mission\n');
fprintf('\n--- PASTE THIS CODE ---\n\n');

code = [ ...
'function [ber, mer, mcsIdx, throughput, phaseID] = fcn(snr)\n' ...
'%% CQB MISSION PHY ENGINE — ARYA-mgc\n' ...
'coder.extrinsic(''run_phy_step'');\n' ...
'\n' ...
'%% Mission Phase Detection\n' ...
'if snr >= 28\n' ...
'    phaseID = 1;  %% Outdoor\n' ...
'elseif snr >= 18\n' ...
'    phaseID = 2;  %% Building entry/exit\n' ...
'elseif snr >= 13\n' ...
'    phaseID = 3;  %% Indoor corridor\n' ...
'elseif snr >= 9\n' ...
'    phaseID = 4;  %% Stairwell\n' ...
'else\n' ...
'    phaseID = 5;  %% Basement/deep indoor\n' ...
'end\n' ...
'\n' ...
'%% Adaptive MCS Selection\n' ...
'if snr >= 26\n' ...
'    modOrder = 256; bps = 8; mcsIdx = 5;\n' ...
'elseif snr >= 20\n' ...
'    modOrder = 64; bps = 6; mcsIdx = 4;\n' ...
'elseif snr >= 14\n' ...
'    modOrder = 16; bps = 4; mcsIdx = 3;\n' ...
'elseif snr >= 8\n' ...
'    modOrder = 4; bps = 2; mcsIdx = 2;\n' ...
'else\n' ...
'    modOrder = 2; bps = 1; mcsIdx = 1;\n' ...
'end\n' ...
'\n' ...
'%% Run full PHY simulation\n' ...
'ber = double(0); mer = double(0); throughput = double(0);\n' ...
'[ber, mer, throughput] = run_phy_step(snr, modOrder, bps);\n'];

fprintf(code);
fprintf('\n--- END OF CODE ---\n');
fprintf('=================================================================\n');
