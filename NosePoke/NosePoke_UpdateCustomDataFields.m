function NosePoke_UpdateCustomDataFields(iTrial)

global BpodSystem
global TaskParameters

% data structure references
RawData = BpodSystem.Data.RawData;
RawEvents = BpodSystem.Data.RawEvents;
TrialStates = RawEvents.Trial{iTrial}.States;
TrialData = BpodSystem.Data.Custom.TrialData;

BpodSystem.Data.TrialTypes(iTrial) = 1;

%% OutcomeRecord
% Go through the states visited this trial and 
idxStatesVisited = RawData.OriginalStateData{iTrial};
TrialStateNames = RawData.OriginalStateNamesByNumber{iTrial};
StatesThisTrial = TrialStateNames(idxStatesVisited);

%% Peri-trial initiation
if any(strcmp('StartCIn', StatesThisTrial))
    TrialData.NoTrialStart(iTrial) = false;
    TrialData.TimeCenterPoke(iTrial) = TrialStates.StartCIn(1,1);
end

if any(strcmp('BrokeFixation', StatesThisTrial))
    TrialData.BrokeFixation(iTrial) = true;
elseif any(strcmp('Sampling', StatesThisTrial))
    TrialData.BrokeFixation(iTrial) = false;
end

% Compute length of SamplingGrace, i.e. Grace Period for Center pokes
if any(strcmp('SamplingGrace', StatesThisTrial))
    RegisteredWithdrawals = TrialStates.SamplingGrace;

    for iExit = 1:size(RegisteredWithdrawals,1) % one may enter SamplingGrace multiple time, i_exit is the number of time
        ExitTime = RegisteredWithdrawals(iExit,1);
        ReturnTime = RegisteredWithdrawals(iExit,2);
        TrialData.SamplingGrace(iExit, iTrial) = (ReturnTime - ExitTime);
    end
end  

% Get total amount of time spent waiting for stimulus, only make sense if
% not CenterPortBaited
if any(strcmp('Sampling', StatesThisTrial))
    SamplingBegin = TrialStates.Sampling(1,1);
    if any(strcmp('WaterC', StatesThisTrial))
        SamplingEnd = TrialStates.Sampling(end,end);
    elseif any(strcmp('StillSampling', StatesThisTrial))
        SamplingEnd = TrialStates.StillSampling(1,2);
    elseif any(strcmp('BrokeFixation', StatesThisTrial))
        SamplingEnd = TrialStates.SamplingGrace(end,end); 
    end
    TrialData.SamplingTime(iTrial) = SamplingEnd - SamplingBegin;
end

if TrialData.CenterPortBaited(iTrial) == true % if not Baited, remains NaN
    if any(strcmp('WaterC', StatesThisTrial))
        TrialData.CenterPortRewarded(iTrial) = true;
    elseif any(strcmp('Sampling', StatesThisTrial))
        TrialData.CenterPortRewarded(iTrial) = false;
    end
end

%% Peri-decision and pre-outcome
if any(strcmp('NoDecision', StatesThisTrial))
    TrialData.NoDecision(iTrial) = true;
elseif any(strcmp('StartLIn', StatesThisTrial)) || any(strcmp('StartRIn',StatesThisTrial))
    TrialData.NoDecision(iTrial) = false;
end

if any(strcmp('WaitSIn', StatesThisTrial)) % could be bimodal since DrinkingC may not fully capture "drinking"
    TrialData.MoveTime(iTrial) = TrialStates.WaitSIn(1, 2) - TrialStates.WaitSIn(1, 1); % from CenterPortOut to SidePortIn, old MT confirmed
end

if any(strcmp('StartLIn', StatesThisTrial))
    TrialData.TimeChoice(iTrial) = TrialStates.StartLIn(1,2);
    TrialData.ChoiceLeft(iTrial) = 1;
    if TrialData.LightLeft(iTrial) == 0
        TrialData.IncorrectChoice(iTrial) = true;
    end
elseif any(strcmp('StartRIn', StatesThisTrial))
    TrialData.TimeChoice(iTrial) = TrialStates.StartRIn(1,2);
    TrialData.ChoiceLeft(iTrial) = 0;
    if TrialData.LightLeft(iTrial) == 1
        TrialData.IncorrectChoice(iTrial) = true;
    end
end

%% Peri-stimulus delivery and Pre-decision
RegisteredWithdrawals = [];
if any(strcmp('LInGrace', StatesThisTrial))
    RegisteredWithdrawals = TrialStates.LInGrace;
elseif any(strcmp('RInGrace', StatesThisTrial))
    RegisteredWithdrawals = TrialStates.RInGrace;
end
if ~isempty(RegisteredWithdrawals)
    for iExit = 1:size(RegisteredWithdrawals, 1) % one may enter SamplingGrace multiple time, i_exit is the number of time
        ExitTime = RegisteredWithdrawals(iExit, 1);
        ReturnTime = RegisteredWithdrawals(iExit, 2);
        TrialData.FeedbackGrace(iExit, iTrial) = (ReturnTime - ExitTime);
    end
