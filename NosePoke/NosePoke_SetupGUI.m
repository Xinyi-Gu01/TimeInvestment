function TaskParameters = NosePoke_SetupGUI()

global BpodSystem

%% Task parameters
TaskParameters = BpodSystem.ProtocolSettings;

if isempty(fieldnames(TaskParameters))
    %% general
    TaskParameters.GUI.SessionDescription = 'First NosePoke';
    TaskParameters.GUIMeta.SessionDescription.Style = 'edittext';

    TaskParameters.GUI.Ports_LMR = '123';
    TaskParameters.GUI.EphysSession = false;
    TaskParameters.GUIMeta.EphysSession.Style = 'checkbox';
    TaskParameters.GUI.Wire1VideoTrigger = 1;
    TaskParameters.GUIMeta.Wire1VideoTrigger.Style = 'popupmenu';
    TaskParameters.GUIMeta.Wire1VideoTrigger.String = {'None', 'Investment', 'All'};

    TaskParameters.GUI.PreITI = 1.5;
    TaskParameters.GUI.WaitCInMax = 15; % max waiting time for C_in before a new trial starts, useful to track progress
    TaskParameters.GUI.ChoiceDeadline = 3; % max waiting time for S_in after stimuli
    TaskParameters.GUI.NoDecisionTimeOut = 3; % (s) where subject chooses the side poke without light
    TaskParameters.GUI.NoDecisionFeedback = 2; % feedback for NoDecision
    TaskParameters.GUIMeta.NoDecisionFeedback.Style = 'popupmenu';
    TaskParameters.GUIMeta.NoDecisionFeedback.String = {'None', 'WhiteNoise'};
    
    TaskParameters.GUI.SingleSidePoke = 0;
    TaskParameters.GUIMeta.SingleSidePoke.Style = 'checkbox'; % old light-guided
    TaskParameters.GUI.IncorrectChoiceTimeOut = 3; % (s), for single-side poke settings only, where subject chooses the side poke without light
    TaskParameters.GUI.IncorrectChoiceFeedback = 2; % feedback for IncorrectChoice
    TaskParameters.GUIMeta.IncorrectChoiceFeedback.Style = 'popupmenu';
    TaskParameters.GUIMeta.IncorrectChoiceFeedback.String = {'None', 'WhiteNoise'};
    
    TaskParameters.GUI.ITI = 3; % end of trial ITI
    TaskParameters.GUI.VI = false; % exprnd based on ITI
    TaskParameters.GUIMeta.VI.Style = 'checkbox';
    
    TaskParameters.GUIPanels.General = {'SessionDescription', 'Ports_LMR', 'EphysSession',...
                                        'Wire1VideoTrigger',...
                                        'PreITI', 'WaitCInMax', 'ChoiceDeadline',...
                                        'NoDecisionTimeOut', 'NoDecisionFeedback',...
                                        'SingleSidePoke',...
                                        'IncorrectChoiceTimeOut', 'IncorrectChoiceFeedback',...
                                        'ITI', 'VI'};
    
    %% Sampling (learn to stay in centre port long enough)
    TaskParameters.GUI.AutoIncrSamplingTarget = 1;
    TaskParameters.GUIMeta.AutoIncrSamplingTarget.Style = 'checkbox';
    
    TaskParameters.GUI.SamplingTargetMin = 0.1;
    TaskParameters.GUI.SamplingTargetMax = 0.8;
    
    TaskParameters.GUI.SamplingTarget = TaskParameters.GUI.SamplingTargetMin; % current stimulus delay time
    TaskParameters.GUIMeta.SamplingTarget.Style = 'text';
    
    TaskParameters.GUI.SamplingTargetIncrStepSize = 0.01; % step size for autoincrementing stimulus delay time, for AutoIncr only
    TaskParameters.GUI.SamplingTargetDecrStepSize = 0.005;
    
    TaskParameters.GUI.BrokeFixationTimeOut = 3; % (s), penalty for C_out before stimulus starts
    TaskParameters.GUI.BrokeFixationFeedback = 2; % feedback for BrokeFixation
    TaskParameters.GUIMeta.BrokeFixationFeedback.Style = 'popupmenu';
    TaskParameters.GUIMeta.BrokeFixationFeedback.String = {'None', 'WhiteNoise'};
    
    TaskParameters.GUI.SamplingGrace = 0;

    TaskParameters.GUI.Stimulus = 1;
    TaskParameters.GUIMeta.Stimulus.Style = 'popupmenu';
    TaskParameters.GUIMeta.Stimulus.String = {'None', 'DelayDuration', 'EndBeep'};
        
    TaskParameters.GUIPanels.Sampling = {'SamplingTarget', 'AutoIncrSamplingTarget', 'SamplingTargetMin', 'SamplingTargetMax',...
                                         'SamplingTargetIncrStepSize', 'SamplingTargetDecrStepSize',...
                                         'BrokeFixationTimeOut', 'BrokeFixationFeedback',...
                                         'SamplingGrace', 'Stimulus'};
    
    %% Reward
    TaskParameters.GUI.RewardAmount = 25;
    TaskParameters.GUI.RewardProb = 1;

    TaskParameters.GUI.BiasControlDepletion = true;
    TaskParameters.GUIMeta.BiasControlDepletion.Style = 'checkbox';
    TaskParameters.GUI.LeftDepletionRate = 0.8;
    TaskParameters.GUI.RightDepletionRate = 0.8;
    
    TaskParameters.GUI.CenterPortRewardAmount = 10;
    TaskParameters.GUI.CenterPortProb = 0;
    
