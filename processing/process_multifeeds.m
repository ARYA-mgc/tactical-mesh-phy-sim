function [v1, v2, v3, v4, totalMbps, n3VoiceActive] = process_multifeeds(snr_all)
%% process_multifeeds — Multi-Feed Processor (Video + Voice + Telemetry)
%  Simulates Dual-Band simultaneous transmissions for 4 Nodes
%  Tactical PHY Mesh — ARYA-mgc

    BW = 8; % MHz L-Band bandwidth
    video_rates = zeros(1, 4);
    
    for n = 1:4
        s = snr_all(n);
        if s >= 26
            bps = 8; % 256-QAM (1080p HD 60fps)
        elseif s >= 20
            bps = 6; % 64-QAM (1080p 30fps)
        elseif s >= 14
            bps = 4; % 16-QAM (720p 30fps)
        elseif s >= 8
            bps = 2; % QPSK (480p Low-rate Video)
        else
            bps = 1; % BPSK (UHF Voice Priority Mode)
        end
        
        % In deep basement (SNR < 8), L-band video is paused for UHF voice priority
        if s < 8 && n == 3
            video_rates(n) = 8; % 8 Mbps robust UHF voice/data link
        else
            video_rates(n) = bps * BW;
        end
    end
    
    v1 = video_rates(1);
    v2 = video_rates(2);
    v3 = video_rates(3);
    v4 = video_rates(4);
    totalMbps = sum(video_rates);
    
    % UHF Voice Penetration indicator (1 = Active)
    if snr_all(3) < 10
        n3VoiceActive = 1;
    else
        n3VoiceActive = 0;
    end
end
