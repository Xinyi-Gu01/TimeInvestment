function Stage2_difficultAssociation

global BpodSystem 

%% Setup HiFi Module
BpodSystem.assertModule('HiFi', 1); 
H = BpodHiFi(BpodSystem.ModuleUSB.HiFi1); 

%% Define Parameters (UPDATED for Continuous Jitter)
S = BpodSystem.ProtocolSettings; 
if isempty(fieldnames(S))  
    S.GUI.RewardVolume = 30; % uL
    S.GUI.SoundDuration = 0.5; % s
    S.GUI.ResponseTime = 10; % s 
    S.GUI.ErrorDelay = 2; % s 
    
    % Jittered Ranges to prevent template matching
    S.GUI.AlphaLeft_Min = 1.0;  
    S.GUI.AlphaLeft_Max = 2.5;   
    S.GUI.BetaLeft = 5; 
    
    S.GUI.AlphaRight_Min = 3.5;  
    S.GUI.AlphaRight_Max = 5.0;   
    S.GUI.BetaRight = 1;  

    S.GUIPanels.BetaCloud_Jitter = {'AlphaLeft_Min', 'AlphaLeft_Max', 'BetaLeft', 'AlphaRight_Min', 'AlphaRight_Max', 'BetaRight', 'SoundDuration'};
    S.GUIPanels.Time = {'ResponseTime', 'ErrorDelay'};
end

%% Initialize GUI and Data arrays
maxTrials = 1000;
BankSize = 20; % Number of unique sounds per side

trialTypes = ceil(rand(1,maxTrials)*2);
trialBankIndices = ceil(rand(1,maxTrials) * BankSize); % Randomly select a sound 1-20 for each trial

BpodSystem.Data.TrialTypes = []; 
BpodSystem.Data.Custom.AssignedAlpha = NaN(1, maxTrials); % Tracks the specific Alpha used
BpodSystem.Data.Custom.MoveTimes = NaN(1, maxTrials);
BpodSystem.Data.Custom.Outcomes = NaN(1, maxTrials); 
BpodSystem.Data.Custom.ChoiceLeft = NaN(1, maxTrials); 

TotalRewardAmount = 0; 
PokeColors = getPokeColors;

BpodParameterGUI('init', S); 
BpodNotebook('init'); 
outcomePlot = LiveOutcomePlot([1 2], {'Left', 'Right'}, trialTypes, 90);
outcomePlot.RewardStateNames = {'Reward'}; 
outcomePlot.PunishStateNames = {'Punish'};
PokesPlot('init', getStateColors, PokeColors);

%% Initialize Custom Metrics Figure (5 Panels)
MetricsFig = figure('Name', 'Live Session Metrics', 'Position', [100, 100, 1500, 300], 'NumberTitle', 'off');
axRate = subplot(1,5,1); hold(axRate, 'on'); title(axRate, 'Trial Rate'); xlabel(axRate, 'Time (min)'); ylabel(axRate, 'Trials Started');
axMove = subplot(1,5,2); hold(axMove, 'on'); title(axMove, 'Movement Time'); xlabel(axMove, 'Time (s)'); ylabel(axMove, 'Count');
axErr = subplot(1,5,3); hold(axErr, 'on'); title(axErr, 'Granular Outcomes'); ylabel(axErr, 'Trial Count');
set(axErr, 'XTick', 1:4, 'XTickLabel', {'Rew', 'Pun', 'NoDec', 'NoStart'});
axBias = subplot(1,5,4); hold(axBias, 'on'); title(axBias, 'Side Accuracy (Bias)'); ylabel(axBias, '% Correct');
set(axBias, 'XTick', 1:2, 'XTickLabel', {'Left', 'Right'}, 'YLim', [0 100]);
axPsych = subplot(1,5,5); hold(axPsych, 'on'); title(axPsych, 'Accuracy by Alpha'); 
xlabel(axPsych, 'Alpha Value'); ylabel(axPsych, '% Correct');
set(axPsych, 'YLim', [0 100], 'XLim', [1 5]);

%% Generate Stimuli Bank (192kHz)
sf = 192000; 
H.SamplingRate = sf;
H.HeadphoneAmpEnabled = false; 

% Pre-calculate the 20 random Alphas for Left and Right
LeftAlphas = S.GUI.AlphaLeft_Min + rand(1, BankSize) * (S.GUI.AlphaLeft_Max - S.GUI.AlphaLeft_Min);
RightAlphas = S.GUI.AlphaRight_Min + rand(1, BankSize) * (S.GUI.AlphaRight_Max - S.GUI.AlphaRight_Min);

disp('Generating audio bank. Please wait...');
% Generate 20 Unique Left Sounds (Slots 1 to 20)
for i = 1:BankSize
    snd = GenerateBetaCloud(sf, S.GUI.SoundDuration, LeftAlphas(i), S.GUI.BetaLeft);
    H.load(i, snd); 
