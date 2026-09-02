%% build_simple_phy_simulink.m
%  SIMPLE & RELIABLE Simulink model — one MATLAB Function block
%  Tactical PHY Mesh — ARYA-mgc

clc; close all;
fprintf('Building Simple PHY Simulink Model...\n\n');

modelName = 'PHY_AdaptiveMod_AryaMGC';

if bdIsLoaded(modelName), close_system(modelName, 0); end
if exist([modelName '.slx'],'file'), delete([modelName '.slx']); end

new_system(modelName);
open_system(modelName);
set_param(modelName, 'StopTime','35', 'SolverType','Fixed-step', 'FixedStep','1');

%% BLOCKS
add_block('simulink/Sources/Clock', [modelName '/Clock'], 'Position',[50 180 80 210]);
add_block('simulink/Math Operations/Gain', [modelName '/SNR'], 'Position',[120 180 160 210], 'Gain','1');
add_block('simulink/User-Defined Functions/MATLAB Function', [modelName '/PHY_Simulator'], 'Position',[230 150 420 240]);
add_block('simulink/Sinks/Display', [modelName '/BER'], 'Position',[500 110 600 140]);
add_block('simulink/Sinks/Display', [modelName '/MER'], 'Position',[500 160 600 190]);
add_block('simulink/Sinks/Display', [modelName '/MCS'], 'Position',[500 210 600 240]);
add_block('simulink/Sinks/Display', [modelName '/Throughput'], 'Position',[500 260 600 290]);
add_block('simulink/Sinks/Scope', [modelName '/Scope'], 'Position',[500 310 550 350], 'NumInputPorts','3');
add_block('simulink/Sinks/To Workspace', [modelName '/Log_BER'], 'Position',[650 110 740 140], 'VariableName','sim_ber', 'SaveFormat','Array');
add_block('simulink/Sinks/To Workspace', [modelName '/Log_MER'], 'Position',[650 160 740 190], 'VariableName','sim_mer', 'SaveFormat','Array');
add_block('simulink/Sinks/To Workspace', [modelName '/Log_MCS'], 'Position',[650 210 740 240], 'VariableName','sim_mcs', 'SaveFormat','Array');
add_block('simulink/Sinks/To Workspace', [modelName '/Log_Tput'], 'Position',[650 260 740 290], 'VariableName','sim_tput', 'SaveFormat','Array');
add_block('simulink/Sinks/To Workspace', [modelName '/Log_SNR'], 'Position',[230 290 320 320], 'VariableName','sim_snr', 'SaveFormat','Array');

fprintf('[OK] All blocks added\n');

%% CONNECT INPUT ONLY
add_line(modelName, 'Clock/1', 'SNR/1', 'autorouting','smart');
add_line(modelName, 'SNR/1', 'PHY_Simulator/1', 'autorouting','smart');
add_line(modelName, 'SNR/1', 'Log_SNR/1', 'autorouting','smart');

%% ANNOTATIONS
a1 = Simulink.Annotation([modelName '/FULL PHY ADAPTIVE MODULATION — Tactical PHY Mesh — ARYA-mgc']);
a1.Position = [380 30]; a1.FontSize = 16; a1.FontWeight = 'bold'; a1.ForegroundColor = 'blue';
a2 = Simulink.Annotation([modelName '/TX(Scramble+FEC+QAM+OFDM) -> Channel(AWGN) -> RX(FFT+EQ+Demod+Viterbi) -> BER/MER']);
a2.Position = [380 55]; a2.FontSize = 10; a2.ForegroundColor = 'black';

%% COLORS
try
    set_param([modelName '/PHY_Simulator'], 'BackgroundColor', 'cyan');
    set_param([modelName '/Clock'], 'BackgroundColor', 'yellow');
end

%% SAVE FIRST
save_system(modelName);
fprintf('[OK] Model saved\n');

%% SET MATLAB FUNCTION CODE
fprintf('[..] Setting MATLAB Function code...\n');
rt = sfroot;
charts = rt.find('-isa', 'Stateflow.EMChart');

