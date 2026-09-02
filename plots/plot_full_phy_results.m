%% plot_full_phy_results.m
%  Generates figures after running the Full PHY Simulink model
%  Tactical PHY Mesh — ARYA-mgc
%
%  Usage: Run Simulink model first, then >> plot_full_phy_results

clc;
fprintf('Generating Full PHY simulation figures...\n\n');

%% Load data from Simulink output
if exist('out', 'var') && isa(out, 'Simulink.SimulationOutput')
    ber = out.get('sim_BER');
    mer = out.get('sim_MER');
    mcs = out.get('sim_MCS');
    snr = out.get('sim_SNR2');
    tput = out.get('sim_Tput');
    time = out.get('tout');
    fprintf('[OK] Data loaded from Simulink output\n\n');
else
    error('No data found! Run the Simulink model first.');
end

mcsNames = {'BPSK-1/2','QPSK-1/2','QPSK-3/4','16QAM-1/2','16QAM-3/4','64QAM-2/3','64QAM-3/4','256QAM-3/4'};

%% Figure 1: BER vs SNR
figure('Name','BER vs SNR','Position',[50 100 900 500],'Color','w');
semilogy(snr, max(ber,1e-7), 'b-o', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'b');
grid on;
xlabel('SNR (dB)','FontSize',13,'FontWeight','bold');
ylabel('BER','FontSize',13,'FontWeight','bold');
title({'BER vs SNR — Adaptive Modulation (Full PHY Chain)','Tactical PHY Mesh — ARYA-mgc'},'FontSize',14,'FontWeight','bold');
ylim([1e-7 1]);

%% Figure 2: MER vs SNR
figure('Name','MER vs SNR','Position',[100 80 900 500],'Color','w');
plot(snr, mer, 'r-s', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'r');
hold on;
plot(snr, snr, 'k--', 'LineWidth', 1);
grid on;
xlabel('SNR (dB)','FontSize',13,'FontWeight','bold');
ylabel('MER (dB)','FontSize',13,'FontWeight','bold');
title({'MER vs SNR — Adaptive Modulation','Tactical PHY Mesh — ARYA-mgc'},'FontSize',14,'FontWeight','bold');
legend({'MER (Adaptive)','Ideal (MER=SNR)'},'FontSize',11,'Location','northwest');

%% Figure 3: MCS Selection
figure('Name','MCS Selection','Position',[150 60 900 400],'Color','w');
modColors = lines(8);
stairs(snr, mcs, 'k-', 'LineWidth', 2);
hold on;
for i = 1:length(snr)
    idx = max(1, min(8, round(mcs(i))));
    plot(snr(i), mcs(i), 'o', 'MarkerSize', 10, 'MarkerFaceColor', modColors(idx,:), 'MarkerEdgeColor', 'k');
end
yticks(1:8); yticklabels(mcsNames);
xlabel('SNR (dB)','FontSize',13,'FontWeight','bold');
ylabel('Selected MCS','FontSize',13,'FontWeight','bold');
title({'Adaptive MCS Selection — Intelligent Link Management','MCU Decision Engine (ARYA-mgc)'},'FontSize',14,'FontWeight','bold');
grid on; ylim([0.5 8.5]);

%% Figure 4: Throughput
figure('Name','Throughput','Position',[200 40 900 450],'Color','w');
area(snr, tput, 'FaceColor', [0.2 0.6 0.9], 'FaceAlpha', 0.6, 'EdgeColor', [0.1 0.3 0.7], 'LineWidth', 1.5);
hold on;
plot(snr, ones(size(snr))*4, 'r--', 'LineWidth', 2);
grid on;
xlabel('SNR (dB)','FontSize',13,'FontWeight','bold');
ylabel('Throughput (Mbps)','FontSize',13,'FontWeight','bold');
title({'Effective Throughput — Adaptive vs Fixed','Tactical PHY Mesh — ARYA-mgc'},'FontSize',14,'FontWeight','bold');
legend({'Adaptive','Fixed BPSK (4 Mbps)'},'FontSize',11,'Location','northwest');

%% Figure 5: Constellation Diagrams (generated fresh)
figure('Name','Constellation Diagrams','Position',[250 20 1000 700],'Color','w');
demo_snrs = [5 12 20 30];
demo_mods = [2 4 16 64];
demo_names = {'BPSK','QPSK','16-QAM','64-QAM'};
modClrs = [0.9 0.2 0.2; 0.9 0.6 0.1; 0.2 0.7 0.3; 0.2 0.5 0.9];

for idx = 1:4
    subplot(2,2,idx);
    M = demo_mods(idx);
    nSym = 2000;
    syms = randi([0 M-1], 1, nSym);
    if M == 2
        modSig = 2*syms-1;
    else
        modSig = qammod(syms, M, 'gray', 'UnitAveragePower', true);
    end
    rxSig = awgn(modSig, demo_snrs(idx), 'measured');
    
    plot(real(rxSig), imag(rxSig), '.', 'Color', modClrs(idx,:), 'MarkerSize', 4);
    hold on;
    if M == 2
        idealPts = [-1 1];
    else
        idealPts = qammod(0:M-1, M, 'gray', 'UnitAveragePower', true);
    end
    plot(real(idealPts), imag(idealPts), 'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'k');
    
    title(sprintf('%s @ SNR=%d dB', demo_names{idx}, demo_snrs(idx)), 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('In-Phase (I)'); ylabel('Quadrature (Q)');
    grid on; axis equal;
    lim = max(abs([real(rxSig) imag(rxSig)])) * 1.3;
    xlim([-lim lim]); ylim([-lim lim]);
end
sgtitle({'Constellation Diagrams — Adaptive Modulation','Tactical PHY Mesh — ARYA-mgc'},'FontSize',14,'FontWeight','bold');

%% Figure 6: RF Spectrum
figure('Name','RF Spectrum','Position',[300 20 900 400],'Color','w');
fs = 8e6; nfft_s = 2048;
txDemo = qammod(randi([0 63],1,500), 64, 'gray', 'UnitAveragePower', true);
ofdmSig = ifft(txDemo, nfft_s);
spec = fftshift(fft(ofdmSig, nfft_s));
freqAx = linspace(-fs/2, fs/2, nfft_s)/1e6;
specDB = 20*log10(abs(spec)/max(abs(spec)) + 1e-10);
plot(freqAx, specDB, 'b-', 'LineWidth', 1.2);
grid on;
xlabel('Frequency (MHz)','FontSize',13,'FontWeight','bold');
ylabel('Normalized Magnitude (dB)','FontSize',13,'FontWeight','bold');
title({'OFDM Signal — RF Spectrum','802.11ah | BW=8 MHz | ARYA-mgc'},'FontSize',14,'FontWeight','bold');
ylim([-40 0]);

fprintf('\nDone! 6 figures generated.\n');
