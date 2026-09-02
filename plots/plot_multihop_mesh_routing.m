%% plot_multihop_mesh_routing.m
%  CRYSTAL CLEAR MULTI-HOP MESH ROUTING VISUALIZATION
%  Route: Node 1 -> Node 2 -> Node 3 -> Node 4
%  Zero text overlaps — Clean ASCII arrows (->)
%  Tactical PHY Mesh — ARYA-mgc
%
%  Usage: >> plot_multihop_mesh_routing

clc;
fprintf('=================================================================\n');
fprintf('  GENERATING FLAWLESS MULTI-HOP MESH ROUTING FIGURE\n');
fprintf('  Clean ASCII -> arrows, zero text collisions, maximum readability\n');
fprintf('  Tactical PHY Mesh — ARYA-mgc\n');
fprintf('=================================================================\n\n');

%% 1. Node Coordinates in CQB Tactical Environment (meters)
% X = Distance (m), Y = Elevation (m)
n1 = [18,  36];  % Node 1: Rooftop
n2 = [48,  24];  % Node 2: Floor 2 Corridor
n3 = [78,  12];  % Node 3: Basement / Ground
n4 = [108,  3];  % Node 4: Far Perimeter

%% Create Large, High-Resolution Figure
fig = figure('Name', 'Multi-Hop Mesh Relay Architecture', 'Color', 'w', ...
             'Position', [50 30 1350 850], 'Units', 'pixels');

% =========================================================================
% (A) TACTICAL BUILDING MAP & MULTI-HOP ROUTE
% =========================================================================
subplot(2, 2, 1);

% 1. Building Background (Floors 1 to 3)
rectangle('Position', [5, 0, 85, 42], 'FaceColor', [0.96 0.96 0.98], ...
          'EdgeColor', [0.3 0.3 0.3], 'LineWidth', 2); hold on;

% Concrete Slabs
line([5 90], [14 14], 'Color', [0.75 0.75 0.75], 'LineWidth', 2.5);
line([5 90], [28 28], 'Color', [0.75 0.75 0.75], 'LineWidth', 2.5);

% Floor Labels (Placed on far left, completely clear of nodes)
text(7, 39, 'Floor 3 (Rooftop)', 'FontSize', 8.5, 'Color', [0.4 0.4 0.4], 'FontWeight', 'bold');
text(7, 25, 'Floor 2 (Corridor)', 'FontSize', 8.5, 'Color', [0.4 0.4 0.4], 'FontWeight', 'bold');
text(7, 11, 'Basement / Floor 1', 'FontSize', 8.5, 'Color', [0.4 0.4 0.4], 'FontWeight', 'bold');

% 2. Direct Link Attempt (Red Dashed Line)
plot([n1(1) n4(1)], [n1(2) n4(2)], 'r--', 'LineWidth', 2);
text(68, 28, 'Direct Link: Blocked (122 dB Loss)', ...
     'Color', 'r', 'FontWeight', 'bold', 'FontSize', 9, ...
     'BackgroundColor', 'w', 'EdgeColor', 'r', 'Margin', 3);

% 3. Multi-Hop Forwarding Arrows (Thick Green Directed Lines)
quiver(n1(1), n1(2), n2(1)-n1(1), n2(2)-n1(2), 0, ...
       'Color', [0 0.6 0], 'LineWidth', 2.8, 'MaxHeadSize', 0.4);
quiver(n2(1), n2(2), n3(1)-n2(1), n3(2)-n2(2), 0, ...
       'Color', [0 0.6 0], 'LineWidth', 2.8, 'MaxHeadSize', 0.4);
quiver(n3(1), n3(2), n4(1)-n3(1), n4(2)-n3(2), 0, ...
       'Color', [0 0.6 0], 'LineWidth', 2.8, 'MaxHeadSize', 0.4);

% Hop Labels (Cleanly placed in open space along the arrows)
text(31, 33, 'Hop 1', 'Color', [0 0.5 0], 'FontWeight', 'bold', 'FontSize', 9.5, ...
     'BackgroundColor', 'w', 'EdgeColor', [0 0.6 0], 'Margin', 2);
