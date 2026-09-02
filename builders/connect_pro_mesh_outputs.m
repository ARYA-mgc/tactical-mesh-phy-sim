%% connect_pro_mesh_outputs.m
%  Connects all outputs of the Pro Mesh Simulink model
%  Tactical PHY Mesh — ARYA-mgc

m = 'ProMesh_DualBand_BaseStation';
fprintf('Connecting Pro Mesh Simulink outputs...\n');

% Connect Throughputs (Ports 1-4)
add_line(m, 'Base_Station_Engine/1', 'N1_Throughput_Mbps/1', 'autorouting','smart');
add_line(m, 'Base_Station_Engine/2', 'N2_Throughput_Mbps/1', 'autorouting','smart');
add_line(m, 'Base_Station_Engine/3', 'N3_Throughput_Mbps/1', 'autorouting','smart');
add_line(m, 'Base_Station_Engine/4', 'N4_Throughput_Mbps/1', 'autorouting','smart');

% Connect Modulation Levels (Ports 5-8)
add_line(m, 'Base_Station_Engine/5', 'N1_Modulation_Level/1', 'autorouting','smart');
add_line(m, 'Base_Station_Engine/6', 'N2_Modulation_Level/1', 'autorouting','smart');
add_line(m, 'Base_Station_Engine/7', 'N3_Modulation_Level/1', 'autorouting','smart');
add_line(m, 'Base_Station_Engine/8', 'N4_Modulation_Level/1', 'autorouting','smart');

% Connect Total Network Throughput (Port 9)
add_line(m, 'Base_Station_Engine/9', 'Total_Network_Mbps/1', 'autorouting','smart');
add_line(m, 'Base_Station_Engine/9', 'Log_Network_Data/1', 'autorouting','smart');

% Connect Scope (4 Throughput Waveforms)
add_line(m, 'Base_Station_Engine/1', 'Live_Network_Scope/1', 'autorouting','smart');
add_line(m, 'Base_Station_Engine/2', 'Live_Network_Scope/2', 'autorouting','smart');
add_line(m, 'Base_Station_Engine/3', 'Live_Network_Scope/3', 'autorouting','smart');
add_line(m, 'Base_Station_Engine/4', 'Live_Network_Scope/4', 'autorouting','smart');

save_system(m);
fprintf('[OK] All Pro Mesh outputs connected! Press ▶ Run in Simulink.\n');
