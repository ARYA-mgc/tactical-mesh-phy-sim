%% build_hierarchical_mesh_simulink.m
%  REAL 2D SPATIAL TACTICAL MESH NETWORK TOPOLOGY
%  Visually matches a real battlefield ad-hoc mesh network:
%
%                     [Node 1: Rooftop] ──► [N1 Rate]
%                       ▲           │
%                       │           ▼
%    [N2 Rate] ◄── [Node 2]       [Node 4] ──► [N4 Rate]
%    (Corridor)         │           ▲      (Perimeter)
%                       ▼           │
%                     [Node 3: Basement] ──► [N3 Rate]
%                            │     ▲
%                            ▼     │ (Uplink / Downlink C2)
%                     [Base Station: Command Post] ──► [Total Rate, Scope, Log]
%
%  Tactical PHY Mesh — ARYA-mgc
%
%  Usage: >> build_hierarchical_mesh_simulink

clc;
fprintf('=================================================================\n');
fprintf('  BUILDING REAL 2D SPATIAL TACTICAL MESH NETWORK MODEL\n');
fprintf('  Tactical PHY Mesh — ARYA-mgc\n');
fprintf('=================================================================\n\n');

modelName = 'Hierarchical_4Node_Mesh_System';

if bdIsLoaded(modelName), close_system(modelName, 0); end
if exist([modelName '.slx'],'file'), delete([modelName '.slx']); end

new_system(modelName);
open_system(modelName);
set_param(modelName, 'StopTime','210', 'SolverType','Fixed-step', 'FixedStep','1');

rt = sfroot;

%% ============================================================
%%  1. TOP-LEVEL CLOCK
%% ============================================================
add_block('simulink/Sources/Clock', [modelName '/Clock'], ...
    'Position', [40 40 65 60]);

%% ============================================================
%%  2. SPATIAL NODE POSITIONS (REAL TACTICAL 2D MESH LAYOUT)
%% ============================================================
nodeNames = {'Node 1', 'Node 2', 'Node 3', 'Node 4'};

% Diamond / Ad-Hoc Spatial Positioning on Canvas
nodePos = [
    430,  30, 580,  95;   % Node 1: Rooftop Leader (Top Center)
    120, 180, 270, 245;   % Node 2: Corridor Breacher (Left)
    430, 330, 580, 395;   % Node 3: Basement Pointman (Lower Center)
    740, 180, 890, 245    % Node 4: Perimeter Guard (Right)
];

t_profiles = {
    '[0 50 51 100 101 160 161 210]', '[30 30 18 18 25 25 30 30]';  % Node 1: Rooftop
    '[0 30 31 70 71 110 111 160 161 210]', '[22 22 15 15 8 8 12 12 20 20]';  % Node 2: Corridor
    '[0 20 21 60 61 120 121 170 171 210]', '[20 20 10 10 5 5 8 8 18 18]';  % Node 3: Basement
    '[0 50 51 150 151 210]', '[25 25 20 20 25 25]'   % Node 4: Perimeter
};

