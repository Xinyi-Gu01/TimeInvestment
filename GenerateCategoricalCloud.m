function Waveform = GenerateCategoricalCloud(sf, Duration, HighToneProb)
    % sf: Sampling frequency (e.g., 192000)
    % Duration: Total duration of the cloud in seconds
    % HighToneProb: Proportion of pips that will be sampled from the High Band (0.0 to 1.0)
    
    % 1. Define distinct frequency bands
    lowMin = 2000;  lowMax = 6000;
    highMin = 10000; highMax = 16000;
    
    % 2. Define temporal parameters
    pipDuration = 0.030; % 30 ms pips
    pipInterval = 0.010; % 10 ms between onsets (100 Hz rate)
    numPips = floor((Duration - pipDuration) / pipInterval) + 1;
    
    % Initialize the total waveform buffer
    totalSamples = ceil(Duration * sf);
    Waveform = zeros(1, totalSamples);
    
    % 3. Generate the Pip Envelope (5ms ramp to prevent clicking)
    rampTime = 0.005;
    rampSamples = floor(rampTime * sf);
    pipSamples = floor(pipDuration * sf);
    envelope = ones(1, pipSamples);
    envelope(1:rampSamples) = linspace(0, 1, rampSamples);
    envelope(end-rampSamples+1:end) = linspace(1, 0, rampSamples);
    
    % 4. Categorical Stochastic Loop
    for i = 1:numPips
        % Determine if this specific pip belongs to the High or Low category
        if rand() < HighToneProb
            % Sample uniformly from the High Band [10kHz - 16kHz]
            currentFreq = highMin + rand() * (highMax - highMin);
        else
            % Sample uniformly from the Low Band [2kHz - 6kHz]
            currentFreq = lowMin + rand() * (lowMax - lowMin);
        end
        
        % Generate the pure tone pip
        t = 0:1/sf:(pipDuration - 1/sf);
        pip = sin(2 * pi * currentFreq * t) .* envelope;
        
        % Calculate onset sample index
        onsetSample = floor((i-1) * pipInterval * sf) + 1;
        offsetSample = onsetSample + pipSamples - 1;
        
        % Add (mix) the pip into the master waveform
        if offsetSample <= totalSamples
            Waveform(onsetSample:offsetSample) = Waveform(onsetSample:offsetSample) + pip;
        end
    end
    
    % 5. Normalize to prevent clipping
    if max(abs(Waveform)) > 0
        Waveform = (Waveform / max(abs(Waveform))) * 0.9; 
    end
end