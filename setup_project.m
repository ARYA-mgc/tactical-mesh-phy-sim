%% setup_project.m — Tactical PHY Simulation System Setup (MATLAB)
%  Author: ARYA-mgc
%  Repository: https://github.com/ARYA-mgc/tactical-mesh-phy-sim-
%
%  Run this script once after opening MATLAB to configure all module paths.
%  Usage:  >> setup_project

clc;
fprintf('=================================================================\n');
fprintf('  Tactical PHY Simulation System (802.11ah & 802.11af)\n');
fprintf('  Author: ARYA-mgc\n');
fprintf('=================================================================\n\n');

%% 1. Resolve project root
projectRoot = fileparts(mfilename('fullpath'));

%% 2. Add modular directories to MATLAB path
subDirs = {'models', 'builders', 'simulations', 'processing', 'plots'};
for i = 1:numel(subDirs)
    d = fullfile(projectRoot, subDirs{i});
    if exist(d, 'dir')
        addpath(d);
        fprintf('[OK]  Added to path: %s\n', subDirs{i});
    end
end

% Standard baseband directories
ahDir = fullfile(projectRoot, '802_11_ah');
afDir = fullfile(projectRoot, '802_11_af', 'GUI simulator');

rmpath_safe(afDir);
rmpath_safe(ahDir);
addpath(ahDir);
fprintf('[OK]  Added to path: 802_11_ah (Default PHY standard)\n');
fprintf('[NOTE] To use 802.11af GUI, run:  switch_to_af\n\n');

%% 3. Toolbox dependency check
requiredToolboxes = {
    'Control System Toolbox'
    'Signal Processing Toolbox'
    'DSP System Toolbox'
    'Communications Toolbox'
};

altNames = {
    {}
    {}
    {}
    {'Communications System Toolbox'}
};

installedToolboxes = ver;
installedNames = {installedToolboxes.Name};

fprintf('--- Toolbox Check ---\n');
allFound = true;
for k = 1:numel(requiredToolboxes)
    found = any(strcmpi(installedNames, requiredToolboxes{k}));
    if ~found && ~isempty(altNames{k})
        for j = 1:numel(altNames{k})
            found = found || any(strcmpi(installedNames, altNames{k}{j}));
        end
    end
    if found
        fprintf('  [OK]      %s\n', requiredToolboxes{k});
    else
        fprintf('  [MISSING] %s  <-- install via Add-On Explorer\n', requiredToolboxes{k});
        allFound = false;
    end
end

fprintf('\n');
if allFound
    fprintf('[OK]  All required toolboxes are installed.\n\n');
else
    fprintf('[!!]  Some toolboxes are missing. The simulator may error.\n');
    fprintf('      Open Add-On Explorer (Home > Add-Ons) to install them.\n\n');
end

%% 4. Quick-Start Guide
fprintf('=================================================================\n');
fprintf('  QUICK-START GUIDE\n');
fprintf('=================================================================\n');
fprintf('  1. Tactical Ground Station GUI:\n');
fprintf('       >> tactical_ground_station_gui\n');
fprintf('  2. Adaptive Modulation Test Suite (BER, MER, Throughput):\n');
fprintf('       >> run_test_cases\n');
fprintf('  3. Tactical CQB Mission Simulation:\n');
fprintf('       >> cqb_mission_sim\n');
fprintf('  4. Electronic Warfare & Jamming Defense:\n');
fprintf('       >> plot_electronic_warfare_attack\n');
fprintf('  5. IEEE 802.11ah Baseband Simulation:\n');
fprintf('       >> main_802_11ah\n');
fprintf('  6. Open Simulink Models:\n');
fprintf('       >> open(''CQB_Mission_AdaptiveMod.slx'')\n');
fprintf('       >> open(''DualBand_DualMod_Mesh_Simulink.slx'')\n');
fprintf('=================================================================\n');
fprintf('  Setup complete! Ready to simulate.\n');
fprintf('=================================================================\n');

%% --- Local helper ---
function rmpath_safe(p)
    if contains(path, p)
        rmpath(p);
    end
end
