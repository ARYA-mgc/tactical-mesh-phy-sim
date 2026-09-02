%% plot_cqb_mission.m
%  Generates CQB mission timeline figures after Simulink run
%  Tactical PHY Mesh — ARYA-mgc

clc;
fprintf('Generating CQB Mission figures...\n\n');

%% Load data
if exist('out','var') && isa(out,'Simulink.SimulationOutput')
    snr   = out.get('cqb_snr');
    ber   = out.get('cqb_ber');
    mcs   = out.get('cqb_mcs');
    tput  = out.get('cqb_tput');
    phase = out.get('cqb_phase');
    time  = out.get('tout');
else
    error('Run the CQB Simulink model first!');
end

%% Mission Phase names and colors
phaseNames  = {'Outdoor','Building Entry','Corridor','Stairwell','Basement'};
phaseColors = [0.2 0.7 0.3; 0.9 0.7 0.1; 0.9 0.5 0.1; 0.8 0.2 0.2; 0.5 0.1 0.1];
mcsNames    = {'BPSK','QPSK','16-QAM','64-QAM','256-QAM'};
mcsColors   = [0.9 0.2 0.2; 0.9 0.6 0.1; 0.2 0.7 0.3; 0.2 0.5 0.9; 0.6 0.2 0.8];

%% Mission labels with time
missionLabels = {
    'Approach', 0, 30;
    'Breach', 30, 45;
    'Corridor', 45, 70;
    'Stairs ↓', 70, 90;
    'Basement', 90, 120;
    'Target', 120, 140;
    'Stairs ↑', 140, 160;
    'Exit', 160, 180;
    'Extract', 180, 210;
};

%% =================== FIGURE 1: FULL MISSION DASHBOARD ===================
figure('Name','CQB Mission Dashboard','Position',[50 50 1200 800],'Color','w');

% --- Subplot 1: SNR Timeline ---
subplot(4,1,1);
area(time, snr, 'FaceColor', [0.85 0.9 1], 'EdgeColor', [0.2 0.4 0.8], 'LineWidth', 2);
ylabel('SNR (dB)','FontWeight','bold');
title('CQB Mission Timeline — NSG Adaptive Modulation System','FontSize',14,'FontWeight','bold');
grid on; ylim([0 35]);
% Add phase labels
for i = 1:size(missionLabels,1)
    t1 = missionLabels{i,2}; t2 = missionLabels{i,3};
    text((t1+t2)/2, 33, missionLabels{i,1}, 'HorizontalAlignment','center', ...
        'FontSize', 8, 'FontWeight', 'bold', 'Color', [0.3 0.3 0.3]);
    if i < size(missionLabels,1)
        xline(t2, ':', 'Color', [0.7 0.7 0.7]);
    end
end

% --- Subplot 2: MCS Selection ---
subplot(4,1,2);
hold on;
for i = 1:length(time)
    idx = max(1, min(5, round(mcs(i))));
    bar(time(i), mcs(i), 1, 'FaceColor', mcsColors(idx,:), 'EdgeColor', 'none');
end
yticks(1:5); yticklabels(mcsNames);
ylabel('Modulation','FontWeight','bold');
title('Adaptive MCS Switching','FontSize',12,'FontWeight','bold');
grid on; ylim([0.5 5.5]);

% --- Subplot 3: Throughput ---
subplot(4,1,3);
area(time, tput, 'FaceColor', [0.2 0.7 0.4], 'FaceAlpha', 0.6, ...
    'EdgeColor', [0.1 0.5 0.2], 'LineWidth', 2);
hold on;
plot(time, ones(size(time))*4, 'r--', 'LineWidth', 1.5);
ylabel('Throughput (Mbps)','FontWeight','bold');
title('Effective Throughput','FontSize',12,'FontWeight','bold');
legend({'Adaptive','Fixed BPSK (4 Mbps)'},'Location','northeast','FontSize',8);
grid on; ylim([0 40]);

