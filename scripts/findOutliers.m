function [outInd] = findOutliers(data)
%% Identify the outliers of a sample using a box plot and return them
%

% Inputs:
%   data: matrix, where rows are observations and rows are different
%         variables
% Outputs:
%   outInd: array with the outlier indices


% Plot the box plot
figure()
boxplot(data);
h = findobj(gcf,'tag','Outliers');

% Get the outliers X and Y data
outXlist = get(h,'XData');
outYlist = get(h,'YData');
outInd = [];

% If not a cell array, cast to cell array
if ~iscell(outXlist)
    outXlist = num2cell(outXlist);
    outYlist = num2cell(outYlist);
end

for i = 1:length(outXlist)
    if ~isnan(outXlist{i})
        for j = 1:numel(outXlist{i})
            outInd(end+1) = find(data(:,outXlist{i}(j)) == outYlist{i}(j));
        end
    end
end

close(gcf)