%% plot_mesh_network.m
%  Generates Professional Figures for 4-Node Mesh Network + Base Station
%  Tactical PHY Mesh — ARYA-mgc

clc; close all;
fprintf('=================================================================\n');
fprintf('  4-NODE MESH NETWORK + BASE STATION SIMULATION\n');
fprintf('  Tactical PHY Mesh — ARYA-mgc — Tactical NSG Commando Network\n');
fprintf('=================================================================\n\n');

%% Node Setup & Mission Profiles (Time-Varying)
time = 0:210;
nNodes = 4;
nodeNames = {'[NODE 1] Person 1 (Rooftop / Open Area)', ...
             '[NODE 2] Person 2 (Corridor / Indoor)', ...
             ' [NODE 3] Person 3 (Basement / Thick Wall)', ...
             '[NODE 4] Person 4 (Base Area / Perimeter)'};
nodeColors = [0.15 0.45 0.85;   % Blue
              0.15 0.75 0.35;   % Green
              0.85 0.25 0.15;   % Red
              0.70 0.20 0.75];  % Magenta

mcsNames = {'BPSK','QPSK','16-QAM','64-QAM','256-QAM'};
BW = 8; % MHz channel bandwidth

% Time-varying SNR calculation for all 4 nodes
snr_matrix = zeros(nNodes, length(time));
tput_matrix = zeros(nNodes, length(time));
mcs_matrix = zeros(nNodes, length(time));

for t = 1:length(time)
    T = time(t);
    % Node 1: Rooftop -> moves inside briefly -> back outside
    if T <= 50, s1 = 30; elseif T <= 100, s1 = 18; elseif T <= 160, s1 = 25; else, s1 = 30; end
    % Node 2: Entry -> corridor -> stairs -> basement -> exit
    if T <= 30, s2 = 22; elseif T <= 70, s2 = 15; elseif T <= 110, s2 = 8; elseif T <= 160, s2 = 12; else, s2 = 20; end
    % Node 3: Entry -> direct basement infiltration -> target -> extract
    if T <= 20, s3 = 20; elseif T <= 60, s3 = 10; elseif T <= 120, s3 = 5; elseif T <= 170, s3 = 8; else, s3 = 18; end
    % Node 4: Static perimeter security
    if T <= 50, s4 = 25; elseif T <= 150, s4 = 20; else, s4 = 25; end
    
    snrs = [s1, s2, s3, s4] + randn(1, 4)*0.8;
    snrs = max(2, snrs);
    snr_matrix(:, t) = snrs;
    
    for n = 1:nNodes
        s = snrs(n);
        if s >= 26, mi=5; bps=8;
        elseif s >= 20, mi=4; bps=6;
        elseif s >= 14, mi=3; bps=4;
        elseif s >= 8,  mi=2; bps=2;
        else,           mi=1; bps=1;
        end
        mcs_matrix(n, t) = mi;
        tput_matrix(n, t) = bps * BW;
    end
end

%% =================== FIGURE 1: NETWORK TOPOLOGY MAP ===================
figure('Name','Mesh Network Architecture','Position',[40 80 1000 650],'Color','w');
ax = axes('Position',[0.02 0.02 0.96 0.96]);
hold(ax, 'on');

% Draw Ground Base Station Center Hub
rectangle('Position',[340 250 240 100], 'Curvature',0.15, 'FaceColor',[0.95 0.90 0.70], ...
    'EdgeColor',[0.6 0.4 0.1], 'LineWidth',2.5);
text(460, 310, 'BASE STATION / GROUND HUB', 'HorizontalAlignment','center', ...
    'FontSize',11, 'FontWeight','bold', 'Color',[0.4 0.2 0.0]);
text(460, 280, 'Central Telemetry & Video Receiver', 'HorizontalAlignment','center', ...
    'FontSize',9, 'FontAngle','italic', 'Color',[0.3 0.3 0.3]);

% 4 Node Positions: [x, y]
nodeBox = [60 450; 600 450; 60 70; 600 70];
hubTargets = [350 330; 570 330; 350 270; 570 270];

