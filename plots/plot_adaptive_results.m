%% plot_adaptive_results.m
%  Run AFTER the Simulink simulation finishes.
%  Reads logged data from workspace and generates presentation figures.
%
%  Usage:  >> plot_adaptive_results

fprintf('Generating figures from simulation data...\n\n');

%% Check if simulation data exists
if exist('out', 'var') && isa(out, 'Simulink.SimulationOutput')
    snr = out.get('sim_SNR');
    modOrder = out.get('sim_ModOrder');
    bitsPerSym = out.get('sim_BitsPerSym');
    throughput = out.get('sim_Throughput');
    time = out.get('tout');
    fprintf('[OK] Loaded data from Simulink output\n');
elseif exist('sim_SNR', 'var')
    snr = sim_SNR;
    modOrder = sim_ModOrder;
    bitsPerSym = sim_BitsPerSym;
    throughput = sim_Throughput;
    time = (0:length(snr)-1)';
    fprintf('[OK] Loaded data from workspace\n');
else
    error('No simulation data found! Run the Simulink model first.');
end

%% ===== FIGURE 1: SNR vs Modulation Order (Adaptive Switching) =====
figure('Name', 'Adaptive MCS Switching', ...
    'Position', [50 100 1000 500], 'Color', 'w');

yyaxis left
plot(time, snr, 'b-', 'LineWidth', 2);
ylabel('SNR (dB)', 'FontSize', 13, 'FontWeight', 'bold');
ylim([0 45]);

yyaxis right
stairs(time, modOrder, 'r-', 'LineWidth', 2.5);
ylabel('Modulation Order (M)', 'FontSize', 13, 'FontWeight', 'bold');
yticks([2 4 16 64 256]);
yticklabels({'BPSK (2)', 'QPSK (4)', '16-QAM (16)', '64-QAM (64)', '256-QAM (256)'});

xlabel('Time (s)', 'FontSize', 13, 'FontWeight', 'bold');
title({'Adaptive Modulation Switching — Real-Time MCS Selection', ...
       'Dual-Band Helmet Antenna System (Tactical PHY Mesh — ARYA-mgc)'}, ...
       'FontSize', 15, 'FontWeight', 'bold');
legend({'SNR (dB)', 'Selected Modulation'}, 'FontSize', 11, 'Location', 'northwest');
grid on;

%% ===== FIGURE 2: Throughput over Time =====
figure('Name', 'Adaptive Throughput', ...
    'Position', [100 50 1000 500], 'Color', 'w');

area(time, throughput, 'FaceColor', [0.2 0.6 0.9], 'FaceAlpha', 0.6, 'EdgeColor', [0.1 0.3 0.7], 'LineWidth', 1.5);
hold on;
fixedBPSK = ones(size(time)) * 4;  % Fixed BPSK = 1 bit/sym × 4 MHz
plot(time, fixedBPSK, 'r--', 'LineWidth', 2);

xlabel('Time (s)', 'FontSize', 13, 'FontWeight', 'bold');
ylabel('Throughput (Mbps)', 'FontSize', 13, 'FontWeight', 'bold');
title({'Adaptive Modulation — Throughput Gain vs Fixed BPSK', ...
       'Intelligent Link Management (ARYA-mgc)'}, ...
       'FontSize', 15, 'FontWeight', 'bold');
legend({'Adaptive Throughput', 'Fixed BPSK (4 Mbps)'}, 'FontSize', 11, 'Location', 'northwest');
grid on;
ylim([0 40]);

%% ===== FIGURE 3: Bits per Symbol Staircase =====
figure('Name', 'MCS Selection Detail', ...
    'Position', [150 50 1000 400], 'Color', 'w');

modColors = [0.9 0.2 0.2;   % BPSK
             0.9 0.6 0.1;   % QPSK
             0.2 0.7 0.3;   % 16-QAM
             0.2 0.5 0.9;   % 64-QAM
             0.6 0.3 0.8];  % 256-QAM
modNames = {'BPSK', 'QPSK', '16-QAM', '64-QAM', '256-QAM'};
modBPS   = [1 2 4 6 8];

stairs(time, bitsPerSym, 'k-', 'LineWidth', 2);
hold on;

for i = 1:length(time)
    idx = find(modBPS == bitsPerSym(i), 1);
    if ~isempty(idx)
        plot(time(i), bitsPerSym(i), '.', 'Color', modColors(idx,:), 'MarkerSize', 8);
    end
end

yticks(modBPS);
yticklabels({'1 (BPSK)', '2 (QPSK)', '4 (16-QAM)', '6 (64-QAM)', '8 (256-QAM)'});
xlabel('Time (s)', 'FontSize', 13, 'FontWeight', 'bold');
ylabel('Bits per Symbol', 'FontSize', 13, 'FontWeight', 'bold');
title({'Adaptive MCS Selection — Spectral Efficiency over Time', ...
       'MCU Decision Engine (ARYA-mgc)'}, ...
       'FontSize', 15, 'FontWeight', 'bold');
grid on;
ylim([0 10]);

%% ===== FIGURE 4: Switching Summary Bar Chart =====
figure('Name', 'Modulation Usage Summary', ...
    'Position', [200 50 600 450], 'Color', 'w');

counts = zeros(1, length(modBPS));
for i = 1:length(modBPS)
    counts(i) = sum(bitsPerSym == modBPS(i));
end
pct = counts / sum(counts) * 100;

b = bar(1:5, pct, 'FaceColor', 'flat');
for i = 1:5
    b.CData(i,:) = modColors(i,:);
end

xticklabels(modNames);
ylabel('Usage (%)', 'FontSize', 13, 'FontWeight', 'bold');
xlabel('Modulation Scheme', 'FontSize', 13, 'FontWeight', 'bold');
title({'Modulation Scheme Usage Distribution', ...
       'Adaptive Link Management (ARYA-mgc)'}, ...
       'FontSize', 14, 'FontWeight', 'bold');
grid on;

% Add percentage labels on bars
for i = 1:5
    if pct(i) > 0
        text(i, pct(i) + 1.5, sprintf('%.1f%%', pct(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
    end
end

fprintf('Done! 4 figures generated.\n');
fprintf('  Fig 1: SNR vs Modulation Switching\n');
fprintf('  Fig 2: Throughput (Adaptive vs Fixed)\n');
fprintf('  Fig 3: Bits/Symbol Staircase\n');
fprintf('  Fig 4: Modulation Usage Summary\n');
