%% build_dualband_mesh_dualmod_simulink.m
%  DUAL-BAND DUAL-MODULATION MESH NETWORK SIMULINK MODEL
%  Each Node has:
%    - UHF Adaptive Modulator (Voice / 400 MHz)
%    - L-Band Adaptive Modulator (HD Video Stream / 1.4 GHz)
%  Receiver Side has:
%    - UHF Demodulator (RX)
%    - L-Band Demodulator (RX)
%    - Mesh Relay & Aggregator Hub
%  Tactical PHY Mesh — ARYA-mgc
%
%  Usage: >> build_dualband_mesh_dualmod_simulink

clc;
fprintf('=================================================================\n');
fprintf('  BUILDING DUAL-BAND DUAL-MODULATOR MESH SIMULINK MODEL\n');
fprintf('  Separate UHF Modulator (Voice) + L-Band Modulator (Video)\n');
fprintf('  Separate UHF Demodulator (RX) + L-Band Demodulator (RX)\n');
fprintf('  Tactical PHY Mesh — ARYA-mgc\n');
fprintf('=================================================================\n\n');

modelName = 'DualBand_DualMod_Mesh_Simulink';

if bdIsLoaded(modelName), close_system(modelName, 0); end
if exist([modelName '.slx'],'file'), delete([modelName '.slx']); end

new_system(modelName);
open_system(modelName);
set_param(modelName, 'StopTime','210', 'SolverType','Fixed-step', 'FixedStep','1');

%% ============================================================
%%  1. TRANSMITTER INPUTS (Voice & Video Streams)
%% ============================================================
% UHF Voice / Tactical Text Message Payload
add_block('simulink/Sources/Constant', [modelName '/UHF_Voice_Msg_TX'], ...
    'Position', [30 80 180 110], 'Value', 'uint8([85 72 70 95 86 79 73 67 69 95 79 75])'); % 'UHF_VOICE_OK'

% L-Band HD Video Stream Payload
add_block('simulink/Sources/Constant', [modelName '/LBand_Video_Stream_TX'], ...
    'Position', [30 170 180 200], 'Value', 'uint8([76 66 65 78 68 95 86 73 68 69 79])'); % 'LBAND_VIDEO'

% Commando Mission SNR Profile (Time-Varying Environment)
add_block('simulink/Sources/Clock', [modelName '/Mission_Clock'], 'Position', [30 260 55 280]);
t_ch = '[0 50 51 100 101 160 161 210]';
s_ch = '[30 30 18 18  25  25  30  30]';
add_block('simulink/Lookup Tables/1-D Lookup Table', [modelName '/Link_SNR_Profile'], ...
    'Position', [100 255 180 285], 'Table', s_ch, 'BreakpointsForDimension1', t_ch);

fprintf('[OK] Voice, Video & Link SNR Sources created\n');

%% ============================================================
%%  2. DUAL-BAND MODULATOR BLOCKS (TX SIDE)
%% ============================================================
% Block A: UHF Adaptive Modulator (380-470 MHz)
add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [modelName '/UHF_Adaptive_Modulator_TX'], ...
    'Position', [250 70 430 130]);

% Block B: L-Band Adaptive Modulator (1.2-1.6 GHz)
add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [modelName '/LBand_Adaptive_Modulator_TX'], ...
    'Position', [250 160 430 220]);

%% ============================================================
%%  3. WIRELESS MESH PROPAGATION CHANNELS
%% ============================================================
add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [modelName '/DualBand_Wireless_Channel'], ...
    'Position', [490 100 640 200]);

%% ============================================================
%%  4. DUAL-BAND DEMODULATOR BLOCKS (RX / BASE STATION SIDE)
%% ============================================================
% Block C: UHF Demodulator (RX)
add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [modelName '/UHF_Demodulator_RX'], ...
    'Position', [700 70 880 130]);

% Block D: L-Band Demodulator (RX)
add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [modelName '/LBand_Demodulator_RX'], ...
    'Position', [700 160 880 220]);

fprintf('[OK] All Modulator, Channel, and Demodulator blocks added\n');

%% ============================================================
%%  5. OUTPUT DISPLAYS & SCOPES
%% ============================================================
% UHF Outputs
add_block('simulink/Sinks/Display', [modelName '/UHF_Voice_Rate_kbps'], 'Position', [950 50 1070 75]);
add_block('simulink/Sinks/Display', [modelName '/UHF_Modulation_Scheme'], 'Position', [950 85 1070 110]);
add_block('simulink/Sinks/Display', [modelName '/UHF_BER'],              'Position', [950 120 1070 145]);

% L-Band Outputs
add_block('simulink/Sinks/Display', [modelName '/LBand_Video_Rate_Mbps'], 'Position', [950 170 1070 195]);
add_block('simulink/Sinks/Display', [modelName '/LBand_Modulation_Scheme'],'Position', [950 205 1070 230]);
add_block('simulink/Sinks/Display', [modelName '/LBand_BER'],             'Position', [950 240 1070 265]);

