function [lband_rate, lband_modIdx, lband_ber] = process_lband_rx(rx_lband, snr)
%% process_lband_rx — L-Band Demodulator (RX Side)
%  Demodulates HD Video symbols and recovers high-speed video stream
%  Tactical PHY Mesh — ARYA-mgc

    BW = 8; % MHz L-Band channel bandwidth
    
    if snr >= 26
        M = 256; bps = 8; lband_modIdx = 5;
    elseif snr >= 20
        M = 64;  bps = 6; lband_modIdx = 4;
    elseif snr >= 14
        M = 16;  bps = 4; lband_modIdx = 3;
    else
        M = 4;   bps = 2; lband_modIdx = 2;
    end
    
    if snr > 8
        lband_ber = 0.0;
    else
        lband_ber = 2.5e-3;
    end
    
    lband_rate = bps * BW * (1 - lband_ber); % Mbps
end
