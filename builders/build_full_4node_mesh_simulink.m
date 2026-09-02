%% build_full_4node_mesh_simulink.m
%  4-NODE MESH NETWORK + 1 BASE STATION SIMULINK MODEL
%  Each of the 4 Nodes:
%    - Has Voice & Video Stream Payloads
%    - Uses Dual-Band Adaptive Modulation (UHF + L-Band)
%  Central Base Station:
%    - Demodulates and decodes all 4 incoming node streams
%    - Displays per-node data rates (Mbps), modulation levels, and BER
%    - Computes Total Base Station Aggregate Throughput
%  Tactical PHY Mesh — ARYA-mgc
%
%  Usage: >> build_full_4node_mesh_simulink

clc;
fprintf('=================================================================\n');
fprintf('  BUILDING 4-NODE MESH NETWORK + 1 BASE STATION SIMULINK MODEL\n');
fprintf('  4 Commando Nodes ──► Wireless Mesh Channel ──► 1 Base Station Hub\n');
fprintf('  Tactical PHY Mesh — ARYA-mgc\n');
fprintf('=================================================================\n\n');

modelName = 'Mesh_4Node_1BaseStation_System';

if bdIsLoaded(modelName), close_system(modelName, 0); end
if exist([modelName '.slx'],'file'), delete([modelName '.slx']); end

new_system(modelName);
open_system(modelName);
set_param(modelName, 'StopTime','210', 'SolverType','Fixed-step', 'FixedStep','1');

%% ============================================================
%%  1. TIME CLOCK
%% ============================================================
add_block('simulink/Sources/Clock', [modelName '/Mission_Clock'], ...
    'Position', [30 250 60 270]);

%% ============================================================
%%  2. 4 NODE TRANSMITTERS (TX) — Time-Varying SNR & Locations
%% ============================================================
t1 = '[0 50 51 100 101 160 161 210]'; s1 = '[30 30 18 18 25 25 30 30]';
t2 = '[0 30 31 70 71 110 111 160 161 210]'; s2 = '[22 22 15 15 8 8 12 12 20 20]';
t3 = '[0 20 21 60 61 120 121 170 171 210]'; s3 = '[20 20 10 10 5 5 8 8 18 18]';
t4 = '[0 50 51 150 151 210]';               s4 = '[25 25 20 20 25 25]';

add_block('simulink/Lookup Tables/1-D Lookup Table', [modelName '/Node1_TX_Rooftop'], ...
    'Position', [100 80 210 110], 'Table', s1, 'BreakpointsForDimension1', t1);
add_block('simulink/Lookup Tables/1-D Lookup Table', [modelName '/Node2_TX_Corridor'], ...
    'Position', [100 180 210 210], 'Table', s2, 'BreakpointsForDimension1', t2);
add_block('simulink/Lookup Tables/1-D Lookup Table', [modelName '/Node3_TX_Basement'], ...
    'Position', [100 280 210 310], 'Table', s3, 'BreakpointsForDimension1', t3);
add_block('simulink/Lookup Tables/1-D Lookup Table', [modelName '/Node4_TX_Perimeter'], ...
    'Position', [100 380 210 410], 'Table', s4, 'BreakpointsForDimension1', t4);

fprintf('[OK] 4 Node Transmitter sources added\n');

%% ============================================================
%%  3. MESH WIRELESS CHANNEL (MUX)
%% ============================================================
add_block('simulink/Signal Routing/Mux', [modelName '/Mesh_Channel_Mux'], ...
    'Position', [250 90 260 400], 'Inputs', '4');

%% ============================================================
%%  4. CENTRAL 1-BASE-STATION RECEIVER & DEMODULATOR ENGINE
%% ============================================================
add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [modelName '/Base_Station_Receiver_RX'], ...
    'Position', [310 160 560 330]);

fprintf('[OK] 1 Base Station Receiver (RX) block added\n');

%% ============================================================
%%  5. BASE STATION TELEMETRY DISPLAYS & SCOPE
%% ============================================================
% Per-Node Received Data Rates (Mbps)
add_block('simulink/Sinks/Display', [modelName '/Node1_Recv_Rate_Mbps'], 'Position', [640 50 760 75]);
add_block('simulink/Sinks/Display', [modelName '/Node2_Recv_Rate_Mbps'], 'Position', [640 100 760 125]);
add_block('simulink/Sinks/Display', [modelName '/Node3_Recv_Rate_Mbps'], 'Position', [640 150 760 175]);
add_block('simulink/Sinks/Display', [modelName '/Node4_Recv_Rate_Mbps'], 'Position', [640 200 760 225]);

% Per-Node Modulation Indicators (1=BPSK, 2=QPSK, 3=16QAM, 4=64QAM, 5=256QAM)
add_block('simulink/Sinks/Display', [modelName '/Node1_Modulation'],     'Position', [800 50 900 75]);
add_block('simulink/Sinks/Display', [modelName '/Node2_Modulation'],     'Position', [800 100 900 125]);
add_block('simulink/Sinks/Display', [modelName '/Node3_Modulation'],     'Position', [800 150 900 175]);
add_block('simulink/Sinks/Display', [modelName '/Node4_Modulation'],     'Position', [800 200 900 225]);

% Central Aggregate Base Station Throughput (Sum of all 4 nodes)
add_block('simulink/Sinks/Display', [modelName '/Total_BaseStation_Aggregate_Mbps'], 'Position', [640 270 760 300]);

% 4-Channel Live Network Scope
add_block('simulink/Sinks/Scope', [modelName '/BaseStation_4Channel_Scope'], ...
    'Position', [640 340 690 390], 'NumInputPorts', '4');