% --- Subplot 4: BER ---
subplot(4,1,4);
semilogy(time, max(ber, 1e-7), 'r-', 'LineWidth', 2);
ylabel('BER','FontWeight','bold');
xlabel('Mission Time (seconds)','FontSize',12,'FontWeight','bold');
title('Bit Error Rate','FontSize',12,'FontWeight','bold');
grid on; ylim([1e-7 1]);

sgtitle('Tactical PHY Mesh — ARYA-mgc — NSG CQB Operation','FontSize',16,'FontWeight','bold','Color','blue');

%% =================== FIGURE 2: MISSION MAP VIEW ===================
figure('Name','CQB Mission Map','Position',[100 50 900 500],'Color','w');

missionSNR  = [30 20 15 8 5 10 12 18 30];
missionTput = missionSNR;  % will calculate
missionMCS  = zeros(1,9);
for i = 1:9
    s = missionSNR(i);
    if s >= 26,     missionMCS(i)=5; missionTput(i)=8*8;
    elseif s >= 20, missionMCS(i)=4; missionTput(i)=6*8;
    elseif s >= 14, missionMCS(i)=3; missionTput(i)=4*8;
    elseif s >= 8,  missionMCS(i)=2; missionTput(i)=2*8;
    else,           missionMCS(i)=1; missionTput(i)=1*8;
    end
end

phases = {'Approach','Breach','Corridor','Stairs↓','Basement','Target','Stairs↑','Exit','Extract'};
xpos = 1:9;

% Bar chart of throughput per phase
b = bar(xpos, missionTput, 'FaceColor', 'flat');
for i = 1:9
    idx = missionMCS(i);
    b.CData(i,:) = mcsColors(idx,:);
end
hold on;

% Add SNR line
yyaxis right;
plot(xpos, missionSNR, 'k-o', 'LineWidth', 2.5, 'MarkerSize', 8, 'MarkerFaceColor', 'k');
ylabel('SNR (dB)','FontSize',12,'FontWeight','bold');

yyaxis left;
ylabel('Throughput (Mbps)','FontSize',12,'FontWeight','bold');
xticks(xpos); xticklabels(phases);
xlabel('Mission Phase','FontSize',12,'FontWeight','bold');
title({'CQB Mission — Throughput per Phase','Adaptive Modulation (ARYA-mgc)'},'FontSize',14,'FontWeight','bold');
grid on;

% Add modulation labels on bars
for i = 1:9
    text(i, missionTput(i)+1, mcsNames{missionMCS(i)}, ...
        'HorizontalAlignment','center','FontSize',9,'FontWeight','bold');
end

legend({'Throughput','SNR'},'Location','north','FontSize',10);

%% =================== FIGURE 3: CONNECTIVITY UPTIME ===================
figure('Name','Connectivity Analysis','Position',[150 50 700 450],'Color','w');

connected = sum(ber < 0.1) / length(ber) * 100;
videoCapable = sum(tput >= 16) / length(tput) * 100;
voiceCapable = sum(tput >= 4) / length(tput) * 100;

categories = {'Voice Comms (>4 Mbps)', 'Video Stream (>16 Mbps)', 'Full HD (>24 Mbps)'};
uptime_pct = [voiceCapable, videoCapable, sum(tput>=24)/length(tput)*100];

b2 = barh(1:3, uptime_pct, 'FaceColor', 'flat');
b2.CData = [0.2 0.7 0.3; 0.2 0.5 0.9; 0.6 0.2 0.8];
yticks(1:3); yticklabels(categories);
xlabel('Mission Uptime (%)','FontSize',12,'FontWeight','bold');
title({'Service Availability During CQB Mission','Adaptive Modulation — ARYA-mgc'},'FontSize',14,'FontWeight','bold');
xlim([0 110]);
grid on;

for i = 1:3
    text(uptime_pct(i)+2, i, sprintf('%.1f%%', uptime_pct(i)), ...
        'FontSize',12,'FontWeight','bold','VerticalAlignment','middle');
end

fprintf('\nDone! 3 figures generated.\n');
fprintf('  Fig 1: Full Mission Dashboard (4 subplots)\n');
fprintf('  Fig 2: Mission Phase Map\n');
fprintf('  Fig 3: Connectivity Uptime Analysis\n');
