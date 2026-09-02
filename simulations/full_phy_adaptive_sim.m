%% full_phy_adaptive_sim.m
%  Complete 802.11ah/af PHY Simulator with Adaptive Modulation
%  Tactical PHY Mesh — ARYA-mgc
%  Dual-Band Conformal Helmet Antenna System
%
%  Full TX → Channel → RX chain with SNR-based adaptive modulation
%  Outputs: Constellation, RF Spectrum, BER, MER
%
%  Usage:  >> full_phy_adaptive_sim

clc; clear; close all;

fprintf('=================================================================\n');
fprintf('  FULL PHY SIMULATOR WITH ADAPTIVE MODULATION\n');
fprintf('  Tactical PHY Mesh — ARYA-mgc\n');
fprintf('  Dual-Band Conformal Helmet Antenna System\n');
fprintf('=================================================================\n\n');

%% =================== CONFIGURABLE PARAMETERS ===================
channelWidth    = 8;            % Channel bandwidth: 1, 2, 4, 8, 16 MHz
GI              = 'normal';     % Guard interval: 'normal' or 'short'
channelType     = 'AWGN';       % Channel: 'AWGN', 'Rician', 'Rayleigh'
useEqualizer    = true;         % Zero-Forcing equalization
nBits           = 10000;        % Number of data bits per run
fc              = 863e6;        % Carrier frequency (Hz) — Sub-1GHz for 802.11ah

% SNR sweep range
SNR_range       = 0:2:35;

% Adaptive modulation thresholds (SNR in dB)
% Format: [modOrder, bitsPerSymbol, codingRate, snrThreshold, name]
adaptiveMCS = struct( ...
    'name',     {'BPSK-1/2', 'QPSK-1/2', 'QPSK-3/4', '16QAM-1/2', '16QAM-3/4', '64QAM-2/3', '64QAM-3/4', '256QAM-3/4'}, ...
    'modOrder', {2,          4,           4,           16,           16,           64,           64,           256}, ...
    'bps',      {1,          2,           2,            4,            4,            6,            6,             8}, ...
    'codeRate', {'1/2',      '1/2',       '3/4',       '1/2',        '3/4',        '2/3',        '3/4',         '3/4'}, ...
    'codeNum',  {[1 2],      [1 2],       [3 4],       [1 2],        [3 4],        [2 3],        [3 4],         [3 4]}, ...
    'snrThr',   {0,          5,           9,           12,           16,           20,           24,            28} ...
);

fprintf('Config: BW=%d MHz, Channel=%s, Equalizer=%d\n', channelWidth, channelType, useEqualizer);
fprintf('SNR range: %d to %d dB\n\n', SNR_range(1), SNR_range(end));

%% =================== OFDM PARAMETERS ===================
switch channelWidth
    case 1,  Nfft = 32;   Nsd = 24;  Nsp = 2;
    case 2,  Nfft = 64;   Nsd = 52;  Nsp = 4;
    case 4,  Nfft = 128;  Nsd = 108; Nsp = 4;
    case 8,  Nfft = 256;  Nsd = 234; Nsp = 8;
    case 16, Nfft = 512;  Nsd = 468; Nsp = 8;
    otherwise, error('Invalid channelWidth');
end

Nsa = Nsd + Nsp;   % total active subcarriers
fs  = channelWidth * 1e6;  % sampling frequency

% CP length
switch GI
    case 'normal', cpLen = Nfft / 4;
    case 'short',  cpLen = Nfft / 8;
end

% Pilot subcarrier indices (simplified)
pilotIndices = round(linspace(1, Nsa, Nsp+2));
pilotIndices = pilotIndices(2:end-1);
dataIndices  = setdiff(1:Nsa, pilotIndices);

%% =================== CONVOLUTIONAL ENCODER SETUP ===================
K = 7;
codeGen = [133 171];
trellis = poly2trellis(K, codeGen);
tblen = 30;

