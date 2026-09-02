%% tactical_ground_station_gui.m
%  DUAL-BAND MESH COMMUNICATION BASE STATION
%  Push-To-Talk / Tactical Broadcast: When 1 Person TALKS, all others LISTEN!
%  Clean Black & White / High-Contrast Presentation UI
%  Tactical PHY Mesh — ARYA-mgc
%
%  Usage: >> tactical_ground_station_gui

function tactical_ground_station_gui()
    clc;
    fprintf('=================================================================\n');
    fprintf('  DUAL-BAND MESH COMMUNICATION BASE STATION\n');
    fprintf('  Broadcast Mode: 1 Node Transmits (🎙️ TALKING), Others Receive (🎧 LISTENING)\n');
    fprintf('=================================================================\n\n');

    % Time-Varying Sequence: 1 person speaks at a time, all others listen!
    mission_steps = [
        struct('time', 15,  'phase', 'TIME T+15s: [PERSON 1 IS BROADCASTING]', ...
               'activeNode', 1, ...
               'speakerMsg', 'Person 1: "Rooftop link established; HD camera streaming; Area clear."', ...
               'snr', [30, 22, 20, 25], ...
               'loc', {{'Open Rooftop Area', 'Ground Floor Entry', 'Corridor Pathway', 'Base Station Area'}}), ...
               
        struct('time', 45,  'phase', 'TIME T+45s: [PERSON 2 IS BROADCASTING]', ...
               'activeNode', 2, ...
               'speakerMsg', 'Person 2: "Entered ground floor corridor; Link is stable and connected."', ...
               'snr', [28, 16, 14, 24], ...
               'loc', {{'Open Rooftop Area', 'Ground Floor Corridor', 'Stairwell Entry', 'Base Station Area'}}), ...
               
        struct('time', 85,  'phase', 'TIME T+85s: [PERSON 3 IS BROADCASTING FROM BASEMENT]', ...
               'activeNode', 3, ...
               'speakerMsg', 'Person 3: "INSIDE BASEMENT; Switched to UHF Penetration Mode; Audio 100% working!"', ...
               'snr', [28, 10, 5, 23], ...
               'loc', {{'Open Rooftop Area', 'Staircase Landing', 'Deep Basement Sector', 'Base Station Area'}}), ...
               
        struct('time', 130, 'phase', 'TIME T+130s: [PERSON 2 IS BROADCASTING]', ...
               'activeNode', 2, ...
               'speakerMsg', 'Person 2: "Relaying basement audio to ground station; All packets received."', ...
               'snr', [30, 18, 12, 25], ...
               'loc', {{'Open Rooftop Area', 'Main Hallway Exit', 'Ascending Central Stairs', 'Base Station Area'}}), ...
               
        struct('time', 175, 'phase', 'TIME T+175s: [PERSON 4 IS BROADCASTING]', ...
               'activeNode', 4, ...
               'speakerMsg', 'Person 4: "Base station confirmed; All 4 nodes connected; Zero packet loss."', ...
               'snr', [30, 24, 22, 26], ...
               'loc', {{'Open Rooftop Area', 'Base Station Area', 'Base Station Area', 'Base Station Area'}})
    ];

    currentStep = 1;
    isPaused = false;
    BW = 8; % MHz

    %% Create Clean High-Contrast Black & White UI
    fig = figure('Name','Dual-Band Mesh Base Station — Live Broadcast Terminal', ...
        'Position',[50 30 1200 730],'Color',[0.96 0.96 0.96],'MenuBar','none','NumberTitle','off', ...
        'CloseRequestFcn',@closeFigure);

    % Header Banner
    uipanel('Parent',fig,'Position',[0.02 0.89 0.96 0.09], ...
        'BackgroundColor',[0.08 0.08 0.08],'BorderType','line','HighlightColor',[0 0 0],'BorderWidth',2);

    uicontrol('Style','text','Parent',fig,'Position',[40 660 1120 32], ...
        'String','DUAL-BAND MESH COMMUNICATION BASE STATION', ...
        'FontSize',14,'FontWeight','bold','ForegroundColor',[1 1 1],'BackgroundColor',[0.08 0.08 0.08]);

    % Control Bar
    phaseLabel = uicontrol('Style','text','Parent',fig,'Position',[40 600 920 32], ...
        'String','● INITIALIZING BROADCAST STREAM...', 'FontSize',11,'FontWeight','bold', ...
        'BackgroundColor',[1 1 1],'ForegroundColor',[0 0 0],'HorizontalAlignment','left');

    btnPause = uicontrol('Style','pushbutton','Parent',fig,'Position',[980 600 180 32], ...
        'String','⏸ PAUSE / RESUME', 'FontSize',10,'FontWeight','bold', ...
        'BackgroundColor',[0.88 0.88 0.88],'ForegroundColor',[0 0 0],'Callback',@togglePause);

    % Card Containers
    cardY = [445, 305, 165, 25];
    cardPanels = gobjects(4,1);
    cardHeaders = gobjects(4,1);
    cardLocations = gobjects(4,1);
    cardMsgBoxes = gobjects(4,1);
    cardStatusBadges = gobjects(4,1);
    cardSnrBadges = gobjects(4,1);
    cardTputBadges = gobjects(4,1);
    cardVideoBadges = gobjects(4,1);

    personTitles = {'Person 1', 'Person 2', 'Person 3', 'Person 4'};

    for n = 1:4
        y = cardY(n);
        
        cardPanels(n) = uipanel('Parent',fig,'Position',[0.02 y/730 0.96 130/730], ...
            'BackgroundColor',[1 1 1],'BorderType','line','HighlightColor',[0.3 0.3 0.3],'BorderWidth',2);

        % Left Column: Header, Location, Message Box (Width: 600px, x: 40 to 640)
        cardHeaders(n) = uicontrol('Style','text','Parent',fig,'Position',[40 y+95 600 24], ...
            'String',sprintf('[NODE %d] %s', n, personTitles{n}),'FontSize',11,'FontWeight','bold', ...
            'ForegroundColor',[0 0 0],'BackgroundColor',[1 1 1],'HorizontalAlignment','left');

        cardLocations(n) = uicontrol('Style','text','Parent',fig,'Position',[40 y+70 600 22], ...
            'String','Location: ---', 'FontSize',9,'ForegroundColor',[0.3 0.3 0.3], ...
            'BackgroundColor',[1 1 1],'HorizontalAlignment','left');

        cardMsgBoxes(n) = uicontrol('Style','text','Parent',fig,'Position',[40 y+12 600 52], ...
            'String','STATUS: ---', 'FontSize',9.5,'FontWeight','bold', ...
            'ForegroundColor',[0 0 0],'BackgroundColor',[0.92 0.92 0.92],'HorizontalAlignment','left');

        % Right Column: Telemetry & Video Badges (Width: 500px, x: 660 to 1160 - Zero Overlap!)
        cardStatusBadges(n) = uicontrol('Style','text','Parent',fig,'Position',[660 y+95 500 24], ...
            'String','RADIO STATE: ---', 'FontSize',9.5,'FontWeight','bold', ...
            'ForegroundColor',[0 0 0],'BackgroundColor',[1 1 1],'HorizontalAlignment','right');

        cardSnrBadges(n) = uicontrol('Style','text','Parent',fig,'Position',[660 y+68 500 22], ...
            'String','VIDEO STATUS: ---', 'FontSize',9.5,'FontWeight','bold', ...
            'ForegroundColor',[0.2 0.2 0.2],'BackgroundColor',[1 1 1],'HorizontalAlignment','right');

        cardTputBadges(n) = uicontrol('Style','text','Parent',fig,'Position',[660 y+40 500 22], ...
            'String','SNR: -- dB | Modulation: ---', 'FontSize',9,'FontWeight','bold', ...
            'ForegroundColor',[0.2 0.2 0.2],'BackgroundColor',[1 1 1],'HorizontalAlignment','right');

        cardVideoBadges(n) = uicontrol('Style','text','Parent',fig,'Position',[660 y+14 500 22], ...
            'String','Throughput: -- Mbps | BER: 0.00e+00', 'FontSize',9.5,'FontWeight','bold', ...
            'ForegroundColor',[0 0 0],'BackgroundColor',[1 1 1],'HorizontalAlignment','right');
    end

    % Render First Step
    updateDisplay();

    %% Automatic Timer Setup (advances every 3.5 seconds)
    autoTimer = timer('ExecutionMode', 'fixedRate', ...
                      'Period', 3.5, ...
                      'TimerFcn', @timerCallback);
    start(autoTimer);

    function timerCallback(~, ~)
        if ~isPaused && isvalid(fig)
            if currentStep < length(mission_steps)
                currentStep = currentStep + 1;
            else
                currentStep = 1; % Loop
            end
            updateDisplay();
        end
    end

    %% Update Display Logic
    function updateDisplay()
        if ~isvalid(fig), return; end
        st = mission_steps(currentStep);
        activeSpeaker = st.activeNode;
        speakerName = personTitles{activeSpeaker};

        set(phaseLabel, 'String', sprintf('  ● [%s]  Current Transmitting Node: Person %d', st.phase, activeSpeaker));

        for i = 1:4
            s = st.snr(i);
            
            % Adaptive MCS & Video Resolution calculation
            if s >= 26
                mcs = '256-QAM (8 bps)'; bps = 8;
                vStat = '📹 VIDEO: 1080p HD LIVE @ 60 FPS (L-Band)';
            elseif s >= 20
                mcs = '64-QAM (6 bps)'; bps = 6;
                vStat = '📹 VIDEO: 1080p LIVE @ 30 FPS (L-Band)';
            elseif s >= 14
                mcs = '16-QAM (4 bps)'; bps = 4;
                vStat = '📹 VIDEO: 720p HD LIVE @ 30 FPS (Dual-Band)';
            elseif s >= 8
                mcs = 'QPSK (2 bps)'; bps = 2;
                vStat = '📹 VIDEO: 480p LOW-BANDWIDTH (Dual-Band)';
            else
                mcs = 'BPSK (1 bps)'; bps = 1;
                vStat = '⚠️ VIDEO: PAUSED (UHF Voice Priority Mode)';
            end

            tput = bps * BW;
            set(cardLocations(i), 'String', sprintf('Location: %s  |  RF Link: %s', st.loc{i}, getBandName(s)), ...
                'BackgroundColor', getCardColor(i == activeSpeaker));
            set(cardSnrBadges(i), 'String', vStat, ...
                'BackgroundColor', getCardColor(i == activeSpeaker));
            set(cardTputBadges(i), 'String', sprintf('RF Link SNR: %d dB   |   Modulation: %s', s, mcs), ...
                'BackgroundColor', getCardColor(i == activeSpeaker));
            set(cardVideoBadges(i), 'String', sprintf('Net Throughput: %d Mbps   |   BER: 0.00e+00 (Zero Errors)', tput), ...
                'BackgroundColor', getCardColor(i == activeSpeaker));

            % 🎙️ TALKING vs 🎧 LISTENING LOGIC
            if i == activeSpeaker
                % ACTIVE TRANSMITTER (TALKING)
                set(cardPanels(i), 'BackgroundColor', [1 1 1], 'HighlightColor', [0 0 0], 'BorderWidth', 3);
                set(cardHeaders(i), 'ForegroundColor', [0 0 0], 'BackgroundColor', [1 1 1], ...
                    'String', sprintf('🎙️ [NODE %d] %s  [🔴 BROADCASTING / TALKING NOW]', i, personTitles{i}));
                set(cardStatusBadges(i), 'String', 'RADIO STATE: 🎙️ TRANSMITTING AUDIO & DATA', ...
                    'BackgroundColor', [1 1 1]);
                
                % Highlighted Black Box for speaker
                set(cardMsgBoxes(i), ...
                    'String', sprintf('★ TRANSMITTING LIVE BROADCAST:\n%s', st.speakerMsg), ...
                    'BackgroundColor', [0.10 0.10 0.10], 'ForegroundColor', [1 1 1]);
            else
                % LISTENING RECEIVER (HEARING THE SPEAKER)
                set(cardPanels(i), 'BackgroundColor', [0.98 0.98 0.98], 'HighlightColor', [0.75 0.75 0.75], 'BorderWidth', 1);
                set(cardHeaders(i), 'ForegroundColor', [0.35 0.35 0.35], 'BackgroundColor', [0.98 0.98 0.98], ...
                    'String', sprintf('🎧 [NODE %d] %s  [LISTENING TO %s]', i, personTitles{i}, speakerName));
                set(cardStatusBadges(i), 'String', sprintf('RADIO STATE: 🎧 RECEIVING FROM %s', upper(speakerName)), ...
                    'BackgroundColor', [0.98 0.98 0.98]);
                
                % Received Message Box showing what they hear
                set(cardMsgBoxes(i), ...
                    'String', sprintf('🎧 HEARS FROM %s:\n%s', upper(speakerName), st.speakerMsg), ...
                    'BackgroundColor', [0.93 0.93 0.93], 'ForegroundColor', [0.20 0.20 0.20]);
            end
        end

        % Play subtle push-to-talk beep
        try
            fs_c = 8000;
            tc = 0:1/fs_c:0.07;
            sound(0.12*sin(2*pi*1700*tc), fs_c);
        catch
        end
    end

    function c = getCardColor(isActive)
        if isActive, c = [1 1 1];
        else, c = [0.98 0.98 0.98];
        end
    end

    function togglePause(~, ~)
        isPaused = ~isPaused;
        if isPaused
            set(btnPause, 'String', '▶ RESUME LIVE FEED', 'BackgroundColor', [0.8 1.0 0.8]);
        else
            set(btnPause, 'String', '⏸ PAUSE FEED', 'BackgroundColor', [0.88 0.88 0.88]);
            updateDisplay();
        end
    end

    function b = getBandName(snr_val)
        if snr_val < 10
            b = 'UHF Band (380-400 MHz Penetration)';
        elseif snr_val >= 20
            b = 'Dual-Band (UHF 380-400 MHz + L-Band 1.6 GHz Video)';
        else
            b = 'Dual-Band (UHF 380-400 MHz + L-Band 1.55-1.65 GHz Balanced)';
        end
    end

    function closeFigure(src, ~)
        try
            stop(autoTimer);
            delete(autoTimer);
        catch
        end
        delete(src);
    end
end
