function [uhf_syms, uhf_bps] = process_uhf_tx(msg_bytes, snr)
%% process_uhf_tx — UHF Adaptive Modulator (TX Side)
%  Encodes voice/messages with Forward Error Correction and adapts modulation (BPSK/QPSK/16QAM)
%  Tactical PHY Mesh — ARYA-mgc

    trellis = poly2trellis(7, [133 171]);
    
    % Adaptive MCS for UHF (Robust penetration priority)
    if snr >= 20
        M = 16; uhf_bps = 4;
    elseif snr >= 10
        M = 4;  uhf_bps = 2;
    else
        M = 2;  uhf_bps = 1; % BPSK for deep concrete penetration
    end
    
    inBits = reshape(de2bi(uint8(msg_bytes), 8, 'left-msb')', 1, []);
    if length(inBits) < 800
        inBits = [inBits randi([0 1], 1, 800 - length(inBits))];
    end
    
    coded = convenc(inBits, trellis);
    nS = floor(length(coded)/uhf_bps);
    bM = reshape(coded(1:nS*uhf_bps), uhf_bps, [])';
    syms = bi2de(bM, 'left-msb');
    
    if M == 2
        uhf_syms = complex(2*double(syms') - 1, 0);
    else
        uhf_syms = qammod(double(syms'), M, 'gray', 'UnitAveragePower', true);
    end
    
    if length(uhf_syms) < 400
        uhf_syms = [uhf_syms complex(zeros(1, 400 - length(uhf_syms)))];
    else
        uhf_syms = uhf_syms(1:400);
    end
end
