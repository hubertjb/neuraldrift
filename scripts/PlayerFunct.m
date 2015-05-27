function PlayerFunct(port2main, port2acq, playerName, trainDuration, windowDuration, testOverlap)

% Adds the parent directory to the Matlab Path
folder = [pwd '\'];
cd('..\');
addpath(genpath(pwd));
cd(folder);

% Find the player number
if port2main == 33001
    playerNb = 1;
elseif port2main == 33002
    playerNb = 2;
else
    disp('Player number could not be identified.');
    playerNb = 0;
end

disp(['Player ',num2str(playerNb)]);
disp(playerName);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%              Connection with main             %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Trying to connect to main...')
playerClient = tcpip('0.0.0.0', port2main, 'NetworkRole', 'client');
playerClient.Timeout = 60; %in seconds
fopen(playerClient);
disp('Connected to main !')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%              Connection with MuLES            %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Trying to connect to MuLES...')
mulesClient = tcpip('0.0.0.0', port2acq, 'NetworkRole', 'client');
mulesClient.InputBufferSize = 5000000;
mulesClient.Timeout = 10; %in seconds

% Wait for the connection with MuLES 
waitingMules = true;
while waitingMules
    waitingMules = false;
    try
        fopen(mulesClient);
    catch
        waitingMules = true;
    end
end

disp('Connected to MuLES !')

% Audio cue, Player has correctly started
audiofilename = 'beep.mp3';
[y, sampF] = audioread(audiofilename);
sound(y,sampF);

% Notify main
fwrite(playerClient, 1); % Notify main

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%              Obtain EEG device info           %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[dev_name, dev_hardware, Fs, tags, nCh] = headerMules();

disp(strcat('Using : ', dev_hardware));

% Selection of Electrodes to compute Alpha power
switch dev_hardware
    case 'INTERAXON-MUSE'
        electArray = [1:4];
        electNames = {'TP7', 'Fp1', 'Fp2', 'TP8'};
    case 'EMOTIV'
        electArray = [9:12];
    case 'ENOBIO'
        electArray = [1:4];
    case 'NEUROSKY'
        electArray = [1];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%              Title                            %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nSamplesTrain = trainDuration * Fs;
nSamplesWindow = windowDuration * Fs;
nSamplesOverlap = testOverlap * Fs;

nColumns = numel(tags);
evalData = NaN(nSamplesWindow*2,nColumns);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%              Main Loop                        %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

quitFlag = false;
evalFirst = true;
nRun = 1;

while true % Player Loop
    commandBoss = fread(playerClient, 1);
    switch commandBoss % Command Switch
        case 'A', %Training data Class 0
            disp('Handshake Phase 1...');
            flushMules();
            pause(trainDuration*1.2);
            eegData = getDataMules();
            train0 = eegData(size(eegData,1)-nSamplesTrain+1 : end,:); 
            sound(y,sampF); %beep
            fwrite(playerClient, 1); % Notify main
        case 'B', %Training data Class 1
            disp('Handshake Phase 2...');
            flushMules();
            pause(trainDuration*1.2);
            eegData = getDataMules();
            train1 = eegData(size(eegData,1)-nSamplesTrain+1 : end,:); 
            sound(y,sampF); %beep
            fwrite(playerClient, 1); % Notify main
        case 'C', %Training classifier
            classifierType = 'SVM';
            % Select electrodes using electArray variable
            [model, mu_col, sigma_col, selectedFeatInd] = learnModel(train0(:,electArray), train1(:,electArray), ...
                                                                          nSamplesWindow, nSamplesOverlap, Fs, ...
                                                                          classifierType, playerName);
            sound(y,sampF); %beep
            delay_ms(200);
            sound(y,sampF); %beep
            fwrite(playerClient, 1); % Notify main
        case 'D', %Evaluate
            evalTic = tic;
            limit = windowDuration;
            while true %Classification Loop
                delay_ms(200);
                % Get data and classify
                if toc(evalTic) > limit*1.1
                    evalTic = tic;
                    limit = testOverlap;
                    eegData = getDataMules();
                    evalData = [evalData;eegData];
                    evalData = evalData(size(evalData,1)-nSamplesWindow+1:end,:);
                    yHat = evaluateExample(evalData(:,electArray), Fs, model, ...
                                           mu_col, sigma_col, selectedFeatInd, classifierType); % Classify the example
                    fwrite(playerClient, yHat);
                end
                           
                % Check if the main requested to Stop
                if playerClient.BytesAvailable > 0 % If available bytes
                    commandBoss = fread(playerClient, 1);
                    if(commandBoss == 'Q') %If Q command
                        quitFlag = true;
                        break; % Breaks Classification Loop
                    elseif(commandBoss == 'R')                      
                        nRun = nRun+1;
                        break; % Breaks Classification Loop
                    end %If Q command
                end % If available bytes 
                
            end % Classification Loop          
    end % Command Switch  
    
    if quitFlag
        break;
    end
end %Player Loop

sound(y,sampF); %beep
% Kill MuLES
killMules();
delay_ms(500);
fclose(mulesClient);
delay_ms(500);
fclose(playerClient);
disp(['Done with Player ',num2str(playerNb)]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%              Auxiliary Functions              %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function flushMules()
        %Deletes all the data in the MuLES Buffer
        commandMules = 'F';
        fwrite(mulesClient, commandMules);
    end

    function [dev_name, dev_hardware, Fs, data_format, nCh] = headerMules()
        % Get information about the EEG device from MuLES
        commandMules = 'H';
        fwrite(mulesClient, commandMules);
        nBytes_4B = fread(mulesClient, 4);  %How large is the package (# bytes)
        nBytes = double(swapbytes(typecast(uint8(nBytes_4B),'int32')));
        package = fread(mulesClient,nBytes);
        header_str = char(package)';
        [dev_name, dev_hardware, Fs, data_format, nCh] = mules_parse_header(header_str);
    end

    function  ch_labels = chNamesMules()
        % Get Channel Names from MuLES
        commandMules = 'N';
        fwrite(mulesClient, commandMules);
        nBytes_4B = fread(mulesClient, 4);  %How large is the package (# bytes)
        nBytes = double(swapbytes(typecast(uint8(nBytes_4B),'int32')));
        package = fread(mulesClient,nBytes);
        ch_names_str = char(package)';
        tmp = textscan(ch_names_str,'%s','delimiter',',');
        ch_labels = tmp{1};
    end

    function eeg_data = getDataMules()
        % Get EEG Data from MuLES
        commandMules = 'R';
        fwrite(mulesClient, commandMules);
        nBytes_4B = fread(mulesClient, 4);  %How large is the package (# bytes)
        nBytes = double(swapbytes(typecast(uint8(nBytes_4B),'int32')));
        eeg_package = fread(mulesClient,nBytes);
        eeg_data = mules_parse_data(eeg_package,tags);
    end

    function killMules()
        %Stops Acquisition and closes MuLES
        commandMules = 'K';
        fwrite(mulesClient, commandMules);
    end

end % END of PlayerFunct
