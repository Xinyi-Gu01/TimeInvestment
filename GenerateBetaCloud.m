%{
----------------------------------------------------------------------------

This file is part of the Sanworks Bpod repository
Copyright (C) Sanworks LLC, Rochester, New York, USA

----------------------------------------------------------------------------

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3.

This program is distributed  WITHOUT ANY WARRANTY and without even the 
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
%}

% GenerateSineWave() returns a sampled sine waveform 
%
% Arguments:
% samplingRate: sampling rate of the system that will play the sound. Unit = Hz
% frequency: The frequency of the sine waveform. Unit = Hz
% duration: The duration of the waveform. Unit = seconds
%
% Returns:
% sineWave: The sine waveform. Samples range in amplitude between [-1, 1].


function Waveform = GenerateBetaCloud(sf, Duration, Alpha, Beta)
    % sf: Sampling frequency (e.g., 192000)
    % Duration: Total duration of the cloud in seconds
    % Alpha, Beta: Parameters for the Beta distribution
    
    % 1. Define the 18 logarithmic frequencies between 5kHz and 40kHz
    freqs = logspace(log10(2000), log10(16000), 18);
    
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
    
    % 4. Stochastic Loop to build the cloud
    for i = 1:numPips
        % Generate a value x from Beta distribution
        x = betarnd(Alpha, Beta);
        
        % Map x [0,1] to one of the 18 log-spaced indices [1,18]
        freqIndex = round(x * 17) + 1; 
        currentFreq = freqs(freqIndex);
        
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
    
    % 5. Normalize to prevent clipping (keep amplitude below 1.0)
    if max(abs(Waveform)) > 0
        Waveform = (Waveform / max(abs(Waveform))) * 0.9; % Scale to 90%
    end
end
