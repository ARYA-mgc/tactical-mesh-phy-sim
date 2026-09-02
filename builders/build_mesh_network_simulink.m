%% build_mesh_network_simulink.m
%  4-NODE DUAL-BAND FULL MESH NETWORK SIMULINK MODEL
%  Each Node Block models a complete TX/RX Commando Terminal:
%    - Node 1: Rooftop Leader (Dual-Band TX/RX, HD Video Stream)
%    - Node 2: Corridor Breacher (Relay Router Node)
%    - Node 3: Basement Pointman (UHF Penetration Mode)
%    - Node 4: Base Perimeter (C2 Transport Node)
%  Central Hub:
%    - Base Station Mesh Router & Central Demodulator
%  Tactical PHY Mesh — ARYA-mgc
%
%  Usage: >> build_mesh_network_simulink

clc;
fprintf('=================================================================\n');
fprintf('  UPDATING 4-NODE MESH NETWORK SIMULINK MODEL\n');
fprintf('  Full TX/RX Elements, Adaptive Dual-Band & Mesh Routing\n');
fprintf('  Tactical PHY Mesh — ARYA-mgc\n');
fprintf('=================================================================\n\n');

modelName = 'MeshNetwork_4Node_BaseStation';

if bdIsLoaded(modelName), close_system(modelName, 0); end
if exist([modelName '.slx'],'file'), delete([modelName '.slx']); end

new_system(modelName);
open_system(modelName);
set_param(modelName, 'StopTime','210', 'SolverType','Fixed-step', 'FixedStep','1');

%% ============================================================
%%  1. TIME CLOCK
%% ============================================================
add_block('simulink/Sources/Clock', [modelName '/Mission_Clock'], ...
    'Position', [30 200 55 220]);

%% ============================================================
%%  2. 4 NODE TX/RX PROFILES (CQB Movement)
%% ============================================================
n1_time = '[0 50 51 100 101 160 161 210]'; n1_snr  = '[30 30 18 18  25  25  30  30]';
n2_time = '[0 30 31 70 71 110 111 160 161 210]'; n2_snr  = '[22 22 15 15 8   8   12  12  20  20]';
n3_time = '[0 20 21 60 61 120 121 170 171 210]'; n3_snr  = '[20 20 10 10 5   5   8   8   18  18]';
n4_time = '[0 50 51 150 151 210]';               n4_snr  = '[25 25 20 20  25  25]';

add_block('simulink/Lookup Tables/1-D Lookup Table', [modelName '/Node1_TX_Rooftop'], ...
    'Position', [100 60 210 90], 'Table', n1_snr, 'BreakpointsForDimension1', n1_time);
add_block('simulink/Lookup Tables/1-D Lookup Table', [modelName '/Node2_TX_Corridor'], ...
    'Position', [100 140 210 170], 'Table', n2_snr, 'BreakpointsForDimension1', n2_time);
add_block('simulink/Lookup Tables/1-D Lookup Table', [modelName '/Node3_TX_Basement'], ...
    'Position', [100 220 210 250], 'Table', n3_snr, 'BreakpointsForDimension1', n3_time);
add_block('simulink/Lookup Tables/1-D Lookup Table', [modelName '/Node4_TX_Perimeter'], ...
    'Position', [100 300 210 330], 'Table', n4_snr, 'BreakpointsForDimension1', n4_time);

fprintf('[OK] 4 Commando Node TX/RX profiles created\n');

%% ============================================================
%%  3. MESH WIRELESS CHANNEL (MUX)
%% ============================================================
add_block('simulink/Signal Routing/Mux', [modelName '/SNR_Mux'], ...
    'Position', [250 90 260 300], 'Inputs', '4');

%% ============================================================
%%  4. CENTRAL BASE STATION MESH ROUTER (MATLAB Function)
%% ============================================================
add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [modelName '/Base_Station'], ...
    'Position', [310 120 510 270]);

fprintf('[OK] Base Station Mesh Router added\n');

%% ============================================================
%%  5. OUTPUT DISPLAYS & SCOPE
%% ============================================================
add_block('simulink/Sinks/Display', [modelName '/N1_Throughput'], 'Position', [590 90 700 110]);
add_block('simulink/Sinks/Display', [modelName '/N2_Throughput'], 'Position', [590 130 700 150]);
add_block('simulink/Sinks/Display', [modelName '/N3_Throughput'], 'Position', [590 170 700 190]);
add_block('simulink/Sinks/Display', [modelName '/N4_Throughput'], 'Position', [590 210 700 230]);
add_block('simulink/Sinks/Display', [modelName '/Total_Tput'],    'Position', [590 260 700 280]);

% Multi-Channel Scope
add_block('simulink/Sinks/Scope', [modelName '/Network_Scope'], ...
    'Position', [590 310 640 350], 'NumInputPorts', '4');

% Log to Workspace
add_block('simulink/Sinks/To Workspace', [modelName '/Log_Data'], ...
    'Position', [590 370 690 400], 'VariableName','mesh_out', 'SaveFormat','Array');

add_block('simulink/Sinks/To Workspace', [modelName '/Log_SNR1'], ...
    'Position', [250 360 340 380], 'VariableName','mesh_snr1', 'SaveFormat','Array');
add_block('simulink/Sinks/To Workspace', [modelName '/Log_SNR2'], ...
    'Position', [250 400 340 420], 'VariableName','mesh_snr2', 'SaveFormat','Array');
add_block('simulink/Sinks/To Workspace', [modelName '/Log_SNR3'], ...
    'Position', [250 440 340 460], 'VariableName','mesh_snr3', 'SaveFormat','Array');
