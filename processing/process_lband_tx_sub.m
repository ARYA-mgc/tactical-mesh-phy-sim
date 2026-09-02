function [lband_out, mesh_out] = process_lband_tx_sub(snr, mesh_in, video_bytes)
%% process_lband_tx_sub — L-Band Adaptive Modulator with Physical Loss Factor & Mesh Relay
%  Carrier Frequency: 1.55 GHz – 1.65 GHz (Wavelength lambda = 19 cm – 18 cm)
%  Incorporates Physical Path Loss (Free Space + Concrete Wall Penetration)
%  Tactical PHY Mesh — ARYA-mgc

    BW_LBAND = 8; % MHz L-Band wideband video bandwidth
    
    % Physical Channel Path Loss (dB): P_tx(20 dBm) + G_tx(3 dBi) + G_rx(3 dBi) - N0(-104 dBm) - Loss
    % Effective SNR = 130 dB - Total Path Loss
    path_loss_db = 130 - snr; 
    
    % If in deep basement (path loss > 105 dB) and Mesh Relay is active:
    % Peer-to-peer relay through corridor node adds +24 dB mesh relay gain!
    if path_loss_db > 105 && mesh_in > 0
        effective_snr = snr + 20; % Mesh relay recovers the link from blackout!
    else
        effective_snr = snr;
    end
    
    if effective_snr >= 26
        bps = 8; % 256-QAM (1080p HD Video 60fps)
    elseif effective_snr >= 20
        bps = 6; % 64-QAM (1080p Video 30fps)
    elseif effective_snr >= 14
        bps = 4; % 16-QAM (720p Video 30fps)
    elseif effective_snr >= 8
        bps = 2; % QPSK (480p Video)
    else
        bps = 1; % Low-rate emergency fallback
    end
    
    lband_out = double(bps * BW_LBAND);
    
    % Relay peer-to-peer mesh packet forward
    mesh_out = lband_out + double(mesh_in) * 0.1;
end
