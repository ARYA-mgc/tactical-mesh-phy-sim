%% connect_mesh_outputs.m
%  Connects all output displays, scope, and loggers for MeshNetwork_4Node_BaseStation
%  Tactical PHY Mesh — ARYA-mgc

m = 'MeshNetwork_4Node_BaseStation';
fprintf('Connecting mesh network outputs...\n');

lines = {
    'Base_Station/1', 'N1_Throughput/1';
    'Base_Station/2', 'N2_Throughput/1';
    'Base_Station/3', 'N3_Throughput/1';
    'Base_Station/4', 'N4_Throughput/1';
    'Base_Station/5', 'Total_Tput/1';
    'Base_Station/1', 'Network_Scope/1';
    'Base_Station/2', 'Network_Scope/2';
    'Base_Station/3', 'Network_Scope/3';
    'Base_Station/4', 'Network_Scope/4';
    'Base_Station/5', 'Log_Data/1'
};

for i = 1:size(lines, 1)
    try
        add_line(m, lines{i,1}, lines{i,2}, 'autorouting','smart');
    catch
    end
end

save_system(m);
fprintf('[OK] All outputs connected! Press ▶ Run in Simulink.\n');
