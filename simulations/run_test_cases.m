%% run_test_cases.m
%  Runs multiple test cases and compares results
%  Tactical PHY Mesh — ARYA-mgc
%
%  Usage: >> run_test_cases

clc; clear; close all;

fprintf('=================================================================\n');
fprintf('  ADAPTIVE MODULATION — MULTI TEST CASE COMPARISON\n');
fprintf('  Tactical PHY Mesh — ARYA-mgc\n');
fprintf('=================================================================\n\n');

%% Define Test Cases
testCases = {
%   Name                    BW(MHz)  Channel      Equalizer  SNR_range
    'AWGN - 8MHz',          8,       'AWGN',      false,     0:2:35;
    'Rician - 8MHz',        8,       'Rician',    true,      0:2:35;
    'Rayleigh - 8MHz',      8,       'Rayleigh',  true,      0:2:35;
    'AWGN - 4MHz',          4,       'AWGN',      false,     0:2:35;
    'AWGN - 16MHz',         16,      'AWGN',      false,     0:2:35;
};

nTests = size(testCases, 1);
nBits  = 5000;

% MCS table
mcsTable = struct( ...
    'name',     {'BPSK','QPSK','16QAM','64QAM','256QAM'}, ...
    'modOrder', {2,     4,     16,     64,     256}, ...
    'bps',      {1,     2,      4,      6,       8}, ...
    'snrThr',   {0,     8,     14,     20,      26} ...
);

% Encoder setup
trellis = poly2trellis(7, [133 171]);

% Channel model parameters
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

%% Storage
allBER   = cell(nTests, 1);
allMER   = cell(nTests, 1);
allMCS   = cell(nTests, 1);
allTput  = cell(nTests, 1);
allSNR   = cell(nTests, 1);

