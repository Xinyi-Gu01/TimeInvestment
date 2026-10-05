function NosePoke_PlotSideOutcome(AxesHandles, Action, varargin)
global BpodSystem
global TaskParameters
global nTrialsToShow %this is for convenience

% colour palette (suitable for most colourblind people)
scarlet = [254, 60, 60]/255; % for incorrect/unbaited sign, contracting with azure
denim = [31, 54, 104]/255; % mainly for neutral signs
azure = [0, 162, 254]/255; % for rewarded sign

% neon_green = [26, 255, 26]/255; % for NotBaited
% neon_purple = [168, 12, 180]/255; % for SkippedBaited

sand = [225, 190 106]/255; % for left-right
turquoise = [64, 176, 166]/255;

switch Action
    case 'init'
        %% initialize Outcome Figure
        BpodSystem.ProtocolFigures.SideOutcomePlotFig = figure('Position', TaskParameters.Figures.OutcomePlot.Position + [-100, 400, 500, -050],...
                                                               'name', 'Outcome plot',...
                                                               'numbertitle', 'off',...
                                                               'MenuBar', 'none',...
                                                               'Resize', 'off');
        BpodSystem.GUIHandles.OutcomePlot.HandleOutcome = axes('Position',   [  .055          .15 .91 .3]);
%         BpodSystem.GUIHandles.OutcomePlot.HandleGracePeriod = axes('Position',  [1*.05           .6  .1  .3], 'Visible', 'off');
        BpodSystem.GUIHandles.OutcomePlot.HandleTrialRate = axes('Position', [1*.05 + 0*.08   .6  .1  .3], 'Visible', 'off');
        BpodSystem.GUIHandles.OutcomePlot.HandleStimDelay = axes('Position', [3*.05 + 2*.08   .6  .1  .3], 'Visible', 'off');
        BpodSystem.GUIHandles.OutcomePlot.HandleMoveTime = axes('Position',  [5*.05 + 4*.08   .6  .1  .3], 'Visible', 'off');
        BpodSystem.GUIHandles.OutcomePlot.HandleFeedback = axes('Position',  [7*.05 + 6*.08   .6  .1  .3], 'Visible', 'off');
        
        nTrialsToShow = 90; %default number of trials to display
        if nargin >= 3 %custom number of trials
            nTrialsToShow =varargin{1};
        end
        
        AxesHandles = BpodSystem.GUIHandles.OutcomePlot;
        
        %% Outcome Plot
        hold(AxesHandles.HandleOutcome, 'on');
%         BpodSystem.GUIHandles.OutcomePlot.CurrentTrialCircle = line(AxesHandles.HandleOutcome, -1, 0.5,...
%                                                                     'LineStyle', 'none', 'Marker', 'o',...
%                                                                     'MarkerEdge', denim, 'MarkerFace', 'none', 'MarkerSize', 6);
        
        BpodSystem.GUIHandles.OutcomePlot.NoTrialStart = line(AxesHandles.HandleOutcome, -1, 0.5,...
                                                              'LineStyle', 'none', 'Marker', 'x',...
                                                              'MarkerEdge', denim, 'MarkerFace', 'none', 'MarkerSize', 6);
        BpodSystem.GUIHandles.OutcomePlot.BrokeFixation = line(AxesHandles.HandleOutcome, -1, 0.5,...
                                                               'LineStyle', 'none', 'Marker', 'square',...
                                                               'MarkerEdge', denim, 'MarkerFace', 'none', 'MarkerSize', 6);
        BpodSystem.GUIHandles.OutcomePlot.NoDecision = line(AxesHandles.HandleOutcome, -1, 0.5,...
                                                            'LineStyle', 'none', 'Marker', '*', ...
                                                            'MarkerEdge', denim, 'MarkerFace', 'none', 'MarkerSize', 8);
        
        BpodSystem.GUIHandles.OutcomePlot.CenterPortBaited = line(AxesHandles.HandleOutcome, -1, 0.5,...
                                                                  'LineStyle', 'none', 'Marker', 'o',...
                                                                  'MarkerEdge', azure, 'MarkerFace', 'none', 'MarkerSize', 6);
        BpodSystem.GUIHandles.OutcomePlot.Baited = line(AxesHandles.HandleOutcome, [-1, -1], [0, 1],...
                                                        'LineStyle', 'none', 'Marker', 'o',...
                                                        'MarkerEdge', azure, 'MarkerFace', 'none', 'MarkerSize', 6);

        BpodSystem.GUIHandles.OutcomePlot.ChoiceLeft = line(AxesHandles.HandleOutcome, -1, 1,...
                                                            'LineStyle', 'none', 'Marker', 'd',...
                                                            'MarkerEdge', 'none', 'MarkerFace', sand, 'MarkerSize', 6);
        BpodSystem.GUIHandles.OutcomePlot.ChoiceRight = line(AxesHandles.HandleOutcome, -1, 0,...
                                                             'LineStyle', 'none', 'Marker', 'd',...
                                                             'MarkerEdge', 'none', 'MarkerFace', turquoise, 'MarkerSize', 6);
        BpodSystem.GUIHandles.OutcomePlot.SkippedFeedback = line(AxesHandles.HandleOutcome, -1, 1,...
                                                                 'LineStyle', 'none', 'Marker', 'o',...
                                                                 'MarkerEdge', scarlet, 'MarkerFace', 'none', 'MarkerSize', 14);
        
