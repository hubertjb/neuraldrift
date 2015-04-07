function [selectedFeatInd] = featureSelect(featArray, targets, nbFeats, varargin)
%% Extract the features from the EEG. Takes 0.003 seconds to execute on 2-second windows on my machine (i7, 8gb)
% 

% Inputs:
%   featArray: [number of features points; number of different features [number of examples, number of features]
%   targets: array containing the targets for every example in featArray
%   nbFeats: number of features to keep
%   [Optional] plotPSD: (bool) if true, plot the PSD of the preprocessed data
% Outputs:
%   selectedFeatures: array containing the list of selected features
%   (indices as found in featArray)

%% Get the correlation matrix
[r,p] = corrcoef([featArray,targets]);  % Compute sample correlation and p-values.
r = r(1:end-1,end); % Only keep the correlations with the targets
p = p(1:end-1,end);

i = find(p<0.05);  % Find significant correlations.
thresholdedR = abs(r);
thresholdedR(p>=0.05) = 0;
thresholdedR(isnan(thresholdedR)) = 0;

%% Select the 5 best features with (p<0.05)

[~,I] = sort(thresholdedR, 'descend');

selectedFeatInd = I(1:nbFeats);