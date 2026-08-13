function HiFiSound2AFC_Confidence_ArduinoSync

global BpodSystem 

%% Assert HiFi module is present + USB-paired (via USB button on console GUI)
BpodSystem.assertModule('HiFi', 1); % The second argument (1) indicates that AnalogIn must be paired with its USB serial port
% Create an instance of the HiFi module
H = BpodHiFi(BpodSystem.ModuleUSB.HiFi1); % The argument is the name of the HiFi module's USB serial port (e.g. COM3)

%% Create trial manager object
trialManager = BpodTrialManager;

%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    S.GUI.RewardAmount = 3; %ul
    S.GUI.SoundDuration = 0.5; % Duration of sound (s)
    %S.GUI.SinWaveFreqLeft = 500; % Frequency of left cue
    %S.GUI.SinWaveFreqRight = 2000; % Frequency of right cue
    S.GUI.AlphaHigh = 5;  % High Alpha for High-Freq cloud
    S.GUI.BetaHigh = 1;   % Low Beta for High-Freq cloud
    S.GUI.AlphaLow = 1;   % Low Alpha for Low-Freq cloud
    S.GUI.BetaLow = 5;    % High Beta for Low-Freq cloud

    S.GUI.CueDelay = 0; % How long the mouse must poke in the center to activate the sound
    S.GUI.ResponseTime = 5; % How long until the mouse must make a choice, or forefeit the trial
    S.GUI.RewardDelay = 0; % How long the mouse must wait in the goal port for reward to be delivered
    S.GUI.ErrorSound = 1; % if 1, plays a white noise pulse on error. if 0, no sound is played.
    S.GUI.ErrorDelay = 1; %% How long the mouse must wait to start the next trial if it makes the wrong choice (s)

    S.GUI.MaxSwitchTime = 5; % Time allowed to reach opposite port
    %S.GUIPanels.Task = {'RewardBase','ErrorSound'}; % GUIPanels organize the parameters into groups.
    %S.GUIPanels.Sound = {'SinWaveFreqLeft', 'SinWaveFreqRight', 'SoundDuration'};
    S.GUIPanels.BetaCloud = {'AlphaHigh', 'BetaHigh', 'AlphaLow', 'BetaLow', 'SoundDuration'};
    S.GUIPanels.Time = {'CueDelay', 'RewardDelay', 'ResponseTime', 'ErrorDelay', 'MaxSwitchTime'};
    
end

%% Define trial types
maxTrials = 1000;
trialTypes = ceil(rand(1,maxTrials)*2);
BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
BpodSystem.Data.AnimalInvestment = zeros(1, maxTrials); % Initialize storage for time investment
BpodSystem.Data.OutcomeDuration = zeros(1, maxTrials);

%% Initialize plots

% Initialize the outcome plot 
outcomePlot = LiveOutcomePlot([1 2], {'Left', 'Right'}, trialTypes, 90); % Create an instance of the LiveOutcomePlot GUI
              % Arg1 = trialTypeManifest, a list of possible trial types (even if not yet in trialTypes).
              % Arg2 = trialTypeNames, a list of names for each trial type in trialTypeManifest
              % Arg3 = trialTypes, a list of integers denoting precomputed trial types in the session
              % Arg4 = nTrialsToShow, the number of trials to show
%outcomePlot.CorrectStateNames = {'LeftRewardDelay', 'RightRewardDelay'}; % List of state names where choice was correct
                                                                         % State names are set when states are defined below.
outcomePlot.RewardStateNames = {'DeliverReward'}; % List of state names where reward was delivered, blue
outcomePlot.PunishStateNames = {'DeliverPunish'}; % List of state names where choice was incorrect and negatively reinforced, red
outcomePlot.CorrectStateNames = {'SwitchForReward'}; % Considered correct once they start switching, green

% Initialize Bpod notebook (for manual data annotation)

BpodNotebook('init'); 

% Initialize parameter GUI plugin
BpodParameterGUI('init', S); 


PokesPlot('init', getStateColors, getPokeColors);
useStateTiming = false;
if ~verLessThan('matlab','9.5') % StateTiming plot requires MATLAB r2018b or newer
    useStateTiming = true;
    StateTiming();
end

%% Define stimuli and send to analog module
sf = 192000; % Use max supported sampling rate
H.SamplingRate = sf;
%leftSound = GenerateSineWave(sf, S.GUI.SinWaveFreqLeft, S.GUI.SoundDuration)*.9; 
                             % Sampling freq (hz), Sine frequency (hz), duration (s)
