function resetSummaryFile(sFile)

if ~exist('sFile','var')
    % prompts the user for the summary file
    fMode = {'*.mat','MAT-files (*.mat)'};
    [fName,fDir,fIndex] = uigetfile(fMode,'Pick A Summary File',pwd);
    if ~fIndex
        % if the user cancelled, then exit
        return
    end
    
    % sets the file name
    sFile = fullfile(fDir,fName);
end
    
% loads the summary file
A = load(sFile);

% determines the start/finish time stamp values
T0 = cellfun(@(x)(x(1)),A.tStampV);
Tf = cellfun(@(x)(x(end)),A.tStampV);

% determines if there are any anomalous video time-stamps
iT0 = find(diff(T0) < 0,1,'first');
if ~isempty(iT0)
    % calculates the mean inter-video duration
    dTmn = mean(T0(2:iT0) - Tf(1:(iT0-1)));
    
    % determines the next anomalous video 
    while ~isempty(iT0)
        % resets the time stamp array
        T = A.tStampV{iT0+1} - A.tStampV{iT0+1}(1);
        A.tStampV{iT0+1} = T + (dTmn + Tf(iT0));        
        
        % resets the start/finish times
        T0(iT0+1) = A.tStampV{iT0+1}(1);
        Tf(iT0+1) = A.tStampV{iT0+1}(end);
                
        % determines the next anomalous video
        iT0 = find(diff(T0) < 0,1,'first');
    end
end

% resaves the summary file
save(sFile,'-struct','A')