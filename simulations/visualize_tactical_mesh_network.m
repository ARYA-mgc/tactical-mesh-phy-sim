%% visualize_tactical_mesh_network.m
%  HIGH-IMPACT TACTICAL AD-HOC MESH NETWORK ARCHITECTURE VISUALIZER
%  Matches military / academic cluster mesh standards:
%    - Mobile Commando Nodes with Dual-Band RF Radii
%    - Squad Leader (Group Head / Cluster Head) in Blue Halo
%    - Interconnected Multi-Path Wireless Mesh Links (Full Ad-Hoc Web)
%    - Tactical Sink / Ground Base Station (C2 Command Post)
%    - Obstacle Environment (Reinforced Concrete Building Floors)
%  Tactical PHY Mesh — ARYA-mgc
%
%  Usage: >> visualize_tactical_mesh_network

clc;
fprintf('=================================================================\n');
fprintf('  GENERATING HIGH-IMPACT TACTICAL MESH ARCHITECTURE VISUALIZATION\n');
fprintf('  Tactical PHY Mesh — ARYA-mgc — Dual-Band Helmet Antenna System\n');
fprintf('=================================================================\n\n');

%% Create Large Widescreen Figure
fig = figure('Name', 'Tactical Ad-Hoc Mesh Network Architecture', 'Color', 'w', ...
             'Position', [60 40 1300 820], 'Units', 'pixels');

ax = axes('Position', [0.03 0.04 0.94 0.92]);
hold on; axis equal;
xlim([0 120]); ylim([0 85]);
set(gca, 'Color', [0.98 0.98 1], 'XColor', 'none', 'YColor', 'none');

%% 1. TACTICAL ENVIRONMENT ZONES (BUILDING & PERIMETER)
% Building Concrete Structure (Left-Center)
rectangle('Position', [15 15 65 60], 'FaceColor', [0.93 0.94 0.96], ...
          'EdgeColor', [0.6 0.65 0.7], 'LineWidth', 2.5, 'Curvature', [0.05 0.05]);
% Floor partitions
line([15 80], [35 35], 'Color', [0.8 0.8 0.85], 'LineWidth', 2, 'LineStyle', '--');
line([15 80], [55 55], 'Color', [0.8 0.8 0.85], 'LineWidth', 2, 'LineStyle', '--');

text(17, 71, 'BUILDING: FLOOR 3 (ROOFTOP OVERWATCH)', 'FontWeight', 'bold', 'FontSize', 8.5, 'Color', [0.4 0.45 0.5]);
text(17, 51, 'BUILDING: FLOOR 2 (CORRIDOR BREACH)',    'FontWeight', 'bold', 'FontSize', 8.5, 'Color', [0.4 0.45 0.5]);
text(17, 31, 'BUILDING: BASEMENT / FLOOR 1 (CQB)',     'FontWeight', 'bold', 'FontSize', 8.5, 'Color', [0.4 0.45 0.5]);

%% 2. NODE COORDINATES
% Node 1: Squad Leader / Group Head (Rooftop)
n1 = [48, 65];
% Node 2: Breacher (Floor 2 Corridor)
n2 = [30, 45];
% Node 3: Pointman (Basement Deep Penetration)
n3 = [55, 25];
% Node 4: Perimeter Guard (Outside Building)
n4 = [92, 42];
% Tactical Sink / Base Station (Command Post)
sink = [105, 75];

nodes = [n1; n2; n3; n4];

%% 3. RF COVERAGE BUBBLES (DUAL-BAND PROPAGATION RINGS)
% Large UHF 380-400 MHz penetrating radius (dashed circles)
theta = linspace(0, 2*pi, 150);
for i = 1:4
    r_uhf = 26; % Penetrating UHF range
    patch(nodes(i,1) + r_uhf*cos(theta), nodes(i,2) + r_uhf*sin(theta), ...
          [0.85 0.92 1], 'FaceAlpha', 0.12, 'EdgeColor', [0.4 0.6 0.9], ...
          'LineStyle', ':', 'LineWidth', 1.2);
