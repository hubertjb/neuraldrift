function [params, trainingAcc] = featureClassif(featureUsed0, featureUsed1, method)


n0 = length(featureUsed0);
n1 = length(featureUsed1);

labels0 = zeros(size(featureUsed0,1),1);
labels1 = ones(size(featureUsed1,1),1);

X = [featureUsed0; featureUsed1];
y = [labels0; labels1]+1;

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
    trainingAcc = NaN;
end



    
    
    

