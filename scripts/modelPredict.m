function yEval = modelPredict(modelParams, electUsed, method)

if strcmp(method,'LR')
    yEval = mnrval(modelParams, electUsed);
elseif strcmp(method,'SVM')
    yEval = svmclassify(modelParams, electUsed);
end