text(61, 21, 'Hop 2', 'Color', [0 0.5 0], 'FontWeight', 'bold', 'FontSize', 9.5, ...
     'BackgroundColor', 'w', 'EdgeColor', [0 0.6 0], 'Margin', 2);
text(91, 10, 'Hop 3', 'Color', [0 0.5 0], 'FontWeight', 'bold', 'FontSize', 9.5, ...
     'BackgroundColor', 'w', 'EdgeColor', [0 0.6 0], 'Margin', 2);

% 4. Draw Commando Nodes
plot(n1(1), n1(2), 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 12, 'LineWidth', 1.5);
plot(n2(1), n2(2), 'go', 'MarkerFaceColor', [0 0.7 0], 'MarkerSize', 12, 'LineWidth', 1.5);
plot(n3(1), n3(2), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 12, 'LineWidth', 1.5);
plot(n4(1), n4(2), 'mo', 'MarkerFaceColor', 'm', 'MarkerSize', 12, 'LineWidth', 1.5);

% Node Labels (Placed clearly above/below with zero collision)
text(n1(1)+2, n1(2)+3.5, 'Node 1: Leader', 'FontWeight', 'bold', 'FontSize', 9, 'Color', 'k');
text(n2(1)+2, n2(2)+3.5, 'Node 2: Relay',  'FontWeight', 'bold', 'FontSize', 9, 'Color', 'k');
text(n3(1)+2, n3(2)+3.5, 'Node 3: Relay',  'FontWeight', 'bold', 'FontSize', 9, 'Color', 'k');
text(n4(1)+2, n4(2)+3.5, 'Node 4: Target', 'FontWeight', 'bold', 'FontSize', 9, 'Color', 'k');

grid on; xlim([0 128]); ylim([-3 48]);
set(gca, 'FontSize', 9.5, 'LineWidth', 1.2);
title('(A) Tactical Building Map & Multi-Hop Relay Chain', 'FontWeight', 'bold', 'FontSize', 11);
xlabel('Distance (meters)', 'FontWeight', 'bold');
ylabel('Elevation (meters)', 'FontWeight', 'bold');

% =========================================================================
% (B) RECEIVED SIGNAL STRENGTH: DIRECT VS MULTI-HOP
% =========================================================================
subplot(2, 2, 2);

labels_b = {'Direct (1->4)', 'Hop 1 (1->2)', 'Hop 2 (2->3)', 'Hop 3 (3->4)'};
rssi_val = [-118, -68, -72, -70]; % dBm
sens_lim = -92; % dBm

b = bar(rssi_val, 0.48);
b.FaceColor = 'flat';
b.CData(1,:) = [0.85 0.2 0.2]; % Red (Direct = Blackout)
b.CData(2,:) = [0.2 0.7 0.3];  % Green (Hop 1)
b.CData(3,:) = [0.2 0.7 0.3];  % Green (Hop 2)
b.CData(4,:) = [0.2 0.7 0.3];  % Green (Hop 3)

yline(sens_lim, 'k--', 'Sensitivity Limit (-92 dBm)', ...
      'LineWidth', 1.6, 'LabelHorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold');

% Text labels inside / above bars
text(1, -125, 'BLACKOUT', 'Color', 'r', 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'FontSize', 9);
text(2, -60,  '+24 dB Margin', 'Color', [0 0.5 0], 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'FontSize', 9);
text(3, -64,  '+20 dB Margin', 'Color', [0 0.5 0], 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'FontSize', 9);
text(4, -62,  '+22 dB Margin', 'Color', [0 0.5 0], 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'FontSize', 9);

set(gca, 'XTick', 1:4, 'XTickLabel', labels_b, 'FontSize', 9, 'LineWidth', 1.2);
ylabel('Received Power RSSI (dBm)', 'FontWeight', 'bold');
title('(B) Link Signal Power: Direct Blackout vs Mesh Recovery', 'FontWeight', 'bold', 'FontSize', 11);
ylim([-134 -48]); grid on;

% =========================================================================
% (C) MULTI-HOP LATENCY & THROUGHPUT
% =========================================================================
subplot(2, 2, 3);

