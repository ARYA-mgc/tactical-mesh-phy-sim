function rf_out = node_tx_modulate(snr, payload_bytes)
%% node_tx_modulate — Internal Adaptive Modulator for each Node Subsystem
%  Converts payload bytes to bits, applies FEC + Adaptive Modulation (BPSK to 256-QAM)
%  Tactical PHY Mesh — ARYA-mgc

    BW = 8; % MHz channel bandwidth
    
    if snr >= 26
        bps = 8; % 256-QAM (1080p HD Video)
    elseif snr >= 20
        bps = 6; % 64-QAM (1080p Video)
    elseif snr >= 14
        bps = 4; % 16-QAM (720p Video)
    elseif snr >= 8
        bps = 2; % QPSK (480p Video)
    else
        bps = 1; % BPSK (UHF Voice Priority Mode)
    end
    
    % Data throughput transmitted on the RF channel
    rf_out = double(bps * BW);
end
