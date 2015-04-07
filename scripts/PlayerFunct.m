function PlayerFunct(port2boss, port2acq, playerName, trainDuration, windowDuration, testOverlap)

%Begining

% Find the player number
if port2boss == 33001
    playerNb = 1;
elseif port2boss == 33002
    playerNb = 2;
else
    disp('Player number could not be identified.');
    playerNb = 0;
end

disp(['Player ',num2str(playerNb)]);
disp(playerName);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%              Connection with Boss             %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Trying to connect to Boss...')
%Open the communication with EEGacq program
playerClient = tcpip('0.0.0.0', port2boss, 'NetworkRole', 'client');
fopen(playerClient);
disp('Connected to Boss !')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%              Connection with EEG              %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Waiting for the EEG acquisition client')
%Open the communication with EEGacq program
eegServer = tcpip('0.0.0.0', port2acq, 'NetworkRole', 'server');
eegServer.InputBufferSize = 5000000;
eegServer.Timeout = 10; %in seconds

%Wait eeg acq client
fopen(eegServer); %Waits indefinitely for the streamer client connnection
disp('EEG acquisition client is connected.');

%Wait user's ENTER
disp('Waiting for the EEG acquisition client.');

nBytes_4B = fread(eegServer, 4);  %How large is the package (# bytes)
nBytes = double(swapbytes(typecast(uint8(nBytes_4B),'int32')));
package = fread(eegServer,nBytes);
[device, fs, tags, nCh] = mesHeaderFormat(char(package)');

nBytes_4B = fread(eegServer, 4);  %How large is the package (# bytes)
nBytes = double(swapbytes(typecast(uint8(nBytes_4B),'int32')));
package = fread(eegServer,nBytes);
chLabels= strsplit(char(package)',',');

%Buffer definition, it will depend of FS and #CHANNELS
bufferSeconds = trainDuration;
nSamples = bufferSeconds*fs;
nColumns = numel(tags);
trainEEG = NaN(nSamples,nColumns);
timeVector = (0:nSamples-1)/fs;

%Window length were power is computed (in samples)
windowLength = fs*windowDuration;
overlapLength = testOverlap; %seconds
overlapSampleLength = floor(overlapLength*fs);

%Test buffer
testEEG = NaN(windowLength,nColumns);
yHatHist = [40];
Xtest = [];

disp(strcat('Using : ', device));

electArray = [1];
electAlpha = [1];
nFeatures = 46;

%Electrodes to compute Alpha power
switch device
    case 'MUSE'
        electArray = [1:4];
        electAlpha = [1 4];
        nFeatures = 46;
    case 'EMOTIV'
        electArray = [9:12];
    case 'ENOBIO'
        electArray = [1:4];
    case 'NEUROSKY'
        electArray = [1];
        electAlpha = [1];
        nFeatures = 22;
end

%State machine label
state = 'NA';

tone(500,100); %beep
tone(900,80); %beep

delay_ms(1000);

if(eegServer.BytesAvailable > 0)
    fread(eegServer, eegServer.BytesAvailable);
end

target = 0;
compteur = 0;
testFeatures = [];
testRawData = [];

FullTestSave = ones(length(electArray),1)';
FullYEval = 1;
FullYHat = 1;

needWaitHandshake = 1;
nRun = 1;
while true %Main loop, it is controlled by the TCP/IP packages rate
    if needWaitHandshake == 1
        playerData = fread(playerClient, 1);
        if(playerData == 'A')
            disp('Handshake Phase 1...');
            state = 'acqTrain0';
            % Empty Buffer.
            if(eegServer.BytesAvailable > 0)
                fread(eegServer, eegServer.BytesAvailable);
            end
            needWaitHandshake = 0;
        end
        if(playerData == 'B')
            disp('Handshake Phase 2...');
            state = 'acqTrain1';
            % Empty Buffer.
            if(eegServer.BytesAvailable > 0)
                fread(eegServer, eegServer.BytesAvailable);
            end
            needWaitHandshake = 0;
        end
        if(playerData == 'C')
            disp('Start Training...');
            state = 'trainClassifier';
            % Empty Buffer.
            if(eegServer.BytesAvailable > 0)
                fread(eegServer, eegServer.BytesAvailable);
            end
            needWaitHandshake = 0;
        end
        if(playerData == 'D')
            disp('Start Real Time Game...');
            state = 'startClassification';
            % Empty Buffer.
            if(eegServer.BytesAvailable > 0)
                fread(eegServer, eegServer.BytesAvailable);
            end
            needWaitHandshake = 0;
        end
        %This is not reach unless you send Q before the testing part
        if(playerData == 'Q')
            disp('Exit...');
            break;
        end
    end
    
    %After Training the data is flushed
    if strcmp(state,'startClassification')
        if(eegServer.BytesAvailable > 0)
            fread(eegServer, eegServer.BytesAvailable);
        end
        state = 'classification';
    end
    %Catch error in communication with the EEG acq client
    try
        nBytes_4B = fread(eegServer, 4);
    catch err;
        break %break if there is an error in communication
    end
    %Break the while loop if the first byte is -1
    nBytes = double(swapbytes(typecast(uint8(nBytes_4B),'int32')));
    if nBytes == -1 %If -1 is recived, close TCP communication
        break;
    end
    %Catch error in communication with the EEG acq client
    try
        data = fread(eegServer,nBytes);
    catch err;
        break
    end
    %Give order to the incoming data, and removing DC component
    eegData = mesDataFormat(data,tags);%normalize_col(mesDataFormat(data,tags));
    [newRows, ~ ] = size(eegData);
    
    trainEEG =  [trainEEG(1+newRows:end, :); eegData];
    testEEG = [testEEG(1+newRows:end, :); eegData];
    
    if ~isnan(trainEEG(1,1))
        switch state
            case 'acqTrain0',
                disp('Handshake Phase 1 Done !');
                fwrite(playerClient, 1);
                needWaitHandshake = 1;
                train0 = trainEEG;
                trainEEG(:) = NaN;
                %state = 'acqTrain1';
                tone(800,100); %beep
                
                size(train0)
                
            case 'acqTrain1',
                disp('Handshake Phase 2 Done !');
                %Don't tell Boss now, wait after Training. (since not long)
                fwrite(playerClient, 1);
                needWaitHandshake = 1;
                train1 = trainEEG;
                trainEEG(:) = NaN;
                %state = 'trainClassifier';
                tone(800,100); %beep
                
        end %switch for training examples
    end %if first row is NaN
    
    switch state
        case 'trainClassifier',
            
            disp('Training classifier');
            %Train 0 !
            electUsed = double(train0(:,electArray));
            
            L = length(electUsed);
            nbWin = floor(L/(windowLength - overlapSampleLength))-2;

            featArray0 = zeros(nbWin,nFeatures);

            for i = 0:nbWin-1
                % Get the window
                start = (windowLength - overlapSampleLength)*i + 1;
                finish = start + windowLength - 1;
                dataWin = electUsed(start:finish,:);

                featArray0(i+1,:) = featureExtract(dataWin, fs, 0);
            end

            %Train 1 !
            electUsed = double(train1(:,electArray));
            
            L = length(electUsed);
            nbWin = floor(L/(windowLength - overlapSampleLength))-2;
            
            featArray1 = zeros(nbWin,nFeatures);

            for i = 0:nbWin-1
                % Get the window
                start = (windowLength - overlapSampleLength)*i + 1;
                finish = start + windowLength - 1;
                dataWin = electUsed(start:finish,:);

                [featArray1(i+1,:), featNames] = featureExtract(dataWin, fs, 1);
            end
            
            % Normalize the features (z-score)
            featArrayAll = [featArray0; featArray1];
            mu_col = nanmean(featArrayAll);
            mu_col(end) = 0;
            sigma_col = nanstd(featArrayAll);
            sigma_col(end) = 1;
            featArray0 = (featArray0-repmat(mu_col,nbWin,1))./repmat(sigma_col,nbWin,1);
            featArray1 = (featArray1-repmat(mu_col,nbWin,1))./repmat(sigma_col,nbWin,1);
            
            % Select features "by hand"
            selectedFeatInd = 2:6; % Remove 1 and 7 as they are computed with delta bands 
%             % Select the best features
%             nSelectedFeat = 10;
%             selectedFeatInd = featureSelect(featArrayAll(:,1:end-1), featArrayAll(:,end), nSelectedFeat);
            disp('Selected features: ')
            disp(featNames(selectedFeatInd))
            
            % Remove start and end of featArray
            featArray0 = featArray0(2:end-2,:);
            featArray1 = featArray1(2:end-2,:);       
            
            % Remove outliers from selected features
            [outInd0] = findOutliers(featArray0(:,selectedFeatInd));
            [outInd1] = findOutliers(featArray1(:,selectedFeatInd));  

            featArray0(outInd0,:) = [];
            featArray1(outInd1,:) = [];
          
            try
                saveName = ['calibration_player_', playerName, num2str(playerNb),'_',num2str(now), '_', num2str(nRun), '.mat'];
                calibData.port2boss = port2boss;
                calibData.port2acq = port2acq;
                calibData.playerNb = playerNb;
                calibData.raw = electUsed;
                calibData.Fs = fs;
                calibData.device = device;
                calibData.chLabels = chLabels;
                calibData.featArray = featArrayAll;
                calibData.featArrayNorm = [featArray0; featArray1];
                calibData.featNames = featNames;
                calibData.selectedFeatInd = selectedFeatInd;
                calibData.selectedFeat = featNames(selectedFeatInd);
                calibData.modelParams = modelParams;
                calibData.trainingAcc = trainingAcc;
                calibData.train0 = train0;
                calibData.train1 = train1;
                save(saveName, 'calibData');
                disp(['Calibration data saved in ',saveName,'.'])
            catch
                disp('Could not save the calibration data.')
            end
                        
            % Train the classifier
            classifierName = 'SVM';
            [modelParams, trainingAcc] = featureClassif(featArray0(:,selectedFeatInd), featArray1(:,selectedFeatInd), classifierName);
            
            % Save the raw data, the features, the normalized features, the
            % feature list, the selected features list, the classifier
            % parameters, and the training accuracy
            try
                saveName = ['calibration_player_', playerName, num2str(playerNb),'_',num2str(now), '_', num2str(nRun), '.mat'];
                calibData.port2boss = port2boss;
                calibData.port2acq = port2acq;
                calibData.playerNb = playerNb;
                calibData.raw = electUsed;
                calibData.Fs = fs;
                calibData.device = device;
                calibData.chLabels = chLabels;
                calibData.featArray = featArrayAll;
                calibData.featArrayNorm = [featArray0; featArray1];
                calibData.featNames = featNames;
                calibData.selectedFeatInd = selectedFeatInd;
                calibData.selectedFeat = featNames(selectedFeatInd);
                calibData.modelParams = modelParams;
                calibData.trainingAcc = trainingAcc;
                calibData.train0 = train0;
                calibData.train1 = train1;
                save(saveName, 'calibData');
                disp(['Calibration data saved in ',saveName,'.'])
            catch
                disp('Could not save the calibration data.')
            end
            
            %Plot !
            scrsz = get(groot,'ScreenSize');
            figure('Position',[scrsz(3)/8 scrsz(4)/4 6*scrsz(3)/8 2*scrsz(4)/4])
            title(strcat('Calibration Player', num2str(playerNb)));
            subplot(3,1,1);
            plot(train0(:,1:end-1))
            subplot(3,1,2);
            plot(train1(:,1:end-1))
            subplot(3,1,3);
            plot([featArray0(:,[3,5]); featArray1(:,[3,5])]);
            drawnow
            pause(1);
            
            testEEG(:) = NaN;
            %state = 'startClassification';
            tone(500,50); tone(500,50); %beep
            
            disp('Training Done !');
            %Don't tell Boss now, wait after Training. (since not long)
            fwrite(playerClient, 1);
            needWaitHandshake = 1;
            
        case 'classification'
            if ~isnan(testEEG(1,1))
                electUsed = double(testEEG(:,electArray));
                FullTestSave = [FullTestSave; electUsed];
                example = featureExtract(electUsed, fs);
                example = (example-mu_col)./sigma_col;
                
                yEval = modelPredict(modelParams, example(selectedFeatInd), classifierName);
                yHat = yEval;
                
                %[~,yHat] = max(yEval,[],2);
                yHatHist = [yHatHist; yHat];
                fwrite(playerClient, yHat);
         
                testEEG(1:windowLength-overlapSampleLength,:) = NaN;
                %Only the shift is cleaned.
                %note that if overlap = 0, then all the matrix is set to
                %NaN
                
                if playerClient.BytesAvailable > 0
                    playerData = fread(playerClient, 1);
                    if(playerData == 'Q')
                        break;
                    elseif(playerData == 'R')
                        needWaitHandshake = 1;
                        trainEEG(:) = NaN;
                        testEEG(:) = NaN;
                        nRun = nRun+1;
                        
                    end
                end
            end
    end
    
    delay_ms(200);
end %while true

saveName = ['test_player_', playerName, num2str(playerNb),'_',num2str(now), '_', num2str(nRun), '.mat'];
testData.port2boss = port2boss;
testData.port2acq = port2acq;
testData.playerNb = playerNb;
testData.raw = electUsed;
testData.Fs = fs;
testData.device = device;
testData.chLabels = chLabels;
testData.data = FullTestSave;
% testData.Threshold = scoreThreshold;
% testData.YHats = FullYHat;
% testData.YEvals = FullYEval;

save(saveName, 'testData');
disp(['Test data saved in ',saveName,'.'])

subplot(2,1,1);
plot(FullTestSave);
subplot(2,1,2);
plot([FullYEval FullYHat]);
bPress = 0;
% while bPress == 0
%     bPress = waitforbuttonpress;
% end

tone(500,1000); %beep
fclose(eegServer);
delay_ms(500);
fclose(playerClient);
disp(['Done with Player ',num2str(playerNb)]);