end


if any(strcmp('StartLIn', StatesThisTrial))
    WaitBegin = TrialStates.StartLIn(1, 1);
    WaitEnd = TrialStates.LIn(end, 2);
    TrialData.FeedbackWaitingTime(iTrial) = WaitEnd - WaitBegin;
elseif any(strcmp('StartRIn',StatesThisTrial))
    WaitBegin = TrialStates.StartRIn(1, 1);
    WaitEnd = TrialStates.RIn(end, 2);
    TrialData.FeedbackWaitingTime(iTrial) = WaitEnd - WaitBegin;
end

if any(strcmp('SkippedFeedback',StatesThisTrial))
    TrialData.TimeSkippedFeedback(iTrial) = TrialStates.SkippedFeedback(1, 1);
    TrialData.SkippedFeedback(iTrial) = true; % True if SkippedFeedback
elseif any(strcmp('WaterL',StatesThisTrial)) || any(strcmp('WaterR',StatesThisTrial)) || any(strcmp('IncorrectChoice',StatesThisTrial))
   TrialData.SkippedFeedback(iTrial) = false;
end

%% Peri-outcome
if any(strcmp('WaterL', StatesThisTrial)) || any(strcmp('WaterR', StatesThisTrial)) % if a choice is made (no matter SingleSidePoke) 
    TrialData.Rewarded(iTrial) = true;
elseif ~isnan(TrialData.ChoiceLeft(iTrial)) % either incorrect, not baited, or skipped
    TrialData.Rewarded(iTrial) = false;
end    
    
if TrialData.Rewarded(iTrial) == true
    if any(strcmp('WaterL', StatesThisTrial))
        TrialData.TimeReward(iTrial) = TrialStates.WaterL(1, 1);
    elseif any(strcmp('WaterR', StatesThisTrial))
        TrialData.TimeReward(iTrial) = TrialStates.WaterR(1, 1);
    end
end

NotBaitedAction = TaskParameters.GUIMeta.NotBaitedFeedback.String{TaskParameters.GUI.NotBaitedFeedback};
if NotBaitedAction == "WhiteNoise" || NotBaitedAction == "Beep"
    TrialData.TimeNotBaitedFeedback(iTrial) = TrialStates.NotBaited(1, 1);
end

if TrialData.Rewarded(iTrial) == true
    DrinkingBegin = TrialStates.Drinking(1, 1);
    DrinkingEnd = TrialStates.Drinking(end, 2); 
    TrialData.DrinkingTime(iTrial) = DrinkingEnd - DrinkingBegin;
end

%% obsolete
%{
Compute: 
- movement times: the time spent to reach the side pokes 
- delay times: time spent in side poke.
    necessary to account for false exit lengths 
    (only want last exit - first entry)
%}
% if any(strcmp('EarlyWithdrawal', StatesThisTrial))
%     TrialData.EarlyWithdrawal(iTrial) = true;
% elseif any_wait_L || any_wait_R
%     MoveBegin = TrialStates.WaitSIn(1,1);
%     
%     if any(strcmp('StartLIn', StatesThisTrial))
%         TrialData.ChoiceLeft(iTrial) = 1;
%         MoveEnd = TrialStates.StartLIn(1,1);
%     elseif any(strcmp('StartRIn', StatesThisTrial))
%         TrialData.ChoiceLeft(iTrial) = 0;
%         MoveEnd = TrialStates.wait_R_start;
%     end
% 
%     TrialData.move_time(iTrial) = MoveEnd(1,2) - MoveBegin;
% 
%     t_first_entry = MoveEnd(1,1);
%     
%     t_last_exit = MoveEnd(end,end);
%     TrialData.port_entry_delay(iTrial) = t_last_exit - t_first_entry; 
% end
% 
% if any(strncmp('water_L', StatesThisTrial,7)) 
%     TrialData.Rewarded(iTrial) = true;
% elseif any(strncmp('water_R', StatesThisTrial,7)) 
%     TrialData.Rewarded(iTrial) = true;
% end
% 
% if any(strcmp('water_LJackpot',StatesThisTrial)) || any(strcmp('water_RJackpot',StatesThisTrial))
%     TrialData.Jackpot(iTrial) = true;
%     TrialData.Rewarded(iTrial) = true;
%     if any(strcmp('water_LJackpot',StatesThisTrial))
%         TrialData.move_time(iTrial) = TrialStates.water_LJackpot(1,2) - TrialStates.WaitSInJackpot(1,1);
%     elseif any(strcmp('water_RJackpot', StatesThisTrial))
%         TrialData.move_time(iTrial) = TrialStates.water_RJackpot(1,2) - TrialStates.WaitSInJackpot(1,1);
%     end
% end

BpodSystem.Data.Custom.TrialData = TrialData;
end