function [lband_syms, lband_bps] = process_lband_tx(video_bytes, snr)
%% process_lband_tx — L-Band Adaptive Modulator (TX Side)
%  Encodes HD Video streams and adapts high-order modulations (QPSK/16QAM/64QAM/256QAM)
%  Tactical PHY Mesh — ARYA-mgc

    trellis = poly2trellis(7, [133 171]);
    
    % Adaptive MCS for L-Band (High throughput video priority)
    if snr >= 26
        M = 256; lband_bps = 8; % 1080p HD 60fps
    elseif snr >= 20
        M = 64;  lband_bps = 6; % 1080p 30fps
    elseif snr >= 14
        M = 16;  lband_bps = 4; % 720p 30fps
    else
        M = 4;   lband_bps = 2; % 480p Low-rate video
    end
    
    inBits = reshape(de2bi(uint8(video_bytes), 8, 'left-msb')', 1, []);
    if length(inBits) < 1600
        inBits = [inBits randi([0 1], 1, 1600 - length(inBits))];
    end
    
    coded = convenc(inBits, trellis);
    nS = floor(length(coded)/lband_bps);
    bM = reshape(coded(1:nS*lband_bps), lband_bps, [])';
    syms = bi2de(bM, 'left-msb');
    
    if M == 2
        lband_syms = complex(2*double(syms') - 1, 0);
    else
        lband_syms = qammod(double(syms'), M, 'gray', 'UnitAveragePower', true);
    end
    
    if length(lband_syms) < 400
        lband_syms = [lband_syms complex(zeros(1, 400 - length(lband_syms)))];
    else
        lband_syms = lband_syms(1:400);
    end
end
