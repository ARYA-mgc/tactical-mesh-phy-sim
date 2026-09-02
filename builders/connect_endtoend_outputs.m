%% connect_endtoend_outputs.m
%  Connects all output ports of End-to-End Mesh Simulink Model
%  Tactical PHY Mesh — ARYA-mgc

m = 'EndToEnd_Mesh_VideoMsg_Simulink';
fprintf('Connecting End-to-End Mesh Simulink outputs...\n');

% 1. Connect Recovered Data Rates (Ports 1-4)
add_line(m, 'EndToEnd_Mesh_Engine/1', 'N1_Recovered_Video_Mbps/1', 'autorouting','smart');
add_line(m, 'EndToEnd_Mesh_Engine/2', 'N2_Recovered_Data_Mbps/1', 'autorouting','smart');
add_line(m, 'EndToEnd_Mesh_Engine/3', 'N3_Recovered_Voice_Mbps/1', 'autorouting','smart');
add_line(m, 'EndToEnd_Mesh_Engine/4', 'N4_Recovered_Data_Mbps/1', 'autorouting','smart');

% 2. Connect Decoded Integrity Badges (Ports 5-8)
add_line(m, 'EndToEnd_Mesh_Engine/5', 'N1_Video_Stream_Integrity/1', 'autorouting','smart');
add_line(m, 'EndToEnd_Mesh_Engine/6', 'N2_Msg_Decoded_100pct/1', 'autorouting','smart');
add_line(m, 'EndToEnd_Mesh_Engine/7', 'N3_Basement_Msg_Decoded_100pct/1', 'autorouting','smart');
add_line(m, 'EndToEnd_Mesh_Engine/8', 'N4_Telemetry_Decoded_100pct/1', 'autorouting','smart');

% 3. Connect Total Base Station Throughput (Port 9)
add_line(m, 'EndToEnd_Mesh_Engine/9', 'Total_BaseStation_Throughput/1', 'autorouting','smart');
add_line(m, 'EndToEnd_Mesh_Engine/9', 'Log_Decoded_Data/1', 'autorouting','smart');

% 4. Connect Active Modulation Scheme Level (Port 10)
add_line(m, 'EndToEnd_Mesh_Engine/10', 'Active_Modulation_Scheme/1', 'autorouting','smart');

% 5. Connect 4-Channel Live Data Scope (Ports 1-4)
add_line(m, 'EndToEnd_Mesh_Engine/1', 'BaseStation_Data_Scope/1', 'autorouting','smart');
add_line(m, 'EndToEnd_Mesh_Engine/2', 'BaseStation_Data_Scope/2', 'autorouting','smart');
add_line(m, 'EndToEnd_Mesh_Engine/3', 'BaseStation_Data_Scope/3', 'autorouting','smart');
add_line(m, 'EndToEnd_Mesh_Engine/4', 'BaseStation_Data_Scope/4', 'autorouting','smart');

save_system(m);
fprintf('[OK] All outputs connected! Press ▶ Run in Simulink.\n');
