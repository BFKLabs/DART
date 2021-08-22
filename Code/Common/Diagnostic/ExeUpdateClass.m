classdef ExeUpdateClass < handle
    
    % class propertes
    properties
        
        % main class objects
        hFig
        hGUI
        hFigM
        hImg
        
        % path string fields
        exeFile
        dartFile
        tempDir
        statusFile
        responseFile
        
        % other scalar class fields
        fSzT
        ok = true;
        iCol = 2;
        tPause = 0.1;
        
    end
    
    % class methods
    methods
        % --- class contructor
        function obj = ExeUpdateClass(hFig)
            
            % sets the main fields
            obj.hFig = hFig;
            obj.hGUI = guidata(hFig);
            obj.hFigM = getappdata(hFig,'hFigM');            
            
            % checks if the executable requires updating
            if obj.checkCurrentUpdateStatus() > 0
                % if no update is required then 
                obj.createResponseFile(0);
                pause(0.05);
                
                % flag that the gui need to be closed
                obj.ok = false;
                
                % if no update is required/feasible then close the gui
                setObjVisibility(obj.hFigM,1)
                obj.deleteTempDir();                
                return                
            end
            
            % initialises the class object fields/objects
            obj.initObjCallbacks();
            obj.initObjProps();
            
        end
        
        % --------------------------------------------- %
        % --- CLASS OBJECT INITIALISATION FUNCTIONS --- %
        % --------------------------------------------- %
        
        % --- initialises the class object fields
        function initObjCallbacks(obj)
            
            % objects with normal callback functions
            cbObj = {'buttonApplyUpdate','buttonCloseUpdate'};
            for i = 1:length(cbObj)
                hObj = getStructField(obj.hGUI,cbObj{i});
                cbFcn = eval(sprintf('@obj.%sCB',cbObj{i}));
                set(hObj,'Callback',cbFcn)
            end                            
            
        end
        
        % --- initialises the object properties
        function initObjProps(obj)
            
            % object retrieval
            hAx = obj.hGUI.axesProg;
            
            % initialises the progress
            obj.hImg = image(hAx,uint8(256*ones(1,1000,3)));
            set(hAx,'xtick',[],'xticklabel',[],'ytick',[],'yticklabel',[])

            % updates the download progress
            obj.updateDownloadProgress(0);            
            
        end
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- Executes on button press in buttonApplyUpdate.
        function buttonApplyUpdateCB(obj,hObject,~)
         
            % global variables
            global mainProgDir
            
            % if running DART via executable, then warn the user that will close
            if isdeployed
                mStr = 'DART will close after applying the executable update.';
                waitfor(msgbox(mStr,'DART Closedown','modal'))
            end

            % sets the temporary file name
            setObjEnable(hObject,0)
            tempFile = fullfile(obj.tempDir,'ExeUpdate.zip');

            % -------------------------------- %
            % --- EXECUTABLE FILE DOWNLOAD --- %
            % -------------------------------- %            
            
            % creates a response file (flagging file download continuation)
            obj.createResponseFile(1);

            % keep looping until the file has been downloaded
            while 1
                if exist(tempFile,'file')
                    % determines the current size of the downloaded file
                    fInfo = dir(tempFile);
                    fSzC = obj.byte2mbyte(fInfo.bytes);

                    % updates the download progress
                    obj.updateDownloadProgress(fSzC);
                    if fSzC == obj.fSzT
                        % if the download is complete, then exit the loop
                        break
                    end
                end

                % pauses for a little bit
                pause(obj.tPause)
            end
            
            % ------------------------------ %
            % --- EXECUTABLE FILE UPDATE --- %
            % ------------------------------ %
            
%             % creates a progress loadbar
%             h = ProgressLoadbar('Updating DART Executable...');
            
            % makes the current GUI invisible
            setObjVisibility(obj.hFig,0);
            pause(0.05);
            
            % if deployed, then close the main DART GUI
            if isdeployed
                % kills the ExeUpdate.exe process (if it is running)
                obj.killExternExe('DART.exe')
