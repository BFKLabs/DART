% --- outputs the raw data given by the field, pStr to a csv file
function outputDistData(pStr,fFile)

% sets the default data directory
[~,hName] = system('hostname');
switch (hName)
    case ('COLMDS-130885')
        dDir = 'C:\DART\Primary\Data\Output\5 - Analysis Data';
    otherwise
        dDir = [];
end

% prompts user for matlab file (if one is not provided)
if (nargin == 1)
    [fName,fDir,fIndex] = uigetfile({'*.mat','Matlab File (*.mat)'},...
                        'Open Matlab Data File',dDir);
    if (fIndex)
        fFile = fullfile(fDir,fName);
    end
elseif (~exist(fFile,'file'))
    % data file does not exist
    eStr = 'Error! Specifed data file is missing.';
    waitfor(errordlg(eStr,'Missing Data File','modal'));
    return    
else
    % determines if the data file is a mat file
    [~,~,fExtn] = fileparts(fFile);
    if (~strcmp(fExtn,'.mat'))
        % data file is not a mat file
        eStr = 'Error! Data file is not a .mat file.';
        waitfor(errordlg(eStr,'Incorrect File Type','modal'));
        return        
    end
end

% ensures the data file is correct
A = load(fFile);
if (~isfield(A,'GroupNames') || ~isfield(A,pStr))
    % data file is not correct format
    eStr = sprintf('Error! Data file does not vontain the field "%s".',pStr);
    waitfor(errordlg(eStr,'Incorrect Data File','modal'));
    return
end

% combines the data into a single array
[grpName,Y] = deal(A.GroupNames,eval(sprintf('A.%s',pStr)));
Y = cellfun(@(x)(sort(x)),num2cell(combineNumericCells(Y),1),'un',0);
Data = [grpName';num2cell(cell2mat(Y))];

% sets the output file name and writes the data to file
[fDir,fName,~] = fileparts(fFile);
if (writeCSVFile(fullfile(fDir,[fName,'.csv']),Data))
    mStr = 'Data was successfully output to csv file.';
    waitfor(msgbox(mStr,'Write Successful','modal'));    
else
    % data file is not correct format
    eStr = 'Error! Close the output data file before attempting to save';
    waitfor(errordlg(eStr,'Incorrect Data File','modal'));    
end