lat_data = [3.2, 3.4, 3.8, 10.4]; % ms
rate_data = [64, 48, 48, 48];     % Mbps

yyaxis left;
b3 = bar(1:4, lat_data, 0.42, 'FaceColor', [0.4 0.65 0.95], 'EdgeColor', 'b');
ylabel('Latency (milliseconds)', 'FontWeight', 'bold');
ylim([0 16]);
for i = 1:4
    text(i, lat_data(i)+0.8, sprintf('%.1f ms', lat_data(i)), ...
         'HorizontalAlignment', 'center', 'FontSize', 8.5, 'FontWeight', 'bold', 'Color', 'b');
end

yyaxis right;
plot(1:4, rate_data, 'ro-', 'LineWidth', 2.2, 'MarkerFaceColor', 'r', 'MarkerSize', 7);
ylabel('Delivered Rate (Mbps)', 'FontWeight', 'bold');
ylim([0 85]);
for i = 1:4
    text(i, rate_data(i)-5, sprintf('%d Mbps', rate_data(i)), ...
         'HorizontalAlignment', 'center', 'FontSize', 8.5, 'FontWeight', 'bold', 'Color', [0.7 0 0]);
end

x_labels_c = {'Hop 1 (1->2)', 'Hop 2 (2->3)', 'Hop 3 (3->4)', 'End-to-End (1->4)'};
set(gca, 'XTick', 1:4, 'XTickLabel', x_labels_c, 'FontSize', 9, 'LineWidth', 1.2);
title('(C) Hop Latency & Delivered Throughput', 'FontWeight', 'bold', 'FontSize', 11);
grid on;

% =========================================================================
% (D) AUTONOMOUS SELF-HEALING REROUTE
% =========================================================================
subplot(2, 2, 4);

t_sim = 0:1:100;
pdr_plot = 99.8 * ones(size(t_sim));
pdr_plot(40) = 95.5; % 150 ms transient buffer

plot(t_sim, pdr_plot, 'b-', 'LineWidth', 2.5); hold on;

% Event line
xline(40, 'r--', 'LineWidth', 1.8);

% Route explanations placed in completely clear top space
text(5, 98.2, 'Primary Route: 1 -> 2 -> 3 -> 4', ...
     'Color', [0 0.5 0], 'FontWeight', 'bold', 'FontSize', 9, ...
     'BackgroundColor', [0.9 1 0.9], 'EdgeColor', [0 0.6 0], 'Margin', 3);

text(52, 98.2, 'Self-Healed: 1 -> 3 -> 4 (UHF Bypass)', ...
     'Color', 'b', 'FontWeight', 'bold', 'FontSize', 9, ...
     'BackgroundColor', [0.9 0.95 1], 'EdgeColor', 'b', 'Margin', 3);

% Event Callout to the RIGHT of the line
text(43, 93.0, {'Node 2 Disconnected', '< 150 ms Self-Healing'}, ...
     'Color', 'r', 'FontWeight', 'bold', 'FontSize', 8.5, ...
     'BackgroundColor', 'w', 'EdgeColor', 'r', 'Margin', 3);

grid on; set(gca, 'FontSize', 9.5, 'LineWidth', 1.2);
title('(D) Autonomous Self-Healing Mesh Reroute (< 150 ms)', 'FontWeight', 'bold', 'FontSize', 11);
xlabel('Mission Timeline (seconds)', 'FontWeight', 'bold');
ylabel('Packet Delivery Ratio (PDR %)', 'FontWeight', 'bold');
xlim([0 100]); ylim([90 101]);

% =========================================================================
% SUPER TITLE (Clean ASCII -> arrows, no Unicode glitch)
% =========================================================================
sgtitle('Multi-Hop Tactical Mesh Routing: Node 1 -> Node 2 -> Node 3 -> Node 4', ...
        'FontSize', 13, 'FontWeight', 'bold');

%% Save Clean High-Resolution Output
imgOut = 'multihop_mesh_routing_proof.png';
exportgraphics(fig, imgOut, 'Resolution', 300);
fprintf('[OK] Flawless figure exported: %s (300 DPI)\n\n', imgOut);
