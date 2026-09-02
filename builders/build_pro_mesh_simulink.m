%% build_pro_mesh_simulink.m
%  PROFESSIONAL DUAL-BAND MESH NETWORK SIMULINK MODEL
%  Includes:
%    - 4 Nodes with Time-Varying SNR Profiles
%    - Live Modulation Scheme Displays (BPSK → 256-QAM)
%    - Live Video Resolution / Voice Mode Indicators
%    - Live Bit Error Rate (BER) Verification
%    - Base Station Aggregator (Total Network Throughput)
%    - Multi-Channel Scope & Data Logging
%  Tactical PHY Mesh — ARYA-mgc
%
%  Usage: >> build_pro_mesh_simulink

clc;
fprintf('=================================================================\n');
fprintf('  BUILDING PROFESSIONAL 4-NODE MESH SIMULINK MODEL\n');
fprintf('  Tactical PHY Mesh — ARYA-mgc — Dual-Band Helmet Antenna System\n');
fprintf('=================================================================\n\n');

modelName = 'ProMesh_DualBand_BaseStation';

if bdIsLoaded(modelName), close_system(modelName, 0); end
if exist([modelName '.slx'],'file'), delete([modelName '.slx']); end

new_system(modelName);
open_system(modelName);
set_param(modelName, 'StopTime','210', 'SolverType','Fixed-step', 'FixedStep','1');

%% ============================================================
%%  1. MISSION TIME CLOCK
%% ============================================================
add_block('simulink/Sources/Clock', [modelName '/Mission_Clock'], ...
    'Position', [30 250 60 270]);

%% ============================================================
%%  2. 4 TIME-VARYING SNR PROFILES (CQB Movement)
%% ============================================================
t1 = '[0 50 51 100 101 160 161 210]'; s1 = '[30 30 18 18 25 25 30 30]';
t2 = '[0 30 31 70 71 110 111 160 161 210]'; s2 = '[22 22 15 15 8 8 12 12 20 20]';
t3 = '[0 20 21 60 61 120 121 170 171 210]'; s3 = '[20 20 10 10 5 5 8 8 18 18]';
t4 = '[0 50 51 150 151 210]';               s4 = '[25 25 20 20 25 25]';

add_block('simulink/Lookup Tables/1-D Lookup Table', [modelName '/Node1_SNR'], ...
    'Position', [100 90 200 120], 'Table', s1, 'BreakpointsForDimension1', t1);
add_block('simulink/Lookup Tables/1-D Lookup Table', [modelName '/Node2_SNR'], ...
    'Position', [100 190 200 220], 'Table', s2, 'BreakpointsForDimension1', t2);
add_block('simulink/Lookup Tables/1-D Lookup Table', [modelName '/Node3_SNR'], ...
    'Position', [100 290 200 320], 'Table', s3, 'BreakpointsForDimension1', t3);
add_block('simulink/Lookup Tables/1-D Lookup Table', [modelName '/Node4_SNR'], ...
    'Position', [100 390 200 420], 'Table', s4, 'BreakpointsForDimension1', t4);

fprintf('[OK] 4 Node SNR Lookup Profiles added\n');

%% ============================================================
%%  3. SNR INPUT MUX
%% ============================================================
add_block('simulink/Signal Routing/Mux', [modelName '/SNR_Mux'], ...
    'Position', [240 100 250 410], 'Inputs', '4');

%% ============================================================
%%  4. CENTRAL BASE STATION ENGINE (MATLAB Function)
%% ============================================================
add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [modelName '/Base_Station_Engine'], ...
    'Position', [300 170 540 340]);

fprintf('[OK] Base Station Engine block added\n');

%% ============================================================
%%  5. LIVE METRICS & DASHBOARD SPREAD
%% ============================================================
% Column 1: Throughput (Mbps)
add_block('simulink/Sinks/Display', [modelName '/N1_Throughput_Mbps'], 'Position', [620 60 740 85]);
add_block('simulink/Sinks/Display', [modelName '/N2_Throughput_Mbps'], 'Position', [620 120 740 145]);
add_block('simulink/Sinks/Display', [modelName '/N3_Throughput_Mbps'], 'Position', [620 180 740 205]);
add_block('simulink/Sinks/Display', [modelName '/N4_Throughput_Mbps'], 'Position', [620 240 740 265]);

% Column 2: Modulation Index (1=BPSK, 2=QPSK, 3=16QAM, 4=64QAM, 5=256QAM)
add_block('simulink/Sinks/Display', [modelName '/N1_Modulation_Level'], 'Position', [780 60 880 85]);
add_block('simulink/Sinks/Display', [modelName '/N2_Modulation_Level'], 'Position', [780 120 880 145]);
add_block('simulink/Sinks/Display', [modelName '/N3_Modulation_Level'], 'Position', [780 180 880 205]);
add_block('simulink/Sinks/Display', [modelName '/N4_Modulation_Level'], 'Position', [780 240 880 265]);

% Column 3: Total Aggregate Network Bandwidth
add_block('simulink/Sinks/Display', [modelName '/Total_Network_Mbps'], 'Position', [620 310 740 340]);