end

% Generate 20 Unique Right Sounds (Slots 21 to 40)
for i = 1:BankSize
    snd = GenerateBetaCloud(sf, S.GUI.SoundDuration, RightAlphas(i), S.GUI.BetaRight);
    H.load(i + BankSize, snd); 
end

% Load Error Sound into Slot 41
errorSound = GenerateWhiteNoise(sf, S.GUI.ErrorDelay, 1, 2);
H.load((BankSize * 2) + 1, errorSound); 

H.push;
H.AMenvelope = 1/(sf*0.001):1/(sf*0.001):1; 
disp('Audio bank loaded.');

%% Main Trial Loop
for currentTrial = 1:maxTrials
    S = BpodParameterGUI('sync', S);
    
    LeftValveTime = GetValveTimes(S.GUI.RewardVolume, 1); 
    RightValveTime = GetValveTimes(S.GUI.RewardVolume, 3);
    
    % Track which specific Alpha we are using for this trial's data file
    if trialTypes(currentTrial) == 1
        BpodSystem.Data.Custom.AssignedAlpha(currentTrial) = LeftAlphas(trialBankIndices(currentTrial));
    else
        BpodSystem.Data.Custom.AssignedAlpha(currentTrial) = RightAlphas(trialBankIndices(currentTrial));
    end
    
    sma = PrepareStateMachine(S, trialTypes(currentTrial), trialBankIndices(currentTrial), BankSize, LeftValveTime, RightValveTime);
    SendStateMachine(sma);
    
    RawEvents = RunStateMachine;
    if ~isempty(fieldnames(RawEvents))
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); 
        States = BpodSystem.Data.RawEvents.Trial{currentTrial}.States;
        
        if ~isnan(States.Reward(1))
            BpodSystem.Data.Custom.Outcomes(currentTrial) = 1;
            TotalRewardAmount = TotalRewardAmount + S.GUI.RewardVolume;
            BpodSystem.Data.Custom.ChoiceLeft(currentTrial) = (trialTypes(currentTrial) == 1); 
        elseif ~isnan(States.Punish(1))
            BpodSystem.Data.Custom.Outcomes(currentTrial) = 2;
            BpodSystem.Data.Custom.ChoiceLeft(currentTrial) = (trialTypes(currentTrial) == 2); 
        elseif ~isnan(States.NoDecision(1))
            BpodSystem.Data.Custom.Outcomes(currentTrial) = 3;
        elseif ~isnan(States.NoTrialStart(1))
            BpodSystem.Data.Custom.Outcomes(currentTrial) = 4;
        end
        
        if ~isnan(States.WaitForChoice(1,1)) && (~isnan(States.Reward(1)) || ~isnan(States.Punish(1)))
            BpodSystem.Data.Custom.MoveTimes(currentTrial) = States.WaitForChoice(1,2) - States.WaitForChoice(1,1);
        end
        
        BpodSystem.Data.TrialSettings(currentTrial) = S; 
        BpodSystem.Data.TrialTypes(currentTrial) = trialTypes(currentTrial); 
        
        PokesPlot('update');
        outcomePlot.update(trialTypes, BpodSystem.Data);
        SaveBpodSessionData;
        
        % Update Custom Metrics Figure
        sgtitle(MetricsFig, ['Total Reward Consumed: ', num2str(TotalRewardAmount), ' uL'], 'FontWeight', 'bold', 'FontSize', 14);
        
        TimeMin = (BpodSystem.Data.TrialStartTimestamp - BpodSystem.Data.TrialStartTimestamp(1)) / 60;
        plot(axRate, TimeMin, 1:currentTrial, 'k-', 'LineWidth', 1.5);
        
        cla(axMove);
        ValidMTs = BpodSystem.Data.Custom.MoveTimes(1:currentTrial);
        histogram(axMove, ValidMTs(~isnan(ValidMTs)), 'BinWidth', 0.25, 'FaceColor', [0.2 0.6 0.8]);
        
        cla(axErr);
        Outs = BpodSystem.Data.Custom.Outcomes(1:currentTrial);
        bar(axErr, 1:4, [sum(Outs==1), sum(Outs==2), sum(Outs==3), sum(Outs==4)], 'FaceColor', [0.5 0.5 0.5]);
        
        cla(axBias);
        LeftTrials = find(trialTypes(1:currentTrial) == 1 & ~isnan(BpodSystem.Data.Custom.ChoiceLeft(1:currentTrial)));
        RightTrials = find(trialTypes(1:currentTrial) == 2 & ~isnan(BpodSystem.Data.Custom.ChoiceLeft(1:currentTrial)));
        
        LeftAcc = sum(BpodSystem.Data.Custom.ChoiceLeft(LeftTrials) == 1) / length(LeftTrials) * 100;
        RightAcc = sum(BpodSystem.Data.Custom.ChoiceLeft(RightTrials) == 0) / length(RightTrials) * 100;
        
        bar(axBias, 1, LeftAcc, 'FaceColor', PokeColors.L);
        bar(axBias, 2, RightAcc, 'FaceColor', PokeColors.R);

        % Live Psychometric Curve (Binned by Alpha)
        cla(axPsych);
        completedTrials = find(~isnan(BpodSystem.Data.Custom.ChoiceLeft(1:currentTrial)));
        
        if ~isempty(completedTrials)
            trialAlphas = BpodSystem.Data.Custom.AssignedAlpha(completedTrials);
            trialCorrect = (BpodSystem.Data.Custom.Outcomes(completedTrials) == 1); 
            
            edges = 1.0:0.5:5.5; 
            binCenters = edges(1:end-1) + 0.25;
            accByBin = NaN(1, length(binCenters));
            
            for b = 1:length(binCenters)
                inBin = (trialAlphas >= edges(b)) & (trialAlphas < edges(b+1));
                if sum(inBin) > 0
                    accByBin(b) = sum(trialCorrect(inBin)) / sum(inBin) * 100;
                end
            end
            
            plot(axPsych, binCenters, accByBin, '-ko', 'LineWidth', 1.5, 'MarkerFaceColor', 'k');
            xline(axPsych, 3.0, 'r--', 'Ambiguous');
        end
    end
    
    HandlePauseCondition;
    if BpodSystem.Status.BeingUsed == 0; return; end 