%         BpodSystem.GUIHandles.OutcomePlot.SurpriseR = line(-1, 1, 'LineStyle', 'none', 'Marker', '+', 'MarkerEdge', 'r', 'MarkerFace', 'r', 'MarkerSize', 6);
%         BpodSystem.GUIHandles.OutcomePlot.SurpriseL = line(-1, 0, 'LineStyle', 'none', 'Marker', '+', 'MarkerEdge', 'r', 'MarkerFace', 'r', 'MarkerSize', 6);
%         BpodSystem.GUIHandles.OutcomePlot.Jackpot = line(-1,0, 'LineStyle','none','Marker','x','MarkerEdge','r','MarkerFace','r', 'MarkerSize',7);

        BpodSystem.GUIHandles.OutcomePlot.CumRwd = text(AxesHandles.HandleOutcome, 1, 1, '0 microL',...
                                                        'verticalalignment', 'bottom',...
                                                        'horizontalalignment', 'center');

        BpodSystem.GUIHandles.OutcomePlot.Legend = legend(AxesHandles.HandleOutcome,...
                                                          'NoTrialStart', 'BrokeFixation', 'NoDecision',...
                                                          '', 'Baited', 'Choice(L)', '', 'SkippedFeedback',...
                                                          'Location', 'east');
        
        set(AxesHandles.HandleOutcome,...
            'TickDir', 'out',...
            'YLim', [-0.5, 1.5],...
            'XLim',[0, nTrialsToShow],...
            'YTick', [0, 1],...
            'YTickLabel', {'Right', 'Left'},...
            'FontSize', 16);
        xlabel(AxesHandles.HandleOutcome, 'Trial#', 'FontSize', 18);
        hold(AxesHandles.HandleOutcome, 'on');
        
        %% Trial rate
        hold(AxesHandles.HandleTrialRate,'on')
        BpodSystem.GUIHandles.OutcomePlot.TrialRate = line(AxesHandles.HandleTrialRate, -1, 0,...
                                                           'LineStyle', '-', 'Color', 'k', 'Visible', 'off');
        BpodSystem.GUIHandles.OutcomePlot.NoStartP = text(AxesHandles.HandleTrialRate, 0, 1,...
                                                          'NoStartP = 0%', 'FontSize', 8, 'Units', 'normalized', 'Visible', 'off');
        AxesHandles.HandleTrialRate.XLabel.String = 'Time (min)'; % FIGURE OUT UNIT
        AxesHandles.HandleTrialRate.YLabel.String = 'Trial Counts';
        AxesHandles.HandleTrialRate.Title.String = 'Trial Start Rate';

