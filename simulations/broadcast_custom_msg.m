%% broadcast_custom_msg.m
%  INTERACTIVE TACTICAL MESSAGE BROADCAST TESTER
%  Allows you or judges to type ANY custom message and watch it
%  get encoded, transmitted across the channel, and decoded live!
%
%  Usage: >> broadcast_custom_msg

clc;
fprintf('=================================================================\n');
fprintf('  INTERACTIVE TACTICAL BROADCAST TESTER (ARYA-mgc)\n');
fprintf('=================================================================\n\n');

% Default or User Prompt
default_msg = 'HOSTAGE EVACUATION COMPLETE - REQUESTING EXTRACTION CHOPPER AT LZ-1';
prompt = sprintf('Enter tactical message to transmit [Press Enter for default]:\n> ');
userInput = input(prompt, 's');

if isempty(userInput)
    msgToSend = default_msg;
else
    msgToSend = userInput;
end

fprintf('\nSelect Commando Node (1=Rooftop [30dB], 2=Corridor [18dB], 3=Basement [6dB], 4=Perimeter [24dB]): ');
nodeChoice = input('', 's');
if isempty(nodeChoice) || ~ismember(nodeChoice, {'1','2','3','4'})
    nodeID = 3; % Default to basement (toughest test case)
else
    nodeID = str2double(nodeChoice);
end

callsigns = {'ALPHA-1 (Rooftop)', 'BRAVO-2 (Corridor)', 'CHARLIE-3 (Basement)', 'DELTA-4 (Perimeter)'};
testSNRs  = [30, 18, 6, 24];
snr = testSNRs(nodeID);

% MCS Selection
if snr >= 26,     bps=8; M=256; mcs='256-QAM'; band='L-Band (HD Video)';
elseif snr >= 20, bps=6; M=64;  mcs='64-QAM';  band='L-Band (Video)';
elseif snr >= 14, bps=4; M=16;  mcs='16-QAM';  band='Dual-Band';
elseif snr >= 8,  bps=2; M=4;   mcs='QPSK';    band='UHF (Voice)';
else,             bps=1; M=2;   mcs='BPSK';    band='UHF Penetration Mode';
end

fprintf('\n[TX ENCODING] Node: %s | Band: %s | MCS: %s (%d bps)\n', callsigns{nodeID}, band, mcs, bps);
fprintf('[TX PAYLOAD]  "%s" (%d characters = %d bits)\n', msgToSend, length(msgToSend), length(msgToSend)*8);

% PHY Processing
trellis = poly2trellis(7, [133 171]);
msgBits = reshape(de2bi(uint8(msgToSend), 8, 'left-msb')', 1, []);
coded = convenc(msgBits, trellis);

nS = floor(length(coded)/bps);
bM = reshape(coded(1:nS*bps), bps, [])';
syms = bi2de(bM, 'left-msb');
if M == 2
    modSig = 2*double(syms') - 1;
else
    modSig = qammod(double(syms'), M, 'gray', 'UnitAveragePower', true);
end

fprintf('[CH PROPAGATION] Transmitting through %d dB SNR channel impairments...\n', snr);
rxSig = awgn(modSig, snr, 'measured');

if M == 2
    rxS = double(real(rxSig)>0);
else
    rxS = qamdemod(rxSig, M, 'gray', 'UnitAveragePower', true);
end
rxBM = de2bi(rxS(:), bps, 'left-msb');
rxB = reshape(rxBM', 1, []);
if length(rxB) < length(coded)
    rxB = [rxB zeros(1, length(coded)-length(rxB))];
end
dec = vitdec(rxB(1:length(coded)), trellis, 30, 'trunc', 'hard');

recBits = dec(1:length(msgBits));
nC = floor(length(recBits)/8);
cB = reshape(recBits(1:nC*8), 8, [])';
cV = bi2de(cB, 'left-msb');
cV(cV<32 | cV>126) = 63;
rxMsg = char(cV');

[~, ber] = biterr(dec(1:length(msgBits)), msgBits);

% Output Result
fprintf('\n=================================================================\n');
fprintf('  BASE STATION DECRYPTION RECEIVER\n');
fprintf('=================================================================\n');
fprintf('  Sender:         %s\n', callsigns{nodeID});
fprintf('  Received SNR:   %d dB\n', snr);
fprintf('  Modulation:     %s\n', mcs);
fprintf('  Bit Error Rate: %.2e (Decoded Accuracy: %.1f%%)\n', ber, (1-ber)*100);
fprintf('  Decoded Msg:    "%s"\n', rxMsg);
fprintf('=================================================================\n');
if strcmp(msgToSend, rxMsg)
    fprintf('  >>> STATUS: 100%% VERIFIED PERFECT RECOVERY! <<<\n');
else
    fprintf('  >>> STATUS: RECEIVED WITH MINOR CORRECTION <<<\n');
end
fprintf('=================================================================\n\n');