%rightSound = GenerateSineWave(sf, S.GUI.SinWaveFreqRight, S.GUI.SoundDuration)*.9;
leftSound = GenerateBetaCloud(sf, S.GUI.SoundDuration, S.GUI.AlphaLow, S.GUI.BetaLow);
rightSound = GenerateBetaCloud(sf, S.GUI.SoundDuration, S.GUI.AlphaHigh, S.GUI.BetaHigh);
errorSound = GenerateWhiteNoise(sf, S.GUI.ErrorDelay, 1, 2);

% Generate early withdrawal sound
w1 = GenerateSineWave(sf, 1000, .5)*.5; w2 = GenerateSineWave(sf, 1200, .5)*.5; earlyWithdrawalSound = w1+w2;
p = sf/100;
gateVector = repmat([ones(1,p) zeros(1,p)], 1, 25);
earlyWithdrawalSound = earlyWithdrawalSound.*gateVector; % Gate waveform to create aversive pulses

% Setup HiFi module
H.HeadphoneAmpEnabled = true; H.HeadphoneAmpGain = 10; % Ignored if using HD version of the HiFi module
H.DigitalAttenuation_dB = 0; % Set a negative value here if necessary for digital volume control.
H.load(1, leftSound); % Load leftSound to the HiFi module at position 1
H.load(2, rightSound); % Load rightSound to the HiFi module at position 2
H.load(3, errorSound); % Load errorSound to the HiFi module at position 3
H.load(4, earlyWithdrawalSound);
H.push; % Add newly loaded sounds to the current sound set.
% Define 1ms linear ramp envelope of amplitude coefficients, to apply at sound onset + in reverse at sound offset
Envelope = 1/(sf*0.001):1/(sf*0.001):1; 
H.AMenvelope = Envelope;




%% Prepare and start first trial
sma = PrepareStateMachine(S, trialTypes, 1, []); % Prepare state machine for trial 1 with empty "current events" variable
trialManager.startTrial(sma); % Sends & starts running first trial's state machine. A MATLAB timer object updates the 
                              % console UI, while code below proceeds in parallel.

%% Main trial loop
%% Main trial loop
for currentTrial = 1:maxTrials
    S = BpodParameterGUI('sync', S); 
    
    currentTrialEvents = trialManager.getCurrentEvents({'DeliverReward', 'DeliverPunish', 'EarlyWithdrawal', 'TimeOutState'});
    if BpodSystem.Status.BeingUsed == 0; return; end 

    if currentTrial < maxTrials
        % 1. OPTIMIZATION: Do the heavy audio math HERE while the animal is drinking/listening to timeout!
        leftSound = GenerateBetaCloud(sf, S.GUI.SoundDuration, S.GUI.AlphaLow, S.GUI.BetaLow);
        rightSound = GenerateBetaCloud(sf, S.GUI.SoundDuration, S.GUI.AlphaHigh, S.GUI.BetaHigh);
        H.load(1, leftSound);
        H.load(2, rightSound);
        
        % 2. Now build and send the matrix for the next trial
        [sma, S] = PrepareStateMachine(S, trialTypes, currentTrial+1, currentTrialEvents); 
        SendStateMachine(sma, 'RunASAP'); 
    end
    
    % MATLAB is now perfectly ready and waiting to catch the data!
    RawEvents = trialManager.getTrialData;
    
    %% --- EXTRACT TIMING DATA DIRECTLY FROM BPOD STATES ---
    % 1. Extract Raw Investment Time
    % 1. Extract Raw Investment Time
    if isfield(RawEvents.States, 'MeasureCorrectInv') && ~isnan(RawEvents.States.MeasureCorrectInv(1))
        actualInvestment = RawEvents.States.MeasureCorrectInv(1,2) - RawEvents.States.MeasureCorrectInv(1,1);
    elseif isfield(RawEvents.States, 'MeasureErrorInv') && ~isnan(RawEvents.States.MeasureErrorInv(1))
        actualInvestment = RawEvents.States.MeasureErrorInv(1,2) - RawEvents.States.MeasureErrorInv(1,1);
    else
        actualInvestment = 0;
    end
    BpodSystem.Data.AnimalInvestment(currentTrial) = actualInvestment;

    % 2. Extract Scaled Outcome Duration (Valve Open Time or Error Sound Time)
    if isfield(RawEvents.States, 'DeliverReward') && ~isnan(RawEvents.States.DeliverReward(1))
        BpodSystem.Data.OutcomeDuration(currentTrial) = RawEvents.States.DeliverReward(1,2) - RawEvents.States.DeliverReward(1,1);
    elseif isfield(RawEvents.States, 'DeliverPunish') && ~isnan(RawEvents.States.DeliverPunish(1))
        BpodSystem.Data.OutcomeDuration(currentTrial) = RawEvents.States.DeliverPunish(1,2) - RawEvents.States.DeliverPunish(1,1);
    else
        BpodSystem.Data.OutcomeDuration(currentTrial) = 0;
    end

    if BpodSystem.Status.BeingUsed == 0; return; end 
    HandlePauseCondition; 

    if currentTrial < maxTrials
        trialManager.startTrial(); 
    end
    
    if ~isempty(fieldnames(RawEvents)) 
      
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct 
        BpodSystem.Data.TrialTypes(currentTrial) = trialTypes(currentTrial); % Adds the trial type of the current trial to data
        %BpodSystem.Data.TrialInvestment(currentTrial) = S.TrialSpecific.InvestmentDuration;
        PokesPlot('update'); % Update Pokes Plot
        if useStateTiming
            StateTiming();
        end
        outcomePlot.update(trialTypes, BpodSystem.Data); % Update the outcome plot
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end
end

