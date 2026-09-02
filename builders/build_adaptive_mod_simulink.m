%% build_adaptive_mod_simulink.m
%  Builds Simulink model for Adaptive Modulation + generates figures
%  Tactical PHY Mesh — ARYA-mgc
%
%  Usage:  >> build_adaptive_mod_simulink

clc;
fprintf('============================================================\n');
fprintf('  Building Adaptive Modulation Simulink Model\n');
fprintf('  Tactical PHY Mesh — ARYA-mgc\n');
fprintf('============================================================\n\n');

modelName = 'AdaptiveModulation_HelmetAntenna';

%% Close & clean
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end
if exist([modelName '.slx'], 'file')
    delete([modelName '.slx']);
end

%% Create model
new_system(modelName);
open_system(modelName);
set_param(modelName, 'StopTime', '200');
set_param(modelName, 'SolverType', 'Fixed-step');
set_param(modelName, 'FixedStep', '1');
fprintf('[OK] Model created\n');

%% ===== 1. SNR SOURCE =====
add_block('simulink/Sources/Clock', ...
    [modelName '/Clock'], ...
    'Position', [50 200 90 230]);

add_block('simulink/Math Operations/Gain', ...
    [modelName '/SNR_Gain'], ...
    'Position', [140 200 180 230], ...
    'Gain', '0.2');
fprintf('[OK] SNR source\n');

%% ===== 2. MATLAB FUNCTION: Adaptive MCS Selector =====
add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [modelName '/Adaptive_Decision_Engine'], ...
    'Position', [260 170 430 260]);
fprintf('[OK] MATLAB Function block added\n');

%% ===== 3. DISPLAYS =====
add_block('simulink/Sinks/Display', ...
    [modelName '/SNR_Display'], ...
    'Position', [260 290 350 320]);

add_block('simulink/Sinks/Display', ...
    [modelName '/ModOrder_Display'], ...
    'Position', [520 150 620 180]);

add_block('simulink/Sinks/Display', ...
    [modelName '/BitsPerSym_Display'], ...
    'Position', [520 200 620 230]);

add_block('simulink/Sinks/Display', ...
    [modelName '/Throughput_Display'], ...
    'Position', [520 250 620 280]);
fprintf('[OK] Display blocks\n');

%% ===== 4. SCOPE =====
add_block('simulink/Sinks/Scope', ...
    [modelName '/Scope'], ...
    'Position', [520 310 570 350], ...
    'NumInputPorts', '2');
fprintf('[OK] Scope\n');

%% ===== 5. TO WORKSPACE (for figure generation) =====
add_block('simulink/Sinks/To Workspace', ...
    [modelName '/Log_SNR'], ...
    'Position', [260 350 340 380], ...
    'VariableName', 'sim_SNR', ...
    'SaveFormat', 'Array');

add_block('simulink/Sinks/To Workspace', ...
    [modelName '/Log_ModOrder'], ...
    'Position', [520 370 620 400], ...
    'VariableName', 'sim_ModOrder', ...
    'SaveFormat', 'Array');

add_block('simulink/Sinks/To Workspace', ...
    [modelName '/Log_BitsPerSym'], ...
    'Position', [520 420 620 450], ...
    'VariableName', 'sim_BitsPerSym', ...
    'SaveFormat', 'Array');

add_block('simulink/Sinks/To Workspace', ...
    [modelName '/Log_Throughput'], ...
    'Position', [520 470 620 500], ...
    'VariableName', 'sim_Throughput', ...
    'SaveFormat', 'Array');
fprintf('[OK] To Workspace logging blocks\n');

%% ===== CONNECT =====
fprintf('[..] Connecting...\n');

add_line(modelName, 'Clock/1', 'SNR_Gain/1', 'autorouting', 'smart');
add_line(modelName, 'SNR_Gain/1', 'Adaptive_Decision_Engine/1', 'autorouting', 'smart');
add_line(modelName, 'SNR_Gain/1', 'SNR_Display/1', 'autorouting', 'smart');
add_line(modelName, 'SNR_Gain/1', 'Log_SNR/1', 'autorouting', 'smart');
add_line(modelName, 'SNR_Gain/1', 'Scope/1', 'autorouting', 'smart');

fprintf('[OK] SNR connections done\n');
fprintf('\n');
fprintf('[!!] MATLAB Function block has only 1 output by default.\n');
fprintf('     After the model opens, you MUST:\n');
fprintf('     1. Double-click "Adaptive_Decision_Engine"\n');
fprintf('     2. Paste the code (printed below)\n');
fprintf('     3. Press Ctrl+S, close the editor\n');
fprintf('     4. THEN run: connect_and_run\n');

%% ===== ANNOTATIONS =====
a1 = Simulink.Annotation([modelName '/ADAPTIVE MODULATION — DUAL-BAND HELMET ANTENNA SYSTEM']);
a1.Position = [350 30]; a1.FontSize = 16; a1.FontWeight = 'bold'; a1.ForegroundColor = 'blue';

a2 = Simulink.Annotation([modelName '/Tactical PHY Mesh — ARYA-mgc']);
a2.Position = [350 55]; a2.FontSize = 12; a2.ForegroundColor = 'black';

a3 = Simulink.Annotation([modelName '/Thresholds: BPSK(<8dB) | QPSK(8-13dB) | 16QAM(14-19dB) | 64QAM(20-25dB) | 256QAM(>=26dB)']);
a3.Position = [350 530]; a3.FontSize = 10; a3.ForegroundColor = 'red';

