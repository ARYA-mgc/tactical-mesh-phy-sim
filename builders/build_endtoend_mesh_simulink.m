%% build_endtoend_mesh_simulink.m
%  END-TO-END DATA/VIDEO/MESSAGE TRANSMISSION SIMULINK MODEL
%  Takes ACTUAL MESSAGE & VIDEO BITSTREAMS as inputs (NOT just SNR numbers)
%  Encodes → Modulates → Transmits across Mesh Channel → Decodes at Base Station
%  Outputs: Decoded Text Messages, Recovered Video Bitstream, BER, and Rates!
%  Tactical PHY Mesh — ARYA-mgc
%
%  Usage: >> build_endtoend_mesh_simulink

clc;
fprintf('=================================================================\n');
fprintf('  BUILDING END-TO-END MESSAGE & VIDEO MESH SIMULINK MODEL\n');
fprintf('  Inputs: Actual Messages, Video Frames & Telemetry Streams\n');
fprintf('  Tactical PHY Mesh — ARYA-mgc\n');
fprintf('=================================================================\n\n');

modelName = 'EndToEnd_Mesh_VideoMsg_Simulink';

if bdIsLoaded(modelName), close_system(modelName, 0); end
if exist([modelName '.slx'],'file'), delete([modelName '.slx']); end

new_system(modelName);
open_system(modelName);
set_param(modelName, 'StopTime','210', 'SolverType','Fixed-step', 'FixedStep','1');

%% ============================================================
%%  1. REAL MESSAGE & VIDEO STREAM GENERATORS (TX INPUTS)
%% ============================================================
% Node 1: HD Video Stream Bit Pattern (L-Band 1.4 GHz)
add_block('simulink/Sources/Constant', [modelName '/Node1_Video_Stream_TX'], ...
    'Position', [30 70 180 100], 'Value', 'uint8([82 79 79 70 84 79 80 95 72 68 95 86 73 68 69 79])'); % 'ROOFTOP_HD_VIDEO'

% Node 2: Tactical Text Message (Corridor Link)
add_block('simulink/Sources/Constant', [modelName '/Node2_Tactical_Msg_TX'], ...
    'Position', [30 160 180 190], 'Value', 'uint8([67 79 82 82 73 68 79 82 95 67 76 69 65 82])'); % 'CORRIDOR_CLEAR'

% Node 3: Deep Basement Voice/Text Message (UHF Penetration Mode)
add_block('simulink/Sources/Constant', [modelName '/Node3_Basement_Msg_TX'], ...
    'Position', [30 250 180 280], 'Value', 'uint8([66 65 83 69 77 69 78 84 95 83 65 70 69])'); % 'BASEMENT_SAFE'

% Node 4: Base Perimeter Telemetry Stream
add_block('simulink/Sources/Constant', [modelName '/Node4_Telemetry_Stream_TX'], ...
    'Position', [30 340 180 370], 'Value', 'uint8([80 69 82 73 77 69 84 69 82 95 79 75])'); % 'PERIMETER_OK'

% Time Clock for Channel Impairment Evolution
add_block('simulink/Sources/Clock', [modelName '/Mission_Clock'], ...
    'Position', [30 420 60 440]);

fprintf('[OK] Real Video/Message TX Input sources created\n');

%% ============================================================
%%  2. TIME-VARYING CHANNEL SNR PROFILE (Environment)
%% ============================================================
t_ch = '[0 50 51 100 101 160 161 210]';
s_ch = '[30 30 18 18  25  25  30  30]';
add_block('simulink/Lookup Tables/1-D Lookup Table', [modelName '/CQB_Channel_SNR'], ...
    'Position', [100 415 180 445], 'Table', s_ch, 'BreakpointsForDimension1', t_ch);

%% ============================================================
%%  3. CENTRAL END-TO-END MESH ENGINE (MATLAB Function)
%% ============================================================
add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [modelName '/EndToEnd_Mesh_Engine'], ...
    'Position', [280 120 540 380]);

fprintf('[OK] End-to-End Mesh PHY Engine added\n');

%% ============================================================
%%  4. RECOVERED OUTPUTS & DISPLAYS (Base Station Receiver)
%% ============================================================
% Video Stream Rates (Mbps)
add_block('simulink/Sinks/Display', [modelName '/N1_Recovered_Video_Mbps'], 'Position', [640 50 770 75]);
add_block('simulink/Sinks/Display', [modelName '/N2_Recovered_Data_Mbps'],  'Position', [640 100 770 125]);
add_block('simulink/Sinks/Display', [modelName '/N3_Recovered_Voice_Mbps'], 'Position', [640 150 770 175]);
add_block('simulink/Sinks/Display', [modelName '/N4_Recovered_Data_Mbps'],  'Position', [640 200 770 225]);

% Decoded Message Verification Status (1 = 100% Error-Free Decoded, 0 = Errors)
add_block('simulink/Sinks/Display', [modelName '/N1_Video_Stream_Integrity'], 'Position', [810 50 930 75]);
add_block('simulink/Sinks/Display', [modelName '/N2_Msg_Decoded_100pct'],      'Position', [810 100 930 125]);
add_block('simulink/Sinks/Display', [modelName '/N3_Basement_Msg_Decoded_100pct'],'Position', [810 150 930 175]);
add_block('simulink/Sinks/Display', [modelName '/N4_Telemetry_Decoded_100pct'],  'Position', [810 200 930 225]);

% Total Base Station Received Aggregate Bandwidth
add_block('simulink/Sinks/Display', [modelName '/Total_BaseStation_Throughput'], 'Position', [640 270 770 300]);

