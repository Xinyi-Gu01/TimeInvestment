function Stage2_difficultAssociation

global BpodSystem 

%% Setup HiFi Module
BpodSystem.assertModule('HiFi', 1); 
H = BpodHiFi(BpodSystem.ModuleUSB.HiFi1); 

%% Define Parameters
S = BpodSystem.ProtocolSettings; 
if isempty(fieldnames(S))  
    S.GUI.RewardVolume = 30; % uL
    S.GUI.SoundDuration = 0.5; % s
    S.GUI.ResponseTime = 10; % s 
    S.GUI.ErrorDelay = 2; % s 
    
    % Easy Stimuli (90% of trials)
    S.GUI.AlphaHigh_Easy = 5;  
    S.GUI.BetaHigh_Easy = 1;   
    S.GUI.AlphaLow_Easy = 1;   
    S.GUI.BetaLow_Easy = 5;   
    
    % Hard Stimuli (10% of trials)
    S.GUI.AlphaHigh_Hard = 3;  
    S.GUI.BetaHigh_Hard = 2;   
    S.GUI.AlphaLow_Hard = 2;   
    S.GUI.BetaLow_Hard = 3;    

    S.GUIPanels.BetaCloud_Easy = {'AlphaHigh_Easy', 'BetaHigh_Easy', 'AlphaLow_Easy', 'BetaLow_Easy', 'SoundDuration'};
    S.GUIPanels.BetaCloud_Hard = {'AlphaHigh_Hard', 'BetaHigh_Hard', 'AlphaLow_Hard', 'BetaLow_Hard'};
    S.GUIPanels.Time = {'ResponseTime', 'ErrorDelay'};
end

%% Initialize GUI and Data arrays
maxTrials = 1000;
trialTypes = ceil(rand(1,maxTrials)*2);
% Generate difficulty array: 90% Easy (1), 10% Hard (2)
trialDifficulties = (rand(1, maxTrials) > 0.9) + 1; 

BpodSystem.Data.TrialTypes = []; 
BpodSystem.Data.TrialDifficulties = []; 
BpodSystem.Data.Custom.MoveTimes = NaN(1, maxTrials);
BpodSystem.Data.Custom.Outcomes = NaN(1, maxTrials); % 1=Rew, 2=Punish, 3=NoDecision, 4=NoTrialStart
BpodSystem.Data.Custom.ChoiceLeft = NaN(1, maxTrials); % 1=Left Choice, 0=Right Choice

TotalRewardAmount = 0; 
PokeColors = getPokeColors;

BpodParameterGUI('init', S); 
BpodNotebook('init'); 
outcomePlot = LiveOutcomePlot([1 2], {'Left', 'Right'}, trialTypes, 90);
outcomePlot.RewardStateNames = {'Reward'}; 
outcomePlot.PunishStateNames = {'Punish'};
PokesPlot('init', getStateColors, PokeColors);

%% Initialize Custom Metrics Figure (Now 5 Panels)
MetricsFig = figure('Name', 'Live Session Metrics', 'Position', [100, 100, 1500, 300], 'NumberTitle', 'off');
axRate = subplot(1,5,1); hold(axRate, 'on'); title(axRate, 'Trial Rate'); xlabel(axRate, 'Time (min)'); ylabel(axRate, 'Trials Started');
axMove = subplot(1,5,2); hold(axMove, 'on'); title(axMove, 'Movement Time'); xlabel(axMove, 'Time (s)'); ylabel(axMove, 'Count');
axErr = subplot(1,5,3); hold(axErr, 'on'); title(axErr, 'Granular Outcomes'); ylabel(axErr, 'Trial Count');
set(axErr, 'XTick', 1:4, 'XTickLabel', {'Rew', 'Pun', 'NoDec', 'NoStart'});
axBias = subplot(1,5,4); hold(axBias, 'on'); title(axBias, 'Side Accuracy (Bias)'); ylabel(axBias, '% Correct');
set(axBias, 'XTick', 1:2, 'XTickLabel', {'Left', 'Right'}, 'YLim', [0 100]);

% NEW: Live Psychometric Panel
axPsych = subplot(1,5,5); hold(axPsych, 'on'); title(axPsych, 'Accuracy by Alpha'); 
xlabel(axPsych, 'Alpha Value'); ylabel(axPsych, '% Correct');
set(axPsych, 'YLim', [0 100], 'XLim', [1 5]);

%% Generate Stimuli (192kHz)
sf = 192000; 
H.SamplingRate = sf;
H.HeadphoneAmpEnabled = false; 