%     TaskParameters.GUI.RandomReward = false;
%     TaskParameters.GUIMeta.RandomReward.Style = 'checkbox';
%     TaskParameters.GUI.RandomRewardProb = 0.1;
%     TaskParameters.GUI.RandomRewardMultiplier = 1;
%     
%     TaskParameters.GUI.Jackpot = 1;
%     TaskParameters.GUIMeta.Jackpot.Style = 'popupmenu';
%     TaskParameters.GUIMeta.Jackpot.String = {'No Jackpot','Fixed Jackpot','Decremental Jackpot','RewardCenterPort'};
%     TaskParameters.GUI.JackpotMin = 1;
%     TaskParameters.GUI.JackpotTime = 1;
%     TaskParameters.GUIMeta.JackpotTime.Style = 'text';

    TaskParameters.GUI.DrinkingGrace = 0.5;
    
    TaskParameters.GUIPanels.Reward = {'RewardAmount', 'RewardProb',...
                                       'BiasControlDepletion', 'LeftDepletionRate', 'RightDepletionRate',...
                                       'CenterPortRewardAmount','CenterPortProb',...
                                       'DrinkingGrace'};
%         'Deplete','DepleteRateLeft','DepleteRateRight',...
%         'RandomReward',...
%         'RandomRewardProb', 'RandomRewardMultiplier',...
%         'Jackpot','JackpotMin','JackpotTime', 'DrinkingTime',...
    
    %% Feedback Delay
    TaskParameters.GUI.FeedbackDelay = 0;
    TaskParameters.GUIMeta.FeedbackDelay.Style = 'text';
    
    TaskParameters.GUI.FeedbackDelayTau = 0;
    TaskParameters.GUI.FeedbackDelayMin = 0;
    TaskParameters.GUI.FeedbackDelayMax = 8;
    TaskParameters.GUI.FeedbackDelayGrace = 0.2;

    TaskParameters.GUI.SkippedFeedbackTimeOut = 0;
    TaskParameters.GUI.SkippedFeedbackFeedback = 1; % feedback for SkippedFeedback
    TaskParameters.GUIMeta.SkippedFeedbackFeedback.Style = 'popupmenu';
    TaskParameters.GUIMeta.SkippedFeedbackFeedback.String = {'None', 'WhiteNoise', 'Beep'};
    
    TaskParameters.GUI.NotBaitedTimeOut = 0.10;
    TaskParameters.GUI.NotBaitedFeedback = 1; % feedback for SkippedFeedback
    TaskParameters.GUIMeta.NotBaitedFeedback.Style = 'popupmenu';
    TaskParameters.GUIMeta.NotBaitedFeedback.String = {'None', 'WhiteNoise', 'Beep'};

    TaskParameters.GUIPanels.FeedbackDelay = {'FeedbackDelay', 'FeedbackDelayTau', 'FeedbackDelayMin',...
                                              'FeedbackDelayMax', 'FeedbackDelayGrace',...
                                              'SkippedFeedbackTimeOut', 'SkippedFeedbackFeedback',...
                                              'NotBaitedTimeOut', 'NotBaitedFeedback'};
    
    %% Photometry
    % Photometry General
    TaskParameters.GUI.Photometry = 0;
    TaskParameters.GUIMeta.Photometry.Style = 'checkbox';
    TaskParameters.GUI.DbleFibers = 0;
    TaskParameters.GUIMeta.DbleFibers.Style = 'checkbox';
    TaskParameters.GUIMeta.DbleFibers.String = 'Auto';
    TaskParameters.GUI.Isobestic405 = 0;
    TaskParameters.GUIMeta.Isobestic405.Style = 'checkbox';
    TaskParameters.GUIMeta.Isobestic405.String = 'Auto';
    TaskParameters.GUI.RedChannel = 0;
    TaskParameters.GUIMeta.RedChannel.Style = 'checkbox';
    TaskParameters.GUIMeta.RedChannel.String = 'Auto';    
    TaskParameters.GUIPanels.PhotometryRecording = {'Photometry', 'DbleFibers', 'Isobestic405', 'RedChannel'};
    
    %% plot photometry
    TaskParameters.GUI.TimeMin = -2;
    TaskParameters.GUI.TimeMax = 2;
    TaskParameters.GUI.NidaqMin = -5;
    TaskParameters.GUI.NidaqMax = 5;
    TaskParameters.GUI.SidePokeIn = 1;
	TaskParameters.GUIMeta.SidePokeIn.Style = 'checkbox';
    TaskParameters.GUI.SidePokeLeave = 1;
	TaskParameters.GUIMeta.SidePokeLeave.Style = 'checkbox';
    TaskParameters.GUI.RewardDelivery = 1;
	TaskParameters.GUIMeta.RewardDelivery.Style = 'checkbox';
    
    TaskParameters.GUI.RandomRewardDelivery = 1;
	TaskParameters.GUIMeta.RandomRewardDelivery.Style = 'checkbox';
    
    TaskParameters.GUI.BaselineBegin = 0.5;
    TaskParameters.GUI.BaselineEnd = 1.5;
    TaskParameters.GUIPanels.PhotometryPlot = {'TimeMin', 'TimeMax', 'NidaqMin', 'NidaqMax',...
                                               'SidePokeIn', 'SidePokeLeave', 'RewardDelivery',...
                                               'RandomRewardDelivery', 'BaselineBegin','BaselineEnd'};
    
    %% Nidaq and Photometry
    TaskParameters.GUI.PhotometryVersion = 1;
    TaskParameters.GUI.Modulation = 1;
    TaskParameters.GUIMeta.Modulation.Style = 'checkbox';
    TaskParameters.GUIMeta.Modulation.String = 'Auto';
	TaskParameters.GUI.NidaqDuration = 20;
    TaskParameters.GUI.NidaqSamplingRate = 6100;
    TaskParameters.GUI.DecimateFactor = 610;
    TaskParameters.GUI.LED1_Name = 'Fiber1 470-A1';
    TaskParameters.GUIMeta.LED1_Name.Style = 'edittext';
    TaskParameters.GUI.LED1_Amp = 1;
    TaskParameters.GUI.LED1_Freq = 211;
    TaskParameters.GUI.LED2_Name = 'Fiber1 405 / 565';
    TaskParameters.GUIMeta.LED2_Name.Style = 'edittext';
    TaskParameters.GUI.LED2_Amp = 5;
    TaskParameters.GUI.LED2_Freq = 531;
    TaskParameters.GUI.LED1b_Name = 'Fiber2 470-mPFC';
    TaskParameters.GUIMeta.LED1b_Name.Style = 'edittext';
    TaskParameters.GUI.LED1b_Amp = 2;
    TaskParameters.GUI.LED1b_Freq = 531;

    TaskParameters.GUIPanels.PhotometryNidaq={'PhotometryVersion', 'Modulation', 'NidaqDuration',...
                                              'NidaqSamplingRate', 'DecimateFactor',...
                                              'LED1_Name', 'LED1_Amp', 'LED1_Freq',...
                                              'LED2_Name', 'LED2_Amp', 'LED2_Freq',...
                                              'LED1b_Name', 'LED1b_Amp', 'LED1b_Freq'};
                        
    %% rig-specific
    TaskParameters.GUI.nidaqDev = 'Dev2';
    TaskParameters.GUIMeta.nidaqDev.Style = 'edittext';

    TaskParameters.GUIPanels.PhotometryRig = {'nidaqDev'};
    
    TaskParameters.GUITabs.General = {'General', 'Sampling', 'Reward', 'FeedbackDelay'};
    TaskParameters.GUITabs.Photometry = {'PhotometryRecording', 'PhotometryNidaq', 'PhotometryPlot', 'PhotometryRig'};
       
    TaskParameters.GUI = orderfields(TaskParameters.GUI);
    TaskParameters.Figures.OutcomePlot.Position = [100, 100, 800, 600];
end
BpodParameterGUI('init', TaskParameters);

end  % End function