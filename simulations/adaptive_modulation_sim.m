%% adaptive_modulation_sim.m
%  Adaptive Modulation Simulation for Dual-Band Helmet Antenna System
%  Tactical PHY Mesh — ARYA-mgc
%
%  Simulates SNR-based adaptive modulation switching:
%    BPSK → QPSK → 16-QAM → 64-QAM → 256-QAM
%  based on measured link quality (RSSI/SNR).
%
%  Usage:  >> adaptive_modulation_sim

clc; clear; close all;

fprintf('============================================================\n');
fprintf('  Adaptive Modulation Simulator — Tactical PHY Mesh — ARYA-mgc\n');
fprintf('  Dual-Band Conformal Helmet Antenna System\n');
fprintf('============================================================\n\n');

%% =================== SYSTEM PARAMETERS ===================
nBits       = 1e5;           % bits per SNR point
SNR_range   = 0:1:35;        % SNR sweep range (dB)
nSNR        = length(SNR_range);

% Modulation schemes available (ordered by spectral efficiency)
modSchemes = struct( ...
    'name',    {'BPSK',  'QPSK',  '16-QAM', '64-QAM', '256-QAM'}, ...
    'order',   {2,       4,       16,       64,       256}, ...
    'bitsPerSymbol', {1, 2,       4,        6,        8}, ...
    'snrThreshold',  {0, 8,       14,       20,       26} ...  % SNR thresholds (dB)
);

% Target BER for adaptive switching
targetBER = 1e-3;

%% =================== FIXED MODULATION BER CURVES ===================
fprintf('Phase 1: Computing BER curves for each modulation...\n');

BER_fixed = zeros(length(modSchemes), nSNR);