%                 obj.waitForDARTClose()
            else
                % deletes the GUI
                delete(obj.hFig)
                
                % otherwise, make the main GUI visible again
                setObjVisibility(obj.hFigM,1)
            end            
            
        end
        
        % --- Executes on button press in buttonApplyUpdate.
        function buttonCloseUpdateCB(obj,~,~)
            
            % kills the ExeUpdate.exe process (if it is running)
            obj.killExternExe('ExeUpdate.exe')

            % creates a response file (flagging no continuation)
            obj.createResponseFile(0);

            % makes the gui visible again
            setObjVisibility(obj.hFigM,1);            
            
            % deletes the temporary data folder and the GUI
            obj.deleteTempDir()
            delete(obj.hFig)            
            
        end             
        
        % ----------------------- %
        % --- OTHER FUNCTIONS --- %
        % ----------------------- %
        
        % --- checks the status of the current update file
        function iStatus = checkCurrentUpdateStatus(obj)

            % global variables
            global mainProgDir

            % creates a loadbar
            h = ProgressLoadbar('Checking Current Executable Versions...');
            
            % initialisations
            iStatus = 0;
            obj.exeFile = which('ExeUpdate.exe');
            obj.dartFile = fullfile(mainProgDir,'DART.ctf');
            obj.tempDir = fullfile(fileparts(obj.exeFile),'TempFiles');
            obj.statusFile = fullfile(obj.tempDir,'Status.mat');

            % sets the important fields into the gui
            setObjVisibility(obj.hFigM,0)

            % deletes the status file (if one already exists)
            if exist(obj.tempDir,'dir')
                rmdir(obj.tempDir,'s')
            end

            % changes directory to the temporary directory
            cDir0 = pwd;
            cd(fileparts(obj.tempDir))

            % runs the executable file
            Process = System.Diagnostics.Process();
            Process.StartInfo.UseShellExecute = false;
            Process.StartInfo.CreateNoWindow = true;
            Process.Start(obj.exeFile);

            % keep waiting until the status file appears
            while ~exist(obj.statusFile,'file')
                pause(0.1);
            end

            % loads the status file information and then deletes it
            sInfo = load(obj.statusFile);
            delete(obj.statusFile);
            cd(cDir0)

            % deletes the loadbar
            delete(h)

            % determines if the file could be successfully detected
            if sInfo.ok
                % determines if the .ctf file exists
                if exist(obj.dartFile,'file')
                    % if so, compare the date to the remote zip file date
                    fInfo = dir(obj.dartFile);
                    updateReqd = fInfo.datenum < datenum(sInfo.mod_time);
                else
                    % if the .ctf file is missing, then force update
                    updateReqd = true;
                end
                
                if ~updateReqd 
                    % if the DART version date time exceeds that stored 
                    % on the remove server, output a message to screen
                    iStatus = 1;
                    mStr = ['Current DART version is the ',...
                            'latest so no update is required.'];
                    waitfor(msgbox(mStr,'No Update Required','modal'))        
                else
                    % otherwise, set the file size information
                    obj.fSzT = obj.byte2mbyte(sInfo.size);       
                end    
            else
                % otherwise, output an error to screen
                eStr = sprintf(['Executable update failed with the following ',...
                                'error:\n\n => "%s"'],sInfo.e_str);
                waitfor(msgbox(eStr,'Executable Update Failure','modal'))

                % exits the function
                iStatus = 2;
            end            

        end
        
        % --- creates the response file with the flag, isCont
        function createResponseFile(obj,cont)

            % sets the response file name
            if exist(obj.tempDir,'dir')
                % sets the response file output directory
                obj.responseFile = fullfile(obj.tempDir,'Response.mat');                
                
                % saves the continuation flag to file and pauses...
                save(obj.responseFile,'cont')
                pause(obj.tPause/2);
            end

        end
        
        % --- deletes the temporary directory
        function deleteTempDir(obj)

            % deletes the temporary directory (if it exists)
            if exist(obj.tempDir,'dir')
                rmdir(obj.tempDir,'s')
            end

        end
        
        % --- updates the download progress bar
        function updateDownloadProgress(obj,fSzC)
            
            % initialisations
            I = get(obj.hImg,'CData');

            % calculates the number 
            pC = fSzC/obj.fSzT;
            nC = roundP(pC*size(I,2));

            % updates the progress bar axes
            [I(:,1:nC,2),I(:,1:nC,3)] = deal(0);
            set(obj.hImg,'CData',I);

            % updates the text string
            tStr = sprintf('%.1f of %.1fMB (%.1f%s Complete)',...
                           fSzC,obj.fSzT,100*pC,'%');
            set(obj.hGUI.textProg,'string',tStr)
            
        end
        
    end
    
    % static class methods
    methods (Static)
        
        % --- converts the size in bytes to megabytes
        function fSzMB = byte2mbyte(fSzB)

            fSzMB = double(fSzB)/(1024^2);

        end
        
        % --- kills the external update executable process (if it is running)
        function killExternExe(exeName)

            % initialisations
            iCol = 2;
            
            % creates a loadbar
            h = ProgressLoadbar('Terminating ExeUpdate.exe...');
            
            % determines if the ExeUpdate.exe process is running
            taskListStr = 'tasklist /fo csv | findstr /c:';
            [~,tList0] = system(sprintf('%s"%s"',taskListStr,exeName));
            if isempty(tList0)
                % if the task is not in the list, then exit
                return
            end

            % splits the task list information into a single cell array
            tListSp = cell2cell(cellfun(@(x)...
                                (regexp(x,'"(.*?)"', 'match')),...
                                strsplit(tList0(1:end-1),'\n')','un',0),1);
            idList = cellfun(@(x)(sprintf('/pid %s',...
                                x(2:end-1))),tListSp(:,iCol),'un',0)';

            % kills the task
            killStr = sprintf('taskkill /f %s',strjoin(idList(:)'));
            [~,~] = system(killStr);

            % pauses before continuing
            pause(1);
            for i = size(tListSp,1)

            end
            
            % closes the loadbar
            delete(h)

        end        
        
        % --- waits for the DART executable to close
        function waitForDARTClose()
            
            % sets the tasklist string
            tPause = 0.1;
            taskListStr = 'tasklist /fo csv | findstr /c:"DART.exe"';
            
            % keep waiting until 
            while true
                % determines if the executable is still running
                [~,Status] = system(taskListStr);
                if isempty(Status)
                    % if the executable is closed, then exit
                    return
                else
                    % otherwise, pause for a short time
                    pause(tPause)
                end                
            end
            
        end
        
    end
end