codeSet = false;
for c = 1:length(charts)
    if contains(charts(c).Path, 'PHY_Simulator')
        charts(c).Script = sprintf([ ...
            'function [ber, mer, mcsIdx, throughput] = fcn(snr)\n' ...
            '%%%% FULL PHY SIMULATOR — Tactical PHY Mesh — ARYA-mgc\n' ...
            '%%%% TX -> Channel -> RX with Adaptive Modulation\n' ...
            'coder.extrinsic(''run_phy_step'');\n' ...
            '\n' ...
            '%%%% Adaptive MCS Selection\n' ...
            'if snr >= 28\n' ...
            '    modOrder = 256; bps = 8; mcsIdx = 8;\n' ...
            'elseif snr >= 24\n' ...
            '    modOrder = 64; bps = 6; mcsIdx = 7;\n' ...
            'elseif snr >= 20\n' ...
            '    modOrder = 64; bps = 6; mcsIdx = 6;\n' ...
            'elseif snr >= 16\n' ...
            '    modOrder = 16; bps = 4; mcsIdx = 5;\n' ...
            'elseif snr >= 12\n' ...
            '    modOrder = 16; bps = 4; mcsIdx = 4;\n' ...
            'elseif snr >= 9\n' ...
            '    modOrder = 4; bps = 2; mcsIdx = 3;\n' ...
            'elseif snr >= 5\n' ...
            '    modOrder = 4; bps = 2; mcsIdx = 2;\n' ...
            'else\n' ...
            '    modOrder = 2; bps = 1; mcsIdx = 1;\n' ...
            'end\n' ...
            '\n' ...
            '%%%% Run full PHY simulation step\n' ...
            'ber = double(0); mer = double(0); throughput = double(0);\n' ...
            '[ber, mer, throughput] = run_phy_step(snr, modOrder, bps);\n']);
        codeSet = true;
        fprintf('[OK] Code injected into PHY_Simulator!\n');
        break;
    end
end

if ~codeSet
    fprintf('[!!] Code injection failed. You will need to paste manually.\n');
end

%% SAVE AGAIN (ports now exist)
save_system(modelName);
pause(1);

%% CONNECT OUTPUTS
if codeSet
    fprintf('[..] Connecting outputs...\n');
    try
        add_line(modelName, 'PHY_Simulator/1', 'BER/1', 'autorouting','smart');
        add_line(modelName, 'PHY_Simulator/2', 'MER/1', 'autorouting','smart');
        add_line(modelName, 'PHY_Simulator/3', 'MCS/1', 'autorouting','smart');
        add_line(modelName, 'PHY_Simulator/4', 'Throughput/1', 'autorouting','smart');
        add_line(modelName, 'PHY_Simulator/1', 'Log_BER/1', 'autorouting','smart');
        add_line(modelName, 'PHY_Simulator/2', 'Log_MER/1', 'autorouting','smart');
        add_line(modelName, 'PHY_Simulator/3', 'Log_MCS/1', 'autorouting','smart');
        add_line(modelName, 'PHY_Simulator/4', 'Log_Tput/1', 'autorouting','smart');
        add_line(modelName, 'PHY_Simulator/1', 'Scope/1', 'autorouting','smart');
        add_line(modelName, 'PHY_Simulator/2', 'Scope/2', 'autorouting','smart');
        add_line(modelName, 'PHY_Simulator/4', 'Scope/3', 'autorouting','smart');
        fprintf('[OK] All outputs connected!\n');
    catch ME
        fprintf('[!!] Connection error: %s\n', ME.message);
    end
end

save_system(modelName);

%% DONE
fprintf('\n=================================================================\n');
fprintf('  Model ready: %s.slx\n', modelName);
fprintf('=================================================================\n');
fprintf('  1. Press Run in Simulink\n');
fprintf('  2. Then run: >> plot_full_phy_results\n');
fprintf('=================================================================\n');
