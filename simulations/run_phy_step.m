function [ber, mer, throughput] = run_phy_step(snr, modOrder, bitsPerSym)
%% run_phy_step — Full PHY TX→Channel→RX for one SNR point
%  Called by Simulink MATLAB Function block
%  Tactical PHY Mesh — ARYA-mgc

    nBits = 2000;
    M = double(modOrder);
    bps = double(bitsPerSym);
    BW = 8;  % MHz
    
    if M < 2, M = 2; end
    if bps < 1, bps = 1; end
    
    %% TX
    dataBits = randi([0 1], 1, nBits);
    
    % Conv encoder
    trellis = poly2trellis(7, [133 171]);
    codedData = convenc(dataBits, trellis);
    
    % QAM Modulation
    nSyms = floor(length(codedData) / bps);
    bitsTrunc = codedData(1:nSyms*bps);
    bitMatrix = reshape(bitsTrunc, bps, [])';
    symbols = bi2de(bitMatrix, 'left-msb');
    
    if M == 2
        modSignal = 2*double(symbols') - 1;
    else
        modSignal = qammod(double(symbols'), M, 'gray', 'UnitAveragePower', true);
    end
    
    txSignal = modSignal;
    
    %% Channel (AWGN)
    rxSignal = awgn(txSignal, snr, 'measured');
    
    %% RX
    if M == 2
        rxSymbols = double(real(rxSignal) > 0);
    else
        rxSymbols = qamdemod(rxSignal, M, 'gray', 'UnitAveragePower', true);
    end
    
    rxBitMatrix = de2bi(rxSymbols(:), bps, 'left-msb');
    rxBits = reshape(rxBitMatrix', 1, []);
    
    % Viterbi decode — match lengths
    decLen = min(length(rxBits), length(codedData));
    % Pad rxBits if shorter than codedData
    if length(rxBits) < length(codedData)
        rxBits = [rxBits zeros(1, length(codedData)-length(rxBits))];
    end
    decoded = vitdec(rxBits(1:length(codedData)), trellis, 30, 'trunc', 'hard');
    
    % BER
    [~, ber] = biterr(decoded(1:nBits), dataBits);
    
    % MER
    errorVec = rxSignal - txSignal;
    mer = 10 * log10(mean(abs(txSignal).^2) / max(mean(abs(errorVec).^2), 1e-20));
    
    % Throughput
    throughput = bps * BW * (1 - ber);
end
