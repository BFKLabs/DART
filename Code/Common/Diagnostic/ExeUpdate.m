classdef ExeUpdate < handle
    
    % class propertes
    properties
    
        % main class propertiers        
        hFigM
        hGUIM
        hImg
        
        % class object handles        
        hFig        
        hPanelD
        hTxtD
        hAxD        
        hPanelC        
        hButC
        
        % path string fields
        exeFile
        zipFile
        dartFile
        tempDir
        statusFile
        responseFile
        
        % fixed object dimensions
        dX = 10;
        widAx = 335;
        hghtAx = 25;
        hghtBut = 25;
        widTxtL = 125;
        hghtTxt = 16;
        hghtPanelD = 80;
        hghtPanelC = 40;        
        
        % variable object dimensions
        widFig
        hghtFig
        widPanel        
        widButC
        widTxtD
        
        % other scalar class fields
        fSzT
        hSz = 13;
        tSz = 12;
        ok = true;
        iCol = 2;
        tPause = 0.1;
        tagStr = 'figExeUpdate';
        
    end        
    
    % class methods
    methods
        
        % --- class contructor
        function obj = ExeUpdate(hFigM)
        
            % sets the main class fields
            obj.hFigM = hFigM;                 
            
            % initialises the class fields/objects
            obj.initClassFields();
            if ~obj.ok
                % if there is no update required then exit
                return
            end
            
            % creates the class objects
            obj.initClassObjects();            
                        
        end
        
        % --------------------------------------------- %
        % --- CLASS OBJECT INITIALISATION FUNCTIONS --- %
        % --------------------------------------------- %        
        
        % --- initialises the class fields
        function initClassFields(obj)
           
            % checks if the executable requires updating
            if obj.checkCurrentUpdateStatus() > 0
                % if no update is required then 
                obj.createResponseFile(0);
                pause(0.1);
                
                % flag that the gui need to be closed
                obj.ok = false;
                
                % if no update is required/feasible then close the gui
                setObjVisibility(obj.hFigM,1)
                obj.deleteTempDir();                
                return                
            end
            
            % variable dimension calculations
            obj.widPanel = obj.widAx + 2*obj.dX;  
            obj.widTxtD = obj.widPanel - (obj.dX/2 + obj.widTxtL);
            obj.widButC = (obj.widPanel - 3*obj.dX)/2;
            obj.widFig = obj.widPanel + 2*obj.dX;
            obj.hghtFig = (obj.hghtPanelD + obj.hghtPanelC) + 3*obj.dX;            
                        
        end
        
        % --- initialises the class objects
        function initClassObjects(obj)
                        
            % deletes any previous GUIs
            hFigPr = findall(0,'tag',obj.tagStr);
            if ~isempty(hFigPr); delete(hFigPr); end
            
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- %
            
            % creates the figure object
            figName = 'DART Executable Update';
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % creates the figure object
            obj.hFig = figure('Position',fPos,'tag',obj.tagStr,...
                              'MenuBar','None','Toolbar','None',...
                              'Name',figName,'Resize','off',...
                              'NumberTitle','off','Visible','off');             

            % ------------------------------ %
            % --- CONTROL BUTTON OBJECTS --- %
            % ------------------------------ %                          
                          
            % initialisations
            bStrC = {'Download & Update','Cancel Update'};
            bFcnC = {@obj.buttonApplyUpdate,@obj.buttonCloseUpdate};
            obj.hButC = cell(length(bStrC),1);            
            
            % creates the control button panel 
            pPosC = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = uipanel(obj.hFig,'Title','','Units',...
                                           'Pixels','Position',pPosC);             
            
            % creates the control button objects
            for i = 1:length(obj.hButC)
                lPos = i*obj.dX + (i-1)*obj.widButC;
                bPos = [lPos,obj.dX-2,obj.widButC,obj.hghtBut];
                obj.hButC{i} = uicontrol(obj.hPanelC,'Units','Pixels',...
                        'String',bStrC{i},'Callback',bFcnC{i},'FontWeight',...
                        'Bold','FontUnits','Pixels','FontSize',obj.tSz,...
                        'Style','PushButton','Position',bPos);
            end                                              
                                       
            % ------------------------------ %
            % --- DOWNLOAD PANEL OBJECTS --- %
            % ------------------------------ %
                          
            % initialisations
            yPosD = sum(pPosC([2,4]));
            tStrD = 'UPDATE DOWNLOAD PROGRESS'; 
            tStrL = 'Download Progress: ';
            pPosD = [obj.dX + [0,yPosD],obj.widPanel,obj.hghtPanelD];
            
            % creates the download information panel
            obj.hPanelD = uipanel(obj.hFig,'Title',tStrD,'Units',...
                        'Pixels','Position',pPosD,'FontUnits','Pixels',...
                        'FontSize',obj.hSz,'FontWeight','bold');
            
            % creates the text labels
            tPosL = [obj.dX-[5,2],obj.widTxtL,obj.hghtTxt];
            uicontrol(obj.hPanelD,'Style','Text','Position',tPosL,...
                        'FontUnits','Pixels','FontWeight','Bold',...
                        'FontSize',obj.tSz,'String',tStrL,...
                        'HorizontalAlignment','right');
                    
            % creates the download progress text label
            lPosD = sum(tPosL([1,3]));
            tPosD = [lPosD,obj.dX-2,obj.widTxtD,obj.hghtTxt];
            obj.hTxtD = uicontrol(obj.hPanelD,'Style','Text',...
                        'Position',tPosD,'FontUnits','Pixels',...
                        'FontWeight','Bold','FontSize',obj.tSz,...
                        'HorizontalAlignment','left','String',tStrL);
                    
            % --------------------------- %
            % --- PROGRESSBAR OBJECTS --- %
            % --------------------------- %    
            
            % creates the axes object
            axPosD = [obj.dX*[1,3],obj.widAx,obj.hghtAx];
            obj.hAxD = axes(obj.hPanelD,'Units','Pixels',...
                        'Position',axPosD,'box','on','xlim',[0,1],...
                        'ylim',[0,1],'TickLength',[0,0]);            
                    
            % initialises the progressbar object and axis properties
            obj.hImg = image(obj.hAxD,uint8(256*ones(1,1000,3)));            
            set(obj.hAxD,'xtick',[],'xticklabel',[],...
                         'ytick',[],'yticklabel',[]);            
            
            % updates the download progress
            obj.updateDownloadProgress(0);      
            
            % makes the GUI object visible
            setObjVisibility(obj.hFig,1)
            centerfig(obj.hFig);
            
        end
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- Executes on button press in buttonApplyUpdate.
        function buttonApplyUpdate(obj, hObject, ~)
            
            % if running DART via executable, then warn the user that 
            % DART will close after the update is complete
            if isdeployed
                mStr = ['DART will close after applying ',...
                        'the executable update.'];
                waitfor(msgbox(mStr,'DART Closedown','modal'))
            end

            % sets the temporary file name
            setObjEnable(hObject,0)
            tempFile = fullfile(obj.tempDir,obj.zipFile);

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
            
            % makes the current GUI invisible
            setObjVisibility(obj.hFig,0);
            pause(0.1);
            
            % if deployed, then close the main DART GUI
            if isdeployed
                % kills the ExeUpdate.exe process (if it is running)
                obj.killExternExe('DART.exe')
                
            else
                % deletes the GUI
                delete(obj.hFig)
                
                % otherwise, make the main GUI visible again
                setObjVisibility(obj.hFigM,1)
            end            
            
        end
        
        % --- Executes on button press in buttonApplyUpdate.
        function buttonCloseUpdate(obj, ~, ~)
            
            % kills the ExeUpdate.exe process (if it is running)
            obj.killExternExe('ExeUpdate.exe')

            % creates a response file (flagging no continuation)
            obj.createResponseFile(0);

            % makes the main gui visible again
            setObjVisibility(obj.hFigM,1);            
            
            % deletes the temporary data folder and the GUI
            obj.deleteTempDir()
            delete(obj.hFig)            
            
        end
        
        % ----------------------- %
        % --- OTHER FUNCTIONS --- %
        % ----------------------- %
        
        % --- sets up the executable update process
        function startExeUpdateProcess(obj)
            
            % sets the default zip file name
            obj.zipFile = 'ExeUpdate.zip';
            
            % sets the specific directory file name
            if ~isempty(which('MultiTrack'))
                % case is multi-tracking
                obj.zipFile = 'ExeUpdate_MT.zip';
            end
            
            % runs the executable file
            Process = System.Diagnostics.Process();
            Process.StartInfo.UseShellExecute = false;
            Process.StartInfo.CreateNoWindow = true;
            Process.StartInfo.FileName = obj.exeFile;
            Process.StartInfo.Arguments = obj.zipFile;
            Process.Start();
            
        end
        
        % --- checks the status of the current update file
        function iStatus = checkCurrentUpdateStatus(obj)

            % creates a loadbar
            lStr = 'Checking Current DART Executable Version...';
            h = ProgressLoadbar(lStr);            
            
            % initialisations
            iStatus = 0;
            obj.exeFile = which('ExeUpdate.exe');
            obj.dartFile = getProgFileName('DART.ctf');
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

            % runs the executable update process
            obj.startExeUpdateProcess();

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
                    dtLocal = datetime(datestr(fInfo.date));
                    dtRemote = datetime(datestr(sInfo.mod_time));
                    updateReqd = time(between(dtLocal,dtRemote)) > 0;
                    
                else
                    % if the .ctf file is missing, then force update
                    updateReqd = true;
                end
                
                if ~updateReqd 
                    % if the DART version date time exceeds that stored 
                    % on the remove server, output a message to screen
                    iStatus = 1;
                    mStr = ['Current executable version is the ',...
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
            try
                I = get(obj.hImg,'CData');
            catch
                return
            end

            % calculates the number 
            pC = fSzC/obj.fSzT;
            nC = roundP(pC*size(I,2));

            % updates the progress bar axes
            [I(:,1:nC,2),I(:,1:nC,3)] = deal(0);
            set(obj.hImg,'CData',I);

            % updates the text string
            tStr = sprintf('%.1f of %.1fMB (%.1f%s Complete)',...
                           fSzC,obj.fSzT,100*pC,'%');
            set(obj.hTxtD,'string',tStr)
            
        end        
        
    end
    
    % static class methods
    methods (Static)
        
        % --- converts the size in bytes to megabytes
        function fSzMB = byte2mbyte(fSzB)

            fSzMB = double(fSzB)/(1024^2);

        end
        
        % --- kills the external update executable process (if running)
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