% Generate 4 distinct sound clouds + 1 error sound
leftSound_Easy = GenerateBetaCloud(sf, S.GUI.SoundDuration, S.GUI.AlphaLow_Easy, S.GUI.BetaLow_Easy);
rightSound_Easy = GenerateBetaCloud(sf, S.GUI.SoundDuration, S.GUI.AlphaHigh_Easy, S.GUI.BetaHigh_Easy);
leftSound_Hard = GenerateBetaCloud(sf, S.GUI.SoundDuration, S.GUI.AlphaLow_Hard, S.GUI.BetaLow_Hard);
rightSound_Hard = GenerateBetaCloud(sf, S.GUI.SoundDuration, S.GUI.AlphaHigh_Hard, S.GUI.BetaHigh_Hard);
errorSound = GenerateWhiteNoise(sf, S.GUI.ErrorDelay, 1, 2);

% Load into slots 1 through 5 (Zero-indexed in state machine as 0-4)
H.load(1, leftSound_Easy); 
H.load(2, rightSound_Easy); 
H.load(3, leftSound_Hard); 
H.load(4, rightSound_Hard); 
H.load(5, errorSound); 
H.push;
H.AMenvelope = 1/(sf*0.001):1/(sf*0.001):1; 

%% Main Trial Loop
for currentTrial = 1:maxTrials
    S = BpodParameterGUI('sync', S);
    
    LeftValveTime = GetValveTimes(S.GUI.RewardVolume, 1); 
    RightValveTime = GetValveTimes(S.GUI.RewardVolume, 3);
    
    sma = PrepareStateMachine(S, trialTypes(currentTrial), trialDifficulties(currentTrial), LeftValveTime, RightValveTime);
    SendStateMachine(sma);
    
    RawEvents = RunStateMachine;
    if ~isempty(fieldnames(RawEvents))
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); 
        States = BpodSystem.Data.RawEvents.Trial{currentTrial}.States;
        
        % 1. Extract Granular Outcomes & Choices
        if ~isnan(States.Reward(1))
            BpodSystem.Data.Custom.Outcomes(currentTrial) = 1;
            TotalRewardAmount = TotalRewardAmount + S.GUI.RewardVolume;
            % If rewarded, they chose the correct side
            BpodSystem.Data.Custom.ChoiceLeft(currentTrial) = (trialTypes(currentTrial) == 1); 
            
        elseif ~isnan(States.Punish(1))
            BpodSystem.Data.Custom.Outcomes(currentTrial) = 2;
            % If punished, they chose the wrong side
            BpodSystem.Data.Custom.ChoiceLeft(currentTrial) = (trialTypes(currentTrial) == 2); 
            
        elseif ~isnan(States.NoDecision(1))
            BpodSystem.Data.Custom.Outcomes(currentTrial) = 3;
        elseif ~isnan(States.NoTrialStart(1))
            BpodSystem.Data.Custom.Outcomes(currentTrial) = 4;
        end
        
        % 2. Extract Movement Time 
        if ~isnan(States.WaitForChoice(1,1)) && (~isnan(States.Reward(1)) || ~isnan(States.Punish(1)))
            BpodSystem.Data.Custom.MoveTimes(currentTrial) = States.WaitForChoice(1,2) - States.WaitForChoice(1,1);
        end
        
        BpodSystem.Data.TrialSettings(currentTrial) = S; 
        BpodSystem.Data.TrialTypes(currentTrial) = trialTypes(currentTrial); 
        BpodSystem.Data.TrialDifficulties(currentTrial) = trialDifficulties(currentTrial); 
        
        % 3. Update Standard Bpod Plots
        PokesPlot('update');
        outcomePlot.update(trialTypes, BpodSystem.Data);
        SaveBpodSessionData;
        
        % 4. Update Custom Metrics Figure
        sgtitle(MetricsFig, ['Total Reward Consumed: ', num2str(TotalRewardAmount), ' uL'], 'FontWeight', 'bold', 'FontSize', 14);
        
        % Trial Rate Curve
        TimeMin = (BpodSystem.Data.TrialStartTimestamp - BpodSystem.Data.TrialStartTimestamp(1)) / 60;
        plot(axRate, TimeMin, 1:currentTrial, 'k-', 'LineWidth', 1.5);
        
        % Movement Time Histogram
        cla(axMove);
        ValidMTs = BpodSystem.Data.Custom.MoveTimes(1:currentTrial);
        histogram(axMove, ValidMTs(~isnan(ValidMTs)), 'BinWidth', 0.25, 'FaceColor', [0.2 0.6 0.8]);
        
        % Granular Error Bar Chart
        cla(axErr);
        Outs = BpodSystem.Data.Custom.Outcomes(1:currentTrial);
        bar(axErr, 1:4, [sum(Outs==1), sum(Outs==2), sum(Outs==3), sum(Outs==4)], 'FaceColor', [0.5 0.5 0.5]);
        
        % Bias Plot (Accuracy by Side)
        cla(axBias);
        LeftTrials = find(trialTypes(1:currentTrial) == 1 & ~isnan(BpodSystem.Data.Custom.ChoiceLeft(1:currentTrial)));
        RightTrials = find(trialTypes(1:currentTrial) == 2 & ~isnan(BpodSystem.Data.Custom.ChoiceLeft(1:currentTrial)));
        
        LeftAcc = sum(BpodSystem.Data.Custom.ChoiceLeft(LeftTrials) == 1) / length(LeftTrials) * 100;
        RightAcc = sum(BpodSystem.Data.Custom.ChoiceLeft(RightTrials) == 0) / length(RightTrials) * 100;
        
        bar(axBias, 1, LeftAcc, 'FaceColor', PokeColors.L);
        bar(axBias, 2, RightAcc, 'FaceColor', PokeColors.R);

        % 5. Live Psychometric Curve (Binned by Alpha)
        cla(axPsych);
        % Find trials where the animal actually made a choice
        completedTrials = find(~isnan(BpodSystem.Data.Custom.ChoiceLeft(1:currentTrial)));
        
        if ~isempty(completedTrials)
            % Get the Alphas and Outcomes for completed trials
            trialAlphas = BpodSystem.Data.Custom.AssignedAlpha(completedTrials);
            % Outcome 1 means Rewarded (Correct)
            trialCorrect = (BpodSystem.Data.Custom.Outcomes(completedTrials) == 1); 
            
            % Define bin edges from 1.0 to 5.0 in steps of 0.5
            edges = 1.0:0.5:5.5; 
            binCenters = edges(1:end-1) + 0.25;
            accByBin = NaN(1, length(binCenters));
            
            % Calculate accuracy for each bin
            for b = 1:length(binCenters)
                inBin = (trialAlphas >= edges(b)) & (trialAlphas < edges(b+1));
                if sum(inBin) > 0
                    accByBin(b) = sum(trialCorrect(inBin)) / sum(inBin) * 100;
                end
            end
            
            % Plot the curve
            plot(axPsych, binCenters, accByBin, '-ko', 'LineWidth', 1.5, 'MarkerFaceColor', 'k');
            
            % Draw a red dashed line at 3.0 to mark the theoretical ambiguous center
            xline(axPsych, 3.0, 'r--', 'Ambiguous');
        end
    end
    
    HandlePauseCondition;
    if BpodSystem.Status.BeingUsed == 0; return; end 