%         %% GracePeriod histogram
%         hold(AxesHandles.HandleGracePeriod, 'on')
%         AxesHandles.HandleGracePeriod.XLabel.String = 'Time (ms)';
%         AxesHandles.HandleGracePeriod.YLabel.String = 'Trial Counts';
%         AxesHandles.HandleGracePeriod.Title.String = 'GracePeriod duration';
%         
        %% StimeDelay histogram
        hold(AxesHandles.HandleStimDelay,'on')
        AxesHandles.HandleStimDelay.XLabel.String = 'Time (ms)'; % FIGURE OUT UNIT
        AxesHandles.HandleStimDelay.YLabel.String = 'Trial Counts';
        AxesHandles.HandleStimDelay.Title.String = 'Stimulus Delay';
        
        %% MoveTime histogram
        hold(AxesHandles.HandleMoveTime,'on')
        AxesHandles.HandleMoveTime.XLabel.String = 'Time (ms)'; % FIGURE OUT UNIT
        AxesHandles.HandleMoveTime.YLabel.String = 'Trial Counts';
        AxesHandles.HandleMoveTime.Title.String = 'Movement Time';

        %% FeedbackDelay histogram
        hold(AxesHandles.HandleFeedback,'on')
        AxesHandles.HandleFeedback.XLabel.String = 'Time (s)';
        AxesHandles.HandleFeedback.YLabel.String = 'Trial Counts';
        AxesHandles.HandleFeedback.Title.String = 'Feedback Delay';
        set(AxesHandles.HandleFeedback,'TickDir', 'out',...
            'XLim', [0, 20],...
            'XTick', [0, 10, 20]);
        
    case 'UpdateTrial'
        iTrial = varargin{1};
        TrialData = BpodSystem.Data.Custom.TrialData;
        
        CenterPortBaited = TrialData.CenterPortBaited;
        Baited = TrialData.Baited;
        
        %% Outcome Plot
        [mn, ~] = rescaleX(AxesHandles.HandleOutcome, iTrial, nTrialsToShow); % see below, mn being the min of xlim
        indxToPlot = mn:iTrial;

        % CenterPortBaited
        if CenterPortBaited(iTrial) == 1
            ndxCenterPortBaited = CenterPortBaited(indxToPlot) == 1;
            XData = indxToPlot(ndxCenterPortBaited);
            YData = 0.5 * ones(1, sum(ndxCenterPortBaited));
            set(BpodSystem.GUIHandles.OutcomePlot.CenterPortBaited,...
                'xdata', XData,...
                'ydata', YData);
        end

        % Baited
        if any(Baited(:, iTrial) == 1)
            % SkippedFeedbackLeft
            ndxBaitedLeft = Baited(1, indxToPlot) == 1;
            ndxBaitedRight = Baited(2, indxToPlot) == 1;
            XData = [indxToPlot(ndxBaitedLeft), indxToPlot(ndxBaitedRight)];
            YData = [ones(1, sum(ndxBaitedLeft)), zeros(1, sum(ndxBaitedRight))];
            set(BpodSystem.GUIHandles.OutcomePlot.Baited,...
                'xdata', XData,...
                'ydata', YData);
        end

    case 'UpdateResult'
        iTrial = varargin{1};
        TrialData = BpodSystem.Data.Custom.TrialData;
        
        NoTrialStart = TrialData.NoTrialStart;
        BrokeFixation = TrialData.BrokeFixation;
        NoDecision = TrialData.NoDecision;
        
        ChoiceLeft = TrialData.ChoiceLeft;
        IncorrectChoice = TrialData.IncorrectChoice;
        SkippedFeedback = TrialData.SkippedFeedback;
         
        SamplingTime = TrialData.SamplingTime;
        MoveTime = TrialData.MoveTime;
        FeedbackWaitingTime = TrialData.FeedbackWaitingTime;
        
        %% Outcome Plot
        % recompute xlim
        [mn, ~] = rescaleX(AxesHandles.HandleOutcome, iTrial, nTrialsToShow);
        indxToPlot = mn:iTrial;

        % NoTrialStart
        if NoTrialStart(iTrial) == 1
            ndxNoTrialStart = NoTrialStart(indxToPlot) == 1;
            XData = indxToPlot(ndxNoTrialStart);
            YData = 0.5 * ones(1, sum(ndxNoTrialStart));
            set(BpodSystem.GUIHandles.OutcomePlot.NoTrialStart,...
                'xdata', XData,...
                'ydata', YData);
        end
        
        % BrokeFixation
        if BrokeFixation(iTrial) == 1
            ndxBrokeFixation = BrokeFixation(indxToPlot) == 1;
            XData = indxToPlot(ndxBrokeFixation);
            YData = 0.5 * ones(1, sum(ndxBrokeFixation));
            set(BpodSystem.GUIHandles.OutcomePlot.BrokeFixation,...
                'xdata', XData,...
                'ydata', YData);
        end
        
         % NoDecision
        if NoDecision(iTrial) == 1
            ndxNoDecision = NoDecision(indxToPlot) == 1;
            XData = indxToPlot(ndxNoDecision);
            YData = 0.5 * ones(1, sum(ndxNoDecision));
            set(BpodSystem.GUIHandles.OutcomePlot.NoDecision,...
                'xdata', XData,...
                'ydata', YData);
        end
        
        % ChoiceLeft
        if ChoiceLeft(iTrial) == 1
            ndxChoiceLeft = ChoiceLeft(indxToPlot) == 1;
            XData = indxToPlot(ndxChoiceLeft);
            YData = ones(1, sum(ndxChoiceLeft));
            set(BpodSystem.GUIHandles.OutcomePlot.ChoiceLeft,...
                'xdata', XData,...
                'ydata', YData);
        end

        % ChoiceRight
        if ChoiceLeft(iTrial) == 0
            ndxChoiceRight = ChoiceLeft(indxToPlot) == 0;
            XData = indxToPlot(ndxChoiceRight);
            YData = zeros(1, sum(ndxChoiceRight));
            set(BpodSystem.GUIHandles.OutcomePlot.ChoiceRight,...
                'xdata', XData,...
                'ydata', YData);
        end
        
        if SkippedFeedback(iTrial) == 1
            % SkippedFeedbackLeft
            ndxSkippedFeedbackLeft = SkippedFeedback(indxToPlot) == 1 & ChoiceLeft(indxToPlot) == 1;
            ndxSkippedFeedbackRight = SkippedFeedback(indxToPlot) == 1 & ChoiceLeft(indxToPlot) == 0;
            XData = [indxToPlot(ndxSkippedFeedbackLeft), indxToPlot(ndxSkippedFeedbackRight)];
            YData = [ones(1, sum(ndxSkippedFeedbackLeft)), zeros(1, sum(ndxSkippedFeedbackRight))];
            set(BpodSystem.GUIHandles.OutcomePlot.SkippedFeedback,...
                'xdata', XData,...
                'ydata', YData);
        end

        %Cumulative Reward Amount
        RewardTotal = CalculateCumulativeReward();
        set(BpodSystem.GUIHandles.OutcomePlot.CumRwd,...
            'position', [iTrial+1 1],...
            'string', [num2str(RewardTotal) ' microL']);
       