function [sma, S] = PrepareStateMachine(S, TrialTypes, currentTrial, currentTrialEvents)
S = BpodParameterGUI('sync', S); 

% Route the correct ports based on trial type[cite: 1]
if TrialTypes(currentTrial) == 1 
    CorrectInvestPortIn = 'Port1In';
    CorrectInvestPortOut = 'Port1Out';
    CorrectOutcomePortIn = 'Port3In';
    CorrectOutcomeLED = 'PWM3';
    
    ErrorInvestPortIn = 'Port3In';
    ErrorInvestPortOut = 'Port3Out';
    ErrorOutcomePortIn = 'Port1In';
    ErrorOutcomeLED = 'PWM1';
    
    RewValve = {'ValveState', 4}; % Right Valve
    stimulusOutput = {'HiFi1', ['P' 0]}; 
else 
    CorrectInvestPortIn = 'Port3In';
    CorrectInvestPortOut = 'Port3Out';
    CorrectOutcomePortIn = 'Port1In';
    CorrectOutcomeLED = 'PWM1';
    
    ErrorInvestPortIn = 'Port1In';
    ErrorInvestPortOut = 'Port1Out';
    ErrorOutcomePortIn = 'Port3In';
    ErrorOutcomeLED = 'PWM3';

    RewValve = {'ValveState', 1}; % Left Valve
    stimulusOutput = {'HiFi1', ['P' 1]}; 
end

sma = NewStateMachine();

% --- INITIALIZATION ---
sma = AddState(sma, 'Name', 'WaitForPoke', ...
    'Timer', 0,...
    'StateChangeConditions', {'Port2In', 'CueDelay'},...
    'OutputActions', {'HiFi1', '*', 'LED', 2}); 

sma = AddState(sma, 'Name', 'CueDelay', ...
    'Timer', S.GUI.CueDelay,...
    'StateChangeConditions', {'Port2Out', 'EarlyWithdrawal', 'Tup', 'DeliverStimulus'},...
    'OutputActions', {});

sma = AddState(sma, 'Name', 'DeliverStimulus', ...
    'Timer', S.GUI.SoundDuration,...
    'StateChangeConditions', {'Port2Out', 'EarlyWithdrawal', 'Tup', 'WaitForResponse'},...
    'OutputActions', stimulusOutput);

sma = AddState(sma, 'Name', 'WaitForResponse', ...
    'Timer', S.GUI.ResponseTime, ...
    'StateChangeConditions', {CorrectInvestPortIn, 'MeasureCorrectInv', ErrorInvestPortIn, 'MeasureErrorInv', 'Tup', 'TimeOutState'}, ... 
    'OutputActions', {});

% --- INVESTMENT PATHS ---
% We removed the heavy PWM lighting to prevent USB crashes. 
% Bpod drives BNC Out 1 High to tell Arduino to start its stopwatch
sma = AddState(sma, 'Name', 'MeasureCorrectInv', ...
    'Timer', 100, ...
    'StateChangeConditions', {CorrectInvestPortOut, 'SwitchForReward', 'Tup', 'TimeOutState'}, ...
    'OutputActions', {'BNC1', 1}); 