end

%% 4. INTERCONNECTED WIRELESS MESH WEB (CRISS-CROSSING FULL MESH LINKS)
% Draw active ad-hoc links with signal strength & throughput indication
mesh_links = [
    1, 2; % Node 1 <-> Node 2
    2, 3; % Node 2 <-> Node 3
    3, 4; % Node 3 <-> Node 4
    4, 1; % Node 4 <-> Node 1 (Closed ring)
    1, 3; % Node 1 <-> Node 3 (Direct UHF Penetration cross-link!)
    2, 4; % Node 2 <-> Node 4 (Cross-link overwatch)
];

% Solid Green = High-Rate L-Band (1.6 GHz, 64 Mbps)
% Dashed Orange = UHF Penetrating Link (400 MHz, Voice Priority)
for k = 1:size(mesh_links, 1)
    pA = nodes(mesh_links(k,1), :);
    pB = nodes(mesh_links(k,2), :);
    
    if (mesh_links(k,1)==1 && mesh_links(k,3-1)==3) || (mesh_links(k,1)==2 && mesh_links(k,2)==4)
        % Cross-floor UHF Link
        line([pA(1) pB(1)], [pA(2) pB(2)], 'Color', [0.9 0.5 0.1], ...
             'LineWidth', 2.2, 'LineStyle', '-.');
    else
        % Primary L-Band Video/Data Link
        line([pA(1) pB(1)], [pA(2) pB(2)], 'Color', [0.1 0.7 0.3], ...
             'LineWidth', 2.8, 'LineStyle', '-');
    end
end

%% 5. UPLINK / DOWNLINK TO SINK (BASE STATION)
% Long-range Dual-Band Tactical Beams to Command Sink
line([n1(1) sink(1)], [n1(2) sink(2)], 'Color', [0.1 0.3 0.9], ...
     'LineWidth', 2.5, 'LineStyle', '--');
line([n4(1) sink(1)], [n4(2) sink(2)], 'Color', [0.1 0.3 0.9], ...
     'LineWidth', 2.0, 'LineStyle', '--');

text(75, 73, 'Tactical Uplink / Downlink (Dual-Band)', ...
     'Color', [0.1 0.3 0.9], 'FontWeight', 'bold', 'FontSize', 8.5, ...
     'Rotation', 10, 'BackgroundColor', 'w', 'Margin', 2);

%% 6. DRAW TACTICAL SINK / BASE STATION ICON
% Command Post Computer / Gateway
rectangle('Position', [sink(1)-6, sink(2)-5, 12, 10], 'FaceColor', [0.2 0.25 0.35], ...
          'EdgeColor', [0.1 0.1 0.2], 'LineWidth', 2, 'Curvature', [0.2 0.2]);
text(sink(1), sink(2)+8, {'TACTICAL SINK', '(C2 Base Command Post)'}, ...
     'FontWeight', 'bold', 'FontSize', 9.5, 'HorizontalAlignment', 'center', ...
     'Color', [0.1 0.2 0.4]);