%% =================== CHANNEL MODEL SETUP ===================
% Rician/Rayleigh multipath (20 paths)
if ~strcmp(channelType, 'AWGN')
    ro = [0.057662 0.176809 0.407163 0.303585 0.258782 ...
          0.061831 0.150340 0.051534 0.185074 0.400967 ...
          0.295723 0.350825 0.262909 0.225894 0.170996 ...
          0.149723 0.240140 0.116587 0.221155 0.259730];
    tau = [1.003019 5.422091 0.518650 2.751772 0.602895 ...
           1.016585 0.143556 0.153832 3.324866 1.935570 ...
           0.429948 3.228872 0.848831 0.073883 0.203952 ...
           0.194207 0.924450 1.381320 0.640512 1.368671] * 1e-6;
    theta = [4.855121 3.419109 5.864470 2.215894 3.758058 ...
             5.430202 3.952093 1.093586 5.775198 0.154459 ...
             5.928383 3.053023 0.628578 2.128544 1.099463 ...
             3.462951 3.664773 2.833799 3.334290 0.393889];
    if strcmp(channelType, 'Rician')
        kFactor = 10;
        ro0 = sqrt(kFactor * sum(ro.^2));
        ro = [ro0 ro]; tau = [0 tau]; theta = [0 theta];
    end
end

%% =================== STORAGE FOR RESULTS ===================
nSNR = length(SNR_range);
BER_before = zeros(length(adaptiveMCS), nSNR);
BER_after  = zeros(length(adaptiveMCS), nSNR);
MER_vals   = zeros(length(adaptiveMCS), nSNR);

BER_adaptive_before = zeros(1, nSNR);
BER_adaptive_after  = zeros(1, nSNR);
MER_adaptive        = zeros(1, nSNR);
selectedMCS         = zeros(1, nSNR);
throughput_adaptive  = zeros(1, nSNR);

% Store constellation data for plotting
constell_tx = {};
constell_rx = {};
constell_snr = [];
constell_name = {};

% Store spectrum data
spectrum_data = [];

%% =================== MAIN SIMULATION LOOP ===================
fprintf('Running simulation...\n');