for m = 1:length(modSchemes)
    M = modSchemes(m).order;
    for s = 1:nSNR
        snr = SNR_range(s);
        
        % Generate random bits
        data = randi([0 1], 1, nBits);
        
        % Pad to multiple of bitsPerSymbol
        bps = modSchemes(m).bitsPerSymbol;
        nPad = mod(bps - mod(length(data), bps), bps);
        if nPad == bps, nPad = 0; end
        dataPadded = [data zeros(1, nPad)];
        
        % Convert bits to symbols
        nSymbols = length(dataPadded) / bps;
        bitMatrix = reshape(dataPadded, bps, [])';  % each row = one symbol's bits
        symbols = bi2de(bitMatrix, 'left-msb')';
        
        % QAM modulation
        if M == 2
            modSignal = 2*symbols - 1;  % BPSK
        else
            modSignal = qammod(symbols, M, 'gray', 'UnitAveragePower', true);
        end
        
        % AWGN channel
        rxSignal = awgn(modSignal, snr, 'measured');
        
        % QAM demodulation
        if M == 2
            rxSymbols = double(real(rxSignal) > 0);
        else
            rxSymbols = qamdemod(rxSignal, M, 'gray', 'UnitAveragePower', true);
        end
        
        % Convert symbols back to bits
        rxBitMatrix = de2bi(rxSymbols(:), bps, 'left-msb');
        rxBits = reshape(rxBitMatrix', 1, []);
        
        % BER calculation
        [~, ber] = biterr(data, rxBits(1:nBits));
        BER_fixed(m, s) = max(ber, 1e-7);  % floor for log plots
    end
    fprintf('  [OK] %s done\n', modSchemes(m).name);
end

%% =================== ADAPTIVE MODULATION ===================
fprintf('\nPhase 2: Running adaptive modulation simulation...\n');

BER_adaptive    = zeros(1, nSNR);
throughput_adaptive = zeros(1, nSNR);
throughput_fixed_bpsk = zeros(1, nSNR);
selectedMod     = zeros(1, nSNR);   % which modulation was selected

for s = 1:nSNR
    snr = SNR_range(s);
    
    % === ADAPTIVE DECISION ENGINE ===
    % Select highest-order modulation that can achieve target BER at this SNR
    chosenMod = 1;  % default to BPSK
    for m = length(modSchemes):-1:1
        if snr >= modSchemes(m).snrThreshold
            chosenMod = m;
            break;
        end
    end
    selectedMod(s) = chosenMod;
    
    M   = modSchemes(chosenMod).order;
    bps = modSchemes(chosenMod).bitsPerSymbol;
    
    % Generate random bits
    data = randi([0 1], 1, nBits);
    
    % Pad
    nPad = mod(bps - mod(length(data), bps), bps);
    if nPad == bps, nPad = 0; end
    dataPadded = [data zeros(1, nPad)];
    
    % Modulate
    nSymbols = length(dataPadded) / bps;
    bitMatrix = reshape(dataPadded, bps, [])';
    symbols = bi2de(bitMatrix, 'left-msb')';
    
    if M == 2
        modSignal = 2*symbols - 1;
    else
        modSignal = qammod(symbols, M, 'gray', 'UnitAveragePower', true);
    end
    
    % AWGN channel
    rxSignal = awgn(modSignal, snr, 'measured');
    
    % Demodulate
    if M == 2
        rxSymbols = double(real(rxSignal) > 0);
    else
        rxSymbols = qamdemod(rxSignal, M, 'gray', 'UnitAveragePower', true);
    end
    
    rxBitMatrix = de2bi(rxSymbols(:), bps, 'left-msb');
    rxBits = reshape(rxBitMatrix', 1, []);
    
    [~, ber] = biterr(data, rxBits(1:nBits));
    BER_adaptive(s) = max(ber, 1e-7);
    
    % Throughput = bits/symbol * (1 - BER) — effective throughput
    throughput_adaptive(s)    = bps * (1 - ber);
    throughput_fixed_bpsk(s)  = 1 * (1 - BER_fixed(1, s));
end

fprintf('  [OK] Adaptive modulation simulation complete\n\n');

%% =================== PLOT RESULTS ===================
fprintf('Phase 3: Generating plots...\n');

colors = lines(length(modSchemes) + 1);

% --- Figure 1: BER Comparison ---
figure('Name', 'Adaptive Modulation — BER Performance', ...
       'Position', [50 100 900 600], 'Color', 'w');

semilogy(SNR_range, BER_adaptive, 'k-o', 'LineWidth', 2.5, ...
    'MarkerSize', 6, 'MarkerFaceColor', 'k', 'DisplayName', 'ADAPTIVE');
hold on; grid on;

lineStyles = {'--', '-.', ':', '--', '-.'};
for m = 1:length(modSchemes)
    semilogy(SNR_range, BER_fixed(m,:), lineStyles{m}, ...
        'Color', colors(m,:), 'LineWidth', 1.5, ...
        'DisplayName', modSchemes(m).name);
end

% Mark switching thresholds
for m = 2:length(modSchemes)
    thr = modSchemes(m).snrThreshold;
    xline(thr, ':', 'Color', [0.5 0.5 0.5], 'LineWidth', 1, ...
        'HandleVisibility', 'off');
    text(thr+0.3, 1e-1, sprintf('→%s', modSchemes(m).name), ...
        'FontSize', 8, 'Color', [0.4 0.4 0.4]);
end

xlabel('SNR (dB)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Bit Error Rate (BER)', 'FontSize', 12, 'FontWeight', 'bold');
title({'Adaptive Modulation — BER vs SNR', ...
       'Dual-Band Helmet Antenna System (ARYA-mgc)'}, ...
       'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'southwest', 'FontSize', 10);
ylim([1e-7 1]);

% --- Figure 2: Throughput Comparison ---
figure('Name', 'Adaptive Modulation — Throughput', ...
       'Position', [100 50 900 600], 'Color', 'w');

bar_data = [throughput_fixed_bpsk; throughput_adaptive]';
b = bar(SNR_range, bar_data, 'grouped');
b(1).FaceColor = [0.7 0.7 0.7];
b(1).DisplayName = 'Fixed BPSK';
b(2).FaceColor = [0.2 0.6 0.9];
b(2).DisplayName = 'Adaptive Modulation';
hold on; grid on;

xlabel('SNR (dB)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Effective Throughput (bits/symbol)', 'FontSize', 12, 'FontWeight', 'bold');
title({'Adaptive Modulation — Throughput Gain', ...
       'Dual-Band Helmet Antenna System (ARYA-mgc)'}, ...
       'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 11);
ylim([0 9]);

% --- Figure 3: Modulation Selection vs SNR ---
figure('Name', 'Adaptive Modulation — MCS Selection', ...
       'Position', [150 50 900 400], 'Color', 'w');

% Color-coded staircase
modColors = [0.9 0.3 0.3;   % BPSK  - red
             0.9 0.6 0.1;   % QPSK  - orange
             0.2 0.7 0.3;   % 16QAM - green
             0.2 0.5 0.9;   % 64QAM - blue
             0.6 0.3 0.8];  % 256QAM - purple

stairs(SNR_range, selectedMod, 'k-', 'LineWidth', 2);
hold on;
for s = 1:nSNR
    plot(SNR_range(s), selectedMod(s), 'o', ...
        'MarkerSize', 10, 'MarkerFaceColor', modColors(selectedMod(s),:), ...
        'MarkerEdgeColor', 'k', 'LineWidth', 1);
end

yticks(1:length(modSchemes));
yticklabels({modSchemes.name});
xlabel('SNR (dB)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Selected Modulation', 'FontSize', 12, 'FontWeight', 'bold');
title({'Adaptive MCS Selection based on Link Quality (SNR)', ...
       'Intelligent Link Management — MCU Decision Engine'}, ...
       'FontSize', 14, 'FontWeight', 'bold');
grid on;
ylim([0.5 length(modSchemes)+0.5]);

% Add SNR threshold annotations
for m = 1:length(modSchemes)
    text(modSchemes(m).snrThreshold + 0.5, m + 0.25, ...
        sprintf('SNR ≥ %d dB', modSchemes(m).snrThreshold), ...
        'FontSize', 9, 'Color', modColors(m,:), 'FontWeight', 'bold');
end

% --- Figure 4: Constellation Diagrams ---
figure('Name', 'Adaptive Modulation — Constellation Diagrams', ...
       'Position', [200 50 1000 700], 'Color', 'w');

demo_snrs = [5, 12, 18, 28];  % Show constellation at different SNRs
demo_mods = [1, 2, 3, 4];     % BPSK, QPSK, 16-QAM, 64-QAM

for idx = 1:4
    subplot(2, 2, idx);
    
    snr = demo_snrs(idx);
    m   = demo_mods(idx);
    M   = modSchemes(m).order;
    bps = modSchemes(m).bitsPerSymbol;
    
    % Generate & modulate
    nSym = 2000;
    syms = randi([0 M-1], 1, nSym);
    if M == 2
        modSig = 2*syms - 1;
    else
        modSig = qammod(syms, M, 'gray', 'UnitAveragePower', true);
    end
    rxSig = awgn(modSig, snr, 'measured');
    
    plot(real(rxSig), imag(rxSig), '.', 'Color', modColors(m,:), 'MarkerSize', 4);
    hold on;
    
    % Plot ideal constellation points
    if M == 2
        idealPts = [-1 1];
        plot(real(idealPts), imag(idealPts), 'ko', 'MarkerSize', 10, ...
            'MarkerFaceColor', 'k', 'LineWidth', 1.5);
    else
        idealPts = qammod(0:M-1, M, 'gray', 'UnitAveragePower', true);
        plot(real(idealPts), imag(idealPts), 'ko', 'MarkerSize', 8, ...
            'MarkerFaceColor', 'k', 'LineWidth', 1.5);
    end
    
    title(sprintf('%s @ SNR = %d dB', modSchemes(m).name, snr), ...
        'FontSize', 12, 'FontWeight', 'bold');
    xlabel('In-Phase (I)'); ylabel('Quadrature (Q)');
    grid on; axis equal;
    lim = max(abs([real(rxSig) imag(rxSig)])) * 1.2;
    if lim > 0, xlim([-lim lim]); ylim([-lim lim]); end
end

sgtitle({'Received Constellation Diagrams at Different SNR Levels', ...
         'Adaptive Modulation — ARYA-mgc'}, ...
         'FontSize', 14, 'FontWeight', 'bold');

%% =================== SUMMARY TABLE ===================
fprintf('\n============================================================\n');
fprintf('  ADAPTIVE MODULATION SWITCHING TABLE\n');
fprintf('============================================================\n');
fprintf('  %-10s | %-10s | %-14s | %-10s\n', ...
    'SNR Range', 'Modulation', 'Bits/Symbol', 'Data Rate');
fprintf('  ----------|------------|----------------|----------\n');
bw = 4e6;  % 4 MHz channel (802.11ah)
for m = 1:length(modSchemes)
    if m < length(modSchemes)
        snrRange = sprintf('%2d–%2d dB', modSchemes(m).snrThreshold, ...
            modSchemes(m+1).snrThreshold - 1);
    else
        snrRange = sprintf('%2d+ dB   ', modSchemes(m).snrThreshold);
    end
    dataRate = modSchemes(m).bitsPerSymbol * bw / 1e6;
    fprintf('  %-10s | %-10s | %d              | ~%.0f Mbps\n', ...
        snrRange, modSchemes(m).name, modSchemes(m).bitsPerSymbol, dataRate);
end
fprintf('============================================================\n');
fprintf('  Simulation complete! Check the figure windows.\n');
fprintf('============================================================\n');
