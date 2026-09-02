%% connect_hierarchical_outputs.m
%  Connects all top-level lines of Hierarchical_4Node_Mesh_System
%  Tactical PHY Mesh — ARYA-mgc

m = 'Hierarchical_4Node_Mesh_System';
fprintf('Connecting Hierarchical Mesh outputs...\n');

lines = {
    'Base_Station_Receiver_Hub/1', 'N1_Throughput/1';
    'Base_Station_Receiver_Hub/2', 'N2_Throughput/1';
    'Base_Station_Receiver_Hub/3', 'N3_Throughput/1';
    'Base_Station_Receiver_Hub/4', 'N4_Throughput/1';
    'Base_Station_Receiver_Hub/5', 'Total_Network_Mbps/1';
    'Base_Station_Receiver_Hub/1', 'Mesh_Network_Scope/1';
    'Base_Station_Receiver_Hub/2', 'Mesh_Network_Scope/2';
    'Base_Station_Receiver_Hub/3', 'Mesh_Network_Scope/3';
    'Base_Station_Receiver_Hub/4', 'Mesh_Network_Scope/4'
};

for i = 1:size(lines, 1)
    try
        add_line(m, lines{i,1}, lines{i,2}, 'autorouting','smart');
    catch
    end
end

save_system(m);
fprintf('[OK] All outputs connected! Press ▶ Run in Simulink.\n');