add_block('simulink/Sinks/To Workspace', [modelName '/Log_SNR4'], ...
    'Position', [250 480 340 500], 'VariableName','mesh_snr4', 'SaveFormat','Array');

fprintf('[OK] Displays, scope, and logging created\n');

%% ============================================================
%%  6. INPUT CONNECTIONS
%% ============================================================
add_line(modelName, 'Mission_Clock/1', 'Node1_TX_Rooftop/1',   'autorouting','smart');
add_line(modelName, 'Mission_Clock/1', 'Node2_TX_Corridor/1',  'autorouting','smart');
add_line(modelName, 'Mission_Clock/1', 'Node3_TX_Basement/1',  'autorouting','smart');
add_line(modelName, 'Mission_Clock/1', 'Node4_TX_Perimeter/1', 'autorouting','smart');

add_line(modelName, 'Node1_TX_Rooftop/1',   'SNR_Mux/1', 'autorouting','smart');
add_line(modelName, 'Node2_TX_Corridor/1',  'SNR_Mux/2', 'autorouting','smart');
add_line(modelName, 'Node3_TX_Basement/1',  'SNR_Mux/3', 'autorouting','smart');
add_line(modelName, 'Node4_TX_Perimeter/1', 'SNR_Mux/4', 'autorouting','smart');

add_line(modelName, 'SNR_Mux/1', 'Base_Station/1', 'autorouting','smart');

add_line(modelName, 'Node1_TX_Rooftop/1',   'Log_SNR1/1', 'autorouting','smart');
add_line(modelName, 'Node2_TX_Corridor/1',  'Log_SNR2/1', 'autorouting','smart');
add_line(modelName, 'Node3_TX_Basement/1',  'Log_SNR3/1', 'autorouting','smart');
add_line(modelName, 'Node4_TX_Perimeter/1', 'Log_SNR4/1', 'autorouting','smart');

fprintf('[OK] Input lines connected\n');

%% ============================================================
%%  7. ANNOTATIONS
%% ============================================================
try
    a1 = Simulink.Annotation([modelName ' - 4-NODE WIRELESS MESH NETWORK TO 1 CENTRAL BASE STATION']);
    a1.Position = [420 15]; a1.FontSize = 16; a1.FontWeight = 'bold'; a1.ForegroundColor = 'blue';

    a2 = Simulink.Annotation([modelName ' - Dual-Band: UHF Voice (400 MHz) + L-Band HD Video (1.4 GHz) | Peer-to-Peer Mesh Relaying']);
    a2.Position = [420 38]; a2.FontSize = 10; a2.ForegroundColor = 'black';

    a3 = Simulink.Annotation([modelName ' - (Node 1 TX-RX) Rooftop Leader (HD Video Feed)']);
    a3.Position = [135 48]; a3.FontSize = 8; a3.ForegroundColor = 'blue';

    a4 = Simulink.Annotation([modelName ' - (Node 2 TX-RX) Corridor Breacher (Mesh Relay Router)']);
    a4.Position = [135 128]; a4.FontSize = 8; a4.ForegroundColor = 'green';

    a5 = Simulink.Annotation([modelName ' - (Node 3 TX-RX) Deep Basement (UHF Penetration Mode)']);
    a5.Position = [135 208]; a5.FontSize = 8; a5.ForegroundColor = 'red';

    a6 = Simulink.Annotation([modelName ' - (Node 4 TX-RX) Base Perimeter (Overwatch Transport)']);
    a6.Position = [135 288]; a6.FontSize = 8; a6.ForegroundColor = 'magenta';

    a7 = Simulink.Annotation([modelName ' - (BASE STATION MESH ROUTER)']);
    a7.Position = [410 278]; a7.FontSize = 10; a7.FontWeight = 'bold'; a7.ForegroundColor = 'red';
catch
end

%% Block Colors
try
    set_param([modelName '/Base_Station'], 'BackgroundColor', 'cyan');
    set_param([modelName '/Node1_TX_Rooftop'], 'BackgroundColor', 'lightBlue');
    set_param([modelName '/Node2_TX_Corridor'], 'BackgroundColor', 'green');
    set_param([modelName '/Node3_TX_Basement'], 'BackgroundColor', 'orange');
    set_param([modelName '/Node4_TX_Perimeter'], 'BackgroundColor', 'magenta');
end

save_system(modelName);
fprintf('\n[OK] Model successfully updated & saved as %s.slx\n\n', modelName);

%% ============================================================
%%  INSTRUCTIONS FOR THE USER
%% ============================================================
fprintf('=================================================================\n');
fprintf('  STEP 1: Double-click cyan "Base_Station" block\n');
fprintf('  STEP 2: Delete default code and paste this:\n');
fprintf('=================================================================\n\n');

fprintf('function [n1t, n2t, n3t, n4t, totalT] = fcn(snr_all)\n');
fprintf('%%%% BASE STATION - 4 Node Mesh Receiver & Router\n');
fprintf('%%%% Tactical PHY Mesh — ARYA-mgc\n');
fprintf('coder.extrinsic(''process_mesh_nodes'');\n');
fprintf('n1t=0; n2t=0; n3t=0; n4t=0; totalT=0;\n');
fprintf('[n1t, n2t, n3t, n4t, totalT] = process_mesh_nodes(snr_all);\n');
fprintf('\n');
fprintf('=================================================================\n');
fprintf('  STEP 3: Press Ctrl+S, close editor\n');
fprintf('  STEP 4: Run >> connect_mesh_outputs\n');
fprintf('  STEP 5: Press ▶ Run in Simulink\n');
fprintf('=================================================================\n');
