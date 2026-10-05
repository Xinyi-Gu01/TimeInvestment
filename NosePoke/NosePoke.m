function NosePoke()
% Learning to Nose Poke side ports

global BpodSystem
global TaskParameters

%% initialize GUI and plot
TaskParameters = NosePoke_SetupGUI();  % Set experiment parameters in GUISetup.m, if no Setting File is chosen
NosePoke_PlotSideOutcome(BpodSystem.GUIHandles, 'init');

%% set up additional bpod module(s) and load waveform
if ~BpodSystem.EmulatorMode % Sound/laser waveform generation is not compulsory in this protocol
    if ~isfield(BpodSystem.ModuleUSB, 'WavePlayer1') && ~isfield(BpodSystem.ModuleUSB, 'HiFi1')
        disp('Warning: To run this protocol with sound or laser, you will need to pair an Analog Output Module or a HiFi Module(hardware) with its USB port. Click the USB config button on the Bpod console.')
    elseif isfield(BpodSystem.ModuleUSB, 'HiFi1')
        BpodSystem.assertModule('HiFi', 1);
        Player = BpodHiFi(BpodSystem.ModuleUSB.HiFi1);
        Player.SamplingRate = 192000;
        Player.DigitalAttenuation_dB = -25;
        Laser = [];
        
    elseif isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
        ChannelNumber = 4; % sound in Analogue Output module is always channel 1 & 2; laser is always channel 3 & 4
        [Player, ~] = SetupWavePlayer(ChannelNumber); % 25kHz = sampling rate of 8Ch with 8Ch fully on; 50kHz for 4Ch; 100kHZ for 2Ch
        Laser = [];
    end

    NosePoke_LoadWaveform(Player, 'TrialIndependent'); %Taking the last Player for now as the WaveformPlayer

else
    disp('Warning: Sound or laser will not be played in emulator mode.')
end

%% set up photometry module
if TaskParameters.GUI.Photometry
    [FigNidaq1, FigNidaq2] = InitializeNidaq();
end

% --------------------------Main loop------------------------------ %
RunSession = true;
iTrial = 1;

while RunSession
    %% initialize trial settings and plot
    NosePoke_InitializeCustomDataFields(iTrial); % Initialize data (trial type) vectors and first values
    TaskParameters = BpodParameterGUI('sync', TaskParameters);
    NosePoke_PlotSideOutcome(BpodSystem.GUIHandles.OutcomePlot, 'UpdateTrial', iTrial);
    
    %% load waveform to auxillary bpod modules
    if ~BpodSystem.EmulatorMode
        NosePoke_LoadWaveform(Player, 'TrialDependent', iTrial); % Load white noise, stimuli trains, and error sound to wave player if not EmulatorMode
    end    
    
    %% set up state matrix and send to bpod
    sma = NosePoke_StateMatrix(iTrial);
    SendStateMatrix(sma);
    
    %% NIDAQ Get nidaq ready to start
    if TaskParameters.GUI.Photometry
        Nidaq_photometry('WaitToStart');
    end
    
    %% Run Trial
    RawEvents = RunStateMatrix;
    
    %% NIDAQ Stop acquisition and save data in bpod structure
    if TaskParameters.GUI.Photometry
        Nidaq_photometry('Stop');
        [PhotoData,Photo2Data] = Nidaq_photometry('Save');
        NidaqData = PhotoData;
        Nidaq2Data = [];
        if TaskParameters.GUI.DbleFibers || TaskParameters.GUI.RedChannel
            Nidaq2Data = Photo2Data;
        end

        % save separately per trial (too large/slow to save entire history to disk)
        if BpodSystem.Status.BeingUsed ~= 0 %only when bpod still active (due to how bpod stops a protocol this would be run again after the last trial)
            [DataFolder, DataName, ~] = fileparts(BpodSystem.Path.CurrentDataFile);
            NidaqDataFolder = [DataFolder, '\', DataName, '_Photometry'];
            if ~isdir(NidaqDataFolder)
                mkdir(NidaqDataFolder)
            end
            fname = fullfile(NidaqDataFolder, ['NidaqData', num2str(iTrial), '.mat']);
            save(fname, 'NidaqData', 'Nidaq2Data')
        end
    end
   
    %% Bpod save and update custom data fields for this trial
    if ~isempty(fieldnames(RawEvents))
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data, RawEvents);
        NosePoke_InsertSessionDescription(iTrial);
        NosePoke_UpdateCustomDataFields(iTrial);
        SaveBpodSessionData;
    end
    
    %% handle pause condition
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.

    if BpodSystem.Status.BeingUsed == 0
        return
    end
        
    %% update figures
    NosePoke_PlotSideOutcome(BpodSystem.GUIHandles.OutcomePlot, 'UpdateResult', iTrial);
    
    %% update photometry plots
    if TaskParameters.GUI.Photometry
        NosePoke_PlotPhotometryData(iTrial, FigNidaq1, FigNidaq2, PhotoData, Photo2Data);
    end
    
    iTrial = iTrial + 1;

end % Main loop

%% release resources and checking
clear Player % release the serial port (done automatically when function returns)

if TaskParameters.GUI.Photometry
    CheckPhotometry(PhotoData, Photo2Data);
end

end % NosePoke()