%         %Plot past trials
%         %Plot correct Left
%         ndxRwdL = ChoiceLeft(indxToPlot) == 1 & IncorrectChoice(indxToPlot) == 0;
%         Xdata = indxToPlot(ndxRwdL);
%         Ydata = ones(1,sum(ndxRwdL));
%         set(BpodSystem.GUIHandles.OutcomePlot.RewardedLeft, 'xdata', Xdata, 'ydata', Ydata);
% 
%         %Plot correct Right
%         ndxRwdR = ChoiceLeft(indxToPlot) == 0  & IncorrectChoice(indxToPlot) == 0;
%         Xdata = indxToPlot(ndxRwdR);
%         Ydata = zeros(1,sum(ndxRwdR));
%         set(BpodSystem.GUIHandles.OutcomePlot.RewardedRight, 'xdata', Xdata, 'ydata', Ydata);
%           
%         set(BpodSystem.GUIHandles.OutcomePlot.CurrentTrialCircle,...
%         'xdata', CurrentTrial, ...
%         'ydata', .5);
%             if TaskParameters.GUI.RandomReward ==true
%                 %Plot surprise Left
%                 ndxRwdL = ChoiceLeft(indxToPlot) == 1 & IncorrectChoice(indxToPlot) == 1 & BpodSystem.Data.Custom.TrialData.RandomThresholdPassed(indxToPlot)==1;
%                 Xdata = indxToPlot(ndxRwdL);
%                 Ydata = ones(1,sum(ndxRwdL));
%                 set(BpodSystem.GUIHandles.OutcomePlot.SurpriseL, 'xdata', Xdata, 'ydata', Ydata);
% 
%                 %Plot surprise Right
%                 ndxRwdR = ChoiceLeft(indxToPlot) == 0  & IncorrectChoice(indxToPlot) == 1 & BpodSystem.Data.Custom.TrialData.RandomThresholdPassed(indxToPlot)==1;
%                 Xdata = indxToPlot(ndxRwdR);
%                 Ydata = zeros(1,sum(ndxRwdR));
%                 set(BpodSystem.GUIHandles.OutcomePlot.SurpriseR, 'xdata', Xdata, 'ydata', Ydata);
%             end
%             
%         %Plot error left
%         ndxRwdL = ChoiceLeft(indxToPlot) == 1  & IncorrectChoice(indxToPlot) == 1;
%         Xdata = indxToPlot(ndxRwdL);
%         Ydata = ones(1, sum(ndxRwdL));
%         set(BpodSystem.GUIHandles.OutcomePlot.UnrewardedLeft,...
%             'xdata', Xdata, ...
%             'ydata', Ydata);      
%         
%         %Plot error right
%         ndxRwdR = ChoiceLeft(indxToPlot) == 0 & IncorrectChoice(indxToPlot) == 1;
%         Xdata = indxToPlot(ndxRwdR);
%         Ydata = zeros(1, sum(ndxRwdR));
%         set(BpodSystem.GUIHandles.OutcomePlot.UnrewardedRight,...
%             'xdata', Xdata, ...
%             'ydata', Ydata);
%         
%         %plot if left correct was not rewarded
%         ndxRwdL = ChoiceLeft(indxToPlot) == 1 & IncorrectChoice(indxToPlot) == 1 & Rewarded(indxToPlot) == 0;
%         Xdata = indxToPlot(ndxRwdL);
%         Ydata = ones(1, sum(ndxRwdL));
%         set(BpodSystem.GUIHandles.OutcomePlot.SkippedFeedbackLeft,...
%             'xdata', Xdata, ...
%             'ydata', Ydata);
%         
%         %plot if right correct was not rewarded
%         ndxRwdR = ChoiceLeft(indxToPlot) == 0 & IncorrectChoice(indxToPlot) == 1 & Rewarded(indxToPlot) == 0;
%         Xdata = indxToPlot(ndxRwdR);
%         Ydata = zeros(1, sum(ndxRwdR));
%         set(BpodSystem.GUIHandles.OutcomePlot.SkippedFeedbackRight,...
%             'xdata', Xdata, ...
%             'ydata', Ydata);
%         
%         %plot if no choice is made
%         ndxNoChoice=isnan(ChoiceLeft(indxToPlot));
%         Xdata = indxToPlot(ndxNoChoice);
%         Ydata = 0.5*ones(1, sum(ndxNoChoice));
%         set(BpodSystem.GUIHandles.OutcomePlot.NoDecision,...
%             'xdata', Xdata,...
%             'ydata', Ydata);
% 
%         if ~isempty(BpodSystem.Data.Custom.TrialData.Jackpot)
%             indxToPlot = mn:CurrentTrial;
%             ndxJackpot = BpodSystem.Data.Custom.TrialData.Jackpot(indxToPlot);
%             XData = indxToPlot(ndxJackpot);
%             YData = 0.5*ones(1,sum(ndxJackpot));
%             set(BpodSystem.GUIHandles.OutcomePlot.Jackpot, 'xdata', XData, 'ydata', YData);
%         end
%         
%         %% GracePeriod
%         BpodSystem.GUIHandles.OutcomePlot.HandleGracePeriod.Visible = 'on';
%         set(get(BpodSystem.GUIHandles.OutcomePlot.HandleGracePeriod, 'Children'), 'Visible', 'on');
%         cla(AxesHandles.HandleGracePeriod)
%         BpodSystem.GUIHandles.OutcomePlot.HistGracePeriod = histogram(AxesHandles.HandleGracePeriod,BpodSystem.Data.Custom.TrialData.false_exits(~isnan(BpodSystem.Data.Custom.TrialData.false_exits)&~repmat(BpodSystem.Data.Custom.TrialData.EarlyWithdrawal,50,1))*1000);
%         BpodSystem.GUIHandles.OutcomePlot.HistGracePeriod.BinWidth = 50;
%         BpodSystem.GUIHandles.OutcomePlot.HistGracePeriod.FaceColor = 'g';
%         BpodSystem.GUIHandles.OutcomePlot.HistGracePeriod.EdgeColor = 'none';
%         BpodSystem.GUIHandles.OutcomePlot.HistGracePeriodEWD = histogram(AxesHandles.HandleGracePeriod,BpodSystem.Data.Custom.TrialData.false_exits(~isnan(BpodSystem.Data.Custom.TrialData.false_exits)&repmat(BpodSystem.Data.Custom.TrialData.EarlyWithdrawal,50,1))*1000);
%         BpodSystem.GUIHandles.OutcomePlot.HistGracePeriodEWD.BinWidth = 50;
%         BpodSystem.GUIHandles.OutcomePlot.HistGracePeriodEWD.FaceColor = 'r';
%         BpodSystem.GUIHandles.OutcomePlot.HistGracePeriodEWD.EdgeColor = 'none';
%         LeftBias = sum(BpodSystem.Data.Custom.TrialData.ChoiceLeft==1)/sum(~isnan(BpodSystem.Data.Custom.TrialData.ChoiceLeft),2);
%         cornertext(AxesHandles.HandleMoveTime,sprintf('Bias=%1.2f',LeftBias))

        %% Trial rate
        BpodSystem.GUIHandles.OutcomePlot.HandleTrialRate.Visible = 'on';
        set(get(BpodSystem.GUIHandles.OutcomePlot.HandleTrialRate,'Children'), 'Visible', 'on');
        BpodSystem.GUIHandles.OutcomePlot.TrialRate.XData = (BpodSystem.Data.TrialStartTimestamp - min(BpodSystem.Data.TrialStartTimestamp)) / 60; % (min)
        BpodSystem.GUIHandles.OutcomePlot.TrialRate.YData = cumsum(NoTrialStart == 0);
        NoTrialStartP = 100 * sum(NoTrialStart == 1)/iTrial;
        set(BpodSystem.GUIHandles.OutcomePlot.NoStartP, 'string', ['NoStartP = ' sprintf('%1.1f',NoTrialStartP) '%']);
