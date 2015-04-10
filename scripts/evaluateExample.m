function yHat = evaluateExample(evalData, Fs, modelParams, mu_col, sigma_col, selectedFeatInd, classifierType)
% Classify the given example according to a trained classifier.
% 
% Inputs
%   evalData: raw EEG data [nbSamples, nbCh]
%   Fs: sampling frequency of the raw data
%   modelParams: object containing the parameters of the trained classifier
%   mu_col: average value of each feature (for z-score normalization)
%   sigma_col: std of each feature (for z-score normalization)
%   selectedFeatInd: indices of selected features
%   classifierType: 'SVM' or 'LR'
%
% Output
%   yHat

example = featureExtract(double(evalData), Fs);
example = (example-mu_col)./sigma_col; % z-score normalize

yEval = modelPredict(modelParams, example(selectedFeatInd), classifierType);
yHat = yEval;



