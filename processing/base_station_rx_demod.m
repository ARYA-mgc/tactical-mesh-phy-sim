function [r1, r2, r3, r4, totalMbps] = base_station_rx_demod(mesh_rf_in)
%% base_station_rx_demod — Internal Central Demodulator for Base Station Subsystem
%  Demodulates the 4 incoming streams from Node Subsystems across the Mesh Channel
%  Tactical PHY Mesh — ARYA-mgc

    r1 = double(mesh_rf_in(1));
    r2 = double(mesh_rf_in(2));
    r3 = double(mesh_rf_in(3));
    r4 = double(mesh_rf_in(4));
    
    totalMbps = r1 + r2 + r3 + r4;
end
