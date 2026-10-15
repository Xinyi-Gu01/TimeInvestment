function Stage2_ContinuousPsychometric

global BpodSystem 

%% Setup HiFi Module
BpodSystem.assertModule('HiFi', 1); 
H = BpodHiFi(BpodSystem.ModuleUSB.HiFi1); 

%% Define Parameters
S = BpodSystem.ProtocolSettings; 
if isempty(fieldnames(S))  
    S.GUI.RewardVolume = 30; % uL
    S.GUI.SoundDuration = 0.5; % s
    
    % New Pre-Stimulus & Grace Parameters
    S.GUI.CueDelay = 0.1; % s (100 ms wait before sound)
    S.GUI.CenterGrace = 0.15; % s (Grace period for brief withdrawals)
    
    S.GUI.ResponseTime = 5; % s 
    S.GUI.ErrorDelay = 2; % s (Timeout for wrong port choice)
    S.GUI.EarlyWithdrawalDelay = 1; % s (Timeout for breaking fixation)
    
    % Beta Distribution Parameters for Difficulty Generation
    S.GUI.TaskDiffAlpha = 0.5; % 0.5 = U-Curve, 1.0 = Flat
    S.GUI.TaskDiffBeta = 0.5;  % 0.5 = U-Curve, 1.0 = Flat
    
    S.GUIPanels.Difficulty = {'TaskDiffAlpha', 'TaskDiffBeta'};
    S.GUIPanels.Time = {'CueDelay', 'SoundDuration', 'CenterGrace', 'ResponseTime', 'ErrorDelay', 'EarlyWithdrawalDelay'};
end

%% Initialize GUI and Data Arrays
maxTrials = 1000;

% INITIALIZE WITH REAL VALUES (No longer a dummy array)
trialProbs = betarnd(S.GUI.TaskDiffAlpha, S.GUI.TaskDiffBeta, 1, maxTrials);
trialTypes = (trialProbs >= 0.5) + 1; % 1 = Left, 2 = Right

% NEW: Trackers to detect manual GUI changes
LastTaskDiffAlpha = S.GUI.TaskDiffAlpha;
LastTaskDiffBeta = S.GUI.TaskDiffBeta;

BpodSystem.Data.TrialTypes = [];
BpodSystem.Data.Custom.HighToneProb = NaN(1, maxTrials); 
BpodSystem.Data.Custom.MoveTimes = NaN(1, maxTrials);
BpodSystem.Data.Custom.Outcomes = NaN(1, maxTrials); % 1=Rew, 2=Pun, 3=NoDec, 4=EarlyW
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
set(axErr, 'XTick', 1:4, 'XTickLabel', {'Rew', 'Pun', 'NoDec', 'EarlyW'});
axBias = subplot(1,5,4); hold(axBias, 'on'); title(axBias, 'Side Accuracy (Bias)'); ylabel(axBias, '% Correct');
set(axBias, 'XTick', 1:2, 'XTickLabel', {'Left', 'Right'}, 'YLim', [0 100]);
axPsych = subplot(1,5,5); hold(axPsych, 'on'); title(axPsych, 'Accuracy by Stimulus Proportion'); 
xlabel(axPsych, 'Proportion of High Tones'); ylabel(axPsych, '% Rightward Choice');
set(axPsych, 'YLim', [0 100], 'XLim', [0 1]);

%% Pre-Load Static Error Sound (192kHz)
sf = 192000; 
H.SamplingRate = sf;
H.HeadphoneAmpEnabled = false; 

errorSound = GenerateWhiteNoise(sf, S.GUI.ErrorDelay, 1, 2);
H.load(2, errorSound); % Load Error sound permanently to Slot 2
H.push;
H.AMenvelope = 1/(sf*0.001):1/(sf*0.001):1; 

