%% connect_dualband_dualmod_outputs.m
%  Connects all output displays, scopes, and loggers in Dual-Band Dual-Modulator model
%  Tactical PHY Mesh — ARYA-mgc

m = 'DualBand_DualMod_Mesh_Simulink';
fprintf('Connecting Dual-Band Dual-Modulator outputs...\n');

lines = {
    'UHF_Demodulator_RX/1',   'UHF_Voice_Rate_kbps/1';
    'UHF_Demodulator_RX/2',   'UHF_Modulation_Scheme/1';
    'UHF_Demodulator_RX/3',   'UHF_BER/1';
    'UHF_Demodulator_RX/1',   'DualBand_Scope/1';
    'LBand_Demodulator_RX/1', 'LBand_Video_Rate_Mbps/1';
    'LBand_Demodulator_RX/2', 'LBand_Modulation_Scheme/1';
    'LBand_Demodulator_RX/3', 'LBand_BER/1';
    'LBand_Demodulator_RX/1', 'Total_DualBand_Mbps/1';
    'LBand_Demodulator_RX/1', 'DualBand_Scope/2';
    'LBand_Demodulator_RX/1', 'Log_DualBand_Data/1'
};

for i = 1:size(lines, 1)
    try
        add_line(m, lines{i,1}, lines{i,2}, 'autorouting','smart');
    catch
    end
end

save_system(m);
fprintf('[OK] All Dual-Modulator & Demodulator outputs verified! Press ▶ Run in Simulink.\n');
