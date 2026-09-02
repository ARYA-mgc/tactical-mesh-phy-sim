%% cqb_mission_sim.m
%  CQB Mission Timeline — Direct MATLAB simulation + figures
%  Tactical PHY Mesh — ARYA-mgc
%
%  Usage: >> cqb_mission_sim

clc; close all;
fprintf('=================================================================\n');
fprintf('  CQB MISSION TIMELINE SIMULATION\n');
fprintf('  Tactical PHY Mesh — ARYA-mgc — NSG Helmet Antenna\n');
fprintf('=================================================================\n\n');

%% =================== MISSION PROFILE ===================
% Realistic 210-second NSG CQB operation
time = 0:210;

% SNR profile matching commando movement
snr = zeros(size(time));
for t = 1:length(time)
    T = time(t);
    if T <= 30       % Approach (outdoor, open)
        snr(t) = 30;
    elseif T <= 45   % Breach entry
        snr(t) = 20;
    elseif T <= 70   % Ground floor corridor
        snr(t) = 15;
    elseif T <= 90   % Stairwell descent
        snr(t) = 8;
    elseif T <= 120  % Basement room clear
        snr(t) = 5;
    elseif T <= 140  % Target room engagement
        snr(t) = 10;
    elseif T <= 160  % Extract via stairs
        snr(t) = 12;
    elseif T <= 180  % Ground floor exit
        snr(t) = 18;
    else             % Outside extraction
        snr(t) = 30;
    end
    % Add slight random variation for realism
    snr(t) = snr(t) + randn * 1.5;
    snr(t) = max(1, snr(t));
end

%% =================== ADAPTIVE MODULATION ===================
mcsNames = {'BPSK', 'QPSK', '16-QAM', '64-QAM', '256-QAM'};
mcsColors = [0.9 0.2 0.2; 0.9 0.6 0.1; 0.2 0.7 0.3; 0.2 0.5 0.9; 0.6 0.2 0.8];
mcsBPS = [1 2 4 6 8];
mcsThresholds = [0 8 14 20 26];  % SNR thresholds

bitsPerSym = zeros(size(time));
mcsIdx = zeros(size(time));
modOrder = zeros(size(time));
throughput = zeros(size(time));
BW = 8;  % MHz

for t = 1:length(time)
    s = snr(t);
    if s >= 26
        mcsIdx(t) = 5; bitsPerSym(t) = 8; modOrder(t) = 256;
    elseif s >= 20
        mcsIdx(t) = 4; bitsPerSym(t) = 6; modOrder(t) = 64;
    elseif s >= 14
        mcsIdx(t) = 3; bitsPerSym(t) = 4; modOrder(t) = 16;
    elseif s >= 8
        mcsIdx(t) = 2; bitsPerSym(t) = 2; modOrder(t) = 4;
    else
        mcsIdx(t) = 1; bitsPerSym(t) = 1; modOrder(t) = 2;
    end
    throughput(t) = bitsPerSym(t) * BW;
end

%% =================== MISSION PHASE LABELS ===================
phases = {'Approach','Breach','Corridor','Stairs ↓','Basement','Target','Stairs ↑','Exit','Extract'};
phaseTimes = [0 30; 30 45; 45 70; 70 90; 90 120; 120 140; 140 160; 160 180; 180 210];
phaseColors = [0.85 0.95 0.85; 0.95 0.95 0.75; 0.95 0.9 0.75; 1 0.85 0.85; 1 0.8 0.8; ...
               0.9 0.85 0.95; 0.85 0.9 1; 0.85 0.95 0.9; 0.85 0.95 0.85];

%% =================== FIGURE 1: MCS STAIRCASE (like your screenshot) ===================
figure('Name','MCS Selection — CQB Mission','Position',[50 100 1000 500],'Color','w');

% Background phase shading
hold on;
for p = 1:size(phaseTimes,1)
    t1 = phaseTimes(p,1); t2 = phaseTimes(p,2);
    fill([t1 t2 t2 t1], [0 0 9 9], phaseColors(p,:), 'EdgeColor','none', 'FaceAlpha', 0.4);
    text((t1+t2)/2, 8.7, phases{p}, 'HorizontalAlignment','center', ...
        'FontSize', 8, 'FontWeight','bold', 'Color', [0.3 0.3 0.3]);
end

% Staircase plot
stairs(time, bitsPerSym, 'k-', 'LineWidth', 2.5);

% Color dots for each modulation
for t = 1:length(time)
    idx = mcsIdx(t);
    plot(time(t), bitsPerSym(t), '.', 'Color', mcsColors(idx,:), 'MarkerSize', 12);
end

yticks(mcsBPS);
yticklabels({'1 (BPSK)', '2 (QPSK)', '4 (16-QAM)', '6 (64-QAM)', '8 (256-QAM)'});
xlabel('Mission Time (s)', 'FontSize', 13, 'FontWeight', 'bold');
ylabel('Bits per Symbol', 'FontSize', 13, 'FontWeight', 'bold');
title({'Adaptive MCS Selection — CQB Mission Timeline', ...
       'MCU Decision Engine (Tactical PHY Mesh — ARYA-mgc)'}, ...
       'FontSize', 15, 'FontWeight', 'bold');
grid on; ylim([0 9]); xlim([0 210]);

%% =================== FIGURE 2: SNR + MODULATION (dual axis) ===================
figure('Name','SNR vs Modulation — CQB','Position',[100 80 1000 500],'Color','w');

