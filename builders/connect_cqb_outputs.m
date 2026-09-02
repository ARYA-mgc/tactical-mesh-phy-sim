%% connect_cqb_outputs.m
%  Run AFTER pasting code into PHY_Engine block
%  Connects all 5 outputs to displays, scope, and loggers

m = 'CQB_Mission_AdaptiveMod';
fprintf('Connecting CQB model outputs...\n');

% PHY_Engine outputs → Displays
add_line(m, 'PHY_Engine/1', 'BER_Value/1', 'autorouting','smart');
add_line(m, 'PHY_Engine/2', 'MER_Value/1', 'autorouting','smart');
add_line(m, 'PHY_Engine/3', 'MCS_Value/1', 'autorouting','smart');
add_line(m, 'PHY_Engine/4', 'Throughput_Value/1', 'autorouting','smart');
add_line(m, 'PHY_Engine/5', 'Phase_Name/1', 'autorouting','smart');

% Scope (SNR, BER, MCS, Throughput)
add_line(m, 'Mission_Profile/1', 'Mission_Scope/1', 'autorouting','smart');
add_line(m, 'PHY_Engine/1', 'Mission_Scope/2', 'autorouting','smart');
add_line(m, 'PHY_Engine/3', 'Mission_Scope/3', 'autorouting','smart');
add_line(m, 'PHY_Engine/4', 'Mission_Scope/4', 'autorouting','smart');

% To Workspace
add_line(m, 'Mission_Profile/1', 'Log_SNR/1', 'autorouting','smart');
add_line(m, 'PHY_Engine/1', 'Log_BER/1', 'autorouting','smart');
add_line(m, 'PHY_Engine/3', 'Log_MCS/1', 'autorouting','smart');
add_line(m, 'PHY_Engine/4', 'Log_Tput/1', 'autorouting','smart');
add_line(m, 'PHY_Engine/5', 'Log_Phase/1', 'autorouting','smart');

save_system(m);
fprintf('[OK] All connected! Press Run now.\n');
