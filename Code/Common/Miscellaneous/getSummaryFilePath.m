function summFile = getSummaryFilePath(iData)

% sets the path for the summary file (from the solution file directory)
if isfield(iData,'sfData')
    if ~isempty(iData.sfData)
        % sets the full file path. if the file exists, then exit
        summFile = fullfile(iData.sfData.dir,'Summary.mat');
        if exist(summFile,'file'); return; end
    end
end

% sets the path for the summary file (from the video file directory)
if isfield(iData,'movStr')
    % sets the full file path. if the file exists, then exit
    summFile = fullfile(fileparts(iData.movStr),'Summary.mat');
    if exist(summFile,'file'); return; end
end

% sets the path for the summary file (from the solution file data)
if isfield(iData,'dir')
    % sets the full file path. if the file exists, then exit
    summFile = fullfile(iData.dir,'Summary.mat');
    if exist(summFile,'file'); return; end
end

% if there is no matching file, then set an empty summary file path
summFile = '';