%% =================== RUN ALL TEST CASES ===================
for t = 1:nTests
    tcName   = testCases{t, 1};
    BW       = testCases{t, 2};
    chanType = testCases{t, 3};
    useEQ    = testCases{t, 4};
    snrRange = testCases{t, 5};
    nSNR     = length(snrRange);
    
    fprintf('━━━ Test %d/%d: %s ━━━\n', t, nTests, tcName);
    
    % OFDM params
    switch BW
        case 1,  Nfft=32;  Nsd=24;
        case 2,  Nfft=64;  Nsd=52;
        case 4,  Nfft=128; Nsd=108;
        case 8,  Nfft=256; Nsd=234;
        case 16, Nfft=512; Nsd=468;
    end
    cpLen = Nfft/4;
    fs = BW * 1e6;
    
    berArr  = zeros(1, nSNR);
    merArr  = zeros(1, nSNR);
    mcsArr  = zeros(1, nSNR);
    tputArr = zeros(1, nSNR);
    
    for s = 1:nSNR
        SNR = snrRange(s);
        
        % Adaptive MCS selection
        chosen = 1;
        for m = length(mcsTable):-1:1
            if SNR >= mcsTable(m).snrThr
                chosen = m;
                break;
            end
        end
        mcsArr(s) = chosen;
        M   = mcsTable(chosen).modOrder;
        bps = mcsTable(chosen).bps;
        
        % TX
        dataBits = randi([0 1], 1, nBits);
        codedData = convenc(dataBits, trellis);
        
        nSyms = floor(length(codedData) / bps);
        bitsTrunc = codedData(1:nSyms*bps);
        bitMatrix = reshape(bitsTrunc, bps, [])';
        symbols = bi2de(bitMatrix, 'left-msb');
        
        if M == 2
            modSignal = 2*double(symbols') - 1;
        else
            modSignal = qammod(double(symbols'), M, 'gray', 'UnitAveragePower', true);
        end
        
        % OFDM
        nOFDM = ceil(length(modSignal) / Nsd);
        padSig = [modSignal zeros(1, nOFDM*Nsd - length(modSignal))];
        ofdmData = reshape(padSig, Nsd, nOFDM);
        ofdmFrame = zeros(Nfft, nOFDM);
        ofdmFrame(2:Nsd+1, :) = ofdmData;
        txTime = ifft(ofdmFrame, Nfft);
        txWithCP = [txTime(end-cpLen+1:end,:); txTime];
        txSignal = txWithCP(:)';
        
        % Channel
        switch chanType
            case 'AWGN'
                rxSignal = txSignal;
            case 'Rician'
                kF = 10;
                ro_r = [sqrt(kF*sum(ro.^2)) ro];
                tau_r = [0 tau]; theta_r = [0 theta];
                rxSignal = zeros(1, length(txSignal));
                for p = 1:length(ro_r)
                    h = ro_r(p)*exp(-1i*theta_r(p));
                    d = round(tau_r(p)*fs);
                    delayed = [zeros(1,d) txSignal(1:end-d)];
                    rxSignal = rxSignal + h*delayed;
                end
                rxSignal = rxSignal / sqrt(sum(ro_r.^2));
            case 'Rayleigh'
                rxSignal = zeros(1, length(txSignal));
                for p = 1:length(ro)
                    h = ro(p)*exp(-1i*theta(p));
                    d = round(tau(p)*fs);
                    delayed = [zeros(1,d) txSignal(1:end-d)];
                    rxSignal = rxSignal + h*delayed;
                end
                rxSignal = rxSignal / sqrt(sum(ro.^2));
        end
        rxSignal = awgn(rxSignal, SNR, 'measured');
        
        % RX OFDM
        rxPar = reshape(rxSignal(1:length(txWithCP(:))), Nfft+cpLen, nOFDM);
        rxNoCP = rxPar(cpLen+1:end, :);
        rxFreq = fft(rxNoCP, Nfft);
        rxData = rxFreq(2:Nsd+1, :);
        
        % Equalization
        if useEQ && ~strcmp(chanType, 'AWGN')
            H = rxData(:,1) ./ ofdmData(:,1);
            H(abs(H) < 1e-6) = 1;
            for sym = 1:nOFDM
                rxData(:,sym) = rxData(:,sym) ./ H;
            end
        end
        
        rxMapped = rxData(:)';
        rxMapped = rxMapped(1:length(modSignal));
        
        % Demod
        if M == 2
            rxSyms = double(real(rxMapped) > 0);
        else
            rxSyms = qamdemod(rxMapped, M, 'gray', 'UnitAveragePower', true);
        end
        rxBitMat = de2bi(rxSyms(:), bps, 'left-msb');
        rxBits = reshape(rxBitMat', 1, []);
        
        % Viterbi
        if length(rxBits) < length(codedData)
            rxBits = [rxBits zeros(1, length(codedData)-length(rxBits))];
        end
        decoded = vitdec(rxBits(1:length(codedData)), trellis, 30, 'trunc', 'hard');
        
        % Metrics
        [~, ber] = biterr(decoded(1:nBits), dataBits);
        errVec = rxMapped - modSignal;
        mer = 10*log10(mean(abs(modSignal).^2) / max(mean(abs(errVec).^2), 1e-20));
        
        berArr(s)  = max(ber, 1e-7);
        merArr(s)  = mer;
        tputArr(s) = bps * BW * (1 - ber);
    end
    
    allBER{t}  = berArr;
    allMER{t}  = merArr;
    allMCS{t}  = mcsArr;
    allTput{t} = tputArr;
    allSNR{t}  = snrRange;
    
    fprintf('  → Done (BER @ 30dB = %.2e)\n\n', berArr(snrRange==30));
end

%% =================== FIGURE 1: BER Comparison ===================
figure('Name','BER Comparison','Position',[50 100 950 550],'Color','w');
colors = [0 0.45 0.74; 0.85 0.33 0.1; 0.93 0.69 0.13; 0.49 0.18 0.56; 0.47 0.67 0.19];
markers = {'o','s','d','^','v'};
for t = 1:nTests
    semilogy(allSNR{t}, allBER{t}, ['-' markers{t}], 'Color', colors(t,:), ...
        'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', colors(t,:), ...
        'DisplayName', testCases{t,1});
    hold on;
end
grid on;
xlabel('SNR (dB)','FontSize',13,'FontWeight','bold');
ylabel('BER','FontSize',13,'FontWeight','bold');
title({'BER Comparison — Different Channel Conditions','Adaptive Modulation | Tactical PHY Mesh — ARYA-mgc'},'FontSize',14,'FontWeight','bold');
legend('Location','southwest','FontSize',10);
ylim([1e-7 1]);

%% =================== FIGURE 2: MER Comparison ===================
figure('Name','MER Comparison','Position',[100 80 950 500],'Color','w');
for t = 1:nTests
    plot(allSNR{t}, allMER{t}, ['-' markers{t}], 'Color', colors(t,:), ...
        'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', colors(t,:), ...
        'DisplayName', testCases{t,1});
    hold on;
end
plot(0:35, 0:35, 'k--', 'LineWidth', 1, 'DisplayName', 'Ideal');
grid on;
xlabel('SNR (dB)','FontSize',13,'FontWeight','bold');
ylabel('MER (dB)','FontSize',13,'FontWeight','bold');
title({'MER Comparison — Channel Impact on Signal Quality','Tactical PHY Mesh — ARYA-mgc'},'FontSize',14,'FontWeight','bold');
legend('Location','northwest','FontSize',10);

%% =================== FIGURE 3: Throughput Comparison ===================
figure('Name','Throughput Comparison','Position',[150 60 950 500],'Color','w');
for t = 1:nTests
    plot(allSNR{t}, allTput{t}, ['-' markers{t}], 'Color', colors(t,:), ...
        'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', colors(t,:), ...
        'DisplayName', testCases{t,1});
    hold on;
end
grid on;
xlabel('SNR (dB)','FontSize',13,'FontWeight','bold');
ylabel('Throughput (Mbps)','FontSize',13,'FontWeight','bold');
title({'Throughput Comparison — Adaptive Modulation','Tactical PHY Mesh — ARYA-mgc'},'FontSize',14,'FontWeight','bold');
legend('Location','northwest','FontSize',10);

%% =================== FIGURE 4: MCS Selection per test ===================
figure('Name','MCS Selection','Position',[200 40 950 500],'Color','w');
for t = 1:nTests
    subplot(nTests, 1, t);
    mcsColors = lines(5);
    stairs(allSNR{t}, allMCS{t}, 'k-', 'LineWidth', 1.5);
    hold on;
    for s2 = 1:length(allSNR{t})
        idx = allMCS{t}(s2);
        plot(allSNR{t}(s2), allMCS{t}(s2), 'o', 'MarkerSize', 8, ...
            'MarkerFaceColor', mcsColors(idx,:), 'MarkerEdgeColor', 'k');
    end
    yticks(1:5); yticklabels({'BPSK','QPSK','16QAM','64QAM','256QAM'});
    ylim([0.5 5.5]); grid on;
    title(testCases{t,1}, 'FontSize', 11, 'FontWeight', 'bold');
    if t == nTests, xlabel('SNR (dB)','FontSize',11); end
end
sgtitle({'Adaptive MCS Selection — All Test Cases','Tactical PHY Mesh — ARYA-mgc'},'FontSize',14,'FontWeight','bold');

%% =================== FIGURE 5: Constellation comparison ===================
figure('Name','Constellation — Channel Comparison','Position',[250 20 1100 400],'Color','w');
testSNR = 18;  % compare at 18 dB
chanTests = {'AWGN','Rician','Rayleigh'};
chanColors = [0.2 0.5 0.9; 0.9 0.5 0.1; 0.8 0.2 0.2];

for ci = 1:3
    subplot(1, 3, ci);
    M = 16; bps = 4;  % 16-QAM at 18 dB
    nSym = 2000;
    syms = randi([0 M-1], 1, nSym);
    modSig = qammod(syms, M, 'gray', 'UnitAveragePower', true);
    
    % Apply channel
    switch chanTests{ci}
        case 'AWGN'
            rxSig = awgn(modSig, testSNR, 'measured');
        case 'Rician'
            kF = 10; ro_r = [sqrt(kF*sum(ro(1:5).^2)) ro(1:5)];
            theta_r = [0 theta(1:5)];
            rxSig = modSig;
            for p = 1:length(ro_r)
                rxSig = rxSig + ro_r(p)*exp(-1i*theta_r(p))*0.1*modSig;
            end
            rxSig = awgn(rxSig, testSNR, 'measured');
        case 'Rayleigh'
            rxSig = modSig;
            for p = 1:5
                rxSig = rxSig + ro(p)*exp(-1i*theta(p))*0.3*modSig;
            end
            rxSig = awgn(rxSig, testSNR, 'measured');
    end
    
    plot(real(rxSig), imag(rxSig), '.', 'Color', chanColors(ci,:), 'MarkerSize', 4);
    hold on;
    idealPts = qammod(0:M-1, M, 'gray', 'UnitAveragePower', true);
    plot(real(idealPts), imag(idealPts), 'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'k');
    title(sprintf('16-QAM @ %s (SNR=%ddB)', chanTests{ci}, testSNR), 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('I'); ylabel('Q'); grid on; axis equal;
    xlim([-2 2]); ylim([-2 2]);
end
sgtitle({'Channel Impact on Constellation — 16-QAM @ 18 dB','Tactical PHY Mesh — ARYA-mgc'},'FontSize',14,'FontWeight','bold');

%% =================== SUMMARY TABLE ===================
fprintf('=================================================================\n');
fprintf('  TEST CASE RESULTS SUMMARY (BER at key SNR points)\n');
fprintf('=================================================================\n');
fprintf('  %-22s | %10s | %10s | %10s | %10s\n', 'Test Case', 'SNR=10dB', 'SNR=20dB', 'SNR=30dB', 'Max Tput');
fprintf('  -----------------------|------------|------------|------------|----------\n');
for t = 1:nTests
    snrR = allSNR{t};
    i10 = find(snrR==10, 1); if isempty(i10), i10=1; end
    i20 = find(snrR==20, 1); if isempty(i20), i20=1; end
    i30 = find(snrR==30, 1); if isempty(i30), i30=1; end
    fprintf('  %-22s | %10.2e | %10.2e | %10.2e | %7.1f Mbps\n', ...
        testCases{t,1}, allBER{t}(i10), allBER{t}(i20), allBER{t}(i30), max(allTput{t}));
end
fprintf('=================================================================\n');
fprintf('  5 figures generated. All test cases complete!\n');
fprintf('=================================================================\n');
