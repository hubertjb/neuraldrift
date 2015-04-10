function Boss()

% Description of Boss Script

% Begining
clear all;
close all;
clc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%   === Configuration of Output Devices ===     %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Enables of Disables EV3 Robot, Bluetooth
bolRobot = false;

% % Enables of Disables Android App, Bluetooth
bolTablet = true;

% Bluetooth configuration for Smartphone or Table running the Android App
btDevice = 'MuSAE N7';
btChannel = 3;
% If you do not know the bluetooth channel number, uncomment the next line:
%btChannel = 0
% Matlab will search for the correct channel, however the connection will 
% take longer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%   === Player Information ===                  %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Name of Players 
player1Name = 'Ana';
player2Name = 'Wil';

% TCP/IP ports for communication with respective PlayerFunct.m instances 
player1Port = 33001;
player2Port = 33002;

% Verify names
if isempty(player1Name) || isempty(player2Name)
    if isempty(player1Name)
        player1Name = 'PC1';
    end
    if isempty(player1Name)
        player2Name = 'PC2';
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% === Configuration of Game Mechanics ===       %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Game Mechanics
trainDuration  = 15;  % Duration of each training section
windowDuration = 2;   % Duration of the test window to extract features
testOverlap    = 1;   % Overlap for the windows

% General Variables
bolPlayer1 = true;
bolPlayer2 = true;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%   === Dependencies and User Interaction ===   %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Adds the parent directory to the Matlab Path
folder = [pwd '\'];
cd('..\');
addpath(genpath(pwd));
pathMules = [pwd '\' 'mules'];
cd(folder);

% Matlab executable path, change if necessary
matlabExePath = ' "C:\Program Files\MATLAB\R2013a\bin\matlab.exe" ';
disp('###### Neural Drift #######')
disp('');

% Creation of a Figure to detect pressesed keys
h = figure();
set(h,'currentch',char(0));

% Audio cue, Beep
audiofilename = 'beep.mp3';
[yBeep, FsBeep] = audioread(audiofilename);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%          Connection with EV3 Robot            %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if bolRobot
    disp('Waiting for EV3 client on port 33000...')
    ev3Server=tcpip('0.0.0.0', 33000, 'NetworkRole', 'server');
    ev3Server.InputBufferSize = 500000;
    ev3Server.Timeout = 60; %in seconds
    %Run EV3 client script in another matlab instance
    system( [ matlabExePath ' -nosplash -nodesktop -r "run(''' folder '\ev3_client.m''); exit();"']);
    %Open a connection with the EV3 client
    fopen(ev3Server);
    disp('Successful connection with EV3 client')
    delay_ms(50);
    sendPowersEV3(0,0);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%  Connection with Android App (in Tablet)      %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if bolTablet
    disp('Waiting for connection with Tablet...');
    if btChannel <= 0
        btInfo = instrhwinfo('Bluetooth',btDevice);
        btDevice = btInfo.RemoteName;
        btChannel = str2num(btInfo.Channels{1});
    end
    disp(sprintf('Connecting with: %s, in channel: %d',btDevice, btChannel));
    %Opening connection with Tablet
    tabletServer = Bluetooth(btDevice,btChannel);
    fopen(tabletServer);
    disp('Bluetooth connection opened sucessfully!');
    disp('Touch the tablet screen to start');
    input('Press Enter to Continue')
    %Receiving a string from the Tablet, the string is ended ('\r')
    index=1;
    while true
        if tabletServer.BytesAvailable ~= 0
            dataRx(index) = fread(tabletServer, 1);
            if dataRx(index) < 20 %See ASCII table ENTER is below 20
                break
            else
                index = index +1 ;
            end
        end
        pause(0.01);
        %tabletServer.BytesAvailable
    end
    
    %Welcoming string from the Tablet, this string is used to check that
    %the bluettoth connection is working properly
    disp(char(dataRx));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%  Execute MuLES Instances                      %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
system( [pathMules '\mules.exe -- "DEVICE01" PORT=30001 LOG=F TCP=T &']);
system( [pathMules '\mules.exe -- "DEVICE02" PORT=30002 LOG=F TCP=T &']);
cd(folder);

%Start sound
filename = 'deep_bass.wav';
[y, Fs] = audioread(filename);
sound(y,Fs/1.1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%           Connection with Player1             %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if bolPlayer1
    disp('Waiting for Player1 client on port 33001...')
    %Open the communication with EEGacq program
    player1Server = tcpip('0.0.0.0', 33001, 'NetworkRole', 'server');
    player1Server.InputBufferSize = 5000000;
    player1Server.Timeout = 20; %in seconds
    
    %Calling PlayerFunct to player1
    playerNameAux = ['''''' player1Name  ''''''];
    system( [ matlabExePath ' -nosplash -nodesktop -r "run(''' [folder ...
        'PlayerFunct(33001,30001,' playerNameAux ',' num2str(trainDuration) ',' ...
        num2str(windowDuration) ',' num2str(testOverlap)]  ')''); exit();"']);
    
    %fopen waits for the client connection.
    fopen(player1Server);
    disp('Connected to Player 1 !')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%           Connection with Player2             %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if bolPlayer2
    disp('Waiting for Player2 client on port 33002...')
    %Open the communication with EEGacq program
    player2Server = tcpip('0.0.0.0', 33002, 'NetworkRole', 'server');
    player2Server.InputBufferSize = 5000000;
    player2Server.Timeout = 20; %in seconds
    
    %Calling PlayerFunct to player1
    playerNameAux = ['''''' player2Name  ''''''];
    system( [ matlabExePath ' -nosplash -nodesktop -r "run(''' [folder ...
        'PlayerFunct(33002,30002,' playerNameAux ',' num2str(trainDuration) ',' ...
        num2str(windowDuration) ',' num2str(testOverlap)]  ')''); exit();"']);
    
    %fopen waits for the client connection.
    fopen(player2Server);
    disp('Connected to Player2 !')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%              === NeuralDrift ===              %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Waiting for both Players to send notifier
waitTwoPlayers();
    
% First Run
nRun = 1;

while true % N-Runs Loop
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%                    Phase 1                    %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Clear communication buffers from previous data for Player1 and Player2
    if bolPlayer1 && player1Server.BytesAvailable > 0
        fread(player1Server, player1Server.BytesAvailable);
    end
    if bolPlayer2 && player2Server.BytesAvailable > 0
        fread(player2Server, player2Server.BytesAvailable);
    end
    
    disp('Handshake Phase 1...')
    sendCommandTablet(204); % 0xCC
    sendCommandPlayers('A');
    
    %This sound indicates that the Phase 1 is initiated
    filename = 'initiating.mp3';
    [y, Fs] = audioread(filename);
    sound(y,Fs/1.1);
    
    % Waiting for both Players to send notifier
    waitTwoPlayers();

    % Phase 1 completed
    disp('Handshake Phase 1 Done !')
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%                    Phase 2                    %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    disp('Handshake Phase 2...')
    sendCommandTablet(221); % 0xDD
    sendCommandPlayers('B');
    
    %This sound indicates that the Phase 2 is initiated
    filename = 'phase2.mp3';
    [y, Fs] = audioread(filename);
    sound(y,Fs/1.1);
    
    % Waiting for both Players to send notifier
    waitTwoPlayers()
    
    % Phase 2 completed 
    disp('Handshake Phase 2 Done !')
    
    %This sound indicates that Phase 1 and Phase 2 are completed
    filename = 'completed.mp3';
    [y, Fs] = audioread(filename);
    sound(y,Fs/1.1);
    delay_ms(1000);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%              === Training ===                 %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    disp('Handshake Training...')  
    sendCommandTablet(238); % 0xEE
    sendCommandPlayers('C');
    
    % Waiting for both Players to send notifier
    waitTwoPlayers()
    
    %This sound indicates that the Classifiers has been trained
    disp('Handshake Done !')
    filename = 'strong_and_holding.mp3';
    [y, Fs] = audioread(filename);
    sound(y,Fs/1.1);
    delay_ms(1000);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%            === Real Time Game ===             %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    disp('Starting the Game...');    
    sendCommandTablet(255); % 0xFF
    sendCommandPlayers('D');
    
    %This sound indicates that the Game has started
    sound(yBeep,FsBeep);
    
    % Waiting for 1 of the 2 Players to quit the game.
    serversState = zeros(2,1);
    
    % Game Variables
    powerP1 = 20;
    powerP1LastClass = 0;
    powerP2 = 20;
    powerP2LastClass = 0;
    toggleStop = false;
    newDecision1 = 1;
    newDecision2 = 1;
    powerP1Step = 0;
    powerP2Step = 0;   
    player1Data = 0;
    player2Data = 0;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%          Gaming Loop                          %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    
    while true %Gaming Loop
        
        incStep = 50;
        motorFactor = 0.25;            
        %Game Mechanics
        if bolPlayer1 && player1Server.BytesAvailable > 0
            player1Data = fread(player1Server, player1Server.BytesAvailable);
            newDecision1 = 1;
            switch player1Data(1)
                case 1,
                    % powerP1 = 50;
                    if powerP1LastClass == 1
                        powerP1Step = powerP1Step + incStep;
                    else
                        powerP1Step = incStep;
                    end
                    powerP1 = powerP1 + powerP1Step;
                case 2,
                    % powerP1 = 0;
                    if powerP1LastClass == 2
                        powerP1Step = powerP1Step - incStep;
                    else
                        powerP1Step = -incStep;
                    end
                    powerP1 = powerP1 + powerP1Step;
            end
            powerP1LastClass = player1Data;
                     
            if powerP1 > 99
                powerP1 = 100;
            elseif powerP1 < 1
                powerP1 = 0;
            end       
        end
        
        if bolPlayer2 && player2Server.BytesAvailable > 0
            player2Data = fread(player2Server, player2Server.BytesAvailable);
            newDecision2 = 1;
            switch player2Data(1)
                case 1,
                    % powerP2 = 50;
                    if powerP2LastClass == 1
                        powerP2Step = powerP2Step + incStep;
                    else
                        powerP2Step = incStep;
                    end
                    powerP2 = powerP2 + powerP2Step;
                case 2,
                    % powerP2 = 0;
                    if powerP2LastClass == 2
                        powerP2Step = powerP2Step - incStep;
                    else
                        powerP2Step = - incStep;
                    end
                    powerP2 = powerP2 + powerP2Step;
            end
            powerP2LastClass = player2Data;
            
            if powerP2 > 99
                powerP2 = 100;
            elseif powerP2 < 1
                powerP2 = 0;
            end
        end
        
        %If a decision was read from any player, update Robot and Tablet
        if newDecision1 == 1 || newDecision2 == 1
            newDecision1 = 0;
            newDecision2 = 0;
            barP1 = uint8(round(powerP1*(10/100)));
            barP2 = uint8(round(powerP2*(10/100)));
            bar1Array = dec2bin(barP1,4);
            bar2Array = dec2bin(barP2,4);
            %Build byte to send to the Tablet
            %High 4 bits encode power from 0 to 10 for P1
            %Low  4 bits encode power from 0 to 10 for P2
            byteBars = [bar1Array,bar2Array];
            bytePowers = uint8(bin2dec(byteBars));
            
            sendCommandTablet(bytePowers);
            delay_ms(500); 
            
            if toggleStop
                sendPowersEV3(0,0);
            else
                sendPowersEV3(motorFactor * powerP1,motorFactor * powerP2);
            end
                       
            fprintf('%d %d (%d) | %d %d (%d)\n', player1Data, powerP1, powerP1Step, player2Data, powerP2, powerP2Step) 
        end
        
        % Detect KeyPressed in Figure "h"
        drawnow; %Need to update CurrentCharacter property
        commandKey = get(h,'CurrentCharacter');
        set(h,'currentch',char(0));
        
        switch commandKey
            case ' ', %SPACE, turns the Robot motors ON / OFF
                disp(toggleStop);
                toggleStop = ~toggleStop;
            case char(27), %ESC  
                break; %Breaks Gaming Loop
            case 'r', 
                break; %Breaks Gaming Loop
            case 'n', %prints information about the game
                fprintf('Class for P1 = %d\r',player1Data);
                fprintf('Class for P2 = %d\r',player2Data);
                fprintf('P1 power = %d\r',powerP1);
                fprintf('P2 power = %d\r',powerP2);
                fprintf('Byte sent to Tablet = %x\r',bytePowers);
                fprintf('Toggle Status %i\r', toggleStop);
        end %Switch commandKey
    end %Gaming Loop
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%           === Out of Gaming Loop ===          %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    switch commandKey
        case char(27), %ESC
            break; %Breaks N-Runs Loop
        case 'r' %Reinitialize the Game (Goto Phase 1)
            sendCommandTablet(187); %xBB
            sendPowersEV3(0,0);
            nRun = nRun +1;
            sendCommandPlayers('R');
            sound(yBeep,FsBeep);
            delay_ms(200);
            sound(yBeep,FsBeep);
            delay_ms(2000);
            input('Press ENTER to continue');
    end
    
end %N-Runs Loop

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%         === Closing connections  ===          %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%This sound indicates that all connections will be closed
sound(yBeep,FsBeep);
delay_ms(200);
sound(yBeep,FsBeep);
delay_ms(200);
sound(yBeep,FsBeep);

% Close EV3
if bolRobot
    sendPowersEV3(0,0);
    delay_ms(200);
    sendPowersEV3(101,101); % Stops the ev3_client.m script
    delay_ms(200);
    fclose(ev3Server);
end

% Close Tablet
if bolTablet
    sendCommandTablet(187); % 0xBB
    delay_ms(500);
    fclose(tabletServer);
end

% Close Player 1
if bolPlayer1
    fwrite(player1Server,'Q');
    delay_ms(500);
    fclose(player1Server);
end

% Close Player 2
if bolPlayer2
    fwrite(player2Server,'Q');
    delay_ms(500);
    fclose(player2Server);
end

close all
disp('Bye !')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%         === Auxiliary Functions ===           %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function waitTwoPlayers()
        % Waiting for 2 Players to finish the Handshake, it finishes when
        % the two players answer
        serversState = zeros(2,1);
        while min(serversState) == 0
            delay_ms(100);

            if bolPlayer1
                if player1Server.BytesAvailable > 0
                    player1Data = fread(player1Server, player1Server.BytesAvailable);
                    serversState(1) = 1; % Player 1 has finished Handshake Phase 2
                end
            else
                serversState(1) = 1; % Player 1 has finished Handshake 
            end
            
            if bolPlayer2
                if player2Server.BytesAvailable > 0
                    player2Data = fread(player2Server, player2Server.BytesAvailable);
                    serversState(2) = 1; % Player 2 has finished Handshake Phase 2
                end
            else
                serversState(2) = 1; % Player 2 has finished Handshake 
            end
        end

    end

    function sendCommandPlayers(command)
        %Send Commands to both Players
            if bolPlayer1
                fwrite(player1Server, command);
            end
            if bolPlayer2
                fwrite(player2Server, command);
            end
    end

    function sendCommandTablet(command)
        %Send Command to Tablet if it is enabled
            if bolTablet
                % Command for table is composed for two nibbles 
                fwrite(tabletServer, command, 'uint8'); 
            end
    end

    function sendPowersEV3(power1, power2)
        %Send Power values for the EV3 Robot, if it is enabled
            if bolRobot
                % Package consist of two bytes, power1 and power2  
                fwrite(ev3Server, uint8([power1,power2]), 'uint8' );
            end
    end

end % Boss Function
