%% build_multifeed_simulink.m
%  DUAL-BAND MULTI-FEED MESH SIMULINK MODEL
%  Simulates 4 Nodes with Video Stream + Voice Feed + Telemetry
%  Tactical PHY Mesh — ARYA-mgc
%
%  Usage: >> build_multifeed_simulink

clc;
fprintf('=================================================================\n');
fprintf('  BUILDING DUAL-BAND MULTI-FEED SIMULINK MODEL\n');
fprintf('  Simultaneous Feeds: Video (L-Band) + Voice/Telemetry (UHF)\n');
fprintf('  Tactical PHY Mesh — ARYA-mgc\n');
fprintf('=================================================================\n\n');

modelName = 'DualBand_MultiFeed_Mesh';

if bdIsLoaded(modelName), close_system(modelName, 0); end
if exist([modelName '.slx'],'file'), delete([modelName '.slx']); end

new_system(modelName);
open_system(modelName);
set_param(modelName, 'StopTime','210', 'SolverType','Fixed-step', 'FixedStep','1');

%% ============================================================
%%  1. TIME CLOCK
%% ============================================================
add_block('simulink/Sources/Clock', [modelName '/Clock'], ...
    'Position', [30 230 60 250]);

%% ============================================================
%%  2. 4-NODE TIME-VARYING SNR FEEDS (Mission Profiles)
%% ============================================================
t_p1 = '[0 50 51 100 101 160 161 210]'; s_p1 = '[30 30 18 18 25 25 30 30]';
t_p2 = '[0 30 31 70 71 110 111 160 161 210]'; s_p2 = '[22 22 15 15 8 8 12 12 20 20]';
t_p3 = '[0 20 21 60 61 120 121 170 171 210]'; s_p3 = '[20 20 10 10 5 5 8 8 18 18]';
t_p4 = '[0 50 51 150 151 210]';               s_p4 = '[25 25 20 20 25 25]';

add_block('simulink/Lookup Tables/1-D Lookup Table', [modelName '/Node1_SNR_Feed'], ...
    'Position', [100 80 200 110], 'Table', s_p1, 'BreakpointsForDimension1', t_p1);
add_block('simulink/Lookup Tables/1-D Lookup Table', [modelName '/Node2_SNR_Feed'], ...
    'Position', [100 170 200 200], 'Table', s_p2, 'BreakpointsForDimension1', t_p2);
add_block('simulink/Lookup Tables/1-D Lookup Table', [modelName '/Node3_SNR_Feed'], ...
    'Position', [100 260 200 290], 'Table', s_p3, 'BreakpointsForDimension1', t_p3);
add_block('simulink/Lookup Tables/1-D Lookup Table', [modelName '/Node4_SNR_Feed'], ...
    'Position', [100 350 200 380], 'Table', s_p4, 'BreakpointsForDimension1', t_p4);

fprintf('[OK] 4 Time-Varying SNR feeds added\n');

%% ============================================================
%%  3. SNR MUX & CENTRAL MULTI-FEED BASE STATION
%% ============================================================
add_block('simulink/Signal Routing/Mux', [modelName '/Feed_Mux'], ...
    'Position', [240 100 250 360], 'Inputs', '4');

add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [modelName '/MultiFeed_Base_Station'], ...
    'Position', [300 140 520 320]);

fprintf('[OK] Multi-Feed Base Station Engine added\n');

%% ============================================================
%%  4. MULTI-FEED OUTPUT DISPLAYS
%% ============================================================
% Video Stream Feeds (Mbps)
add_block('simulink/Sinks/Display', [modelName '/N1_Video_Rate'], 'Position', [600 70 710 95]);
add_block('simulink/Sinks/Display', [modelName '/N2_Video_Rate'], 'Position', [600 115 710 140]);
add_block('simulink/Sinks/Display', [modelName '/N3_Video_Rate'], 'Position', [600 160 710 185]);
add_block('simulink/Sinks/Display', [modelName '/N4_Video_Rate'], 'Position', [600 205 710 230]);

% Voice & Network Status
add_block('simulink/Sinks/Display', [modelName '/Total_Network_Mbps'], 'Position', [600 260 710 285]);
add_block('simulink/Sinks/Display', [modelName '/N3_Voice_Penetration_Mode'], 'Position', [600 310 710 335]);

% 4-Channel Live Scope for Video & Audio Feeds
add_block('simulink/Sinks/Scope', [modelName '/MultiFeed_Scope'], ...
    'Position', [600 365 650 415], 'NumInputPorts', '4');