end

%% State Machine Assembly
function sma = PrepareStateMachine(S, TrialType, Difficulty, LeftValveTime, RightValveTime)

if TrialType == 1 % LEFT TRIAL
    CorrectPortIn = 'Port1In';
    ErrorPortIn = 'Port3In';
    RewValve = {'ValveState', 1}; 
    RewardTime = LeftValveTime;
    
    if Difficulty == 1
        Stimulus = {'HiFi1', ['P' 0]}; % Slot 1: Easy Left
    else
        Stimulus = {'HiFi1', ['P' 2]}; % Slot 3: Hard Left
    end
else              % RIGHT TRIAL 
    CorrectPortIn = 'Port3In';
    ErrorPortIn = 'Port1In';
    RewValve = {'ValveState', 4}; 
    RewardTime = RightValveTime;
    
    if Difficulty == 1
        Stimulus = {'HiFi1', ['P' 1]}; % Slot 2: Easy Right
    else
        Stimulus = {'HiFi1', ['P' 3]}; % Slot 4: Hard Right
    end
end

sma = NewStateMachine();

% 1. Wait for Center Poke
sma = AddState(sma, 'Name', 'WaitForCenterPoke', ...
    'Timer', 60,...
    'StateChangeConditions', {'Port2In', 'PlayStimulus', 'Tup', 'NoTrialStart'},...
    'OutputActions', {'PWM2', 255}); 

% 2. Play Sound 
sma = AddState(sma, 'Name', 'PlayStimulus', ...
    'Timer', S.GUI.SoundDuration,...
    'StateChangeConditions', {'Tup', 'WaitForChoice'},...
    'OutputActions', Stimulus);

% 3. Wait for Choice 
sma = AddState(sma, 'Name', 'WaitForChoice', ...
    'Timer', S.GUI.ResponseTime,...
    'StateChangeConditions', {CorrectPortIn, 'Reward', ErrorPortIn, 'Punish', 'Tup', 'NoDecision'},...
    'OutputActions', {'PWM1', 255, 'PWM3', 255}); 

% 4. Immediate Fixed Reward
sma = AddState(sma, 'Name', 'Reward', ...
    'Timer', RewardTime,...
    'StateChangeConditions', {'Tup', 'Drinking'},...
    'OutputActions', RewValve);

% 5. Drinking grace period 
sma = AddState(sma, 'Name', 'Drinking', ...
    'Timer', 2,...
    'StateChangeConditions', {'Tup', 'exit'},...
    'OutputActions', {});

% 6. Immediate Punishment
sma = AddState(sma, 'Name', 'Punish', ...
    'Timer', S.GUI.ErrorDelay,...
    'StateChangeConditions', {'Tup', 'exit'},...
    'OutputActions', {'HiFi1', ['P' 4]}); % UPDATED: Slot 5 is now the error noise

% 7. Granular Error States
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