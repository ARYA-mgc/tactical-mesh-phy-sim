function [n1t, n2t, n3t, n4t, totalT] = process_mesh_nodes(snr_all)
%% process_mesh_nodes — Complete Full-Mesh TX/RX Engine for Simulink
%  Features:
%    - Node 1..4: Dual-Band Adaptive Modulation (UHF Voice + L-Band Video)
%    - Mesh Relay: Node 3 (Basement) packets relay through Node 2 (Corridor)
%    - Base Station Receiver: Adaptive Demodulation + Viterbi FEC Decoding
%  Tactical PHY Mesh — ARYA-mgc

    BW = 8; % MHz channel bandwidth
    trellis = poly2trellis(7, [133 171]);
    nBits = 2000;
    tputs = zeros(1, 4);
    
    % Node-specific mission payloads
    payloads = {
        'NODE1_HD_VIDEO_STREAM_ROOFTOP_OVERWATCH', ...
        'NODE2_TACTICAL_CORRIDOR_MESH_RELAY_LINK', ...
        'NODE3_BASEMENT_EMERGENCY_UHF_PENETRATION', ...
        'NODE4_PERIMETER_C2_TRANSPORT_DATA_STREAM'
    };
    
    for node = 1:4
        snr = snr_all(node);
        
        % 1. Adaptive MCS Selection per Node
        if snr >= 26
            M = 256; bps = 8; % L-Band 1080p HD 60fps (Node 1 / Rooftop)
        elseif snr >= 20
            M = 64;  bps = 6; % L-Band 1080p 30fps
        elseif snr >= 14
            M = 16;  bps = 4; % Dual-Band 720p Video (Node 2 / Corridor)
        elseif snr >= 8
            M = 4;   bps = 2; % Dual-Band 480p
        else
            M = 2;   bps = 1; % UHF BPSK Penetration Mode (Node 3 / Basement)
        end
        
        % 2. TX Encoding & Forward Error Correction
        rawMsg = payloads{node};
        inBits = reshape(de2bi(uint8(rawMsg), 8, 'left-msb')', 1, []);
        if length(inBits) < nBits
            inBits = [inBits randi([0 1], 1, nBits - length(inBits))];
        else
            inBits = inBits(1:nBits);
        end
        coded = convenc(inBits, trellis);
        
        % 3. QAM Modulation
        nS = floor(length(coded)/bps);
        bM = reshape(coded(1:nS*bps), bps, [])';
        syms = bi2de(bM, 'left-msb');
        
        if M == 2
            modSig = 2*double(syms') - 1;
        else
            modSig = qammod(double(syms'), M, 'gray', 'UnitAveragePower', true);
        end
        
        % 4. Wireless Mesh Channel (Multipath Fading + Peer Relay)
        % If Node 3 is in basement (low SNR), packets relay through Node 2 in corridor
        if node == 3 && snr < 10
            effective_snr = snr + 6; % 6 dB mesh relay gain through Node 2
        else
            effective_snr = snr;
        end
        
        rxSig = awgn(modSig, effective_snr, 'measured');
        
        % 5. Base Station Demodulation (RX Side)
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
        
        % 6. Viterbi FEC Decoding
        dec = vitdec(rxB(1:length(coded)), trellis, 30, 'trunc', 'hard');
        
        [~, ber] = biterr(dec(1:nBits), inBits);
        tputs(node) = bps * BW * (1 - ber);
    end
    
    n1t = tputs(1);
    n2t = tputs(2);
    n3t = tputs(3);
    n4t = tputs(4);
    totalT = sum(tputs);
end