end

%% State Machine Assembly
function sma = PrepareStateMachine(S, TrialType, BankIndex, BankSize, LeftValveTime, RightValveTime)

if TrialType == 1 % LEFT TRIAL
    CorrectPortIn = 'Port1In';
    ErrorPortIn = 'Port3In';
    RewValve = {'ValveState', 1}; 
    RewardTime = LeftValveTime;
    SoundTrigger = BankIndex - 1; 
else              % RIGHT TRIAL 
    CorrectPortIn = 'Port3In';
    ErrorPortIn = 'Port1In';
    RewValve = {'ValveState', 4}; 
    RewardTime = RightValveTime;
    SoundTrigger = (BankIndex + BankSize) - 1; 
end

ErrorTrigger = (BankSize * 2); 

sma = NewStateMachine();

sma = AddState(sma, 'Name', 'WaitForCenterPoke', ...
    'Timer', 60,...
    'StateChangeConditions', {'Port2In', 'PlayStimulus', 'Tup', 'NoTrialStart'},...
    'OutputActions', {'PWM2', 255}); 

sma = AddState(sma, 'Name', 'PlayStimulus', ...
    'Timer', S.GUI.SoundDuration,...
    'StateChangeConditions', {'Tup', 'WaitForChoice'},...
    'OutputActions', {'HiFi1', ['P' SoundTrigger]}); 

sma = AddState(sma, 'Name', 'WaitForChoice', ...
    'Timer', S.GUI.ResponseTime,...
    'StateChangeConditions', {CorrectPortIn, 'Reward', ErrorPortIn, 'Punish', 'Tup', 'NoDecision'},...
    'OutputActions', {'PWM1', 255, 'PWM3', 255}); 

sma = AddState(sma, 'Name', 'Reward', ...
    'Timer', RewardTime,...
    'StateChangeConditions', {'Tup', 'Drinking'},...
    'OutputActions', RewValve);

sma = AddState(sma, 'Name', 'Drinking', ...
    'Timer', 2,...
    'StateChangeConditions', {'Tup', 'exit'},...
    'OutputActions', {});

sma = AddState(sma, 'Name', 'Punish', ...
    'Timer', S.GUI.ErrorDelay,...
    'StateChangeConditions', {'Tup', 'exit'},...
    'OutputActions', {'HiFi1', ['P' ErrorTrigger]}); 

sma = AddState(sma, 'Name', 'NoDecision', ...
    'Timer', 1,...
    'StateChangeConditions', {'Tup', 'exit'},...
    'OutputActions', {});

sma = AddState(sma, 'Name', 'NoTrialStart', ...
    'Timer', 0.1,...
    'StateChangeConditions', {'Tup', 'exit'},...
    'OutputActions', {});

%% Plotting Helpers
function state_colors = getStateColors
state_colors = struct( ...
    'WaitForCenterPoke', [0.5 0.5 1],...
    'PlayStimulus', 0.75*[1 1 0],...
    'WaitForChoice',[0.5 1 1],... 
    'Reward', [0, 1, 0], ...
    'Drinking', [0, 0.8, 0], ...
    'Punish', [1, 0, 0], ...
    'NoDecision', [0.5, 0, 0], ...
    'NoTrialStart', [0.8, 0.8, 0.8]);

function poke_colors = getPokeColors
poke_colors = struct('L', 0.6*[1 0.66 0], 'C', [0 0 0], 'R', 0.9*[1 0.66 0]);