repSNR = [round(mean(snr_matrix(1,:))), round(mean(snr_matrix(2,:))), ...
          round(mean(snr_matrix(3,:))), round(mean(snr_matrix(4,:)))];
repTput = [round(mean(tput_matrix(1,:))), round(mean(tput_matrix(2,:))), ...
           round(mean(tput_matrix(3,:))), round(mean(tput_matrix(4,:)))];

for n = 1:nNodes
    bx = nodeBox(n,1); by = nodeBox(n,2);
    rectangle('Position',[bx by 240 95], 'Curvature',0.2, ...
        'FaceColor', nodeColors(n,:)*0.25 + 0.75, 'EdgeColor', nodeColors(n,:), 'LineWidth',2);
    text(bx+120, by+70, nodeNames{n}, ...
        'HorizontalAlignment','center', 'FontSize',9.5, 'FontWeight','bold', 'Color', nodeColors(n,:));
    text(bx+120, by+44, sprintf('Avg SNR: %d dB | %s', repSNR(n), mcsNames{round(repTput(n)/(8*BW)*4)+1}), ...
        'HorizontalAlignment','center', 'FontSize',8.5);
    text(bx+120, by+20, sprintf('Throughput: ~%d Mbps (Dual-Band)', repTput(n)), ...
        'HorizontalAlignment','center', 'FontSize',9, 'FontWeight','bold');
    
    % Draw clean arrow lines from node box edge to Base Station hub
    if n == 1
        x1 = bx + 240; y1 = by + 20; x2 = hubTargets(1,1); y2 = hubTargets(1,2);
    elseif n == 2
        x1 = bx; y1 = by + 20; x2 = hubTargets(2,1); y2 = hubTargets(2,2);
    elseif n == 3
        x1 = bx + 240; y1 = by + 75; x2 = hubTargets(3,1); y2 = hubTargets(3,2);
    else
        x1 = bx; y1 = by + 75; x2 = hubTargets(4,1); y2 = hubTargets(4,2);
    end
    
    % Link arrow
    quiver(x1, y1, (x2-x1)*0.92, (y2-y1)*0.92, 0, 'Color', nodeColors(n,:), ...
        'LineWidth', 2.5, 'MaxHeadSize', 0.6);
end

% Inter-node mesh links (Peer-to-Peer Relay)
plot([300 600], [497 497], 'Color', [0.5 0.5 0.5], 'LineWidth', 1.8, 'LineStyle', '--');
plot([300 600], [117 117], 'Color', [0.5 0.5 0.5], 'LineWidth', 1.8, 'LineStyle', '--');
plot([180 180], [165 450], 'Color', [0.5 0.5 0.5], 'LineWidth', 1.8, 'LineStyle', '--');
plot([720 720], [165 450], 'Color', [0.5 0.5 0.5], 'LineWidth', 1.8, 'LineStyle', '--');

text(460, 520, 'Inter-Node Peer-to-Peer Relay Mesh (UHF Dual-Band Link)', 'HorizontalAlignment','center', ...
    'FontSize',9.5, 'FontWeight','bold', 'Color',[0.3 0.3 0.3]);

title({'4-Node Mesh Network Architecture with Base Station Aggregator', ...
       'Tactical PHY Mesh — ARYA-mgc (Intelligent Link Management)'}, ...
       'FontSize',15, 'FontWeight','bold', 'Color','blue');
axis off; axis([0 920 0 600]);

%% =================== FIGURE 2: TIME-VARYING MISSION THROUGHPUT ===================
figure('Name','Mesh Timeline Throughput','Position',[80 60 1050 650],'Color','w');

subplot(2,1,1);
hold on;
for n = 1:nNodes
    plot(time, snr_matrix(n,:), 'LineWidth', 2, 'Color', nodeColors(n,:), ...
        'DisplayName', sprintf('Node %d SNR', n));
