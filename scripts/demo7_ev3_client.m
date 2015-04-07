%Using the lego mindstorms with the block EV3
%This example is based in the toolbox
% https://wiki.qut.edu.au/display/cyphy/QUT+EV3+MATLAB+toolkit
% and its documentation

%The robot consists in two Continuous tracks (Right and Left) connected to
%the ports B and C respectively

%Raymundo Cassani
%Sept 2014

%% Connecting the Brick using USB and bluetooth 
% Initialization of connection is slower using BT but more responsive
% Use preferently BT 
% When connected, a Beep is produced
clear all;
close all;

mode = 'BT'; % USB, BT

disp('Connectiing with EV3 Brick...')
tic
try
    switch mode
        case 'USB'
            b = Brick('ioType','usb');
        case 'BT'
            b = Brick('ioType','instrbt','btDevice','EV3','btChannel',1);
    end
    b.beep();
    sprintf('Connection required %f seconds',toc)
catch
end

% Contrilling motors
pause(1);
motorPowerB = 0;
motorPowerC = 0;
%Note that 50 is 50% forward and -50 is %50 backward 

%Start the motors with zero power
b.outputStart(0,Device.MotorB);
pause(0.01);
b.outputStart(0,Device.MotorC);


disp('%%%%%%%%%%%%%%%%')

ev3Client=tcpip('localhost', 33000, 'NetworkRole', 'client');
ev3Client.InputBufferSize = 5000;
ev3Client.Timeout = 600;
fopen(ev3Client);
%Timeout
disp('Successful connection with Server')


while true
    %This ensures that we are reading only the newest commands
    bd = ev3Client.BytesAvailable;
    if bd > 2
        fread(ev3Client, ev3Client.BytesAvailable-2);    
    end
    
    motorPowerB = fread(ev3Client,1);
    motorPowerC = fread(ev3Client,1);
    if motorPowerB>100 && motorPowerC > 100
        break
    end
        
    b.outputPower(0,Device.MotorB,motorPowerB);
    b.outputPower(0,Device.MotorC,motorPowerC);
        
end 

%Remember to destroy the Brick
b.delete
fclose(ev3Client);

