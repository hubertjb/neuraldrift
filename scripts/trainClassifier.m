function [params, trainingAcc] = trainClassifier(feature0, feature1, method)
% Trains a binary classifier.
%
% Inputs
%   feature0: Features for class 0
%             array of dimension [number of features points, number of different features  + 1]
%             each column corresponds to the observations of one type of
%             feature; the very last column is the corresponding labels
%   feature1: Features for class 1 (same structure as feature0)
%   method:   Classifier to use (either 'LR' for logistic regression or
%             'SVM' for support vector machines
%
% Outputs
%   params:
%   trainingAcc: 

labels0 = zeros(size(feature0,1),1);
labels1 = ones(size(feature1,1),1);

X = [feature0; feature1];
y = [labels0; labels1]+1; % Why is there a "+1" again?

if strcmp(method,'LR')
    params = mnrfit(X,y);
    [~, yhat_lr] = max(mnrval(params, X), [], 2);
    acc_lr = classperf(y, yhat_lr);
    disp(['Train accuracy: ', num2str(acc_lr.CorrectRate*100), '%']);
    trainingAcc = acc_lr.CorrectRate*100;
    
elseif strcmp(method,'SVM')
    params = svmtrain(X, y, 'kernel_function', 'linear');
    yhat_svm = svmclassify(params, X);
    acc_svm = classperf(y, yhat_svm);
    disp(['Train accuracy: ', num2str(acc_svm.CorrectRate*100), '%']);
    trainingAcc = acc_svm.CorrectRate*100;
    
else
    error([method,' is not a supported classifier.']);
    trainingAcc = NaN;
    
end



    
    
    

