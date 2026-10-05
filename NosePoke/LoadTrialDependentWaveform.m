function LoadTrialDependentWaveform(Player, iTrial, SoundLevel, ClickLength)
global BpodSystem
global TaskParameters
% global Player

if nargin <4
    ClickLength = 2; % in sampling frame
end

if nargin <3
    SoundLevel = 1;
end

if ~BpodSystem.EmulatorMode
    % load auditory stimuli
    fs = Player.SamplingRate;
    
    if TaskParameters.GUI.PlayStimulus == 2 % click task
        [LeftClickTrain,RightClickTrain] = GetClickStimulus(iTrial, TaskParameters.GUI.SampleTime, fs, ClickLength, SoundLevel);

        SoundIndex = 3;
        Player.loadWaveform(SoundIndex, LeftClickTrain);

        SoundIndex = 4;
        Player.loadWaveform(SoundIndex, RightClickTrain);
    elseif TaskParameters.GUI.PlayStimulus == 3 % freq task
    
    end

    %Player.Waveforms;
end
end