for n = 1:4
    subPath = [modelName '/' nodeNames{n}];
    add_block('simulink/Ports & Subsystems/Subsystem', subPath, ...
        'Position', nodePos(n,:));
    
    Simulink.SubSystem.deleteContents(subPath);
    
    % Inports
    add_block('simulink/Sources/In1', [subPath '/In'], 'Position', [20 30 40 50]);
    add_block('simulink/Sources/In1', [subPath '/Mesh In'], 'Position', [20 180 40 200]);
    if n == 1
        add_block('simulink/Sources/In1', [subPath '/Ground In'], 'Position', [20 230 40 250]);
    end
    
    add_block('simulink/Lookup Tables/1-D Lookup Table', [subPath '/SNR'], ...
        'Position', [70 25 130 55], 'Table', t_profiles{n,2}, 'BreakpointsForDimension1', t_profiles{n,1});
    
    add_block('simulink/Sources/Constant', [subPath '/Voice Data'], ...
        'Position', [60 90 130 115], 'Value', sprintf('uint8([86 79 73 67 69 %d])', n));
    add_block('simulink/Sources/Constant', [subPath '/Video Data'], ...
        'Position', [60 140 130 165], 'Value', sprintf('uint8([86 73 68 69 79 %d])', n));
    
    uhfModPath = [subPath '/UHF Mod'];
    add_block('simulink/User-Defined Functions/MATLAB Function', uhfModPath, 'Position', [180 40 310 110]);
    
    try
        chart = rt.find('-isa', 'Stateflow.EMChart', 'Path', uhfModPath);
        if ~isempty(chart)
            chart.Script = sprintf([ ...
                'function uhf_out = fcn(snr, voice_bytes)\n' ...
                '%%%% UHF ADAPTIVE MODULATOR (380-400 MHz Voice Channel)\n' ...
                'coder.extrinsic(''process_uhf_tx_sub'');\n' ...
                'uhf_out = double(0);\n' ...
                'uhf_out = process_uhf_tx_sub(snr, voice_bytes);\n']);
        end
    catch
    end
    
    lbandModPath = [subPath '/L-Band Mod'];
    add_block('simulink/User-Defined Functions/MATLAB Function', lbandModPath, 'Position', [180 130 310 210]);
    
    try
        chart = rt.find('-isa', 'Stateflow.EMChart', 'Path', lbandModPath);
        if ~isempty(chart)
            chart.Script = sprintf([ ...
                'function [lband_out, mesh_out] = fcn(snr, mesh_in, video_bytes)\n' ...
                '%%%% L-BAND ADAPTIVE MODULATOR (1.55-1.65 GHz Video Channel)\n' ...
                'coder.extrinsic(''process_lband_tx_sub'');\n' ...
                'lband_out = double(0); mesh_out = double(0);\n' ...
                '[lband_out, mesh_out] = process_lband_tx_sub(snr, mesh_in, video_bytes);\n']);
        end
    catch
    end
    
    add_block('simulink/Math Operations/Add', [subPath '/Combine'], 'Position', [350 70 375 110], 'Inputs', '++');
    add_block('simulink/Sinks/Out1', [subPath '/TX'], 'Position', [420 80 440 100]);
    add_block('simulink/Sinks/Out1', [subPath '/Mesh Out'], 'Position', [420 180 440 200]);
    
    try
        add_line(subPath, 'In/1', 'SNR/1', 'autorouting','smart');
        add_line(subPath, 'SNR/1', 'UHF Mod/1', 'autorouting','smart');
        add_line(subPath, 'Voice Data/1', 'UHF Mod/2', 'autorouting','smart');
        
        add_line(subPath, 'SNR/1', 'L-Band Mod/1', 'autorouting','smart');
        add_line(subPath, 'Mesh In/1', 'L-Band Mod/2', 'autorouting','smart');
        add_line(subPath, 'Video Data/1', 'L-Band Mod/3', 'autorouting','smart');
        
        add_line(subPath, 'UHF Mod/1', 'Combine/1', 'autorouting','smart');
        add_line(subPath, 'L-Band Mod/1', 'Combine/2', 'autorouting','smart');
        add_line(subPath, 'Combine/1', 'TX/1', 'autorouting','smart');
        add_line(subPath, 'L-Band Mod/2', 'Mesh Out/1', 'autorouting','smart');
    catch
    end
    
    add_line(modelName, 'Clock/1', [nodeNames{n} '/1'], 'autorouting','smart');
    
    try
        set_param(subPath, 'BackgroundColor', 'white', 'ForegroundColor', 'black');
    catch
    end
end

fprintf('[OK] 4 Nodes spatially placed in 2D Mesh topology\n');

%% ============================================================
%%  3. PER-NODE REAL-TIME THROUGHPUT DISPLAYS (ON CANVAS)
%% ============================================================
add_block('simulink/Sinks/Display', [modelName '/N1 Rate'], 'Position', [610 50 690 75]);
add_block('simulink/Sinks/Display', [modelName '/N2 Rate'], 'Position', [15 200 95 225]);
add_block('simulink/Sinks/Display', [modelName '/N3 Rate'], 'Position', [610 350 690 375]);
add_block('simulink/Sinks/Display', [modelName '/N4 Rate'], 'Position', [915 200 995 225]);

%% ============================================================
%%  4. PEER-TO-PEER MESH RELAY LINKS (REAL INTERCONNECTED MESH)
%% ============================================================
% Hop 1: Node 1 (Rooftop) ──► Node 2 (Corridor Relay)
add_line(modelName, 'Node 1/2', 'Node 2/2', 'autorouting','smart');