%         cornertext(AxesHandles.HandleTrialRate,sprintf('NoStartP=%1.2f',NoTrialStartP)) %percentage of No Trial Started

        %% Stimulus Delay
        if NoTrialStart(iTrial) == 0
            BpodSystem.GUIHandles.OutcomePlot.HandleStimDelay.Visible = 'on';
            set(get(BpodSystem.GUIHandles.OutcomePlot.HandleStimDelay,'Children'),'Visible','on');
            cla(AxesHandles.HandleStimDelay)
            BpodSystem.GUIHandles.OutcomePlot.HistBrokeFixation = histogram(AxesHandles.HandleStimDelay, SamplingTime(BrokeFixation == 1) * 1000);
            BpodSystem.GUIHandles.OutcomePlot.HistBrokeFixation.BinWidth = 50;
            BpodSystem.GUIHandles.OutcomePlot.HistBrokeFixation.FaceColor = scarlet;
            BpodSystem.GUIHandles.OutcomePlot.HistBrokeFixation.EdgeColor = 'none';
            BpodSystem.GUIHandles.OutcomePlot.HistNBrokeFixation = histogram(AxesHandles.HandleStimDelay, SamplingTime(BrokeFixation == 0) * 1000);
            BpodSystem.GUIHandles.OutcomePlot.HistNBrokeFixation.BinWidth = 50;
            BpodSystem.GUIHandles.OutcomePlot.HistNBrokeFixation.FaceColor = azure;
            BpodSystem.GUIHandles.OutcomePlot.HistNBrokeFixation.EdgeColor = 'none';
            BrokeFixationP = 100*sum(BrokeFixation == 1) / sum(NoTrialStart == 0);
            BpodSystem.GUIHandles.OutcomePlot.BrokeFixP = text(AxesHandles.HandleStimDelay, 0, 1, ['BrokeFixP = ' sprintf('%1.1f', BrokeFixationP) '%'],...
                                                               'FontSize', 8, 'Units', 'normalized');
