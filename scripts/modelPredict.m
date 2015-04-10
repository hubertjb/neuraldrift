function yEval = modelPredict(modelParams, feats, method)

if strcmp(method,'LR')
    yEval = mnrval(modelParams, feats);
elseif strcmp(method,'SVM')
    yEval = svmclassify(modelParams, feats);
end