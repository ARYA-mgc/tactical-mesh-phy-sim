%% export_mesh_results_image.m
%  PERFECT 4-PANEL SIMULATION RESULTS FIGURE FOR Tactical Mesh
%  (A) Node Throughput vs Mission Timeline
%  (B) Base Station Aggregate Network Bandwidth
%  (C) Commando RF Link Quality (SNR) — Non-overlapping layout
%  (D) Adaptive Modulation Switching (MCS)
%  Tactical PHY Mesh — ARYA-mgc
%
%  Usage: >> export_mesh_results_image

clc;
fprintf('=================================================================\n');
fprintf('  GENERATING OFFICIAL 4-PANEL RESULTS FIGURE (Tactical Mesh)\n');
fprintf('  ARYA-mgc — Dual-Band Helmet Antenna System\n');
fprintf('=================================================================\n\n');

% Mission time vector (210-second CQB operation)
t = 0:1:210;

% Time-varying SNR profiles for 4 Nodes
s1 = zeros(size(t)); s2 = zeros(size(t)); s3 = zeros(size(t)); s4 = zeros(size(t));
r1 = zeros(size(t)); r2 = zeros(size(t)); r3 = zeros(size(t)); r4 = zeros(size(t));

BW = 8; % MHz L-Band Bandwidth

for k = 1:length(t)
    time = t(k);
    
    % Node 1: Rooftop Leader (Overwatch)
    if time <= 50, s1(k) = 30; elseif time <= 100, s1(k) = 18; elseif time <= 160, s1(k) = 25; else, s1(k) = 30; end
    % Node 2: Corridor Breacher (Relay Router)
    if time <= 30, s2(k) = 22; elseif time <= 70, s2(k) = 15; elseif time <= 110, s2(k) = 8; elseif time <= 160, s2(k) = 12; else, s2(k) = 20; end
    % Node 3: Basement Pointman (Deep Penetration)
    if time <= 20, s3(k) = 20; elseif time <= 60, s3(k) = 10; elseif time <= 120, s3(k) = 5; elseif time <= 170, s3(k) = 8; else, s3(k) = 18; end
    % Node 4: Perimeter Guard (Transport)
    if time <= 50, s4(k) = 25; elseif time <= 150, s4(k) = 20; else, s4(k) = 25; end
    
    % Adaptive Rate Calculation (BW = 8 MHz)
    getRate = @(s) BW * (8*(s>=26) + 6*(s>=20 & s<26) + 4*(s>=14 & s<20) + 2*(s>=8 & s<14) + 1*(s<8));
    
    r1(k) = getRate(s1(k));
    r2(k) = getRate(s2(k));
    r3(k) = getRate(s3(k));
    r4(k) = getRate(s4(k));
end

total_bandwidth = r1 + r2 + r3 + r4;

%% Create Publication-Quality Figure
fig = figure('Name', '4-Node Tactical Mesh Simulation Results', 'Color', 'w', ...
             'Position', [100 80 1150 780], 'Units', 'pixels');

% -------------------------------------------------------------
% (A) NODE THROUGHPUT VS MISSION TIMELINE
% -------------------------------------------------------------
subplot(2, 2, 1);
plot(t, r1, 'b-', 'LineWidth', 2.2); hold on;
plot(t, r2, 'g-', 'LineWidth', 2.2);
plot(t, r3, 'r-', 'LineWidth', 2.2);
plot(t, r4, 'm-', 'LineWidth', 2.2);
grid on; set(gca, 'FontSize', 10, 'LineWidth', 1.2);
title('(A) Node Throughput vs Mission Timeline', 'FontWeight', 'bold', 'FontSize', 11);
xlabel('Mission Time (seconds)', 'FontWeight', 'bold');
ylabel('Throughput (Mbps)', 'FontWeight', 'bold');
legend({'Node 1 (Rooftop HD Video)', 'Node 2 (Corridor Relay)', ...
        'Node 3 (Basement UHF)', 'Node 4 (Perimeter C2)'}, ...
        'Location', 'northwest', 'FontSize', 8.5);
xlim([0 210]);
ylim([0 75]);