%             cornertext(AxesHandles.HandleStimDelay,sprintf('BrokeFixP=%1.2f',BrokeFixationP)) %percentage of BrokeFixation with Trial Started
        end

%         %% SamplingTime
%         BpodSystem.GUIHandles.OutcomePlot.HandleSampleTime.Visible = 'on';
%         set(get(BpodSystem.GUIHandles.OutcomePlot.HandleSampleTime, 'Children'), 'Visible', 'on');
%         cla(AxesHandles.HandleSampleTime)
%         BpodSystem.GUIHandles.OutcomePlot.HistSTEarly = histogram(AxesHandles.HandleSampleTime, BpodSystem.Data.Custom.TrialData.sample_length(BpodSystem.Data.Custom.TrialData.EarlyWithdrawal)*1000);
%         BpodSystem.GUIHandles.OutcomePlot.HistSTEarly.BinWidth = 50;
%         BpodSystem.GUIHandles.OutcomePlot.HistSTEarly.FaceColor = 'r';
%         BpodSystem.GUIHandles.OutcomePlot.HistSTEarly.EdgeColor = 'none';
%         BpodSystem.GUIHandles.OutcomePlot.HistST = histogram(AxesHandles.HandleSampleTime,BpodSystem.Data.Custom.TrialData.sample_length(~BpodSystem.Data.Custom.TrialData.EarlyWithdrawal)*1000);
%         BpodSystem.GUIHandles.OutcomePlot.HistST.BinWidth = 50;
%         BpodSystem.GUIHandles.OutcomePlot.HistST.FaceColor = 'b';
%         BpodSystem.GUIHandles.OutcomePlot.HistST.EdgeColor = 'none';
%         BpodSystem.GUIHandles.OutcomePlot.HistSTJackpot = histogram(AxesHandles.HandleSampleTime,BpodSystem.Data.Custom.TrialData.sample_length(BpodSystem.Data.Custom.TrialData.Jackpot)*1000);
%         BpodSystem.GUIHandles.OutcomePlot.HistSTJackpot.BinWidth = 50;
%         BpodSystem.GUIHandles.OutcomePlot.HistSTJackpot.FaceColor = 'g';
%         BpodSystem.GUIHandles.OutcomePlot.HistSTJackpot.EdgeColor = 'none';
%         EarlyP = sum(BpodSystem.Data.Custom.TrialData.EarlyWithdrawal)/size(BpodSystem.Data.Custom.TrialData.ChoiceLeft,2);
%         cornertext(AxesHandles.HandleSampleTime, sprintf('P=%1.2f', EarlyP))
%         
        %% MoveTime
        if NoDecision(iTrial) == 0 % no need to update if no choice made
            BpodSystem.GUIHandles.OutcomePlot.HandleMoveTime.Visible = 'on';
            set(get(BpodSystem.GUIHandles.OutcomePlot.HandleMoveTime,'Children'), 'Visible', 'on');
            cla(AxesHandles.HandleMoveTime)
            BpodSystem.GUIHandles.OutcomePlot.HistMTLeft = histogram(AxesHandles.HandleMoveTime, MoveTime(ChoiceLeft == 1) * 1000);
            BpodSystem.GUIHandles.OutcomePlot.HistMTLeft.BinWidth = 50;
            BpodSystem.GUIHandles.OutcomePlot.HistMTLeft.FaceColor = sand;
            BpodSystem.GUIHandles.OutcomePlot.HistMTLeft.EdgeColor = 'none';

            BpodSystem.GUIHandles.OutcomePlot.HistMTRight = histogram(AxesHandles.HandleMoveTime, MoveTime(ChoiceLeft == 0) * 1000);
            BpodSystem.GUIHandles.OutcomePlot.HistMTRight.BinWidth = 50;
            BpodSystem.GUIHandles.OutcomePlot.HistMTRight.FaceColor = turquoise;
            BpodSystem.GUIHandles.OutcomePlot.HistMTRight.EdgeColor = 'none';

            LeftP = 100 * sum(ChoiceLeft == 1) / sum(BrokeFixation == 0);
            RightP = 100 * sum(ChoiceLeft == 0) / sum(BrokeFixation == 0);
            NoDeciP = 100 * sum(NoDecision == 1) / sum(BrokeFixation== 0);
            IncorrectP = 100 * sum(IncorrectChoice == 1) / sum(~isnan(ChoiceLeft));

            BpodSystem.GUIHandles.OutcomePlot.LeftP = text(AxesHandles.HandleMoveTime, 0, 1.00, ['LeftP = ' sprintf('%1.1f', LeftP) '%'],...
                'Color', sand, 'FontSize', 8, 'Units', 'normalized');
            BpodSystem.GUIHandles.OutcomePlot.RightP = text(AxesHandles.HandleMoveTime, 0, 0.95, ['RightP = ' sprintf('%1.1f', RightP) '%'],...
                'Color', turquoise, 'FontSize', 8, 'Units', 'normalized');
            BpodSystem.GUIHandles.OutcomePlot.NoDeciP = text(AxesHandles.HandleMoveTime, 0, 0.90, ['NoDeciP = ' sprintf('%1.1f', NoDeciP) '%'],...
                'Color', denim, 'FontSize', 8, 'Units', 'normalized');
            BpodSystem.GUIHandles.OutcomePlot.IncorrectP = text(AxesHandles.HandleMoveTime, 0, 0.85, ['IncorrectP = ' sprintf('%1.1f', IncorrectP) '%'],...
                'Color', scarlet, 'FontSize', 8, 'Units', 'normalized');
