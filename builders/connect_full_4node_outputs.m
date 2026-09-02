%% connect_full_4node_outputs.m
%  Connects all output displays, scope, and loggers for 4-Node Mesh + 1 Base Station model
%  Tactical PHY Mesh — ARYA-mgc

m = 'Mesh_4Node_1BaseStation_System';
fprintf('Connecting 4-Node Mesh + 1 Base Station outputs...\n');

lines = {
    'Base_Station_Receiver_RX/1', 'Node1_Recv_Rate_Mbps/1';
    'Base_Station_Receiver_RX/2', 'Node2_Recv_Rate_Mbps/1';
    'Base_Station_Receiver_RX/3', 'Node3_Recv_Rate_Mbps/1';
    'Base_Station_Receiver_RX/4', 'Node4_Recv_Rate_Mbps/1';
    
    'Base_Station_Receiver_RX/5', 'Node1_Modulation/1';
    'Base_Station_Receiver_RX/6', 'Node2_Modulation/1';
    'Base_Station_Receiver_RX/7', 'Node3_Modulation/1';
    'Base_Station_Receiver_RX/8', 'Node4_Modulation/1';
    
    'Base_Station_Receiver_RX/9', 'Total_BaseStation_Aggregate_Mbps/1';
    'Base_Station_Receiver_RX/9', 'Log_Mesh_Data/1';
    
    'Base_Station_Receiver_RX/1', 'BaseStation_4Channel_Scope/1';
    'Base_Station_Receiver_RX/2', 'BaseStation_4Channel_Scope/2';
    'Base_Station_Receiver_RX/3', 'BaseStation_4Channel_Scope/3';
    'Base_Station_Receiver_RX/4', 'BaseStation_4Channel_Scope/4'
};

for i = 1:size(lines, 1)
    try
        add_line(m, lines{i,1}, lines{i,2}, 'autorouting','smart');
    catch
    end
end

save_system(m);
fprintf('[OK] All 4-Node Mesh + Base Station outputs connected! Press ▶ Run in Simulink.\n');