% To Workspace Log
add_block('simulink/Sinks/To Workspace', [modelName '/Log_Total_Mbps'], ...
    'Position', [600 440 700 470], 'VariableName', 'total_network_mbps', 'SaveFormat', 'Array');

fprintf('[OK] Video & Voice Displays, Scope, Logging added\n');

%% ============================================================
%%  5. INPUT CONNECTIONS
%% ============================================================
add_line(modelName, 'Clock/1', 'Node1_SNR_Feed/1', 'autorouting','smart');
add_line(modelName, 'Clock/1', 'Node2_SNR_Feed/1', 'autorouting','smart');
add_line(modelName, 'Clock/1', 'Node3_SNR_Feed/1', 'autorouting','smart');
add_line(modelName, 'Clock/1', 'Node4_SNR_Feed/1', 'autorouting','smart');

add_line(modelName, 'Node1_SNR_Feed/1', 'Feed_Mux/1', 'autorouting','smart');
add_line(modelName, 'Node2_SNR_Feed/1', 'Feed_Mux/2', 'autorouting','smart');
add_line(modelName, 'Node3_SNR_Feed/1', 'Feed_Mux/3', 'autorouting','smart');
add_line(modelName, 'Node4_SNR_Feed/1', 'Feed_Mux/4', 'autorouting','smart');

add_line(modelName, 'Feed_Mux/1', 'MultiFeed_Base_Station/1', 'autorouting','smart');

fprintf('[OK] Input connections established\n');

%% ============================================================
%%  6. ANNOTATIONS
%% ============================================================
a1 = Simulink.Annotation([modelName '/DUAL-BAND MULTI-FEED MESH NETWORK — BASE STATION']);
a1.Position = [430 18]; a1.FontSize = 16; a1.FontWeight = 'bold'; a1.ForegroundColor = 'blue';

a2 = Simulink.Annotation([modelName '/Simultaneous Video Streams (L-Band 1.4 GHz) + Voice / Mesh Control (UHF 400 MHz)']);
a2.Position = [430 42]; a2.FontSize = 10; a2.ForegroundColor = 'black';

a3 = Simulink.Annotation([modelName '/Node 1: Rooftop (HD Video Feed)']);
a3.Position = [115 65]; a3.FontSize = 8; a3.ForegroundColor = 'blue';

a4 = Simulink.Annotation([modelName '/Node 2: Corridor (Video Feed)']);
a4.Position = [115 155]; a4.FontSize = 8; a4.ForegroundColor = 'green';

a5 = Simulink.Annotation([modelName '/Node 3: Basement (UHF Voice Priority)']);
a5.Position = [115 245]; a5.FontSize = 8; a5.ForegroundColor = 'red';

a6 = Simulink.Annotation([modelName '/Node 4: Base Area (Video Feed)']);
a6.Position = [115 335]; a6.FontSize = 8; a6.ForegroundColor = 'magenta';

%% Colors
try
    set_param([modelName '/MultiFeed_Base_Station'], 'BackgroundColor', 'cyan');
    set_param([modelName '/Node1_SNR_Feed'], 'BackgroundColor', 'lightBlue');
    set_param([modelName '/Node2_SNR_Feed'], 'BackgroundColor', 'green');
    set_param([modelName '/Node3_SNR_Feed'], 'BackgroundColor', 'orange');
    set_param([modelName '/Node4_SNR_Feed'], 'BackgroundColor', 'magenta');
end

save_system(modelName);
fprintf('\n[OK] Model created and saved as %s.slx\n\n', modelName);

%% ============================================================
%%  INSTRUCTIONS FOR USER
%% ============================================================
fprintf('=================================================================\n');
fprintf('  STEP 1: Double-click the cyan "MultiFeed_Base_Station" block\n');
fprintf('  STEP 2: Delete default code and paste this:\n');
fprintf('=================================================================\n\n');

fprintf('function [v1, v2, v3, v4, totalMbps, n3VoiceActive] = fcn(snr_all)\n');
fprintf('%%%% DUAL-BAND MULTI-FEED PROCESSOR (ARYA-mgc)\n');
fprintf('coder.extrinsic(''process_multifeeds'');\n');
fprintf('v1=0; v2=0; v3=0; v4=0; totalMbps=0; n3VoiceActive=1;\n');
fprintf('[v1, v2, v3, v4, totalMbps, n3VoiceActive] = process_multifeeds(snr_all);\n');
fprintf('\n');
fprintf('=================================================================\n');
fprintf('  STEP 3: Press Ctrl+S, close editor\n');
fprintf('  STEP 4: Run >> connect_multifeed_outputs\n');
fprintf('  STEP 5: Press Run in Simulink\n');
fprintf('=================================================================\n');
