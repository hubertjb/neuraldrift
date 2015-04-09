function delay_ms(miliSeconds)
%DELAY function pauses the program during MILISECONDS (ms) 
% MILISECONDS = delay time in miliseconds
%
% Raymundo Cassani

seconds = miliSeconds/1000;
tic_delay = tic;
while toc(tic_delay) < seconds
end
%Nothing here
end


