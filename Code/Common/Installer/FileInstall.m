classdef FileInstall < handle
    
    % class properties
    properties
        
        % input arguments
        objP
        indP
        
        % class object handles
        hFig        
        hPanel
        hChkD
        hEditD
        hButD  
        jBarP
        hButP
        hTxtP
        hButC        
        
        % other class fields
        pStr
        fDirT
        fURL
        fExtn
        tmpFile
        fSzT
        wOpt
        
        % fixed object dimensions
        dX = 10;    
        xOfs = 2;
        tSzC = 12;                
        tSzH = 13;
        tSzD = 18;
        widAxP = 250;
        widButC = 125;
        hghtBut = 25;
        hghtChk = 22;
        hghtEdit = 22;
        hghtTxt = 16;
        hghtPanel = [40,70,75];  
        
        % derived object dimensions
        widPanel
        widEditD
        widTable
        hghtTable
        widTxtP
        widButP
        hghtFig        
        widFig        
        
        % other parameters
        nPanel        
        nButC = 3;   
        tPause = 0.1;
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = FileInstall(objP,indP)
            
            % sets the input variables
            obj.objP = objP;
            obj.indP = indP;
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObj();
            
            % makes the class figure visible
            obj.centreFigPosition();
            set(obj.hFig,'Visible','on');
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % memory allocation
            obj.hButC = cell(obj.nButC,1);
            obj.nPanel = length(obj.hghtPanel);            
            obj.fDirT = fullfile(pwd,'temp_files');
            obj.pStr = obj.objP.pStrS{obj.objP.iTab}{obj.indP};
            
            % sets up the web-options struct
            obj.wOpt = weboptions;
            obj.wOpt.CertificateFilename = ('');
            obj.wOpt.ContentType = 'raw';
            
            % retrieves the file URL/extension
            [obj.fURL,obj.fExtn] = getProgInstallURL(obj.pStr);
            tmpName = sprintf('%s%s',obj.pStr,obj.fExtn);
            obj.tmpFile = fullfile(obj.fDirT,tmpName);
            
            % panel object dimensions
            obj.widPanel = obj.nButC*(obj.dX + obj.widButC) + obj.dX;            
            
            % parent directory panel dimensions
            obj.widEditD = obj.widPanel - (2.5*obj.dX + obj.hghtBut);
            obj.widTxtP = obj.widPanel - 2*obj.dX;
            
            % installation progress object dimensions
            obj.widButP = obj.widPanel - (2.5*obj.dX + obj.widAxP);
            
            % sets the figure height/width
            obj.widFig = obj.widPanel + 2*obj.dX;
            obj.hghtFig = sum(obj.hghtPanel) + (obj.nPanel+1)*obj.dX;            
            
        end
        
        % --- initialises the class fields
        function initClassObj(obj)
            
            % creates the figure object
            tagStr = 'figFileInstall';
            fPos = [100,100,obj.widFig,obj.hghtFig];            
        
            % makes the parent gui invisible
            set(obj.objP.hFig,'Visible','off');
            
            % removes any previous GUIs
            hFigPr = findall(0,'tag',tagStr);
            if ~isempty(hFigPr); delete(hFigPr); end
            
            % creates the figure object
            fStr = 'Third Party Software Installer';
            obj.hFig = figure('Position',fPos,'tag',tagStr,...
                              'MenuBar','None','Toolbar','None',...
                              'Name',fStr,'NumberTitle','off',...
                              'Visible','off','Resize','off',...
                              'CloseRequestFcn',@obj.exitInstaller);            
           
            % ------------------------------ %
            % --- CONTROL BUTTON OBJECTS --- %
            % ------------------------------ %
            
            % initialisations
            cbFcnB = {@obj.backSelect,...
                      @obj.installProgFile,...
                      @obj.exitInstaller};
            bStr = {'Back','Start Installation','Exit Installer'};            
            
            % creates the control button panel
            pPosC = [obj.dX*[1,1],obj.widPanel,obj.hghtPanel(1)];
            hPanelC = uipanel(obj.hFig,'Title','','Units','Pixel',...
                                       'Position',pPosC);
            
            % creates the control button objects
            for i = 1:length(bStr)
                % sets the button position vector
                lPos = obj.dX + (i-1)*(obj.dX + obj.widButC);
                bPosC = [lPos,obj.dX-2,obj.widButC,obj.hghtBut];
                
                % creates the button objects
                obj.hButC{i} = uicontrol(hPanelC,...
                            'Style','PushButton','String',bStr{i},...
                            'Units','Pixels','Position',bPosC,...
                            'Callback',cbFcnB{i},'FontWeight','Bold',...
                            'FontUnits','Pixels','FontSize',obj.tSzC,...
                            'HorizontalAlignment','Center');                
            end     
            
            % disables the installation button
            set(obj.hButC{2},'Enable','off');
            
            % ------------------------------------- %
            % --- INSTALLATION PROGRESS OBJECTS --- %
            % ------------------------------------- %
            
            % creates the control button panel
            y0I = sum(pPosC([2,4])) + obj.dX;
            tStr = 'PROGRAM FILE DOWNLOAD';
            pPosP = [obj.dX,y0I,obj.widPanel,obj.hghtPanel(2)];
            hPanelP = uipanel(obj.hFig,'Title',tStr,'Units','Pixel',...
                                'Position',pPosP,'FontWeight','Bold',...
                                'FontUnits','Pixels','FontSize',obj.tSzH);
            
            % creates the directory editbox
            tPosP = [obj.dX,obj.dX/2,obj.widTxtP,obj.hghtTxt];
            obj.hTxtP = uicontrol(hPanelP,'Style','Text',...
                            'Units','Pixels',...
                            'Position',tPosP,'FontUnits','Pixels',...
                            'FontSize',obj.tSzC,'FontWeight','Bold',...
                            'HorizontalAlignment','Left');
            
                            
            % creates the progress-bar
            y0Ax = sum(tPosP([2,4])) + obj.dX/2;
            axPosP = [obj.dX,y0Ax,obj.widAxP,obj.hghtEdit];
            obj.jBarP = javax.swing.JProgressBar(0, 1000);
            createJavaComponent(obj.jBarP,axPosP,hPanelP);                   
                          
            % creates the axes objects 
            cbFcnBP = @obj.downloadProgFile;
            lPosB = sum(axPosP([1,3])) + obj.dX/2;
            bPosP = [lPosB,y0Ax,obj.widButP,obj.hghtEdit];
            obj.hButP = uicontrol(hPanelP,...
                            'Style','PushButton','String','Download File',...
                            'Units','Pixels','Position',bPosP,...
                            'Callback',cbFcnBP,'FontWeight','Bold',...
                            'FontUnits','Pixels','FontSize',obj.tSzC,...
                            'HorizontalAlignment','Center');                     
                     
            % initialises the progress properties
            obj.checkTempFileExist();            
                        
            % ---------------------------------------- %
            % --- INSTALLATION INFORMATION OBJECTS --- %
            % ---------------------------------------- %
            
            % creates the control button panel
            y0P = sum(pPosP([2,4])) + obj.dX;
            tStr = 'INSTALLER DOWNLOAD INFORMATION';
            pPosD = [obj.dX,y0P,obj.widPanel,obj.hghtPanel(3)];
            hPanelD = uipanel(obj.hFig,'Title',tStr,'Units','Pixel',...
                                'Position',pPosD,'FontWeight','Bold',...
                                'FontUnits','Pixels','FontSize',obj.tSzH);

            % creates the directory editbox
            tStrC0 = 'Delete temporary installation files once complete?';
            cPosP = [obj.dX,obj.dX-2,obj.widTxtP,obj.hghtTxt];
            obj.hChkD = uicontrol(hPanelD,'Style','CheckBox',...
                            'String',tStrC0,'Units','Pixels',...
                            'Position',cPosP,'FontUnits','Pixels',...
                            'FontSize',obj.tSzC,'FontWeight','Bold',...
                            'HorizontalAlignment','Left','Value',1);                            
            
            % creates the directory editbox
            y0E = sum(cPosP([2,4])) + obj.dX/2;
            ePosD = [obj.dX,y0E,obj.widEditD,obj.hghtEdit];
            obj.hEditD = uicontrol(hPanelD,'Style','Edit',...
                            'String',obj.fDirT,'Units','Pixels',...
                            'Position',ePosD,'FontWeight','Bold',...
                            'FontUnits','Pixels','FontSize',obj.tSzC,...
                            'HorizontalAlignment','Left',...
                            'Enable','Inactive'); 
                        
            % creates the button objects
            cbFcnBD = @obj.setInstallDir;
            bPosD = [sum(ePosD([1,3]))+obj.dX/2,y0E-2,obj.hghtBut*[1,1]];
            uicontrol(hPanelD,'Style','PushButton',...
                        'String','...','Units','Pixels','Position',bPosD,...
                        'Callback',cbFcnBD,'FontWeight','Bold',...
                        'FontUnits','Pixels','FontSize',obj.tSzD,...
                        'HorizontalAlignment','Center');                         
                        
        end
        
        % ------------------------------------- %
        % --- INSTALLER CLASS I/O FUNCTIONS --- %
        % ------------------------------------- %        
        
        % --- closes the file installer
        function backSelect(obj,~,~)
            
            % returns to the 3rd party software sub-gui
            set(obj.hFig,'Visible','off');
            set(obj.objP.hFig,'Visible','on');
            
        end        
        
        % --- exit installer callback function
        function exitInstaller(obj,~,~)
            
            % prompts the user if they want to close the installer
            set(obj.hFig,'Visible','off');
            if obj.objP.objM.closeFigure()
                % if so, then delete the file installer GUI
                delete(obj.hFig)
            else
                % otherwise, make the gui visible again
                set(obj.hFig,'Visible','on');
            end
            
        end                
        
        % -------------------------------- %
        % --- OTHER CALLBACK FUNCTIONS --- %
        % -------------------------------- %                  
        
        % --- parent installation directory callback function
        function setInstallDir(obj,~,~)
            
            % prompts the user for the search directory
            tStr = 'Select the root search directory';
            sDirNw = uigetdir(obj.fDirT,tStr);
            if sDirNw == 0
                % if the user cancelled, then exit
                return
            end
            
            % updates the other fields
            obj.fDirT = sDirNw;
            set(obj.hEditD,'String',sDirNw);
            
            % sets the full path of the temporary file
            tmpName = sprintf('%s%s',obj.pStr,obj.fExtn);
            obj.tmpFile = fullfile(obj.fDirT,tmpName);
            
            % initialises the progress properties
            obj.checkTempFileExist();                        
            
        end                
        
        % --- start installation button callback function
        function downloadProgFile(obj,~,~)
            
            % updates the download progress strings
            obj.setProgressProps('Downloading');            
            
            % attempts to download the file
            if ~obj.downloadFile()
                % if there was an error, then exit with an error
                obj.setProgressProps('Failed');                
                return
            end
            
            % updates the download progress strings
            obj.setProgressProps('Complete');                              
            
        end                
        
        % --- start installation button callback function
        function installProgFile(obj,~,~)
            
            % starts the installation process
            obj.setProgressProps('InstallStart');
            
            % performs the program installation based on operating system 
            if ispc
                % case is for pc
                switch obj.fExtn
                    case {'.exe','.msi'}
                        % case is executable
                        cmdStr = sprintf('"%s"',obj.tmpFile);
                        instSuccess = system(cmdStr) == 0;
                        
                    case '.zip'
                        % case is a zip-file
                        instSuccess = obj.installZipFile();
                end
            else
                % case is for mac
                switch obj.fExtn
                    case '.dmg'
                        % case is dmg file
                        a = 1;
                        
                    case {'.tar.gz','.7z'}
                        % case is a zip-file
                        instSuccess = obj.installZipFile();
                end                
            end
            
            if instSuccess
                obj.setProgressProps('InstallComplete');
            else
                obj.setProgressProps('InstallIncomplete');
            end            
            
        end        
        
        % --- installs a program from a zip-file
        function instSuccess = installZipFile(obj)
            
            % initialisations
            instSuccess = true;
            
            % unzips the files into the temporary zip file directory
            try
                zipDir = fullfile(obj.fDirT,'temp_zip');
                unzip(obj.tmpFile, zipDir);
            catch
                instSuccess = false;
                return
            end
        
            % installs the program from the zip file
            switch obj.pStr
                case 'ffmpeg'
                    % case is the ffmpeg codecs
                    if ispc
                        % case is pc installation

                        % retrieves the ffmpeg executable file path
                        fInfo = dir(fullfile(zipDir,'**\ffmpeg.exe'));
                        fFile = fullfile(fInfo.folder,fInfo.name);
                        
                        % runs the installation file
                        system(sprintf('"%s"',fFile));
                        pause(0.05); clc
                        
                        % flag the installation was a success
                        instSuccess = true;
                        
                    else
                        % case is mac installation
                        
                        % FINISH ME!
                        a = 1;
                    end
                    
                case 'ghcli'                   
                    % case is the github cli
                
                    % FINISH ME!
                    a = 1;                    
            end
            
            % deletes the temporary zip file directory and contents
            rmdir(zipDir,'s')
            
        end
            
        % ------------------------------- %
        % --- FILE DOWNLOAD FUNCTIONS --- %
        % ------------------------------- %
        
        % --- downloads the file, tFile 
        function ok = downloadFile(obj)
            
            % initialisations
            ok = true;       
            
            % creates the temporary file directory (if it doesn't exist)
            if ~exist(obj.fDirT,'dir')
                mkdir(obj.fDirT);
            end            
            
            try
                % attempts to save the file using websave
                websave(obj.tmpFile,obj.fURL,obj.wOpt);
                
            catch
                % if that fails, use urlwrite
                [~,Status] = urlwrite(obj.fURL,obj.tmpFile);
                ok = Status == 1;
            end
                
        end
            
        % --- sets the progress object properties
        function setProgressProps(obj,pType)
            
            % initialisations+
            [eStrC,eStrP] = deal('off');            
            
            % sets the progress object properties based on type
            switch pType
                case 'Initial'
                    % case is initialising
                    eStrP = 'on';
                    obj.jBarP.setValue(0);
                    obj.jBarP.setStringPainted(false);
                    obj.jBarP.setIndeterminate(false); 
                    pStrP = 'Waiting To Start Download...';
                    
                case 'Downloading'
                    % case is file downloading                    
                    obj.jBarP.setIndeterminate(true);
                    pStrP = 'Program Files Currently Downloading...';
                    
                case 'Complete'
                    % case is download complete
                    eStrC = 'on';
                    obj.jBarP.setValue(990);
                    obj.jBarP.setIndeterminate(false);            
                    pStrP = 'Installer File Download Complete';                                        
                    
                case 'Failed'
                    % case is download failed
                    eStrP = 'on';
                    obj.jBarP.setValue(0);
                    obj.jBarP.setIndeterminate(false);
                    pStrP = 'Installer Download Failed...';                         

                case 'InstallStart'
                    % case is installation is starting
                    pStrP = 'Starting Program Installation...';                    
                    
                case 'InstallIncomplete'
                    % case is program installed was incomplete
                    eStrC = 'on';
                    pStrP = 'Program Installation Incomplete...';
                    
                case 'InstallComplete'
                    % case is program installed successfully
                    pStrP = 'Program Installation Completed Successfully';
                    
                    % deletes the temporary file (if required)
                    if get(obj.hChkD,'Value')
                        % deletes the temporary file
                        delete(obj.tmpFile)
                        
                        % removes the temporary directory (if not empty)
                        fInfo = dir(fullfile(obj.fDirT));
                        if all(arrayfun(@(x)(x.isdir),fInfo))
                            rmdir(obj.fDirT);
                        end
                    end             
                    
                    % flag that the program is installed on the parent gui
                    ind = [obj.objP.iTab,obj.indP];
                    obj.objP.isInst{ind(1)}(ind(2)) = true;
                    set(obj.objP.hButS{ind(1)}{ind(2)},'enable','off')
                    set(obj.objP.hTxtS{ind(1)}{ind(2)},'enable','off')
                    
                    % resets the tab enabled properties
                    instReqd = cellfun(@(x)(any(~x)),obj.objP.isInst);
                    obj.objP.jTabGrpS.setEnabledAt(ind(1)-1,instReqd(ind(1)));

                    % if all 3rd party software programs have been
                    % installed, then disable the button on the main GUI
                    if ~any(instReqd)
                        ttStrNw = ['All 3rd party software used by ',...
                                   'DART has been installed.'];
                        obj.objP.objM.jButM{2}.setEnabled(0);
                        obj.objP.objM.jButM{2}.setToolTipText(ttStrNw);                               
                        set(obj.objP.objM.hTxtM{2},'Enable','off');
                    end
                    
                    % if git has been installed, then enable the button 
                    % on the main GUI                    
                    if strcmp(obj.objP.pStrS{ind(1)}{ind(2)},'git')
                        ttStrNw = 'Installs one or more versions of DART.';
                        obj.objP.objM.jButM{3}.setEnabled(1);
                        obj.objP.objM.jButM{3}.setToolTipText(ttStrNw);                        
                        set(obj.objP.objM.hTxtM{3},'Enable','on')              
                    end
                    
            end
            
            % updates the button enabled properties
            set(obj.hButP,'Enable',eStrP)
            set(obj.hButC{2},'Enable',eStrC)            
            
            % updates the progress status string
            set(obj.hTxtP,'String',sprintf('Status: %s',pStrP));   
            pause(0.01)                                
            
        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %         
        
        % --- checks if the downloaded file exists
        function checkTempFileExist(obj)
            
            % determines if the file exists
            if exist(obj.tmpFile,'file')
                % if so, then reset the progress to being complete
                obj.setProgressProps('Complete');
            else
                % otherwise, reset the progress to the initial state
                obj.setProgressProps('Initial');                
            end
            
        end
        
        % --- centres the figure position to the screen's centre
        function centreFigPosition(obj)

            % global variables
            scrSz = get(0,'ScreenSize');

            % retrieves the screen and figure position
            hPos = get(obj.hFig,'position');
            p0 = [(scrSz(3)-hPos(3))/2,(scrSz(4)-hPos(4))/2];
            if ~isequal(p0,hPos(1:2))
                set(obj.hFig,'position',[p0,hPos(3:4)])
            end

        end                   
        
    end
    
end
    
    