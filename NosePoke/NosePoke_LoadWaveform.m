function NosePoke_LoadWaveform(Player, Mode, iTrial)
% BrokeFixationSound -> Sound Index 1
% NoDecisionSound      -> 2
% IncorrectChoiceSound -> 3
% SkippedFeedbackSound -> 4
% NotBaitedFeedbackSound -> 5
% Sound Index 6 onwards are reserved for trial-dependent waveform (Max index for HiFi: 20; for Analog: 64)

global BpodSystem
global TaskParameters

if nargin < 3
    iTrial = 0;
end

SoundLevel = 0.2;

% load auditory stimuli
fs = Player.SamplingRate;

switch Mode
    case 'TrialIndependent'
        %%
        SoundIndex = 1;
        BrokeFixationSound = [];
        if isfield(TaskParameters.GUI, 'BrokeFixationTimeOut') && TaskParameters.GUI.BrokeFixationTimeOut > 0
            switch TaskParameters.GUIMeta.BrokeFixationFeedback.String{TaskParameters.GUI.BrokeFixationFeedback}
                case 'None' % no adjustment

                case 'WhiteNoise'
                    BrokeFixationSound = rand(1, fs*TaskParameters.GUI.BrokeFixationTimeOut)*2 - 1;
                    BrokeFixationSound = BrokeFixationSound*SoundLevel;
            end
        end

        if ~isempty(BrokeFixationSound)
            if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                Player.loadWaveform(SoundIndex, BrokeFixationSound);
                Player.TriggerProfiles(SoundIndex, 1:2) = SoundIndex;
            elseif isfield(BpodSystem.ModuleUSB, 'HiFi1')
                Player.load(SoundIndex, BrokeFixationSound);
            end
        end

        %%
        SoundIndex = 2;
        NoDecisionSound = [];
        if isfield(TaskParameters.GUI, 'NoDecisionTimeOut') && TaskParameters.GUI.NoDecisionTimeOut > 0
            switch TaskParameters.GUIMeta.NoDecisionFeedback.String{TaskParameters.GUI.NoDecisionFeedback}
                case 'None' % no adjustment

                case 'WhiteNoise'
                    NoDecisionSound = rand(1, fs*TaskParameters.GUI.NoDecisionTimeOut)*2 - 1;
                    NoDecisionSound = NoDecisionSound*SoundLevel;
            end
        end

        if ~isempty(NoDecisionSound)
            if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                Player.loadWaveform(SoundIndex, NoDecisionSound);
                Player.TriggerProfiles(SoundIndex, 1:2) = SoundIndex;
            elseif isfield(BpodSystem.ModuleUSB, 'HiFi1')
                Player.load(SoundIndex, NoDecisionSound);
            end
        end

        %%
        SoundIndex = 3;
        IncorrectChoiceSound = [];
        if isfield(TaskParameters.GUI, 'IncorrectChoiceTimeOut') && TaskParameters.GUI.IncorrectChoiceTimeOut > 0
            switch TaskParameters.GUIMeta.IncorrectChoiceFeedback.String{TaskParameters.GUI.IncorrectChoiceFeedback}
                case 'None' % no adjustment

                case 'WhiteNoise'
                    IncorrectChoiceSound = rand(1, fs*TaskParameters.GUI.IncorrectChoiceTimeOut)*2 - 1;
                    IncorrectChoiceSound = IncorrectChoiceSound*SoundLevel;
            end
        end

        if ~isempty(IncorrectChoiceSound)
            if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                Player.loadWaveform(SoundIndex, IncorrectChoiceSound);
                Player.TriggerProfiles(SoundIndex, 1:2) = SoundIndex;
            elseif isfield(BpodSystem.ModuleUSB, 'HiFi1')
                Player.load(SoundIndex, IncorrectChoiceSound);
            end
        end
        
        %%
        SoundIndex = 4;
        SkippedFeedbackSound = [];
        if isfield(TaskParameters.GUI, 'SkippedFeedbackTimeOut') && TaskParameters.GUI.SkippedFeedbackTimeOut > 0
            switch TaskParameters.GUIMeta.SkippedFeedbackFeedback.String{TaskParameters.GUI.SkippedFeedbackFeedback}
                case 'None' % no adjustment

                case 'WhiteNoise'
                    SkippedFeedbackSound = rand(1, fs*TaskParameters.GUI.SkippedFeedbackTimeOut)*2 - 1;
                    SkippedFeedbackSound = SkippedFeedbackSound*SoundLevel;

                case 'Beep' % 1k Hz
                    SkippedFeedbackSound = GenerateRiskCue(fs, TaskParameters.GUI.SkippedFeedbackTimeOut, 'Freq', 1, 1);
                    
            end
        end

        if ~isempty(SkippedFeedbackSound)
            if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                Player.loadWaveform(SoundIndex, SkippedFeedbackSound);
                Player.TriggerProfiles(SoundIndex, 1:2) = SoundIndex;
            elseif isfield(BpodSystem.ModuleUSB, 'HiFi1')
                Player.load(SoundIndex, SkippedFeedbackSound);
            end
        end

        %%
        SoundIndex = 5;
        NotBaitedSound = [];
        if isfield(TaskParameters.GUI, 'NotBaitedTimeOut') && TaskParameters.GUI.NotBaitedTimeOut > 0
            switch TaskParameters.GUIMeta.NotBaitedFeedback.String{TaskParameters.GUI.NotBaitedFeedback}
                case 'None' % no adjustment

                case 'WhiteNoise'
                    NotBaitedSound = rand(1, fs*TaskParameters.GUI.NotBaitedTimeOut)*2 - 1;
                    NotBaitedSound = NotBaitedSound*SoundLevel;

                case 'Beep' % 0.5k Hz
                    NotBaitedSound = GenerateRiskCue(fs, TaskParameters.GUI.NotBaitedTimeOut, 'Freq', 0.5, 0.5);

            end
        end

        if ~isempty(NotBaitedSound)
            if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                Player.loadWaveform(SoundIndex, NotBaitedSound);
                Player.TriggerProfiles(SoundIndex, 1:2) = SoundIndex;
            elseif isfield(BpodSystem.ModuleUSB, 'HiFi1')
                Player.load(SoundIndex, NotBaitedSound);
            end
        end

        if isfield(BpodSystem.ModuleUSB, 'HiFi1')
            Player.push()
        end

    case 'TrialDependent'
        %% (CURRENTLY ONLY FOR LEARNING TO WAIT, NOT CLICKS)
        SoundIndex = 6;
        SamplingSound = [];
        if isfield(TaskParameters.GUI, 'SamplingTarget') && TaskParameters.GUI.SamplingTarget > 0
            switch TaskParameters.GUIMeta.Stimulus.String{TaskParameters.GUI.Stimulus}
                case 'None' % no adjustment

                case 'DelayDuration' % full pure tone (1 kHz) to indicate how long to wait
                    SamplingSound = GenerateRiskCue(fs, SamplingTarget, 'Freq', 1, 1);

                case 'EndBeep' % pure tone (1 kHz) 0.05s before the target sampling time reached
                    SamplingSound = GenerateRiskCue(fs, SamplingTarget, 'Freq', 1, 1);
                    LastIdx = max(1, length(SamplingSound)-50);
                    SamplingSound(1:LastIdx) = 0;

            end
        end

        if ~isempty(SamplingSound)
            if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                Player.loadWaveform(SoundIndex, SamplingSound);
                if TaskParameters.GUI.SingleSidePoke
                    if BpodSystem.Data.Custom.LightLeft(iTrial) == 0
                        Player.TriggerProfiles(SoundIndex, 2) = SoundIndex;
                    elseif BpodSystem.Data.Custom.LightLeft(iTrial) == 1
                        Player.TriggerProfiles(SoundIndex, 1) = SoundIndex;
                    end
                else
                    Player.TriggerProfiles(SoundIndex, 1:2) = SoundIndex;
                end
            elseif isfield(BpodSystem.ModuleUSB, 'HiFi1')
                if TaskParameters.GUI.SingleSidePoke
                    if BpodSystem.Data.Custom.LightLeft(iTrial) == 0
                        Player.load(SoundIndex, [0; SamplingSound]);
                    elseif BpodSystem.Data.Custom.LightLeft(iTrial) == 1
                        Player.load(SoundIndex, [SamplingSound; 0]);
                    end
                else
                    Player.load(SoundIndex, SamplingSound);
                end
                Player.push()
            end
        end

end % end switch
end % end function