hold on;
for p = 1:size(phaseTimes,1)
    t1 = phaseTimes(p,1); t2 = phaseTimes(p,2);
    fill([t1 t2 t2 t1], [0 0 40 40], phaseColors(p,:), 'EdgeColor','none', 'FaceAlpha', 0.3);
    text((t1+t2)/2, 37, phases{p}, 'HorizontalAlignment','center', ...
        'FontSize', 8, 'FontWeight','bold', 'Color', [0.3 0.3 0.3]);
end

yyaxis left;
plot(time, snr, 'b-', 'LineWidth', 2);
ylabel('SNR (dB)', 'FontSize', 13, 'FontWeight', 'bold');
ylim([0 40]);

yyaxis right;
stairs(time, modOrder, 'r-', 'LineWidth', 2.5);
ylabel('Modulation Order (M)', 'FontSize', 13, 'FontWeight', 'bold');
set(gca, 'YScale', 'log');
yticks([2 4 16 64 256]);
yticklabels({'BPSK','QPSK','16-QAM','64-QAM','256-QAM'});

xlabel('Mission Time (s)', 'FontSize', 13, 'FontWeight', 'bold');
title({'CQB Mission — SNR vs Adaptive Modulation Switching', ...
       'NSG Helmet Antenna System (ARYA-mgc)'}, ...
       'FontSize', 15, 'FontWeight', 'bold');
legend({'SNR (dB)', 'Modulation Order'}, 'FontSize', 11, 'Location', 'south');
grid on; xlim([0 210]);

%% =================== FIGURE 3: THROUGHPUT TIMELINE ===================
figure('Name','Throughput — CQB Mission','Position',[150 60 1000 450],'Color','w');

hold on;
for p = 1:size(phaseTimes,1)
    t1 = phaseTimes(p,1); t2 = phaseTimes(p,2);
    fill([t1 t2 t2 t1], [0 0 70 70], phaseColors(p,:), 'EdgeColor','none', 'FaceAlpha', 0.3);
end

area(time, throughput, 'FaceColor', [0.2 0.6 0.9], 'FaceAlpha', 0.7, ...
    'EdgeColor', [0.1 0.3 0.7], 'LineWidth', 2);
plot(time, ones(size(time))*8, 'r--', 'LineWidth', 2);

% Label throughput at each phase
for p = 1:size(phaseTimes,1)
    t1 = phaseTimes(p,1); t2 = phaseTimes(p,2);
    midT = (t1+t2)/2;
    phaseMask = time >= t1 & time < t2;
    avgTput = mean(throughput(phaseMask));
    text(midT, avgTput + 3, sprintf('%.0f\nMbps', avgTput), ...
        'HorizontalAlignment','center', 'FontSize', 9, 'FontWeight', 'bold');
end

xlabel('Mission Time (s)', 'FontSize', 13, 'FontWeight', 'bold');
ylabel('Throughput (Mbps)', 'FontSize', 13, 'FontWeight', 'bold');
title({'CQB Mission — Adaptive Throughput Timeline', ...
       'Tactical PHY Mesh — ARYA-mgc'}, 'FontSize', 15, 'FontWeight', 'bold');
legend({'Adaptive Throughput', 'Fixed BPSK (8 Mbps)'}, 'FontSize', 11, 'Location', 'north');
grid on; ylim([0 70]); xlim([0 210]);

%% =================== FIGURE 4: MISSION SUMMARY BAR ===================
figure('Name','Mission Summary','Position',[200 40 800 450],'Color','w');

phaseSNR = [30 20 15 8 5 10 12 18 30];
phaseTput = zeros(1,9);
phaseMod = cell(1,9);
for p = 1:9
    s = phaseSNR(p);
    if s>=26, phaseTput(p)=64; phaseMod{p}='256-QAM';
    elseif s>=20, phaseTput(p)=48; phaseMod{p}='64-QAM';
    elseif s>=14, phaseTput(p)=32; phaseMod{p}='16-QAM';
    elseif s>=8, phaseTput(p)=16; phaseMod{p}='QPSK';
    else, phaseTput(p)=8; phaseMod{p}='BPSK';
    end
end

b = bar(1:9, phaseTput, 'FaceColor', 'flat');
for i = 1:9
    if phaseSNR(i)>=26, ci=5; elseif phaseSNR(i)>=20, ci=4;
    elseif phaseSNR(i)>=14, ci=3; elseif phaseSNR(i)>=8, ci=2;
    else, ci=1; end
    b.CData(i,:) = mcsColors(ci,:);
end

for i = 1:9
    text(i, phaseTput(i)+2, sprintf('%s\n(%ddB)', phaseMod{i}, phaseSNR(i)), ...
        'HorizontalAlignment','center', 'FontSize', 8, 'FontWeight', 'bold');
end

xticks(1:9); xticklabels(phases);
ylabel('Throughput (Mbps)', 'FontSize', 13, 'FontWeight', 'bold');
xlabel('Mission Phase', 'FontSize', 13, 'FontWeight', 'bold');
title({'CQB Mission — Performance per Phase', ...
       'NSG Adaptive Modulation (ARYA-mgc)'}, 'FontSize', 14, 'FontWeight', 'bold');
grid on; ylim([0 80]);

%% =================== SUMMARY ===================
fprintf('\n[OK] 4 figures generated!\n');
fprintf('  Fig 1: MCS Staircase (like adaptive_modulation_sim)\n');
fprintf('  Fig 2: SNR vs Modulation (dual axis)\n');
fprintf('  Fig 3: Throughput Timeline\n');
fprintf('  Fig 4: Mission Phase Summary\n');
fprintf('\nAvg throughput: %.1f Mbps\n', mean(throughput));
fprintf('Max throughput: %.0f Mbps (during approach/extract)\n', max(throughput));
fprintf('Min throughput: %.0f Mbps (during basement)\n', min(throughput));
fprintf('=================================================================\n');