%             cornertext(AxesHandles.HandleMoveTime,{sprintf('LeftP=%1.2f',LeftP),sprintf('RightP=%1.2f',RightP),...
%                                                    sprintf('StartNewP=%1.2f',StartNewP),sprintf('NoDeciP=%1.2f',NoDeciP),...
%                                                    sprintf('IncorrectP=%1.2f',IncorrectP)})
        end

        %% Feedback Delay
        if ~isnan(SkippedFeedback(iTrial)) % no need to update if no new SkippedFeedback
            BpodSystem.GUIHandles.OutcomePlot.HandleFeedback.Visible = 'on';
            set(get(BpodSystem.GUIHandles.OutcomePlot.HandleFeedback,'Children'),'Visible','on');
            cla(AxesHandles.HandleFeedback)

            BpodSystem.GUIHandles.OutcomePlot.HistRFLeft = histogram(AxesHandles.HandleFeedback, FeedbackWaitingTime(SkippedFeedback == 0 & ChoiceLeft == 1));
            BpodSystem.GUIHandles.OutcomePlot.HistRFLeft.BinWidth = 1;
            BpodSystem.GUIHandles.OutcomePlot.HistRFLeft.FaceColor = 'none';
            BpodSystem.GUIHandles.OutcomePlot.HistRFLeft.EdgeColor = sand;

            BpodSystem.GUIHandles.OutcomePlot.HistRFRight = histogram(AxesHandles.HandleFeedback, FeedbackWaitingTime(SkippedFeedback == 0 & ChoiceLeft == 0));
            BpodSystem.GUIHandles.OutcomePlot.HistRFRight.BinWidth = 1;
            BpodSystem.GUIHandles.OutcomePlot.HistRFRight.FaceColor = 'none';
            BpodSystem.GUIHandles.OutcomePlot.HistRFRight.EdgeColor = turquoise;

            BpodSystem.GUIHandles.OutcomePlot.HistSFLeft = histogram(AxesHandles.HandleFeedback, FeedbackWaitingTime(SkippedFeedback == 1 & ChoiceLeft  ==1));
            BpodSystem.GUIHandles.OutcomePlot.HistSFLeft.BinWidth = 1;
            BpodSystem.GUIHandles.OutcomePlot.HistSFLeft.FaceColor = sand;
            BpodSystem.GUIHandles.OutcomePlot.HistSFLeft.EdgeColor = 'none';

            BpodSystem.GUIHandles.OutcomePlot.HistSFRight = histogram(AxesHandles.HandleFeedback, FeedbackWaitingTime(SkippedFeedback == 1 & ChoiceLeft == 0));
            BpodSystem.GUIHandles.OutcomePlot.HistSFRight.BinWidth = 1;
            BpodSystem.GUIHandles.OutcomePlot.HistSFRight.FaceColor = turquoise;
            BpodSystem.GUIHandles.OutcomePlot.HistSFRight.EdgeColor = 'none';

            SFLeftP = 100 * sum(SkippedFeedback == 1 & ChoiceLeft == 1) / sum(~isnan(ChoiceLeft)); % skipped feedback left
            SFRightP = 100 * sum(SkippedFeedback == 1 & ChoiceLeft == 0) / sum(~isnan(ChoiceLeft));
            RFLeftP = 100 * sum(SkippedFeedback == 0 & ChoiceLeft == 1) / sum(~isnan(ChoiceLeft)); % received feedback left (incl. IncorrectChoice)
            RFRightP = 100 * sum(SkippedFeedback == 0 & ChoiceLeft == 0) / sum(~isnan(ChoiceLeft));

            BpodSystem.GUIHandles.OutcomePlot.SFLeftP = text(AxesHandles.HandleFeedback, 0, 1.00, ['SkippedLeftP = ' sprintf('%1.1f', SFLeftP) '%'],...
                'FontSize', 8, 'Units', 'normalized');
            BpodSystem.GUIHandles.OutcomePlot.SFRightP = text(AxesHandles.HandleFeedback, 0, 0.95, ['SkippedRightP = ' sprintf('%1.1f', SFRightP) '%'],...
                'FontSize', 8, 'Units', 'normalized');
            BpodSystem.GUIHandles.OutcomePlot.RFLeftP = text(AxesHandles.HandleFeedback, 0, 0.90, ['ReceivedLeftP = ' sprintf('%1.1f', RFLeftP) '%'],...
                'FontSize', 8, 'Units', 'normalized');
            BpodSystem.GUIHandles.OutcomePlot.RFRightP = text(AxesHandles.HandleFeedback, 0, 0.85, ['ReceivedRightP = ' sprintf('%1.1f', RFRightP) '%'],...
                'FontSize', 8, 'Units', 'normalized');