% Antenna tower icon on Sink
plot(sink(1), sink(2)+3, 'w^', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
text(sink(1), sink(2)-0.5, 'BASE C2', 'Color', 'w', 'FontWeight', 'bold', ...
     'FontSize', 7.5, 'HorizontalAlignment', 'center');

%% 7. DRAW COMMANDO NODES WITH TACTICAL ICONS & BADGES
nodeTitles = {
    'NODE 1: SQUAD LEADER (Group Head)'
    'NODE 2: CORRIDOR BREACHER'
    'NODE 3: BASEMENT POINTMAN'
    'NODE 4: PERIMETER OVERWATCH'
};

nodeSpecs = {
    '1080p 60fps HD | L-Band 64 Mbps'
    'Mesh Relay Router | 48 Mbps'
    'UHF Voice Priority | 8-16 Mbps'
    'Perimeter Guard | 48 Mbps'
};

for i = 1:4
    px = nodes(i,1); py = nodes(i,2);
    
    if i == 1
        % Group Head (Leader): Glowing Blue Halo
        patch(px + 6*cos(theta), py + 6*sin(theta), [0.3 0.6 1], ...
              'FaceAlpha', 0.3, 'EdgeColor', [0 0.4 0.9], 'LineWidth', 2);
        plot(px, py, 'o', 'MarkerSize', 16, 'MarkerFaceColor', [0.1 0.4 0.9], ...
             'MarkerEdgeColor', 'k', 'LineWidth', 2);
    else
        % Member Nodes: High-Contrast Tactical Circles
        plot(px, py, 'o', 'MarkerSize', 14, 'MarkerFaceColor', [0.2 0.7 0.4], ...
             'MarkerEdgeColor', 'k', 'LineWidth', 1.8);
    end
    
    % WiFi / Radio Wave arcs above each node (Matching user reference image!)
    arc_ang = linspace(pi/4, 3*pi/4, 20);
    plot(px + 3.2*cos(arc_ang), py + 3.2*sin(arc_ang), 'Color', [0.2 0.2 0.3], 'LineWidth', 1.6);
    plot(px + 4.5*cos(arc_ang), py + 4.5*sin(arc_ang), 'Color', [0.2 0.2 0.3], 'LineWidth', 1.8);
    plot(px + 5.8*cos(arc_ang), py + 5.8*sin(arc_ang), 'Color', [0.2 0.2 0.3], 'LineWidth', 2.0);
    
    % Node Label Badge Box
    text(px, py-4.2, nodeTitles{i}, 'FontWeight', 'bold', 'FontSize', 8, ...
         'HorizontalAlignment', 'center', 'BackgroundColor', 'w', ...
         'EdgeColor', [0.5 0.5 0.6], 'Margin', 2);
    text(px, py-7.0, nodeSpecs{i}, 'FontSize', 7, 'FontWeight', 'bold', ...
         'HorizontalAlignment', 'center', 'Color', [0.2 0.4 0.2]);
end

%% 8. TACTICAL LEGEND & LIVE NETWORK TELEMETRY PANEL
% Bottom Legend Box
legendBox = rectangle('Position', [12 3 96 9], 'FaceColor', 'w', ...
                      'EdgeColor', [0.7 0.7 0.8], 'LineWidth', 1.5, 'Curvature', [0.1 0.1]);

% Legend items
plot(16, 7.5, 'o', 'MarkerSize', 10, 'MarkerFaceColor', [0.1 0.4 0.9], 'MarkerEdgeColor', 'k');
text(19, 7.5, 'Squad Leader (Group Head)', 'FontWeight', 'bold', 'FontSize', 8);

plot(38, 7.5, 'o', 'MarkerSize', 9, 'MarkerFaceColor', [0.2 0.7 0.4], 'MarkerEdgeColor', 'k');
text(41, 7.5, 'Commando Member Node', 'FontWeight', 'bold', 'FontSize', 8);

line([58 64], [7.5 7.5], 'Color', [0.1 0.7 0.3], 'LineWidth', 2.8);
text(66, 7.5, 'Primary L-Band Mesh Link (1.6 GHz)', 'FontWeight', 'bold', 'FontSize', 8);

line([84 90], [7.5 7.5], 'Color', [0.9 0.5 0.1], 'LineWidth', 2.2, 'LineStyle', '-.');
text(92, 7.5, 'UHF Penetration Link (400 MHz)', 'FontWeight', 'bold', 'FontSize', 8);

%% Save High-Resolution Image
imgOut = 'tactical_mesh_network_architecture.png';
exportgraphics(fig, imgOut, 'Resolution', 300);
fprintf('[OK] High-impact mesh network figure saved: %s (300 DPI)\n\n', imgOut);
