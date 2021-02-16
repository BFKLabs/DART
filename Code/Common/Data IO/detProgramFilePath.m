% --- determines the path of the ghost-script/xpdf directories
function pfDir = detProgramFilePath(fType)

% if not a PC then exit the function
if (~ispc)
    eStr = 'Error! This function is only applicable to PC Operating Systems.';
    waitfor(errordlg(eStr,'Incorrect Operating System','modal'));
    pfDir = []; 
    return
end

% initialisations (volume names)
vStr = {'A','B','C','D','E','F','G','H','I'};

% sets the temporary program file directory name
if (strcmp(computer,'PCWIN'))
    % sets the program file directory string
    [pTmp,archType] = deal('Program Files (x86)','32-Bit');
    
    % sets the directory suffix string
    switch (fType)
        case ('gs') % case is ghost-script
            endDir = '\bin\gswin32c.exe';
        case ('Xpdf') % case is xpdf
            endDir = '\bin32\';
    end
else
    % sets the program file directory string
    [pTmp,archType] = deal('Program Files','64-Bit');
    
    % sets the directory suffix string
    switch (fType)
        case ('gs') % case is ghost-script
            endDir = '\bin\gswin64c.exe';
        case ('Xpdf') % case is xpdf
            endDir = '\bin64\';
    end    
end

switch (fType)
    case ('gs')
        pName = 'Ghost-Script';
    case ('Xpdf')
        pName = 'Xpdf';
end

% loops through all the volumes determining the program path
for i = 1:length(vStr)
    % sets the new directory string name
    nwDir = fullfile(sprintf('%s:',vStr{i}),pTmp,fType);
    if (exist(nwDir,'dir'))
        % if it exists, then determine if the new file exists
        switch (fType)
            case ('gs') %
                % determines the directories within the top directory
                a = dir(nwDir);
                a = a(cellfun(@(x)(~(strcmp(x,'.')|strcmp(x,'..'))),field2cell(a,'name')));
                
                % if there is more than one sub-directory, then retrieve
                % the most recent version of Ghost-Script
                if (length(a) > 1)
                    [~,ii] = sort(field2cell(a,'datenum'));
                    a = a(ii(1));
                end
                
                % sets the program name, path and type string                
                [pfDir,tStr] = deal(fullfile(nwDir,a(1).name,endDir),'file');
            case ('Xpdf') % 
                % sets the program name, path and type string                
                [pfDir,tStr] = deal(fullfile(nwDir,endDir),'dir');
        end
        
        % if there is a match, then exit the function
        if (exist(pfDir,tStr))
            return
        end        
    end    
end

% returns an error and an empty string
eStr = sprintf(['Error! The program "%s" has not been installed. Please '...
                'ensure that you have the "%s" version of the program ',...
                'install.'],pName,archType);
pfDir = [];
waitfor(errordlg(eStr,'Program Not Installed','modal')); 