% Combined Aggregate Output
add_block('simulink/Sinks/Display', [modelName '/Total_DualBand_Mbps'],    'Position', [950 290 1070 320]);

% Dual-Channel Scope
add_block('simulink/Sinks/Scope', [modelName '/DualBand_Scope'], ...
    'Position', [950 350 1000 400], 'NumInputPorts', '2');

% Data Logger
add_block('simulink/Sinks/To Workspace', [modelName '/Log_DualBand_Data'], ...
    'Position', [950 420 1070 450], 'VariableName', 'dualband_log', 'SaveFormat', 'Array');

fprintf('[OK] Displays, Scopes, and Data Loggers created\n');

%% ============================================================
%%  6. INJECT CODE FIRST TO DEFINE PORTS
%% ============================================================
fprintf('Configuring block ports and internal algorithms...\n');
try
    rt = sfroot;
    charts = rt.find('-isa', 'Stateflow.EMChart');
    for c = 1:length(charts)
        p = charts(c).Path;
        if contains(p, 'UHF_Adaptive_Modulator_TX')
            charts(c).Script = sprintf([ ...
                'function [uhf_syms, uhf_bps] = fcn(msg_bytes, snr)\n' ...
                '%%%% UHF ADAPTIVE MODULATOR (TX)\n' ...
                'coder.extrinsic(''process_uhf_tx'');\n' ...
                'uhf_syms = complex(zeros(1, 400)); uhf_bps = 1;\n' ...
                '[uhf_syms, uhf_bps] = process_uhf_tx(msg_bytes, snr);\n']);
        elseif contains(p, 'LBand_Adaptive_Modulator_TX')
            charts(c).Script = sprintf([ ...
                'function [lband_syms, lband_bps] = fcn(video_bytes, snr)\n' ...
                '%%%% L-BAND ADAPTIVE MODULATOR (TX)\n' ...
                'coder.extrinsic(''process_lband_tx'');\n' ...
                'lband_syms = complex(zeros(1, 400)); lband_bps = 4;\n' ...
                '[lband_syms, lband_bps] = process_lband_tx(video_bytes, snr);\n']);
        elseif contains(p, 'DualBand_Wireless_Channel')
            charts(c).Script = sprintf([ ...
                'function [rx_uhf, rx_lband] = fcn(tx_uhf, tx_lband, snr)\n' ...
                '%%%% DUAL-BAND WIRELESS CHANNEL\n' ...
                'coder.extrinsic(''awgn'');\n' ...
                'rx_uhf = awgn(tx_uhf, snr, ''measured'');\n' ...
                'rx_lband = awgn(tx_lband, max(2, snr - 3), ''measured'');\n']);
        elseif contains(p, 'UHF_Demodulator_RX')
            charts(c).Script = sprintf([ ...
                'function [uhf_rate, uhf_modIdx, uhf_ber] = fcn(rx_uhf, snr)\n' ...
                '%%%% UHF DEMODULATOR (RX)\n' ...
                'coder.extrinsic(''process_uhf_rx'');\n' ...
                'uhf_rate = 0; uhf_modIdx = 1; uhf_ber = 0;\n' ...
                '[uhf_rate, uhf_modIdx, uhf_ber] = process_uhf_rx(rx_uhf, snr);\n']);
        elseif contains(p, 'LBand_Demodulator_RX')
            charts(c).Script = sprintf([ ...
                'function [lband_rate, lband_modIdx, lband_ber] = fcn(rx_lband, snr)\n' ...
                '%%%% L-BAND DEMODULATOR (RX)\n' ...
                'coder.extrinsic(''process_lband_rx'');\n' ...
                'lband_rate = 0; lband_modIdx = 3; lband_ber = 0;\n' ...
                '[lband_rate, lband_modIdx, lband_ber] = process_lband_rx(rx_lband, snr);\n']);
        end
    end
    save_system(modelName);
    fprintf('[OK] Block ports configured!\n');
catch ME
    fprintf('[NOTE] Code injection status: %s\n', ME.message);
end

