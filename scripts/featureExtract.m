function [featArray, featNames] = featureExtract(rawData, Fs, varargin)
%% Extract the features from the EEG. Takes 0.003 seconds to execute on 2-second windows on my machine (i7, 8gb)
% 
% Feature list
% 1- Delta
% 2- Theta
% 3- Alpha in parieto-temporal (A1, A2)
% 4- Beta in frontal (Fp1, Fp2)
% 5- Alpha/beta
% 6- Theta/beta
% 7- Delta/beta
% 8- Std(delta)
% 9- Std(theta)
% 10- Std(alpha)
% 11- Std(beta)
% 12- Std(alpha/beta)
% 13- Std(theta/beta)
% 14- Std(delta/beta)

% Inputs:
%   rawData: array of dimension [number of samples, number of channels]
%   Fs: sampling frequency of the raw data
%   [Optional] currentClass: (int) class of raw data
%   [Optional] plotPSD: (bool) if true, plot the PSD of the preprocessed data
% Outputs:
%   featArray: [number of features points; number of different features
%   featNames: cell array containing the names of all the computed features
%   logPSD: the logarithm of the PSD, as computed for further feature
%           extraction (for debugging purposes!)

% If it is calibration data, extract the class target from varargin
nVarargs = length(varargin);
switch nVarargs
    case 1
        currentClass = varargin{1};
        plotPSD = false;
    case 2
        currentClass = varargin{1};
        plotPSD = varargin{2};
    otherwise
        currentClass = NaN;
        plotPSD = false;
end

%% 1. Compute the log-normalized PSD

[winSampleLength, nbCh] = size(rawData);
t = (0:winSampleLength-1)/Fs;
w = hamming(winSampleLength,'periodic');

% PCA (Keep the two first components)
% [coeff,score,~,~,~,~] = pca(rawData);
% componentsToKeep = [1,2,3,4];
% dataWinCentered = score(:,componentsToKeep)*coeff(componentsToKeep,:);
dataWinCentered = (rawData - repmat(mean(rawData),winSampleLength,1)); %./repmat(std(rawData),winSampleLength,1);

% Apply the Hamming window
dataWinCenteredHam = dataWinCentered.*repmat(w, 1, nbCh);

NFFT = 2^nextpow2(winSampleLength);
Y  = fft(dataWinCenteredHam, NFFT)/winSampleLength;
% logPSD = log10(2*abs(Y(1:NFFT/2+1,:)));
logPSD = (2*abs(Y(1:NFFT/2+1,:)));
f = Fs/2*linspace(0,1,NFFT/2+1);

% Plot the logPSD of the PCA-filtered raw signals  
if plotPSD %true && currentClass == 1
    figure(101);
    
    subplot(4,1,1)
    plot(t, [rawData])
    legend('A1','Fp1','Fp2','A2')
    title(['Original signals (class ',num2str(currentClass),')']);
    ylabel('Amplitude')
    
    subplot(4,1,2)
    plot(t, [score])
    legend('PC1','PC2','PC3','PC4')
    title('Principal components')
    ylabel('Amplitude')
    
    subplot(4,1,3)
    plot(t, [dataWinCentered])
    legend('A1','Fp1','Fp2','A2')
    title('Reconstructed signals');
    xlabel('Time (s)')
    ylabel('Amplitude')
    
    subplot(4,1,4)
    plot(f, [exp(logPSD)])
    legend('A1','Fp1','Fp2','A2')
    title('PSD');
    xlabel('Frequency (Hz)')
    set(gca,'XTick',0:10:Fs/2)
    ylabel('Power')
    
    pause()
end

%% 2. Bandpass the PCA-corrected time signals (NOT USED BECAUSE OF THE START/END DAMPING)
% Wp = 0.1/Fs/2; Ws = 40/Fs/2;
% [n,Wn] = buttord(Wp,Ws,1,60);
% [b,a]=butter(n,Wn);
% dataWinFiltered = filter(b,a,dataWinCentered);
dataWinFiltered = dataWinCentered;

%% 2. Compute the features

if nbCh == 1 % Neurosky
    alphaCh = 1;
    betaCh = 1;
else % Muse, Enobio, Emotiv
    alphaCh = [1,4];
    betaCh = [2,3];
end

% SPECTRAL FEATURES
% Average and standard deviation of band powers
% Delta <4
ind_delta = (f<4);
meanDelta = mean(logPSD(ind_delta,:));
stdDelta = std(logPSD(ind_delta,:),0,1);
% Theta 4-8
ind_theta = (f>=4 & f<=8);
meanTheta = mean(logPSD(ind_theta,:));
stdTheta = std(logPSD(ind_theta,:),0,1);
% Alpha 8-12
ind_alpha = (f>=8 & f<=12);
meanAlpha = mean(logPSD(ind_alpha,alphaCh)); % meanAlpha = mean(logPSD(ind_alpha,:));
stdAlpha = std(logPSD(ind_alpha,alphaCh),0,1);
% Beta 12-30
ind_beta = (f>=12 & f<=30);
meanBeta = mean(logPSD(ind_beta,betaCh));
stdBeta = std(logPSD(ind_beta,betaCh),0,1);

% Fill the array of features
featArray(1) = mean(meanDelta);
featArray(2) = mean(meanTheta);
featArray(3) = mean(meanAlpha);
featArray(4) = mean(meanBeta);

featArray(5) = featArray(3)./featArray(4);
featArray(6) = featArray(2)./featArray(4);
featArray(7) = featArray(1)./featArray(4);

featArray(8) = mean(stdDelta);
featArray(9) = mean(stdTheta);
featArray(10) = mean(stdAlpha);
featArray(11) = mean(stdBeta);

featArray(12) = featArray(10)./featArray(11);
featArray(13) = featArray(9)./featArray(11);
featArray(14) = featArray(8)./featArray(11);

featNames = {'delta','theta','alpha_temp','beta_front','alpha/beta','theta/beta','delta/beta','std_delta','std_theta','std_alpha_temp','std_beta_front','std_alpha/beta','std_theta/beta','std_delta_beta'};

currFeatInd = length(featArray);

% TEMPORAL FEATURES
% a) Mean and log variance of the amplitude values
meanAmp = mean(dataWinFiltered);
varAmp = log10(var(dataWinFiltered));

featArray(currFeatInd:currFeatInd+nbCh-1) = meanAmp;
featArray(currFeatInd+nbCh:currFeatInd+2*nbCh-1) = varAmp;
for j = 1:nbCh
    featNames{end+1} = ['meanAmp_ch',num2str(j)];
    featNames{end+1} = ['varAmp_ch',num2str(j)];
end
currFeatInd = length(featArray)+1;

% b) Autoregressive model
order = 6;
for i = 1:nbCh
    arcoeff = aryule(dataWinFiltered(:,i),order);
    featArray(currFeatInd:currFeatInd+order-1) = arcoeff(2:end);
    currFeatInd = length(featArray)+1;
    for j = order:-1:1 % skip the last coefficient! (It's always 1...)
        featNames{end+1} = ['ar',num2str(order),'_coeff',num2str(j),'_ch',num2str(i)];
    end
end

% c) Information theoritic features
% TODO

% d) Wavelet coefficients
% cw1 = cwt(dataWinFiltered(:,1),1:32,'sym2','plot'); 
% title('Continuous Transform, absolute coefficients.') 
% ylabel('Scale')
% [cw1,sc] = cwt(dataWinFiltered(:,1),1:32,'sym2','scal');
% title('Scalogram') 
% ylabel('Scale')



% Add the targets in featArray
featArray(1,currFeatInd) = currentClass;