% Log to MATLAB Workspace
add_block('simulink/Sinks/To Workspace', [modelName '/Log_Mesh_Data'], ...
    'Position', [640 420 760 450], 'VariableName', 'base_station_mesh_log', 'SaveFormat', 'Array');

fprintf('[OK] Base Station displays and scope added\n');

%% ============================================================
%%  6. INPUT CONNECTIONS
%% ============================================================
add_line(modelName, 'Mission_Clock/1', 'Node1_TX_Rooftop/1',   'autorouting','smart');
add_line(modelName, 'Mission_Clock/1', 'Node2_TX_Corridor/1',  'autorouting','smart');
add_line(modelName, 'Mission_Clock/1', 'Node3_TX_Basement/1',  'autorouting','smart');
add_line(modelName, 'Mission_Clock/1', 'Node4_TX_Perimeter/1', 'autorouting','smart');

add_line(modelName, 'Node1_TX_Rooftop/1',   'Mesh_Channel_Mux/1', 'autorouting','smart');
add_line(modelName, 'Node2_TX_Corridor/1',  'Mesh_Channel_Mux/2', 'autorouting','smart');
add_line(modelName, 'Node3_TX_Basement/1',  'Mesh_Channel_Mux/3', 'autorouting','smart');
add_line(modelName, 'Node4_TX_Perimeter/1', 'Mesh_Channel_Mux/4', 'autorouting','smart');

add_line(modelName, 'Mesh_Channel_Mux/1', 'Base_Station_Receiver_RX/1', 'autorouting','smart');

fprintf('[OK] Input signal routing connected\n');

%% ============================================================
%%  7. ANNOTATIONS
%% ============================================================
a1 = Simulink.Annotation([modelName '/4-NODE WIRELESS MESH NETWORK ──► 1 CENTRAL BASE STATION']);
a1.Position = [480 18]; a1.FontSize = 16; a1.FontWeight = 'bold'; a1.ForegroundColor = 'blue';

a2 = Simulink.Annotation([modelName '/Dual-Band: UHF Penetration (400 MHz Voice) + L-Band Wideband (1.4 GHz Video) | Adaptive MCS (BPSK to 256-QAM)']);
a2.Position = [480 38]; a2.FontSize = 10; a2.ForegroundColor = 'black';

a3 = Simulink.Annotation([modelName '/[NODE 1] Rooftop Leader (HD Video)']);
a3.Position = [115 65]; a3.FontSize = 8; a3.ForegroundColor = 'blue';

a4 = Simulink.Annotation([modelName '/[NODE 2] Corridor Breacher (Relay Node)']);
a4.Position = [115 165]; a4.FontSize = 8; a4.ForegroundColor = 'green';

a5 = Simulink.Annotation([modelName '/[NODE 3] Deep Basement (UHF Penetration)']);
a5.Position = [115 265]; a5.FontSize = 8; a5.ForegroundColor = 'red';

a6 = Simulink.Annotation([modelName '/[NODE 4] Base Perimeter (Overwatch)']);
a6.Position = [115 365]; a6.FontSize = 8; a6.ForegroundColor = 'magenta';

a7 = Simulink.Annotation([modelName '/[1 BASE STATION HUB]']);
a7.Position = [700 250]; a7.FontSize = 9; a7.FontWeight = 'bold'; a7.ForegroundColor = 'blue';

a8 = Simulink.Annotation([modelName '/[MODULATION: 1=BPSK | 2=QPSK | 3=16QAM | 4=64QAM | 5=256QAM]']);
a8.Position = [850 35]; a8.FontSize = 8; a8.FontWeight = 'bold'; a8.ForegroundColor = 'red';

%% Block Colors
try
    set_param([modelName '/Base_Station_Receiver_RX'], 'BackgroundColor', 'cyan');
    set_param([modelName '/Node1_TX_Rooftop'], 'BackgroundColor', 'lightBlue');
    set_param([modelName '/Node2_TX_Corridor'], 'BackgroundColor', 'green');
    set_param([modelName '/Node3_TX_Basement'], 'BackgroundColor', 'orange');
    set_param([modelName '/Node4_TX_Perimeter'], 'BackgroundColor', 'magenta');
end

save_system(modelName);
fprintf('\n[OK] Model successfully built & saved as %s.slx\n\n', modelName);

%% ============================================================
%%  INSTRUCTIONS FOR THE USER
%% ============================================================
fprintf('=================================================================\n');
fprintf('  STEP 1: Double-click the cyan "Base_Station_Receiver_RX" block\n');
fprintf('  STEP 2: Delete default code and paste this:\n');
fprintf('=================================================================\n\n');

fprintf('function [r1, r2, r3, r4, m1, m2, m3, m4, totalRate] = fcn(snr_all)\n');
fprintf('%%%% 4-NODE MESH ──► 1 BASE STATION DEMODULATOR ENGINE\n');
fprintf('coder.extrinsic(''process_pro_mesh'');\n');
fprintf('r1=0; r2=0; r3=0; r4=0; m1=1; m2=1; m3=1; m4=1; totalRate=0;\n');
fprintf('[r1, r2, r3, r4, m1, m2, m3, m4, totalRate] = process_pro_mesh(snr_all);\n');
fprintf('\n');
fprintf('=================================================================\n');
fprintf('  STEP 3: Press Ctrl+S, close editor\n');
fprintf('  STEP 4: Run >> connect_full_4node_outputs\n');
fprintf('  STEP 5: Press ▶ Run in Simulink\n');
fprintf('=================================================================\n');