%             cornertext(AxesHandles.HandleFeedback,{sprintf('SFLeftP=%1.2f',SFLeftP),sprintf('SFRightP=%1.2f',SFRightP),...
%                                                    sprintf('RFLeftP=%1.2f',RFLeftP),sprintf('RFRightP=%1.2f',RFRightP)})
        end
end % end switch
end % end function

function [mn,mx] = rescaleX(AxesHandle,CurrentTrial,nTrialsToShow)
    FractionWindowStickpoint = .75; % After this fraction of visible trials, the trial position in the window "sticks" and the window begins to slide through trials.
    mn = max(round(CurrentTrial - FractionWindowStickpoint*nTrialsToShow),1);
    mx = mn + nTrialsToShow - 1;
    set(AxesHandle,'XLim',[mn-1 mx+1]);
end

function cornertext(h,str)
    unit = get(h,'Units');
    set(h,'Units','char');
    pos = get(h,'Position');
    if ~iscell(str)
        str = {str};
    end
    for i = 1:length(str)
        x = pos(1)+1;y = pos(2)+pos(4)-i;
        uicontrol(h.Parent,'Units','char','Position',[x,y,length(str{i})+1,1],'string',str{i},'style','text','background',[1,1,1],'FontSize',8);
    end
    set(h,'Units',unit);
end