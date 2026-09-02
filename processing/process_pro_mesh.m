function [t1, t2, t3, t4, m1, m2, m3, m4, totalRate] = process_pro_mesh(snr_all)
%% process_pro_mesh — Engine for Professional Mesh Simulink Model
%  Calculates real-time rate, modulation index, and BER for all 4 nodes
%  Tactical PHY Mesh — ARYA-mgc

    BW = 8; % MHz channel bandwidth
    trellis = poly2trellis(7, [133 171]);
    nBits = 2000;
    
    tputs = zeros(1, 4);
    modLevels = zeros(1, 4);
    
    for n = 1:4
        s = snr_all(n);
        
        if s >= 26
            M = 256; bps = 8; mi = 5;
        elseif s >= 20
            M = 64;  bps = 6; mi = 4;
        elseif s >= 14
            M = 16;  bps = 4; mi = 3;
        elseif s >= 8
            M = 4;   bps = 2; mi = 2;
        else
            M = 2;   bps = 1; mi = 1;
        end
        
        modLevels(n) = mi;
        
        % Full PHY step verification
        data = randi([0 1], 1, nBits);
        coded = convenc(data, trellis);
        nS = floor(length(coded)/bps);
        bM = reshape(coded(1:nS*bps), bps, [])';
        syms = bi2de(bM, 'left-msb');
        
        if M == 2
            modSig = 2*double(syms') - 1;
        else
            modSig = qammod(double(syms'), M, 'gray', 'UnitAveragePower', true);
        end
        
        rxSig = awgn(modSig, s, 'measured');
        
        if M == 2
            rxS = double(real(rxSig) > 0);
        else
            rxS = qamdemod(rxSig, M, 'gray', 'UnitAveragePower', true);
        end
        
        rxBM = de2bi(rxS(:), bps, 'left-msb');
        rxB = reshape(rxBM', 1, []);
        if length(rxB) < length(coded)
            rxB = [rxB zeros(1, length(coded)-length(rxB))];
        end
        dec = vitdec(rxB(1:length(coded)), trellis, 30, 'trunc', 'hard');
        
        [~, ber] = biterr(dec(1:nBits), data);
        tputs(n) = bps * BW * (1 - ber);
    end
    
    t1 = tputs(1);
    t2 = tputs(2);
    t3 = tputs(3);
    t4 = tputs(4);
    
    m1 = modLevels(1);
    m2 = modLevels(2);
    m3 = modLevels(3);
    m4 = modLevels(4);
    
    totalRate = sum(tputs);
end
