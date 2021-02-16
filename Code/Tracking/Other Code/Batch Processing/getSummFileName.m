% --- retrieves the name of the summary file from the directory, smDir -- %
function smFile = getSummFileName(smDir)

% finds all the .mat files in the summary file directory
matFile = dir(fullfile(smDir,'*.mat'));
if isempty(matFile)
    % if there was no .mat files, then use default name
    smFile = 'Summary.mat';
else
    % determines if any of the .mat files have the word "Summary" in the
    % title
    matName = field2cell(matFile,'name');
    iFile = find(strcmp(matName,'Summary.mat'));
    if isempty(iFile)
        iFile = find(strContains(matName,'Summary'));
    end
    
    % determines if a unique match was made
    switch (length(iFile))
        case (0) % no match, so use default name
            smFile = 'Summary.mat';
        case (1) % unique match, so set file name
            smFile = matName{iFile};
        otherwise % more than one match? this is an error...
            eStr = sprintf('Critical Error! You have more than 1 summary file in "%s"',smDir);
            waitfor(errordlg(eStr,'Summary File Error','modal'));
    end
end