end
grid on;
ylabel('Link SNR (dB)', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Mission Time (seconds)', 'FontSize', 11);
title('Per-Node Signal Quality (SNR) across CQB Mission Phases', 'FontSize', 13, 'FontWeight', 'bold');
legend('Location', 'northeast', 'FontSize', 9);
ylim([0 38]); xlim([0 210]);

subplot(2,1,2);
totalTputTimeline = sum(tput_matrix, 1);
area(time, totalTputTimeline, 'FaceColor', [0.85 0.92 1.0], 'EdgeColor', [0.2 0.4 0.8], 'LineWidth', 1.5, ...
    'DisplayName', 'Total Base Station Aggregate');
hold on;
for n = 1:nNodes
    plot(time, tput_matrix(n,:), 'LineWidth', 2, 'Color', nodeColors(n,:), ...
        'DisplayName', sprintf('Node %d Rate', n));
end
grid on;
ylabel('Throughput (Mbps)', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Mission Time (seconds)', 'FontSize', 11);
title('Adaptive Throughput Received at Base Station (Individual & Total Aggregate)', 'FontSize', 13, 'FontWeight', 'bold');
legend('Location', 'northeast', 'FontSize', 9);
ylim([0 max(totalTputTimeline)*1.2]); xlim([0 210]);

sgtitle({'4-Node Dynamic Mesh Link Performance (Base Station View)', 'Tactical PHY Mesh — ARYA-mgc'}, ...
    'FontSize', 15, 'FontWeight', 'bold');

%% =================== FIGURE 3: BROADCASTED TACTICAL MESSAGES ===================
figure('Name','Tactical Message Broadcast Verification','Position',[120 40 1050 600],'Color','w');

messages = {
    'Person 1 (Rooftop): Video link established; Clear signal to base station.', ...
    'Person 2 (Corridor): In indoor corridor; Relaying packets between nodes.', ...
    'Person 3 (Basement): Switched to UHF mode; Voice and data 100% active in basement.', ...
    'Person 4 (Base Area): Monitoring all node feeds; All links connected successfully.'
};

trellis = poly2trellis(7, [133 171]);

for n = 1:nNodes
    subplot(4, 1, n);
    msg = messages{n};
    msgBits = reshape(de2bi(uint8(msg), 8, 'left-msb')', 1, []);
    coded = convenc(msgBits, trellis);
    
    % Node test SNR at basement or current spot
    test_snr = repSNR(n);
    if test_snr >= 26, bps=8; M=256;
    elseif test_snr >= 20, bps=6; M=64;
    elseif test_snr >= 14, bps=4; M=16;
    elseif test_snr >= 8,  bps=2; M=4;
    else,                  bps=1; M=2;
    end
    
    nS = floor(length(coded)/bps);
    bM = reshape(coded(1:nS*bps), bps, [])';
    syms = bi2de(bM, 'left-msb');
    if M==2, modSig = 2*double(syms') - 1;
    else, modSig = qammod(double(syms'), M, 'gray', 'UnitAveragePower', true); end
    
    rxSig = awgn(modSig, test_snr, 'measured');
    
    if M==2, rxS = double(real(rxSig)>0);
    else, rxS = qamdemod(rxSig, M, 'gray', 'UnitAveragePower', true); end
    rxBM = de2bi(rxS(:), bps, 'left-msb');
    rxB = reshape(rxBM', 1, []);
    if length(rxB)<length(coded), rxB = [rxB zeros(1,length(coded)-length(rxB))]; end
    dec = vitdec(rxB(1:length(coded)), trellis, 30, 'trunc', 'hard');
    
    recBits = dec(1:length(msgBits));
    nC = floor(length(recBits)/8);
    cB = reshape(recBits(1:nC*8), 8, [])';
    cV = bi2de(cB, 'left-msb');
    cV(cV<32 | cV>126) = 63;
    rxMsg = char(cV');
    
    [~, msgBER] = biterr(dec(1:length(msgBits)), msgBits);
    
    % Plot verification bar
    charMatch = double(msg(1:min(length(msg),length(rxMsg)))) == double(rxMsg(1:min(length(msg),length(rxMsg))));
    bar(charMatch, 'FaceColor', nodeColors(n,:), 'EdgeColor', 'none');
    ylim([0 1.6]);
    text(length(msg)/2, 1.35, sprintf('TX: "%s"', msg), ...
        'HorizontalAlignment','center', 'FontSize', 8.5, 'FontWeight','bold', 'Color', [0.1 0.2 0.5]);
    text(length(msg)/2, 1.10, sprintf('Decoded at Base Station: "%s" [BER = %.1e]', rxMsg, msgBER), ...
        'HorizontalAlignment','center', 'FontSize', 8.5, 'FontWeight','bold', 'Color', [0.1 0.6 0.1]);
    ylabel(sprintf('Node %d', n), 'FontWeight','bold', 'Color', nodeColors(n,:));
    set(gca, 'XTick', []);
end

sgtitle({'Tactical Message Broadcasting & Recovery at Base Station', ...
         'UHF/L-Band Full Verification — Tactical PHY Mesh — ARYA-mgc'}, ...
         'FontSize', 14, 'FontWeight', 'bold', 'Color', 'blue');

%% =================== FIGURE 4: CONSTELLATIONS AT BASE STATION ===================
figure('Name','Base Station Constellations','Position',[160 20 1000 600],'Color','w');

for n = 1:nNodes
    subplot(2, 2, n);
    test_snr = repSNR(n);
    if test_snr >= 26, bps=8; M=256;
    elseif test_snr >= 20, bps=6; M=64;
    elseif test_snr >= 14, bps=4; M=16;
    elseif test_snr >= 8,  bps=2; M=4;
    else,                  bps=1; M=2;
    end
    
    nSym = 1800;
    syms = randi([0 M-1], 1, nSym);
    if M==2, modSig = 2*syms - 1;
    else, modSig = qammod(syms, M, 'gray', 'UnitAveragePower', true); end
    rxSig = awgn(modSig, test_snr, 'measured');
    
    plot(real(rxSig), imag(rxSig), '.', 'Color', nodeColors(n,:), 'MarkerSize', 4);
    hold on;
    if M==2, idealPts = [-1 1];
    else, idealPts = qammod(0:M-1, M, 'gray', 'UnitAveragePower', true); end
    plot(real(idealPts), imag(idealPts), 'ko', 'MarkerSize', 7, 'MarkerFaceColor', 'k');
    
    title(sprintf('Node %d (%s) @ %d dB SNR\nModulation: %s | Link Rate: %d Mbps', ...
        n, nodeNames{n}(9:16), test_snr, mcsNames{round(log2(M)/2)+1}, bps*BW), ...
        'FontSize', 10, 'FontWeight', 'bold');
    xlabel('In-Phase (I)'); ylabel('Quadrature (Q)');
    grid on; axis equal;
    lim = max(abs([real(rxSig) imag(rxSig)]))*1.25;
    if lim > 0, xlim([-lim lim]); ylim([-lim lim]); end
end

sgtitle({'Constellation Constellations Received per Node at Ground Base Station', ...
         'Adaptive Modulation Response — ARYA-mgc'}, ...
         'FontSize', 14, 'FontWeight', 'bold');

%% Command Window Summary
fprintf('\n=================================================================\n');
fprintf('  BASE STATION SUMMARY — 4-NODE TACTICAL MESH\n');
fprintf('=================================================================\n');
for n = 1:nNodes
    fprintf('  %-35s | Avg SNR: %2d dB | Avg Rate: %2d Mbps\n', ...
        nodeNames{n}, repSNR(n), repTput(n));
end
fprintf('  ─────────────────────────────────────────────────────────────\n');
fprintf('  PEAK AGGREGATE NETWORK THROUGHPUT: %d Mbps\n', max(totalTputTimeline));
fprintf('  AVERAGE AGGREGATE NETWORK THROUGHPUT: %.1f Mbps\n', mean(totalTputTimeline));
fprintf('=================================================================\n');
fprintf('  4 Presentation-Quality Figures Generated Successfully!\n');