a4 = Simulink.Annotation([modelName '/Mod Order (M) ->']);
a4.Position = [460 160]; a4.FontSize = 9;

a5 = Simulink.Annotation([modelName '/Bits/Symbol ->']);
a5.Position = [460 210]; a5.FontSize = 9;

a6 = Simulink.Annotation([modelName '/Throughput (Mbps) ->']);
a6.Position = [460 260]; a6.FontSize = 9;

fprintf('[OK] Annotations\n');

%% ===== COLORS =====
try
    set_param([modelName '/Adaptive_Decision_Engine'], 'BackgroundColor', 'cyan');
    set_param([modelName '/Clock'], 'BackgroundColor', 'yellow');
    fprintf('[OK] Colors\n');
catch
end

%% ===== SET MATLAB FUNCTION CODE via Stateflow API =====
fprintf('[..] Setting MATLAB Function code...\n');
try
    save_system(modelName);  % must save first
    rt = sfroot;
    allCharts = rt.find('-isa', 'Stateflow.EMChart');
    if ~isempty(allCharts)
        chart = allCharts(end);
        chart.Script = sprintf([...
            'function [modOrder, bitsPerSym, throughputMbps] = fcn(snr)\n' ...
            '%%%% ADAPTIVE DECISION ENGINE — ARYA-mgc\n' ...
            '%%%% Selects modulation based on measured SNR (Link Quality)\n' ...
            '%%%% Maps to: Intelligent Link Management block\n' ...
            '\n' ...
            'BW = 4;  %%%% Channel bandwidth (MHz)\n' ...
            '\n' ...
            'if snr >= 26\n' ...
            '    modOrder = 256; bitsPerSym = 8;  %%%% 256-QAM\n' ...
            'elseif snr >= 20\n' ...
            '    modOrder = 64;  bitsPerSym = 6;  %%%% 64-QAM\n' ...
            'elseif snr >= 14\n' ...
            '    modOrder = 16;  bitsPerSym = 4;  %%%% 16-QAM\n' ...
            'elseif snr >= 8\n' ...
            '    modOrder = 4;   bitsPerSym = 2;  %%%% QPSK\n' ...
            'else\n' ...
            '    modOrder = 2;   bitsPerSym = 1;  %%%% BPSK\n' ...
            'end\n' ...
            '\n' ...
            'throughputMbps = bitsPerSym * BW;\n']);
        fprintf('[OK] MATLAB Function code set automatically!\n');
        
        % Now save and connect the 3 outputs
        save_system(modelName);
        
        % Connect outputs after code is set (3 output ports now exist)
        add_line(modelName, 'Adaptive_Decision_Engine/1', 'ModOrder_Display/1', 'autorouting', 'smart');
        add_line(modelName, 'Adaptive_Decision_Engine/2', 'BitsPerSym_Display/1', 'autorouting', 'smart');
        add_line(modelName, 'Adaptive_Decision_Engine/3', 'Throughput_Display/1', 'autorouting', 'smart');
        add_line(modelName, 'Adaptive_Decision_Engine/2', 'Scope/2', 'autorouting', 'smart');
        
        % Connect to workspace loggers
        add_line(modelName, 'Adaptive_Decision_Engine/1', 'Log_ModOrder/1', 'autorouting', 'smart');
        add_line(modelName, 'Adaptive_Decision_Engine/2', 'Log_BitsPerSym/1', 'autorouting', 'smart');
        add_line(modelName, 'Adaptive_Decision_Engine/3', 'Log_Throughput/1', 'autorouting', 'smart');
        
        fprintf('[OK] All outputs connected!\n');
        autoCodeSet = true;
    else
        fprintf('[!!] Could not find MATLAB Function chart\n');
        autoCodeSet = false;
    end
catch ME
    fprintf('[!!] Auto-code failed: %s\n', ME.message);
    fprintf('     You will need to manually set the code (see below)\n');
    autoCodeSet = false;
end

%% ===== SAVE =====
savePath = fullfile(pwd, [modelName '.slx']);
save_system(modelName, savePath);
fprintf('[OK] Model saved: %s\n\n', savePath);

%% ===== PRINT RESULTS =====
fprintf('============================================================\n');
fprintf('  DONE! Simulink model is ready.\n');
fprintf('============================================================\n\n');

if autoCodeSet
    fprintf('  Everything is connected automatically!\n');
    fprintf('  Just press ▶ Run in Simulink.\n\n');
    fprintf('  After simulation, run this for FIGURES:\n');
    fprintf('    >> plot_adaptive_results\n\n');
else
    fprintf('  Double-click the cyan block and paste this code:\n\n');
    fprintf('  function [modOrder, bitsPerSym, throughputMbps] = fcn(snr)\n');
    fprintf('  BW = 4;\n');
    fprintf('  if snr >= 26\n');
    fprintf('      modOrder = 256; bitsPerSym = 8;\n');
    fprintf('  elseif snr >= 20\n');
    fprintf('      modOrder = 64;  bitsPerSym = 6;\n');
    fprintf('  elseif snr >= 14\n');
    fprintf('      modOrder = 16;  bitsPerSym = 4;\n');
    fprintf('  elseif snr >= 8\n');
    fprintf('      modOrder = 4;   bitsPerSym = 2;\n');
    fprintf('  else\n');
    fprintf('      modOrder = 2;   bitsPerSym = 1;\n');
    fprintf('  end\n');
    fprintf('  throughputMbps = bitsPerSym * BW;\n\n');
end

fprintf('============================================================\n');