for s = 1:nSNR
    SNR = SNR_range(s);
    
    %% === ADAPTIVE MCS SELECTION ===
    chosenMCS = 1;
    for m = length(adaptiveMCS):-1:1
        if SNR >= adaptiveMCS(m).snrThr
            chosenMCS = m;
            break;
        end
    end
    selectedMCS(s) = chosenMCS;
    
    M    = adaptiveMCS(chosenMCS).modOrder;
    bps  = adaptiveMCS(chosenMCS).bps;
    Kmod = 1 / sqrt(2/3 * (M - 1));  % Normalization factor
    
    % Puncture pattern based on coding rate
    crNum = adaptiveMCS(chosenMCS).codeNum;
    switch crNum(1)
        case 1, puncpat = [];                        % Rate 1/2
        case 2, puncpat = [1 1 1 0];                 % Rate 2/3
        case 3, puncpat = [1 1 1 0 0 1];             % Rate 3/4
    end
    
    %% === TX: Generate Data ===
    dataBits = randi([0 1], 1, nBits);
    DATA = [zeros(1, 16) dataBits zeros(1, 6)];  % service + tail bits
    
    dataLen = length(DATA);
    Ncbps = Nsd * bps;  % coded bits per OFDM symbol
    if isempty(puncpat)
        Ndbps = Ncbps / 2;
    else
        Ndbps = Ncbps * sum(puncpat) / (2 * length(puncpat) / 2);
    end
    Ndbps = floor(Ndbps);
    if Ndbps < 1, Ndbps = 1; end
    
    totalBits = ceil(dataLen / Ndbps) * Ndbps;
    nPad = totalBits - dataLen;
    DATA = [DATA zeros(1, nPad)];
    
    %% === TX: Scrambler ===
    scrambledData = DATA;  % simplified scrambling
    s_reg = [1 0 1 1 1 0 1];  % initial state
    for i = 1:length(scrambledData)
        feedback = xor(s_reg(4), s_reg(7));
        scrambledData(i) = xor(DATA(i), feedback);
        s_reg = [feedback s_reg(1:6)];
    end
    scrambledData(end-nPad-5:end-nPad) = zeros(1, 6);  % zero tail bits
    
    %% === TX: Convolutional Encoder ===
    if isempty(puncpat)
        codedData = convenc(scrambledData, trellis);
    else
        codedData = convenc(scrambledData, trellis, puncpat);
    end
    
    %% === TX: Interleaver ===
    Ncol = 16;
    Nrows = ceil(length(codedData) / Ncol);
    padLen = Nrows * Ncol - length(codedData);
    intrlvInput = [codedData zeros(1, padLen)];
    intrlvd = matintrlv(intrlvInput, Nrows, Ncol);
    
    %% === TX: QAM Modulation ===
    nSyms = floor(length(intrlvd) / bps);
    bitsTrunc = intrlvd(1:nSyms*bps);
    bitMatrix = reshape(bitsTrunc, bps, [])';
    symbols = bi2de(bitMatrix, 'left-msb');
    
    if M == 2
        mappedData = 2*symbols' - 1;  % BPSK
    else
        mappedData = qammod(symbols', M, 'gray', 'UnitAveragePower', true);
    end
    
    txConstellation = mappedData;  % save for plotting
    
    %% === TX: OFDM Modulation (IFFT + CP) ===
    nOFDMsyms = ceil(length(mappedData) / Nsd);
    padData = [mappedData zeros(1, nOFDMsyms*Nsd - length(mappedData))];
    ofdmData = reshape(padData, Nsd, nOFDMsyms);
    
    % Insert into FFT bins
    ofdmFrame = zeros(Nfft, nOFDMsyms);
    ofdmFrame(2:Nsd+1, :) = ofdmData;  % data in positive freq
    
    % IFFT
    txTimeDomain = ifft(ofdmFrame, Nfft);
    
    % Add CP
    txWithCP = [txTimeDomain(end-cpLen+1:end, :); txTimeDomain];
    
    % Serialize
    txSignal = txWithCP(:)';
    
    % Save spectrum
    if s == round(nSNR/2)  % save spectrum at mid-SNR
        spectrum_data = txSignal;
    end
    
    %% === CHANNEL ===
    switch channelType
        case 'AWGN'
            rxSignal = txSignal;
        case {'Rician', 'Rayleigh'}
            nPaths = length(ro);
            sigLen = length(txSignal);
            rxSignal = zeros(1, sigLen);
            for p = 1:nPaths
                h = ro(p) * exp(-1i * theta(p));
                delay = round(tau(p) * fs);
                delayed = [zeros(1, delay) txSignal(1:sigLen-delay)];
                rxSignal = rxSignal + h * delayed;
            end
            rxSignal = rxSignal / sqrt(sum(ro.^2));
    end
    
    % Add AWGN noise
    rxSignal = awgn(rxSignal, SNR, 'measured');
    
    %% === RX: OFDM Demodulation ===
    rxParallel = reshape(rxSignal(1:length(txWithCP(:))), Nfft+cpLen, nOFDMsyms);
    rxNoCP = rxParallel(cpLen+1:end, :);  % remove CP
    rxFreqDomain = fft(rxNoCP, Nfft);
    rxData = rxFreqDomain(2:Nsd+1, :);
    
    %% === RX: Equalization (ZF) ===
    if useEqualizer && ~strcmp(channelType, 'AWGN')
        % Estimate channel from known TX
        H_est = rxData(:,1) ./ ofdmData(:,1);
        H_est(abs(H_est) < 1e-6) = 1;  % avoid division by zero
        for sym = 1:nOFDMsyms
            rxData(:,sym) = rxData(:,sym) ./ H_est;
        end
    end
    
    rxMappedData = rxData(:)';
    rxMappedData = rxMappedData(1:length(mappedData));
    
    rxConstellation = rxMappedData;  % save for plotting
    
    %% === RX: QAM Demodulation ===
    if M == 2
        rxSymbols = double(real(rxMappedData) > 0);
    else
        rxSymbols = qamdemod(rxMappedData, M, 'gray', 'UnitAveragePower', true);
    end
    
    rxBitMatrix = de2bi(rxSymbols(:), bps, 'left-msb');
    demodBits = reshape(rxBitMatrix', 1, []);
    
    % BER before Viterbi
    validLen = min(length(demodBits), length(intrlvd));
    [~, berBefore] = biterr(demodBits(1:validLen), intrlvd(1:validLen));
    
    %% === RX: De-interleaver ===
    deintrlvInput = [demodBits zeros(1, max(0, length(intrlvInput)-length(demodBits)))];
    deintrlvInput = deintrlvInput(1:length(intrlvInput));
    deintrlvd = matdeintrlv(deintrlvInput, Nrows, Ncol);
    deintrlvd = deintrlvd(1:length(codedData));
    
    %% === RX: Viterbi Decoder ===
    if isempty(puncpat)
        decoded = vitdec(deintrlvd, trellis, tblen, 'trunc', 'hard');
    else
        decoded = vitdec(deintrlvd, trellis, tblen, 'trunc', 'hard', puncpat);
    end
    
    %% === RX: Descrambler ===
    plainData = decoded;
    s_reg2 = [1 0 1 1 1 0 1];
    for i = 1:length(plainData)
        feedback = xor(s_reg2(4), s_reg2(7));
        plainData(i) = xor(decoded(i), feedback);
        s_reg2 = [feedback s_reg2(1:6)];
    end
    
    %% === METRICS ===
    % BER after Viterbi
    validLen2 = min(length(plainData)-nPad-6, length(DATA)-nPad-6);
    if validLen2 > 0
        [~, berAfter] = biterr(plainData(1:validLen2), DATA(1:validLen2));
    else
        berAfter = 0;
    end
    
    % MER (Modulation Error Ratio)
    if length(rxMappedData) == length(mappedData)
        errorVec = rxMappedData - mappedData;
        mer = 10 * log10(mean(abs(mappedData).^2) / mean(abs(errorVec).^2));
    else
        mer = 0;
    end
    
    BER_adaptive_before(s) = max(berBefore, 1e-7);
    BER_adaptive_after(s)  = max(berAfter, 1e-7);
    MER_adaptive(s)        = mer;
    throughput_adaptive(s)  = bps * (1 - berAfter) * channelWidth;
    
    % Save constellation data at key SNR points
    if any(SNR == [5 12 18 28])
        constell_tx{end+1} = txConstellation(1:min(2000,length(txConstellation)));
        constell_rx{end+1} = rxConstellation(1:min(2000,length(rxConstellation)));
        constell_snr(end+1) = SNR;
        constell_name{end+1} = adaptiveMCS(chosenMCS).name;
    end
    
    fprintf('  SNR=%2d dB → %s (M=%d) | BER=%.2e | MER=%.1f dB\n', ...
        SNR, adaptiveMCS(chosenMCS).name, M, berAfter, mer);
end

fprintf('\n[OK] Simulation complete!\n\n');

%% =================== FIGURE 1: BER vs SNR ===================
figure('Name', 'BER Performance', 'Position', [50 100 950 550], 'Color', 'w');

semilogy(SNR_range, BER_adaptive_before, 'r--o', 'LineWidth', 2, 'MarkerSize', 6, ...
    'MarkerFaceColor', 'r', 'DisplayName', 'BER before Viterbi');
hold on; grid on;
semilogy(SNR_range, BER_adaptive_after, 'b-s', 'LineWidth', 2.5, 'MarkerSize', 7, ...
    'MarkerFaceColor', 'b', 'DisplayName', 'BER after Viterbi (Adaptive)');

% Mark MCS switching thresholds
for m = 2:length(adaptiveMCS)
    thr = adaptiveMCS(m).snrThr;
    if thr >= SNR_range(1) && thr <= SNR_range(end)
        xline(thr, ':', 'Color', [0.6 0.6 0.6], 'HandleVisibility', 'off');
        text(thr+0.3, 5e-1, adaptiveMCS(m).name, 'FontSize', 7, 'Rotation', 90, ...
            'Color', [0.4 0.4 0.4]);
    end
end

xlabel('SNR (dB)', 'FontSize', 13, 'FontWeight', 'bold');
ylabel('Bit Error Rate (BER)', 'FontSize', 13, 'FontWeight', 'bold');
title({'Adaptive Modulation — BER Performance (Full PHY Chain)', ...
       sprintf('802.11ah | BW=%d MHz | %s Channel | ARYA-mgc', channelWidth, channelType)}, ...
       'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'southwest', 'FontSize', 11);
ylim([1e-7 1]);

%% =================== FIGURE 2: MER vs SNR ===================
figure('Name', 'MER Performance', 'Position', [100 80 950 500], 'Color', 'w');

plot(SNR_range, MER_adaptive, 'b-o', 'LineWidth', 2, 'MarkerSize', 6, ...
    'MarkerFaceColor', [0.2 0.5 0.9]);
hold on; grid on;
plot(SNR_range, SNR_range, 'k--', 'LineWidth', 1, 'DisplayName', 'SNR = MER (ideal)');

xlabel('SNR (dB)', 'FontSize', 13, 'FontWeight', 'bold');
ylabel('MER (dB)', 'FontSize', 13, 'FontWeight', 'bold');
title({'Modulation Error Ratio (MER) vs SNR', ...
       sprintf('Adaptive Modulation | %s Channel | ARYA-mgc', channelType)}, ...
       'FontSize', 14, 'FontWeight', 'bold');
legend({'MER (Adaptive)', 'Ideal (MER = SNR)'}, 'FontSize', 11, 'Location', 'northwest');

%% =================== FIGURE 3: Constellation Diagrams ===================
if ~isempty(constell_rx)
    figure('Name', 'Constellation Diagrams', 'Position', [150 60 1000 700], 'Color', 'w');
    
    nConst = min(4, length(constell_rx));
    modColors = [0.9 0.2 0.2; 0.9 0.6 0.1; 0.2 0.7 0.3; 0.2 0.5 0.9];
    
    for idx = 1:nConst
        subplot(2, 2, idx);
        
        % Plot received constellation
        rx = constell_rx{idx};
        plot(real(rx), imag(rx), '.', 'Color', modColors(idx,:), 'MarkerSize', 4);
        hold on;
        
        % Plot ideal constellation
        tx = constell_tx{idx};
        idealPts = unique(tx);
        plot(real(idealPts), imag(idealPts), 'ko', 'MarkerSize', 10, ...
            'MarkerFaceColor', 'k', 'LineWidth', 1.5);
        
        title(sprintf('%s @ SNR = %d dB', constell_name{idx}, constell_snr(idx)), ...
            'FontSize', 12, 'FontWeight', 'bold');
        xlabel('In-Phase (I)'); ylabel('Quadrature (Q)');
        grid on; axis equal;
        lim = max(abs([real(rx) imag(rx)])) * 1.3;
        if lim > 0 && ~isnan(lim)
            xlim([-lim lim]); ylim([-lim lim]);
        end
    end
    
    sgtitle({'Received Constellation Diagrams — Adaptive Modulation', ...
             'Full PHY Chain (Tactical PHY Mesh — ARYA-mgc)'}, ...
             'FontSize', 14, 'FontWeight', 'bold');
end

%% =================== FIGURE 4: RF Spectrum ===================
figure('Name', 'RF Spectrum', 'Position', [200 40 950 450], 'Color', 'w');

if ~isempty(spectrum_data)
    nfft_spec = 2048;
    spectrum = fftshift(fft(spectrum_data, nfft_spec));
    freqAxis = linspace(-fs/2, fs/2, nfft_spec) / 1e6;
    spectrumDB = 20*log10(abs(spectrum) / max(abs(spectrum)) + 1e-10);
    
    plot(freqAxis, spectrumDB, 'b-', 'LineWidth', 1.2);
    grid on;
    xlabel('Frequency (MHz)', 'FontSize', 13, 'FontWeight', 'bold');
    ylabel('Normalized Magnitude (dB)', 'FontSize', 13, 'FontWeight', 'bold');
    title({'OFDM Signal — Normalized RF Spectrum', ...
           sprintf('802.11ah | BW=%d MHz | ARYA-mgc', channelWidth)}, ...
           'FontSize', 14, 'FontWeight', 'bold');
    ylim([-40 0]);
end

%% =================== FIGURE 5: Adaptive MCS Selection ===================
figure('Name', 'MCS Selection', 'Position', [250 20 950 400], 'Color', 'w');

modColors5 = lines(length(adaptiveMCS));

stairs(SNR_range, selectedMCS, 'k-', 'LineWidth', 2);
hold on;
for s2 = 1:nSNR
    plot(SNR_range(s2), selectedMCS(s2), 'o', 'MarkerSize', 10, ...
        'MarkerFaceColor', modColors5(selectedMCS(s2),:), ...
        'MarkerEdgeColor', 'k');
end

yticks(1:length(adaptiveMCS));
yticklabels({adaptiveMCS.name});
xlabel('SNR (dB)', 'FontSize', 13, 'FontWeight', 'bold');
ylabel('Selected MCS', 'FontSize', 13, 'FontWeight', 'bold');
title({'Adaptive MCS Selection — Intelligent Link Management', ...
       'MCU Decision Engine (ARYA-mgc)'}, ...
       'FontSize', 14, 'FontWeight', 'bold');
grid on;
ylim([0.5 length(adaptiveMCS)+0.5]);

%% =================== FIGURE 6: Throughput ===================
figure('Name', 'Throughput', 'Position', [300 20 950 450], 'Color', 'w');

area(SNR_range, throughput_adaptive, 'FaceColor', [0.2 0.6 0.9], ...
    'FaceAlpha', 0.6, 'EdgeColor', [0.1 0.3 0.7], 'LineWidth', 1.5);
hold on;
plot(SNR_range, ones(size(SNR_range))*channelWidth*0.5, 'r--', 'LineWidth', 2);
grid on;

xlabel('SNR (dB)', 'FontSize', 13, 'FontWeight', 'bold');
ylabel('Throughput (Mbps)', 'FontSize', 13, 'FontWeight', 'bold');
title({'Adaptive Modulation — Effective Throughput', ...
       sprintf('BW=%d MHz | %s Channel | ARYA-mgc', channelWidth, channelType)}, ...
       'FontSize', 14, 'FontWeight', 'bold');
legend({'Adaptive Throughput', sprintf('Fixed BPSK-1/2 (%.1f Mbps)', channelWidth*0.5)}, ...
    'FontSize', 11, 'Location', 'northwest');

%% =================== RESULTS TABLE ===================
fprintf('=================================================================\n');
fprintf('  SIMULATION RESULTS SUMMARY\n');
fprintf('=================================================================\n');
fprintf('  %-12s | %-6s | %-10s | %-10s | %-8s\n', ...
    'SNR (dB)', 'MCS', 'BER(pre)', 'BER(post)', 'MER(dB)');
fprintf('  ------------|--------|------------|------------|--------\n');
for s2 = 1:nSNR
    fprintf('  %6d      | %-6s | %.2e  | %.2e  | %6.1f\n', ...
        SNR_range(s2), adaptiveMCS(selectedMCS(s2)).name, ...
        BER_adaptive_before(s2), BER_adaptive_after(s2), MER_adaptive(s2));
end
fprintf('=================================================================\n');
fprintf('  6 figures generated. Simulation complete!\n');
fprintf('=================================================================\n');
