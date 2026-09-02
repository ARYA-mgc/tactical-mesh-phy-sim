%% connect_multifeed_outputs.m
%  Connects all multi-feed outputs in Simulink model
%  Tactical PHY Mesh — ARYA-mgc

m = 'DualBand_MultiFeed_Mesh';
fprintf('Connecting Multi-Feed Simulink outputs...\n');

% Connect Video Rates (Ports 1-4)
add_line(m, 'MultiFeed_Base_Station/1', 'N1_Video_Rate/1', 'autorouting','smart');
add_line(m, 'MultiFeed_Base_Station/2', 'N2_Video_Rate/1', 'autorouting','smart');
add_line(m, 'MultiFeed_Base_Station/3', 'N3_Video_Rate/1', 'autorouting','smart');
add_line(m, 'MultiFeed_Base_Station/4', 'N4_Video_Rate/1', 'autorouting','smart');

% Connect Total Network Mbps (Port 5)
add_line(m, 'MultiFeed_Base_Station/5', 'Total_Network_Mbps/1', 'autorouting','smart');
add_line(m, 'MultiFeed_Base_Station/5', 'Log_Total_Mbps/1', 'autorouting','smart');

% Connect N3 Voice Mode Indicator (Port 6)
add_line(m, 'MultiFeed_Base_Station/6', 'N3_Voice_Penetration_Mode/1', 'autorouting','smart');

% Connect MultiFeed Scope (4 Video/Audio Channels)
add_line(m, 'MultiFeed_Base_Station/1', 'MultiFeed_Scope/1', 'autorouting','smart');
add_line(m, 'MultiFeed_Base_Station/2', 'MultiFeed_Scope/2', 'autorouting','smart');
add_line(m, 'MultiFeed_Base_Station/3', 'MultiFeed_Scope/3', 'autorouting','smart');
add_line(m, 'MultiFeed_Base_Station/4', 'MultiFeed_Scope/4', 'autorouting','smart');

save_system(m);
fprintf('[OK] All Multi-Feed outputs connected! Press ▶ Run in Simulink.\n');
