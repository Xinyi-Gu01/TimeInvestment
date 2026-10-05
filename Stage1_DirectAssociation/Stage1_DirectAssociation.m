function Stage1_DirectAssociation

global BpodSystem 

%% Setup HiFi Module
BpodSystem.assertModule('HiFi', 1); 
H = BpodHiFi(BpodSystem.ModuleUSB.HiFi1); 

%% Define Parameters
S = BpodSystem.ProtocolSettings; 
if isempty(fieldnames(S))  
    S.GUI.RewardVolume = 30; % uL - Generous for initial training
    S.GUI.SoundDuration = 0.5; % s
    S.GUI.ResponseTime = 10; % s - Give them plenty of time to find the port
    S.GUI.ErrorDelay = 2; % s - Short timeout for errors
    
    S.GUI.AlphaHigh = 5;  
    S.GUI.BetaHigh = 1;   
    S.GUI.AlphaLow = 1;   
    S.GUI.BetaLow = 5;    
    S.GUIPanels.BetaCloud = {'AlphaHigh', 'BetaHigh', 'AlphaLow', 'BetaLow', 'SoundDuration'};
    S.GUIPanels.Time = {'ResponseTime', 'ErrorDelay'};
end

%% Initialize GUI and Data
maxTrials = 1000;
trialTypes = ceil(rand(1,maxTrials)*2);
BpodSystem.Data.TrialTypes = []; 

BpodParameterGUI('init', S); 
BpodNotebook('init'); 
outcomePlot = LiveOutcomePlot([1 2], {'Left', 'Right'}, trialTypes, 90);
outcomePlot.RewardStateNames = {'Reward'}; 
outcomePlot.PunishStateNames = {'Punish'};
PokesPlot('init', getStateColors, getPokeColors);

%% Generate Stimuli (192kHz)
sf = 192000; 
H.SamplingRate = sf;
H.HeadphoneAmpEnabled = false; % Keep disabled for powered speakers

leftSound = GenerateBetaCloud(sf, S.GUI.SoundDuration, S.GUI.AlphaLow, S.GUI.BetaLow);
rightSound = GenerateBetaCloud(sf, S.GUI.SoundDuration, S.GUI.AlphaHigh, S.GUI.BetaHigh);
errorSound = GenerateWhiteNoise(sf, S.GUI.ErrorDelay, 1, 2);

H.load(1, leftSound); 
H.load(2, rightSound); 
H.load(3, errorSound); 
H.push;
H.AMenvelope = 1/(sf*0.001):1/(sf*0.001):1; 

%% Main Trial Loop
for currentTrial = 1:maxTrials
    S = BpodParameterGUI('sync', S);
    
    % Get valve open times for the fixed reward volume
    % Assumes you have run Bpod's LiquidCalibrator app and saved the curves
    LeftValveTime = GetValveTimes(S.GUI.RewardVolume, 1); 
    RightValveTime = GetValveTimes(S.GUI.RewardVolume, 3);
    
    % Prepare State Machine
    sma = PrepareStateMachine(S, trialTypes(currentTrial), LeftValveTime, RightValveTime);
    SendStateMachine(sma);
    
    RawEvents = RunStateMachine;
    
    if ~isempty(fieldnames(RawEvents))
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); 
        BpodSystem.Data.TrialSettings(currentTrial) = S; 
        BpodSystem.Data.TrialTypes(currentTrial) = trialTypes(currentTrial); 
        
        PokesPlot('update');
        outcomePlot.update(trialTypes, BpodSystem.Data);
        SaveBpodSessionData;
    end
    
    HandlePauseCondition;
    if BpodSystem.Status.BeingUsed == 0; return; end 
end

%% State Machine Assembly
function sma = PrepareStateMachine(S, TrialType, LeftValveTime, RightValveTime)

if TrialType == 1 % LEFT TRIAL (Plots as Left)
    CorrectPortIn = 'Port1In';
    ErrorPortIn = 'Port3In';
    CorrectLED = {'PWM1', 255}; % Left LED
    RewValve = {'ValveState', 1}; % Left Valve
    RewardTime = LeftValveTime;
    Stimulus = {'HiFi1', ['P' 1]}; 
else              % RIGHT TRIAL (Plots as Right)
    CorrectPortIn = 'Port3In';
    ErrorPortIn = 'Port1In';
    CorrectLED = {'PWM3', 255}; % Right LED
    RewValve = {'ValveState', 4}; % Right Valve
    RewardTime = RightValveTime;
    Stimulus = {'HiFi1', ['P' 0]}; 
end

sma = NewStateMachine();

% 1. Guide animal to Center Port
sma = AddState(sma, 'Name', 'WaitForCenterPoke', ...
    'Timer', 0,...
    'StateChangeConditions', {'Port2In', 'PlayStimulus'},...
    'OutputActions', {'PWM2', 255}); % Illuminate Center Port

% 2. Play Sound (Animal can leave immediately in Stage 1)
sma = AddState(sma, 'Name', 'PlayStimulus', ...
    'Timer', S.GUI.SoundDuration,...
    'StateChangeConditions', {'Tup', 'WaitForChoice'},...
    'OutputActions', Stimulus);

% 3. Guide animal to Correct Side Port
sma = AddState(sma, 'Name', 'WaitForChoice', ...
    'Timer', S.GUI.ResponseTime,...
    'StateChangeConditions', {CorrectPortIn, 'Reward', ErrorPortIn, 'Punish', 'Tup', 'TimeOut'},...
    'OutputActions', CorrectLED); % ONLY illuminate the correct port to guide them

% 4. Immediate Fixed Reward (No Arduino Handshake)
sma = AddState(sma, 'Name', 'Reward', ...
    'Timer', RewardTime,...
    'StateChangeConditions', {'Tup', 'Drinking'},...
    'OutputActions', RewValve);

% 5. Drinking grace period (allows them to finish the drop before resetting)
sma = AddState(sma, 'Name', 'Drinking', ...
    'Timer', 2,...
    'StateChangeConditions', {'Tup', 'exit'},...
    'OutputActions', {});

% 6. Immediate Punishment
sma = AddState(sma, 'Name', 'Punish', ...
    'Timer', S.GUI.ErrorDelay,...
    'StateChangeConditions', {'Tup', 'exit'},...
    'OutputActions', {'HiFi1', ['P' 2]}); % Play error sound

% 7. Omission Timeout
sma = AddState(sma, 'Name', 'TimeOut', ...
    'Timer', 1,...
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
    'TimeOut', [0.5, 0, 0]);

function poke_colors = getPokeColors
poke_colors = struct('L', 0.6*[1 0.66 0], 'C', [0 0 0], 'R', 0.9*[1 0.66 0]);