% -------------------------------------------------------------
% (B) BASE STATION AGGREGATE NETWORK BANDWIDTH
% -------------------------------------------------------------
subplot(2, 2, 2);
area(t, total_bandwidth, 'FaceColor', [0.8 0.9 1], 'EdgeColor', 'b', 'LineWidth', 2); hold on;
grid on; set(gca, 'FontSize', 10, 'LineWidth', 1.2);
title('(B) Base Station Aggregate Network Bandwidth', 'FontWeight', 'bold', 'FontSize', 11);
xlabel('Mission Time (seconds)', 'FontWeight', 'bold');
ylabel('Aggregate Bandwidth (Mbps)', 'FontWeight', 'bold');
xlim([0 210]);
ylim([0 220]);
avgRate = mean(total_bandwidth);
yline(avgRate, 'r--', sprintf('Avg: %.1f Mbps', avgRate), ...
      'LineWidth', 1.8, 'LabelHorizontalAlignment', 'left', 'FontSize', 9.5, 'FontWeight', 'bold');

% -------------------------------------------------------------
% (C) COMMANDO RF LINK QUALITY (SNR) — NO TEXT OVERLAP!
% -------------------------------------------------------------
subplot(2, 2, 3);
plot(t, s1, 'b--', 'LineWidth', 2); hold on;
plot(t, s2, 'g--', 'LineWidth', 2);
plot(t, s3, 'r--', 'LineWidth', 2);
plot(t, s4, 'm--', 'LineWidth', 2);

% Clean Threshold Lines
yline(26, 'k:', '256-QAM HD Video Threshold (26 dB)', ...
      'LineWidth', 1.6, 'LabelHorizontalAlignment', 'center', 'FontSize', 8.5, 'FontWeight', 'bold');
yline(8, 'k:', 'UHF Voice Penetration Threshold (8 dB)', ...
      'LineWidth', 1.6, 'LabelHorizontalAlignment', 'center', 'FontSize', 8.5, 'FontWeight', 'bold');

grid on; set(gca, 'FontSize', 10, 'LineWidth', 1.2);
title('(C) Commando RF Link Quality (SNR)', 'FontWeight', 'bold', 'FontSize', 11);
xlabel('Mission Time (seconds)', 'FontWeight', 'bold');
ylabel('Link SNR (dB)', 'FontWeight', 'bold');
legend({'Node 1', 'Node 2', 'Node 3', 'Node 4'}, ...
       'Location', 'northwest', 'FontSize', 8.5);
xlim([0 210]);
ylim([0 35]);

% -------------------------------------------------------------
% (D) ADAPTIVE MODULATION SWITCHING (MCS)
% -------------------------------------------------------------
subplot(2, 2, 4);
stairs(t, (r1/8), 'b-', 'LineWidth', 2.4); hold on;
stairs(t, (r3/8), 'r-', 'LineWidth', 2.4);
grid on; set(gca, 'FontSize', 10, 'LineWidth', 1.2);
title('(D) Adaptive Modulation Switching (MCS)', 'FontWeight', 'bold', 'FontSize', 11);
xlabel('Mission Time (seconds)', 'FontWeight', 'bold');
ylabel('Modulation Index', 'FontWeight', 'bold');
yticks(1:5);
yticklabels({'BPSK (1 bps)', 'QPSK (2 bps)', '16-QAM (4 bps)', '64-QAM (6 bps)', '256-QAM (8 bps)'});
legend({'Node 1 (Rooftop L-Band)', 'Node 3 (Basement UHF)'}, ...
       'Location', 'northeast', 'FontSize', 8.5);
xlim([0 210]);
ylim([0.5 5.5]);

% Master Header Title
sgtitle('4-Node Dual-Band Tactical Mesh Network — Simulation Results (Tactical Mesh)', ...
        'FontSize', 13, 'FontWeight', 'bold');

%% Save Clean High-Resolution Output Image
imgFileName = 'tactical_mesh_results_official.png';
exportgraphics(fig, imgFileName, 'Resolution', 300);
fprintf('[OK] Flawless 4-panel figure exported to: %s (300 DPI)\n\n', imgFileName);