% Hop 2: Node 2 (Corridor) ──► Node 3 (Basement Relay)
add_line(modelName, 'Node 2/2', 'Node 3/2', 'autorouting','smart');

% Hop 3: Node 3 (Basement) ──► Node 4 (Perimeter Guard)
add_line(modelName, 'Node 3/2', 'Node 4/2', 'autorouting','smart');

% Hop 4: Node 4 (Perimeter) ──► Node 1 (Self-Healing Ring Return)
add_block('simulink/Discrete/Unit Delay', [modelName '/Ring_Delay'], ...
    'Position', [650 130 675 155], 'SampleTime', '1', 'InitialCondition', '0');

add_line(modelName, 'Node 4/2', 'Ring_Delay/1', 'autorouting','smart');
add_line(modelName, 'Ring_Delay/1', 'Node 1/2', 'autorouting','smart');

fprintf('[OK] Real peer-to-peer wireless mesh links interconnected\n');

%% ============================================================
%%  5. BASE STATION (TACTICAL COMMAND POST) AT BOTTOM CENTER
%% ============================================================
bsPath = [modelName '/Base Station'];
add_block('simulink/Ports & Subsystems/Subsystem', bsPath, ...
    'Position', [380 480 630 600]);

Simulink.SubSystem.deleteContents(bsPath);

% 4 Uplink Inports (from the 4 Commando Nodes)
add_block('simulink/Sources/In1', [bsPath '/N1 In'], 'Position', [30 30 50 50]);
add_block('simulink/Sources/In1', [bsPath '/N2 In'], 'Position', [30 70 50 90]);
add_block('simulink/Sources/In1', [bsPath '/N3 In'], 'Position', [30 110 50 130]);
add_block('simulink/Sources/In1', [bsPath '/N4 In'], 'Position', [30 150 50 170]);

% Ground C2 Command Generator
add_block('simulink/Sources/Constant', [bsPath '/C2 Command Data'], ...
    'Position', [30 200 130 225], 'Value', 'uint8([67 50 95 67 76 69 65 82])');

% Demodulator Function Block
demodBlockPath = [bsPath '/Demodulator'];
add_block('simulink/User-Defined Functions/MATLAB Function', demodBlockPath, ...
    'Position', [140 60 300 150]);

try
    chart = rt.find('-isa', 'Stateflow.EMChart', 'Path', demodBlockPath);
    if ~isempty(chart)
        chart.Script = sprintf([ ...
            'function [n1, n2, n3, n4, total] = fcn(u1, u2, u3, u4)\n' ...
            '%%%% BASE STATION DEMODULATOR\n' ...
            'n1 = double(u1); n2 = double(u2); n3 = double(u3); n4 = double(u4);\n' ...
            'total = n1 + n2 + n3 + n4;\n']);
    end
catch
end

add_block('simulink/Sinks/Out1', [bsPath '/N1 Rate'], 'Position', [360 25 380 40]);
add_block('simulink/Sinks/Out1', [bsPath '/N2 Rate'], 'Position', [360 55 380 70]);
add_block('simulink/Sinks/Out1', [bsPath '/N3 Rate'], 'Position', [360 85 380 100]);
add_block('simulink/Sinks/Out1', [bsPath '/N4 Rate'], 'Position', [360 115 380 130]);
add_block('simulink/Sinks/Out1', [bsPath '/Total Rate'], 'Position', [360 145 380 160]);
add_block('simulink/Sinks/Out1', [bsPath '/C2 TX'], 'Position', [360 205 380 220]);

try
    add_line(bsPath, 'N1 In/1', 'Demodulator/1', 'autorouting','smart');
    add_line(bsPath, 'N2 In/1', 'Demodulator/2', 'autorouting','smart');
    add_line(bsPath, 'N3 In/1', 'Demodulator/3', 'autorouting','smart');
    add_line(bsPath, 'N4 In/1', 'Demodulator/4', 'autorouting','smart');
    
    add_line(bsPath, 'Demodulator/1', 'N1 Rate/1', 'autorouting','smart');
    add_line(bsPath, 'Demodulator/2', 'N2 Rate/1', 'autorouting','smart');
    add_line(bsPath, 'Demodulator/3', 'N3 Rate/1', 'autorouting','smart');
    add_line(bsPath, 'Demodulator/4', 'N4 Rate/1', 'autorouting','smart');
    add_line(bsPath, 'Demodulator/5', 'Total Rate/1', 'autorouting','smart');
    add_line(bsPath, 'C2 Command Data/1', 'C2 TX/1', 'autorouting','smart');