%% ============================================================
%%  7. CONNECT ALL SIGNAL WIRES
%% ============================================================
try
    add_line(modelName, 'Mission_Clock/1', 'Link_SNR_Profile/1', 'autorouting','smart');

    % Connect TX Modulators
    add_line(modelName, 'UHF_Voice_Msg_TX/1',      'UHF_Adaptive_Modulator_TX/1',   'autorouting','smart');
    add_line(modelName, 'Link_SNR_Profile/1',      'UHF_Adaptive_Modulator_TX/2',   'autorouting','smart');

    add_line(modelName, 'LBand_Video_Stream_TX/1', 'LBand_Adaptive_Modulator_TX/1', 'autorouting','smart');
    add_line(modelName, 'Link_SNR_Profile/1',      'LBand_Adaptive_Modulator_TX/2', 'autorouting','smart');

    % Connect Channel
    add_line(modelName, 'UHF_Adaptive_Modulator_TX/1',   'DualBand_Wireless_Channel/1', 'autorouting','smart');
    add_line(modelName, 'LBand_Adaptive_Modulator_TX/1', 'DualBand_Wireless_Channel/2', 'autorouting','smart');
    add_line(modelName, 'Link_SNR_Profile/1',            'DualBand_Wireless_Channel/3', 'autorouting','smart');

    % Connect RX Demodulators
    add_line(modelName, 'DualBand_Wireless_Channel/1', 'UHF_Demodulator_RX/1',   'autorouting','smart');
    add_line(modelName, 'Link_SNR_Profile/1',          'UHF_Demodulator_RX/2',   'autorouting','smart');

    add_line(modelName, 'DualBand_Wireless_Channel/2', 'LBand_Demodulator_RX/1', 'autorouting','smart');
    add_line(modelName, 'Link_SNR_Profile/1',          'LBand_Demodulator_RX/2', 'autorouting','smart');

    % Connect UHF Outputs
    add_line(modelName, 'UHF_Demodulator_RX/1', 'UHF_Voice_Rate_kbps/1', 'autorouting','smart');
    add_line(modelName, 'UHF_Demodulator_RX/2', 'UHF_Modulation_Scheme/1', 'autorouting','smart');
    add_line(modelName, 'UHF_Demodulator_RX/3', 'UHF_BER/1', 'autorouting','smart');
    add_line(modelName, 'UHF_Demodulator_RX/1', 'DualBand_Scope/1', 'autorouting','smart');

    % Connect L-Band Outputs
    add_line(modelName, 'LBand_Demodulator_RX/1', 'LBand_Video_Rate_Mbps/1', 'autorouting','smart');
    add_line(modelName, 'LBand_Demodulator_RX/2', 'LBand_Modulation_Scheme/1', 'autorouting','smart');
    add_line(modelName, 'LBand_Demodulator_RX/3', 'LBand_BER/1', 'autorouting','smart');
    add_line(modelName, 'LBand_Demodulator_RX/1', 'Total_DualBand_Mbps/1', 'autorouting','smart');
    add_line(modelName, 'LBand_Demodulator_RX/1', 'DualBand_Scope/2', 'autorouting','smart');
    add_line(modelName, 'LBand_Demodulator_RX/1', 'Log_DualBand_Data/1', 'autorouting','smart');
    fprintf('[OK] All input and output signal lines connected!\n');
catch
    fprintf('[NOTE] Run >> connect_dualband_dualmod_outputs to complete wiring.\n');
end

%% ============================================================
%%  8. ANNOTATIONS
%% ============================================================
a1 = Simulink.Annotation([modelName '/DUAL-BAND DUAL-MODULATOR MESH ARCHITECTURE']);
a1.Position = [520 18]; a1.FontSize = 16; a1.FontWeight = 'bold'; a1.ForegroundColor = 'blue';

a2 = Simulink.Annotation([modelName '/UHF Modulator (Voice 400 MHz) + L-Band Modulator (Video 1.4 GHz) ──► Wireless Mesh Channel ──► Dual Demodulator RX']);
a2.Position = [520 38]; a2.FontSize = 10; a2.ForegroundColor = 'black';

a3 = Simulink.Annotation([modelName '/[TRANSMITTER (TX)]']);
a3.Position = [340 52]; a3.FontSize = 9; a3.FontWeight = 'bold'; a3.ForegroundColor = 'blue';

a4 = Simulink.Annotation([modelName '/[WIRELESS CHANNEL]']);
a4.Position = [565 82]; a4.FontSize = 9; a4.FontWeight = 'bold'; a4.ForegroundColor = 'magenta';

a5 = Simulink.Annotation([modelName '/[RECEIVER (RX) / BASE STATION]']);
a5.Position = [790 52]; a5.FontSize = 9; a5.FontWeight = 'bold'; a5.ForegroundColor = 'blue';

%% Colors
try
    set_param([modelName '/UHF_Adaptive_Modulator_TX'], 'BackgroundColor', 'yellow');
    set_param([modelName '/LBand_Adaptive_Modulator_TX'], 'BackgroundColor', 'lightBlue');
    set_param([modelName '/DualBand_Wireless_Channel'], 'BackgroundColor', 'orange');
    set_param([modelName '/UHF_Demodulator_RX'], 'BackgroundColor', 'green');
    set_param([modelName '/LBand_Demodulator_RX'], 'BackgroundColor', 'cyan');
end

save_system(modelName);
fprintf('\n=================================================================\n');
fprintf('  [OK] Model successfully built & saved as %s.slx\n', modelName);
fprintf('  Press ▶ Run in Simulink to simulate!\n');
fprintf('=================================================================\n\n');