%% Main Trial Loop
for currentTrial = 1:maxTrials
    S = BpodParameterGUI('sync', S);
    
    LeftValveTime = GetValveTimes(S.GUI.RewardVolume, 1); 
    RightValveTime = GetValveTimes(S.GUI.RewardVolume, 3);
    
    % 1. DYNAMIC DIFFICULTY GENERATION (Only triggers if GUI is changed)
    if S.GUI.TaskDiffAlpha ~= LastTaskDiffAlpha || S.GUI.TaskDiffBeta ~= LastTaskDiffBeta
        disp('Difficulty parameters changed! Regenerating future trials...');
        
        % Overwrite only the trials that haven't happened yet
        futureTrials = currentTrial:maxTrials;
        futureProbs = betarnd(S.GUI.TaskDiffAlpha, S.GUI.TaskDiffBeta, 1, length(futureTrials));
        trialProbs(futureTrials) = futureProbs;
        trialTypes(futureTrials) = (futureProbs >= 0.5) + 1;
        
        % Reset the trackers to the new values
        LastTaskDiffAlpha = S.GUI.TaskDiffAlpha;
        LastTaskDiffBeta = S.GUI.TaskDiffBeta;
    end
    
    tProb = trialProbs(currentTrial);
    BpodSystem.Data.Custom.HighToneProb(currentTrial) = tProb;
    
    % 2. GENERATE ON-THE-FLY STIMULUS
    snd = GenerateCategoricalCloud(sf, S.GUI.SoundDuration, tProb);
    H.load(1, snd); 
    H.push;
    
    sma = PrepareStateMachine(S, trialTypes(currentTrial), LeftValveTime, RightValveTime);
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
        elseif ~isnan(States.EarlyWithdrawal(1))
            BpodSystem.Data.Custom.Outcomes(currentTrial) = 4;
        end
        
        if ~isnan(States.WaitForChoice(1,1)) && (~isnan(States.Reward(1)) || ~isnan(States.Punish(1)))
            BpodSystem.Data.Custom.MoveTimes(currentTrial) = States.WaitForChoice(1,2) - States.WaitForChoice(1,1);
        end
        
        BpodSystem.Data.TrialSettings(currentTrial) = S; 
        BpodSystem.Data.TrialTypes(currentTrial) = trialTypes(currentTrial); 
        
        PokesPlot('update');
        % FIX: Pass the full array so Bpod perfectly maps outcomes to the blue dots
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

       % 5. Live Psychometric Curve (Plotting % Rightward Choices)
        cla(axPsych);
        completedTrials = find(~isnan(BpodSystem.Data.Custom.ChoiceLeft(1:currentTrial)));
        
        if ~isempty(completedTrials)
            tProbs = BpodSystem.Data.Custom.HighToneProb(completedTrials);
            tChoseRight = (BpodSystem.Data.Custom.ChoiceLeft(completedTrials) == 0); 
            
            edges = 0.0:0.1:1.0; 
            binCenters = edges(1:end-1) + 0.05;
            pctRightByBin = NaN(1, length(binCenters));
            
            for b = 1:length(binCenters)
                inBin = (tProbs >= edges(b)) & (tProbs < edges(b+1));
                if sum(inBin) > 0
                    pctRightByBin(b) = sum(tChoseRight(inBin)) / sum(inBin) * 100;
                end
            end
            
            plot(axPsych, binCenters, pctRightByBin, '-ko', 'LineWidth', 1.5, 'MarkerFaceColor', 'k');
            xline(axPsych, 0.5, 'r--', 'Ambiguous'); 
            yline(axPsych, 50, 'r--'); 
        end
    end
    
    HandlePauseCondition;
    if BpodSystem.Status.BeingUsed == 0
        [SessionPath, SessionName, ~] = fileparts(BpodSystem.Path.CurrentDataFile);
        saveas(MetricsFig, fullfile(SessionPath, [SessionName, '_Metrics.png']));
        savefig(MetricsFig, fullfile(SessionPath, [SessionName, '_Metrics.fig']));
        return; 
    end 
end

%% State Machine Assembly
function sma = PrepareStateMachine(S, TrialType, LeftValveTime, RightValveTime)

if TrialType == 1 % LEFT TRIAL
    CorrectPortIn = 'Port1In';
    ErrorPortIn = 'Port3In';
    RewValve = {'ValveState', 1}; 
    RewardTime = LeftValveTime;
else              % RIGHT TRIAL 
    CorrectPortIn = 'Port3In';
    ErrorPortIn = 'Port1In';
    RewValve = {'ValveState', 4}; 
    RewardTime = RightValveTime;
end

sma = NewStateMachine();

sma = AddState(sma, 'Name', 'WaitForCenterPoke', ...
    'Timer', 0,...
    'StateChangeConditions', {'Port2In', 'CueDelay'},...
    'OutputActions', {'PWM2', 255}); 

sma = AddState(sma, 'Name', 'CueDelay', ...
    'Timer', S.GUI.CueDelay,...
    'StateChangeConditions', {'Port2Out', 'CenterGrace', 'Tup', 'PlayStimulus'},...
    'OutputActions', {});

sma = AddState(sma, 'Name', 'PlayStimulus', ...
    'Timer', S.GUI.SoundDuration,...
    'StateChangeConditions', {'Port2Out', 'CenterGrace', 'Tup', 'WaitForChoice'},...
    'OutputActions', {'HiFi1', ['P' 0]}); 

sma = AddState(sma, 'Name', 'CenterGrace', ...
    'Timer', S.GUI.CenterGrace, ... 
    'StateChangeConditions', {'Port2In', '>back', 'Tup', 'EarlyWithdrawal'}, ...
    'OutputActions', {});

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
    'OutputActions', {'HiFi1', ['P' 1]}); 

sma = AddState(sma, 'Name', 'EarlyWithdrawal', ...
    'Timer', S.GUI.EarlyWithdrawalDelay, ...
    'StateChangeConditions', {'Tup', 'exit'}, ...
    'OutputActions', {'HiFi1', ['P' 1]}); % Play Error Sound 

sma = AddState(sma, 'Name', 'NoDecision', ...
    'Timer', 1,...
    'StateChangeConditions', {'Tup', 'exit'},...
    'OutputActions', {});

%% Plotting Helpers
function state_colors = getStateColors
state_colors = struct( ...
    'WaitForCenterPoke', [0.5 0.5 1],...
    'CueDelay', 0.8*[1 1 1],...
    'PlayStimulus', 0.75*[1 1 0],...
    'CenterGrace', 0.5*[1 1 1],...
    'WaitForChoice',[0.5 1 1],... 
    'Reward', [0, 1, 0], ...
    'Drinking', [0, 0.8, 0], ...
    'Punish', [1, 0, 0], ...
    'EarlyWithdrawal', [1, 0.5, 0], ...
    'NoDecision', [0.5, 0, 0]);

function poke_colors = getPokeColors
poke_colors = struct('L', 0.6*[1 0.66 0], 'C', [0 0 0], 'R', 0.9*[1 0.66 0]);