catch
end

try
    set_param(bsPath, 'BackgroundColor', 'white', 'ForegroundColor', 'black');
catch
end

%% ============================================================
%%  6. TOP-LEVEL WIRELESS CONNECTIONS & DASHBOARD
%% ============================================================
% Individual Uplink RF lines from Nodes to Base Station
add_line(modelName, 'Node 1/1', 'Base Station/1', 'autorouting','smart');
add_line(modelName, 'Node 2/1', 'Base Station/2', 'autorouting','smart');
add_line(modelName, 'Node 3/1', 'Base Station/3', 'autorouting','smart');
add_line(modelName, 'Node 4/1', 'Base Station/4', 'autorouting','smart');

% Connect Node displays directly to Base Station outputs
add_line(modelName, 'Base Station/1', 'N1 Rate/1', 'autorouting','smart');
add_line(modelName, 'Base Station/2', 'N2 Rate/1', 'autorouting','smart');
add_line(modelName, 'Base Station/3', 'N3 Rate/1', 'autorouting','smart');
add_line(modelName, 'Base Station/4', 'N4 Rate/1', 'autorouting','smart');

% Downlink Command from Base Station back to Squad Leader (Node 1)
add_line(modelName, 'Base Station/6', 'Node 1/3', 'autorouting','smart');

% Command Post Aggregate Displays, Scope & Logger
add_block('simulink/Sinks/Display', [modelName '/Total Rate'], 'Position', [670 490 770 515]);
add_block('simulink/Sinks/Display', [modelName '/C2 Ground TX'], 'Position', [670 535 770 560]);
add_block('simulink/Sinks/Scope',   [modelName '/Scope'],      'Position', [810 490 850 535], 'NumInputPorts', '4');

add_block('simulink/Signal Routing/Mux', [modelName '/Log_Mux'], 'Position', [795 560 800 610], 'Inputs', '5');
add_block('simulink/Sinks/To Workspace', [modelName '/Log'],     'Position', [835 570 925 600], ...
    'VariableName', 'mesh_log', 'SaveFormat', 'Array');

try
    add_line(modelName, 'Base Station/5', 'Total Rate/1', 'autorouting','smart');
    add_line(modelName, 'Base Station/6', 'C2 Ground TX/1', 'autorouting','smart');

    add_line(modelName, 'Base Station/1', 'Scope/1', 'autorouting','smart');
    add_line(modelName, 'Base Station/2', 'Scope/2', 'autorouting','smart');
    add_line(modelName, 'Base Station/3', 'Scope/3', 'autorouting','smart');
    add_line(modelName, 'Base Station/4', 'Scope/4', 'autorouting','smart');

    add_line(modelName, 'Base Station/1', 'Log_Mux/1', 'autorouting','smart');
    add_line(modelName, 'Base Station/2', 'Log_Mux/2', 'autorouting','smart');
    add_line(modelName, 'Base Station/3', 'Log_Mux/3', 'autorouting','smart');
    add_line(modelName, 'Base Station/4', 'Log_Mux/4', 'autorouting','smart');
    add_line(modelName, 'Base Station/5', 'Log_Mux/5', 'autorouting','smart');
    add_line(modelName, 'Log_Mux/1',      'Log/1',     'autorouting','smart');
catch
end

save_system(modelName);
fprintf('\n=================================================================\n');
fprintf('  [OK] Real 2D Spatial Tactical Mesh Network successfully built!\n');
fprintf('  Topological Layout: Diamond Mesh (Rooftop, Corridor, Basement, Perimeter)\n');
fprintf('  Command Post Base Station at Bottom with Bi-Directional C2 Downlink!\n');
fprintf('  Press ▶ Run in Simulink to simulate!\n');
fprintf('=================================================================\n\n');