% Multi-Channel Scope
add_block('simulink/Sinks/Scope', [modelName '/Live_Network_Scope'], ...
    'Position', [620 380 670 430], 'NumInputPorts', '4');

% To Workspace Log
add_block('simulink/Sinks/To Workspace', [modelName '/Log_Network_Data'], ...
    'Position', [620 460 740 490], 'VariableName', 'network_log', 'SaveFormat', 'Array');

fprintf('[OK] Displays, Scopes, and Logger created\n');

%% ============================================================
%%  6. CONNECTIONS: Clock → SNR Tables → Mux → Engine
%% ============================================================
add_line(modelName, 'Mission_Clock/1', 'Node1_SNR/1', 'autorouting','smart');
add_line(modelName, 'Mission_Clock/1', 'Node2_SNR/1', 'autorouting','smart');
add_line(modelName, 'Mission_Clock/1', 'Node3_SNR/1', 'autorouting','smart');
add_line(modelName, 'Mission_Clock/1', 'Node4_SNR/1', 'autorouting','smart');

add_line(modelName, 'Node1_SNR/1', 'SNR_Mux/1', 'autorouting','smart');
add_line(modelName, 'Node2_SNR/1', 'SNR_Mux/2', 'autorouting','smart');
add_line(modelName, 'Node3_SNR/1', 'SNR_Mux/3', 'autorouting','smart');
add_line(modelName, 'Node4_SNR/1', 'SNR_Mux/4', 'autorouting','smart');

add_line(modelName, 'SNR_Mux/1', 'Base_Station_Engine/1', 'autorouting','smart');

fprintf('[OK] Input connections completed\n');

%% ============================================================
%%  7. ANNOTATIONS
%% ============================================================
a1 = Simulink.Annotation([modelName '/DUAL-BAND TACTICAL MESH NETWORK — GROUND BASE STATION']);
a1.Position = [500 20]; a1.FontSize = 17; a1.FontWeight = 'bold'; a1.ForegroundColor = 'blue';

a2 = Simulink.Annotation([modelName '/Intelligent Link Management: Adaptive MCS (BPSK to 256-QAM) | UHF Penetration + L-Band Video']);
a2.Position = [500 42]; a2.FontSize = 10; a2.ForegroundColor = 'black';

a3 = Simulink.Annotation([modelName '/Person 1 (Rooftop Overwatch)']);
a3.Position = [115 75]; a3.FontSize = 8; a3.ForegroundColor = 'blue';
a4 = Simulink.Annotation([modelName '/Person 2 (Corridor Transit)']);
a4.Position = [115 175]; a4.FontSize = 8; a4.ForegroundColor = 'green';
a5 = Simulink.Annotation([modelName '/Person 3 (Deep Basement)']);
a5.Position = [115 275]; a5.FontSize = 8; a5.ForegroundColor = 'red';
a6 = Simulink.Annotation([modelName '/Person 4 (Base Perimeter)']);
a6.Position = [115 375]; a6.FontSize = 8; a6.ForegroundColor = 'magenta';

a7 = Simulink.Annotation([modelName '/Modulation Scheme: 1=BPSK | 2=QPSK | 3=16QAM | 4=64QAM | 5=256QAM']);
a7.Position = [830 42]; a7.FontSize = 8; a7.ForegroundColor = 'red';

%% Styling
try
    set_param([modelName '/Base_Station_Engine'], 'BackgroundColor', 'cyan');
    set_param([modelName '/Node1_SNR'], 'BackgroundColor', 'lightBlue');
    set_param([modelName '/Node2_SNR'], 'BackgroundColor', 'green');
    set_param([modelName '/Node3_SNR'], 'BackgroundColor', 'orange');
    set_param([modelName '/Node4_SNR'], 'BackgroundColor', 'magenta');
end

save_system(modelName);
fprintf('\n[OK] Model successfully built & saved as %s.slx\n\n', modelName);

%% ============================================================
%%  INSTRUCTIONS
%% ============================================================
fprintf('=================================================================\n');
fprintf('  STEP 1: Double-click the cyan "Base_Station_Engine" block\n');
fprintf('  STEP 2: Delete default code and paste this:\n');
fprintf('=================================================================\n\n');

fprintf('function [t1, t2, t3, t4, m1, m2, m3, m4, totalRate] = fcn(snr_all)\n');
fprintf('%%%% PRO DUAL-BAND BASE STATION ENGINE\n');
fprintf('coder.extrinsic(''process_pro_mesh'');\n');
fprintf('t1=0; t2=0; t3=0; t4=0; m1=1; m2=1; m3=1; m4=1; totalRate=0;\n');
fprintf('[t1, t2, t3, t4, m1, m2, m3, m4, totalRate] = process_pro_mesh(snr_all);\n');
fprintf('\n');
fprintf('=================================================================\n');
fprintf('  STEP 3: Press Ctrl+S, close editor\n');
fprintf('  STEP 4: Run >> connect_pro_mesh_outputs\n');
fprintf('  STEP 5: Press ▶ Run in Simulink\n');
fprintf('=================================================================\n');