% Active Modulation Indicators (5=256QAM, 4=64QAM, 3=16QAM, 2=QPSK, 1=BPSK)
add_block('simulink/Sinks/Display', [modelName '/Active_Modulation_Scheme'], 'Position', [810 270 930 300]);

% Multi-Channel Scope (Signals across nodes)
add_block('simulink/Sinks/Scope', [modelName '/BaseStation_Data_Scope'], ...
    'Position', [640 340 690 390], 'NumInputPorts', '4');

% To Workspace Logger
add_block('simulink/Sinks/To Workspace', [modelName '/Log_Decoded_Data'], ...
    'Position', [640 420 770 450], 'VariableName', 'decoded_mesh_data', 'SaveFormat', 'Array');

fprintf('[OK] Recovered displays, status badges, and scopes created\n');

%% ============================================================
%%  5. INPUT CONNECTIONS
%% ============================================================
add_line(modelName, 'Node1_Video_Stream_TX/1',     'EndToEnd_Mesh_Engine/1', 'autorouting','smart');
add_line(modelName, 'Node2_Tactical_Msg_TX/1',     'EndToEnd_Mesh_Engine/2', 'autorouting','smart');
add_line(modelName, 'Node3_Basement_Msg_TX/1',     'EndToEnd_Mesh_Engine/3', 'autorouting','smart');
add_line(modelName, 'Node4_Telemetry_Stream_TX/1', 'EndToEnd_Mesh_Engine/4', 'autorouting','smart');
add_line(modelName, 'Mission_Clock/1',             'CQB_Channel_SNR/1',      'autorouting','smart');
add_line(modelName, 'CQB_Channel_SNR/1',           'EndToEnd_Mesh_Engine/5', 'autorouting','smart');

fprintf('[OK] Input stream connections established\n');

%% ============================================================
%%  6. ANNOTATIONS & LABELS
%% ============================================================
a1 = Simulink.Annotation([modelName '/END-TO-END TACTICAL MESH: VIDEO STREAM & MESSAGE PROPAGATION']);
a1.Position = [500 18]; a1.FontSize = 16; a1.FontWeight = 'bold'; a1.ForegroundColor = 'blue';

a2 = Simulink.Annotation([modelName '/Inputs: Real Video Frames & Tactical Messages ──► QAM/OFDM Mesh Channel ──► Base Station Decoded Outputs']);
a2.Position = [500 38]; a2.FontSize = 10; a2.ForegroundColor = 'black';

a3 = Simulink.Annotation([modelName '/[TX 1] Node 1 HD Video Stream']);
a3.Position = [105 55]; a3.FontSize = 8; a3.ForegroundColor = 'blue';

a4 = Simulink.Annotation([modelName '/[TX 2] Node 2 Tactical Text Msg']);
a4.Position = [105 145]; a4.FontSize = 8; a4.ForegroundColor = 'green';

a5 = Simulink.Annotation([modelName '/[TX 3] Node 3 Basement UHF Msg']);
a5.Position = [105 235]; a5.FontSize = 8; a5.ForegroundColor = 'red';

a6 = Simulink.Annotation([modelName '/[TX 4] Node 4 Telemetry Stream']);
a6.Position = [105 325]; a6.FontSize = 8; a6.ForegroundColor = 'magenta';

a7 = Simulink.Annotation([modelName '/[BASE STATION RECEIVER & DECODER]']);
a7.Position = [700 250]; a7.FontSize = 9; a7.FontWeight = 'bold'; a7.ForegroundColor = 'blue';

a8 = Simulink.Annotation([modelName '/[DECRYPTION INTEGRITY]']);
a8.Position = [870 35]; a8.FontSize = 8; a8.FontWeight = 'bold'; a8.ForegroundColor = 'black';

%% Block Colors
try
    set_param([modelName '/EndToEnd_Mesh_Engine'], 'BackgroundColor', 'cyan');
    set_param([modelName '/Node1_Video_Stream_TX'], 'BackgroundColor', 'lightBlue');
    set_param([modelName '/Node2_Tactical_Msg_TX'], 'BackgroundColor', 'green');
    set_param([modelName '/Node3_Basement_Msg_TX'], 'BackgroundColor', 'orange');
    set_param([modelName '/Node4_Telemetry_Stream_TX'], 'BackgroundColor', 'magenta');
end

save_system(modelName);
fprintf('\n[OK] Model successfully built & saved as %s.slx\n\n', modelName);

%% ============================================================
%%  INSTRUCTIONS FOR THE USER
%% ============================================================
fprintf('=================================================================\n');
fprintf('  STEP 1: Double-click the cyan "EndToEnd_Mesh_Engine" block\n');
fprintf('  STEP 2: Delete default code and paste this:\n');
fprintf('=================================================================\n\n');

fprintf('function [r1, r2, r3, r4, ok1, ok2, ok3, ok4, totalRate, modLvl] = fcn(tx1, tx2, tx3, tx4, snr_ch)\n');
fprintf('%%%% END-TO-END MESH VIDEO & MESSAGE ENGINE\n');
fprintf('coder.extrinsic(''process_endtoend_mesh'');\n');
fprintf('r1=0; r2=0; r3=0; r4=0; ok1=1; ok2=1; ok3=1; ok4=1; totalRate=0; modLvl=5;\n');
fprintf('[r1, r2, r3, r4, ok1, ok2, ok3, ok4, totalRate, modLvl] = process_endtoend_mesh(tx1, tx2, tx3, tx4, snr_ch);\n');
fprintf('\n');
fprintf('=================================================================\n');
fprintf('  STEP 3: Press Ctrl+S, close editor\n');
fprintf('  STEP 4: Run >> connect_endtoend_outputs\n');
fprintf('  STEP 5: Press ▶ Run in Simulink\n');
fprintf('=================================================================\n');
