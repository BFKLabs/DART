function ok = writeXLSData(fFile,DataNw,sName,isApp)

% initialisations
ok = true;
nwFunc = exist('writecell','file');

% outputs the data based on function type
if nwFunc
    % case is using the new function format
    wMode = {'overwritesheet','append'};
    
    if iscell(DataNw)
        writecell(DataNw,fFile,'Sheet',sName,'WriteMode',wMode{1+isApp});
    else
        writematrix(DataNw,fFile,'Sheet',sName,'WriteMode',wMode{1+isApp});
    end
    
else
    % case is using the old function format
    if isApp
        % case is the other data blocks
        while (1)
            try
                % attempts to append to the output file
                xlsappend(fFile,DataNw,sName) 
                break
            catch ME
                % if there error was due to a locked file, then close
                % all instances of Excel. otherwise, rethrow the error
                if strcmp(ME.identifier,'MATLAB:xlswrite:LockedFile') && ispc
                    closeExcelProcesses() 
                else
                    ok = false;
                end
            end
        end         
    else
        try
            xlwrite(fFile,DataNw,sName);
        catch ME
            ok = false;            
        end
    end
end

% if there was an error, then output a message to screen
if ~ok
    eStr = ['There was an error outputting the data to file. Please ',...
            'ensure that the file you are writing to is closed'];
    waitfor(errordlg(eStr,'Data Output Error','modal'))
end