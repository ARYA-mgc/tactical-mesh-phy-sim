function uhf_out = process_uhf_tx_sub(snr, voice_bytes)
%% process_uhf_tx_sub — UHF Adaptive Modulator inside Node Subsystem
%  Carrier Frequency: 380 MHz – 400 MHz (Wavelength lambda = 79 cm – 75 cm)
%  Voice / Control channel (BPSK / QPSK)
%  Tactical PHY Mesh — ARYA-mgc

    BW_UHF = 2; % MHz UHF channel bandwidth allocation
    
    if snr >= 14
        bps = 2; % QPSK
    else
        bps = 1; % BPSK (Robust concrete penetration mode)
    end
    
    uhf_out = double(bps * BW_UHF);
end
