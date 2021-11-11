% --- creates a multi-line axis label array
function axLblF = createMultiLineAxisLabel(lblStr)

% memory allocation
axLbl = cell(1,length(lblStr));

% sets up the label string array
for i = 1:length(lblStr)
    % builds up the axis label string array
    lblStrNw = lblStr{i}{1};
    for j = 2:length(lblStr{i})
        lblStrNw = sprintf('%s\\newline%s',lblStrNw,lblStr{i}{j});
    end
    
    % sets the final axis label
    axLbl{i} = sprintf('%s\n',lblStrNw);
end

%
axLblF = strtrim(strjoin(axLbl));