sma = AddState(sma, 'Name', 'MeasureErrorInv', ...
    'Timer', 100, ...
    'StateChangeConditions', {ErrorInvestPortOut, 'SwitchForPunish', 'Tup', 'TimeOutState'}, ...
    'OutputActions', {'BNC1', 1});

% --- THE SWITCH PATHS ---
sma = AddState(sma, 'Name', 'SwitchForReward', ...
    'Timer', S.GUI.MaxSwitchTime, ...
    'StateChangeConditions', {CorrectOutcomePortIn, 'TriggerReward', 'Tup', 'TimeOutState'}, ...
    'OutputActions', {CorrectOutcomeLED, 255});

sma = AddState(sma, 'Name', 'SwitchForPunish', ...
    'Timer', S.GUI.MaxSwitchTime, ...
    'StateChangeConditions', {ErrorOutcomePortIn, 'TriggerPunish', 'Tup', 'TimeOutState'}, ...
    'OutputActions', {ErrorOutcomeLED, 255});

% --- OUTCOME EXECUTION (THE HANDSHAKE) ---

% 1. REWARD
% Drive Wire2 High to tell Arduino "Animal is here, give me the pulse"
sma = AddState(sma, 'Name', 'TriggerReward', ...
    'Timer', 10, ... % Failsafe timeout
    'StateChangeConditions', {'BNC1High', 'DeliverReward', 'Tup', 'TimeOutState'}, ...
    'OutputActions', {'BNC2', 1});

% Open the valve. Stay in this state as long as Arduino holds BNC1 High.
sma = AddState(sma, 'Name', 'DeliverReward', ...
    'Timer', 10, ...
    'StateChangeConditions', {'BNC1Low', 'TimeOutState', 'Tup', 'TimeOutState'}, ...
    'OutputActions', {RewValve{1}, RewValve{2}, 'BNC2', 1}); 

% 2. PUNISHMENT
sma = AddState(sma, 'Name', 'TriggerPunish', ...
    'Timer', 10, ...
    'StateChangeConditions', {'BNC1High', 'DeliverPunish', 'Tup', 'TimeOutState'}, ...
    'OutputActions', {'BNC2', 1});

% Play the sound. Stay in this state as long as Arduino holds BNC1 High.
sma = AddState(sma, 'Name', 'DeliverPunish', ...
    'Timer', 10, ...
    'StateChangeConditions', {'BNC1Low', 'StopPunish', 'Tup', 'StopPunish'}, ...
    'OutputActions', {'HiFi1', ['P' 2], 'BNC2', 1}); 

sma = AddState(sma, 'Name', 'StopPunish', ...
    'Timer', 0, ...
    'StateChangeConditions', {'Tup', 'TimeOutState'}, ...
    'OutputActions', {'HiFi1', ['x' 2]});

% --- TIMEOUT / EXIT ---
sma = AddState(sma, 'Name', 'EarlyWithdrawal', ...
    'Timer', 2, 'StateChangeConditions', {'Tup', 'TimeOutState'}, 'OutputActions', {'HiFi1', ['P' 3]});

sma = AddState(sma, 'Name', 'TimeOutState', ...
    'Timer', 1, 'StateChangeConditions', {'Tup', '>exit'}, 'OutputActions', {});

% --- HELPER FUNCTIONS FOR UI PLOTTING ---

function state_colors = getStateColors
state_colors = struct( ...
    'WaitForPoke', [0.5 0.5 1],...
    'CueDelay',0.3*[1 1 1],...
    'DeliverStimulus', 0.75*[1 1 0],...
    'WaitForResponse',[0.5 1 1],... 
    'MeasureCorrectInv', [.2, .8, .2], ...   % Greenish
    'MeasureErrorInv', [.8, .2, .2], ...     % Reddish
    'SwitchForReward', [.2, .2, 1], ...      
    'SwitchForPunish', [.7, .7, 1], ...      
    'TriggerReward', [0, 1, 0], ...
    'DeliverReward', [0, 1, 0], ...          
    'TriggerPunish', [1, 0, 0], ...
    'DeliverPunish', [1, 0, 0], ...          
    'StopPunish', [1, 0, 0], ...             
    'EarlyWithdrawal', 0.75*[0, 1, 0], ...
    'TimeOutState', [1, 0, 0]);

function poke_colors = getPokeColors
poke_colors = struct( ...
      'L', 0.6*[1 0.66 0], ...
      'C', [0 0 0], ...
      'R',  0.9*[1 0.66 0]);