classdef DARTProgInstall < handle
    
    % class properties
    properties
        
        % input arguments
        objM
        
        % class object handles
        hFig        
        hPanel
        hEditD
        hButD
        hTable
        jBarP        
        hTxtP
        hButC        
        
        % other class fields
        fDirB
        tData
        dDir0
        prVer
        
        % dart installation fields        
        gFiles
        exFile
        chkFile
        exDir
        outDir        
        rDesc        
        
        % fixed object dimensions
        dX = 10;    
        xOfs = 2;
        tSzC = 12;        
        tSzD = 18;
        hdrSz = 13;
        widAxP = 200;
        widButC = 125;
        hghtBut = 25;     
        hghtEdit = 22;
        hghtTxt = 16;
        hghtPanel = [40,55,NaN,55];
        
        % derived object dimensions
        widPanel
        widEditD
        widTable
        hghtTable
        widTxtP
        hghtFig        
        widFig
        
        % other parameters
        nPanel
        HWT = 18;
        H0T = 22;        
        nRow = 4;
        nButC = 3;                
        isInit = true;
        ix = [1,1,2,2];
        iy = [1,2,2,1];
        
    end
    
    % hidden class properties
    properties (Hidden)
       
        % Git Repository Information
        tKey = 'bea6406bc8bcc5e24e68c9889f108faf4eeff3b9';
        rBaseURL = '@github.com/BFKLabs/';
                
        % other installation fields
        gDirB
        gDirB0 = fullfile('Git','Repo');
        rAbb = {'Main', 'Git', 'AnalysisGen'};
        rName = {'DART', 'DARTGit', 'DARTAnalysisGen'};
        rBase = {'DART Program', 'Git Functions', 'Analysis Functions'};                
        
        % Github user name/token key
        gtUser = 'DARTUser';        
        gtKey = '9c1892c12d18cbadcb8512f3eeb7e4770e5eeea6';
        
        % Github config state file fields
        tUpdate = '2020-07-28T12:53:20.2227612+01:00';
        relVer = 'v0.11.0';
        relURL = 'https://github.com/cli/cli/releases/tag/v0.11.0';
        
    end
    
    % class properties
    methods
        
        % --- class constructor
        function obj = DARTProgInstall(objM)
            
            % sets the input arguments
            obj.objM = objM;
            
            % sets the base installation directory
            obj.fDirB = pwd;
            
        end        
        
        % --- initialises the class fields
        function initClassFields(obj)
                        
            % memory allocation
            obj.nPanel = length(obj.hghtPanel);
            obj.hButC = cell(obj.nButC,1);                        
            
            % sets the exclusion/git repository directories
            obj.exDir = {{'Git'},[],[]};
            obj.gFiles = {
                {'Code/*', 'Para Files/*', 'External Files/*',...
                 'DART.fig', 'DART.m'};...
                {'Classes/*', 'GUI Code/*', 'Other Code/*'};...
                {'*.m'}
            };
                
            % sets up the repository descriptions
            obj.rDesc = cell(length(obj.gFiles),1);
            for i = 1:length(obj.rDesc)
                obj.rDesc{i} = sprintf('%s (%s)',obj.rBase{i},obj.rAbb{i});
            end

            % determines the previous dart installs in the base path
            obj.prVer = obj.findDARTInstalls(obj.fDirB);
            
            % sets the exclude/checkout file paths
            obj.exFile = fullfile('info', 'exclude');
            obj.chkFile = fullfile('info', 'sparse-checkout');
        
            % sets the output directories
            FuncDir = fullfile('Data','Analysis','1 - Analysis Functions');
            obj.outDir = {'','Git',FuncDir};            
            
            % panel object dimensions
            obj.widPanel = obj.nButC*(obj.dX + obj.widButC) + obj.dX;
            
            % parent directory panel dimensions
            obj.widEditD = obj.widPanel - (3*obj.dX + obj.hghtBut);
            
            % dart installation info panel dimensions
            obj.hghtTable = obj.H0T + obj.nPanel*obj.HWT;
            obj.widTable = obj.widPanel - 2*obj.dX;
            obj.hghtPanel(3) = obj.hghtTable + 3.5*obj.dX;
            
            % installation progress object dimensions
            obj.widTxtP = obj.widPanel - (2.5*obj.dX + obj.widAxP);
            
            % sets the figure height/width
            obj.widFig = obj.widPanel + 2*obj.dX;
            obj.hghtFig = sum(obj.hghtPanel) + (obj.nPanel+1)*obj.dX;
            
        end
        
        % --- initialises the class fields
        function initClassObj(obj)

            % creates the figure object
            tagStr = 'figDARTProgInstall';
            fPos = [100,100,obj.widFig,obj.hghtFig];            
        
            % removes any previous GUIs
            hFigPr = findall(0,'tag',tagStr);
            if ~isempty(hFigPr); delete(hFigPr); end
            
            % creates the figure object
            fStr = 'DART SOFTWARE INSTALLER';
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
                      @obj.startDARTInstallation,...
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
                                   
            % ------------------------------------- %
            % --- INSTALLATION PROGRESS OBJECTS --- %
            % ------------------------------------- %
            
            % creates the control button panel
            y0I = sum(pPosC([2,4])) + obj.dX;
            pPosP = [obj.dX,y0I,obj.widPanel,obj.hghtPanel(2)];
            hPanelP = uipanel(obj.hFig,'Title','INSTALL PROGRESS',...
                                       'Units','Pixel','Position',pPosP,...
                                       'FontWeight','Bold',...
                                       'FontUnits','Pixels',...
                                       'FontSize',obj.hdrSz);
            
            % creates the axes objects 
            axPosP = [obj.dX*[1,1],obj.widAxP,obj.hghtEdit];
            obj.jBarP = javax.swing.JProgressBar(0, 1000);
            obj.jBarP.setStringPainted(false);
            obj.jBarP.setIndeterminate(false); 
            createJavaComponent(obj.jBarP,axPosP,hPanelP);
                     
            % creates the directory editbox
            tStrP0 = 'Waiting To Start Installation...';
            lPosP = sum(axPosP([1,3])) + obj.dX;
            tPosP = [lPosP,obj.dX+2,obj.widTxtP,obj.hghtTxt];
            obj.hTxtP = uicontrol(hPanelP,'Style','Text',...
                            'Units','Pixels','Position',tPosP,...
                            'FontUnits','Pixels','FontSize',obj.tSzC,...
                            'HorizontalAlignment','Left',...
                            'FontWeight','bold');
            
            % updates the progressbar
            obj.updateProgressFields(0,tStrP0,'off');
                        
            % ---------------------------------------- %
            % --- INSTALLATION INFORMATION OBJECTS --- %
            % ---------------------------------------- %

            % initialisations
            tStrI = 'DART INSTALLATION INFORMATION';            
            colStr = {'Install Directory Name','Default Link'};
            colForm = {'char',{' ','No Link'}};
            colEdit = true(1,length(colStr));
            
            % sets the table column width
            colWid = [NaN,150];
            colWid(1) = obj.widTable - (colWid(2) + obj.xOfs);
            
            % creates the control button panel
            y0P = sum(pPosP([2,4])) + obj.dX;
            pPosI = [obj.dX,y0P,obj.widPanel,obj.hghtPanel(3)];
            hPanelI = uipanel(obj.hFig,'Title',tStrI,...
                            'Units','Pixel','Position',pPosI,'FontWeight',...
                            'Bold','FontUnits','Pixels','FontSize',...
                            obj.hdrSz);            
            
            % creates the table object
            cbFcnI = @obj.tableEditCallback;
            tabPos = [obj.dX*[1,1],obj.widTable,obj.hghtTable];
            obj.tData = repmat({' '},obj.nRow,length(colStr));
            obj.hTable = uitable(hPanelI,'Position',tabPos,...
                            'ColumnName',colStr,'ColumnFormat',colForm,...
                            'ColumnEditable',colEdit,'RowName',[],...
                            'CellEditCallback',cbFcnI,'Data',obj.tData,...
                            'ColumnWidth',num2cell(colWid));
                                   
            % -------------------------------------------- %
            % --- PARENT INSTALLATION DIRECTORY OBJECT --- %
            % -------------------------------------------- %
            
            % initialisations
            tStrD = 'DART PARENT INSTALLATION DIRECTORY';              
            
            % creates the control button panel
            y0D = sum(pPosI([2,4])) + obj.dX;
            pPosD = [obj.dX,y0D,obj.widPanel,obj.hghtPanel(4)];
            hPanelD = uipanel(obj.hFig,'Title',tStrD,'Units','Pixel',...
                            'Position',pPosD,'FontWeight','Bold',...
                            'FontUnits','Pixels','FontSize',obj.hdrSz);
            
            % creates the directory editbox
            ePosD = [obj.dX*[1,1],obj.widEditD,obj.hghtEdit];
            obj.hEditD = uicontrol(hPanelD,'Style','Edit',...
                            'String',obj.fDirB,'Units','Pixels',...
                            'Position',ePosD,'FontWeight','Bold',...
                            'FontUnits','Pixels','FontSize',obj.tSzC,...
                            'HorizontalAlignment','Left',...
                            'Enable','Inactive');
            
            % creates the button objects
            cbFcnBP = @obj.setInstallDir;
            bPosD = [sum(ePosD([1,3]))+obj.dX,obj.dX-2,obj.hghtBut*[1,1]];
            uicontrol(hPanelD,'Style','PushButton',...
                        'String','...','Units','Pixels','Position',bPosD,...
                        'Callback',cbFcnBP,'FontWeight','Bold',...
                        'FontUnits','Pixels','FontSize',obj.tSzD,...
                        'HorizontalAlignment','Center');                           
            
            % disables the start install button
            obj.setButtonEnabledProps();
            obj.resetColumnFormatString([],NaN)
                    
        end
        
        % --- resets the class objects
        function resetClassObj(obj)
            
            % resets the table data
            obj.tData(:) = {' '};
            set(obj.hTable,'Data',obj.tData);
            obj.resetColumnFormatString([],NaN)
            
            % resets the progressbar           
            obj.setButtonEnabledProps();            
            tStrP0 = 'Waiting To Start Installation...';
            obj.updateProgressFields(0,tStrP0,'off');
            
        end
        
        % ------------------------------------- %
        % --- INSTALLER CLASS I/O FUNCTIONS --- %
        % ------------------------------------- %
        
        % --- opens the class installer
        function openInstaller(obj)
            
            % makes the main GUI installer
            set(obj.objM.hFig,'Visible','off');
            
            % initialises the GUI objects
            if obj.isInit
                % initialises the class field/objects
                obj.initClassFields();
                obj.initClassObj();
                
                % updates the initialisation flag
                obj.isInit = false;
            else
                % clear the class objects
                obj.resetClassObj();
            end
            
            % makes the installer object visible
            obj.centreFigPosition();
            set(obj.hFig,'Visible','on');
            
        end            
        
        % --- closes the class installer
        function backSelect(obj,~,~)
            
            % makes the main GUI installer
            set(obj.hFig,'Visible','off');            
            set(obj.objM.hFig,'Visible','on');
                        
        end  
        
        % --- exit installer callback function
        function exitInstaller(obj,~,~)
            
            % prompts the user if they want to close the installer
            obj.objM.closeFigure();
            
        end        
        
        % -------------------------------- %
        % --- OTHER CALLBACK FUNCTIONS --- %
        % -------------------------------- %   
        
        % --- parent installation directory callback function
        function setInstallDir(obj,~,~)
            
            % prompts the user for the search directory
            tStr = 'Select the root search directory';
            sDirNw = uigetdir(obj.fDirB,tStr);
            if sDirNw == 0
                % if the user cancelled, then exit
                return
            end
            
            % determines if directories already exist
            hasD = ~cellfun(@(x)(isempty(strtrim(x))),obj.tData(:,1));
            if any(cellfun(@(x)(exist(fullfile...
                            (sDirNw,x),'dir')),obj.tData(hasD,1)) > 0)
                % if there are folders with names that already exists, in
                % the new directory) then output an error message
                eStr = sprintf(['Directories with names ',...
                        'listed within the table already exist in the ',...
                        'selected parent installation directory.\n\n',...
                        'Either chose another parent installation ',...
                        'directory or alter the installation ',...
                        'directory names.']);
                waitfor(msgbox(eStr,'Non-Unique Directories','modal'));
            else
                % updates the other fields
                obj.fDirB = sDirNw;
                set(obj.hEditD,'String',sDirNw);
                
                % determines the previous dart installs in the base path
                obj.prVer = obj.findDARTInstalls(obj.fDirB);
                obj.resetColumnFormatString([],NaN);
            end
            
        end
        
        % --- installation information table cell edit callback function
        function tableEditCallback(obj,~,evnt)
            
            % initialisations
            nwVal = evnt.NewData;
            [iRow,iCol] = deal(evnt.Indices(1),evnt.Indices(2));
            
            % determines if the previous rows have been filled correctly
            if iRow > 1
                % retrieves the filled flags for the previous table rows
                xiD = 1:(iRow-1);
                hasD = cellfun(@(x)(~isempty(strtrim(x))),obj.tData(xiD,:));
                
                % determines if all the rows have been filled correctly
                if ~all(all(hasD,2))
                    % if not, then output an error to screen
                    eStr = ['Error! All fields on previous rows must ',...
                            'be filled before starting rows.'];
                    waitfor(msgbox(eStr,'Invalid Table Entry','modal'))
                    
                    % resets the table data and button enabled properties
                    set(obj.hTable,'Data',obj.tData)
                    obj.setButtonEnabledProps();
                    return
                end
            end
            
            % updates the table
            switch iCol
                case 1
                    % case is the program name
                    resetTable = true;
                    if obj.chkDirString(nwVal)
                        % determines which directory field has been set
                        hasD = ~cellfun(@(x)...
                                    (isempty(strtrim(x))),obj.tData(:,1));
                        hasD(iRow) = false;
                        
                        % determines if the new directory name is unique
                        if any(strcmp(obj.tData(hasD,1),nwVal))
                            % if the name is not unique, then output an
                            % error message to screen
                            tStr = 'Non-Unique Directory Name';
                            eStr = sprintf(['The directory name "%s" ',...
                                            'is already being used.'],nwVal);
                            waitfor(msgbox(eStr,tStr,'modal'))
                            
                        elseif exist(fullfile(obj.fDirB,nwVal),'Dir')
                            % if the directory exists the output an error 
                            tStr = 'Directory Already Exists';
                            eStr = sprintf(['The directory "%s" ',...
                                    'already exists in the parent ',...
                                    'directory.'],nwVal);
                            waitfor(msgbox(eStr,tStr,'modal'))                            
                            
                        else
                            % otherwise, update the table data cell
                            prVal = obj.tData{iRow,iCol};
                            obj.tData{iRow,iCol} = nwVal;
                            resetTable = false;
                            
                            % updates the column format strings
                            obj.resetColumnFormatString(prVal,iRow);
                        end
                    end
                    
                    % resets the table (if there was an error)
                    if resetTable
                        set(obj.hTable,'Data',obj.tData)
                    end
                    
                case 2
                    % case is the linking column
                    sStr = sprintf('"%s"',obj.tData{iRow,1});
                    if contains(nwVal,sStr)
                        % if 
                        eStr = sprintf(['Unable to link the ',...
                                'program default directory structure ',...
                                'to itself.\nEither use "No Link" or ',...
                                'set to another intallation folder.']);
                        waitfor(msgbox(eStr,'Default Link Error','modal'));
                            
                        % resets the table data
                        set(obj.hTable,'Data',obj.tData)
                    else
                        obj.tData{iRow,iCol} = nwVal;
                    end
                    
            end
            
            % updates the button enabled properties
            obj.setButtonEnabledProps();
            
        end        
        
        % --- start installation button callback function
        function startDARTInstallation(obj,hObj,~)
            
            % initialisations
            obj.dDir0 = pwd;
            nDir = sum(~cellfun(@(x)(isempty(strtrim(x))),obj.tData(:,1)));
            addpath(obj.dDir0);
            
            % updates the download progress strings
            obj.updateProgressFields(0,'Starting DART Installation');
            
            % installs DART for the specified versions            
            dDir = cell(nDir,1);
            for iDir = 1:nDir           
                % installs the DART version for the current directory
                dDir{iDir} = obj.installDART(iDir,nDir);
                
                % initialises the git-hub configuration props
                if iDir == 1
                    obj.initGitConfigFiles();
                    obj.initGitConfigFields();
                end
            end
            
            % changes back to the original directory
            cd(obj.dDir0)
            rmpath(obj.dDir0);            
            
            % links the program default directory files between versions
            for iDir = 1:nDir
                obj.initProgDefFile(dDir,iDir);
            end            
            
            % updates the download progress strings
            obj.updateProgressFields(1,'Installation Complete');            
            pause(1);
            
            % enables the program installation button
            set(hObj,'Enable','off')
            
            % resets the table data
            obj.tData(:) = {' '};
            set(obj.hTable,'Data',obj.tData);
            obj.resetColumnFormatString([],NaN)
            
            % resets the progressbar
            tStrP0 = 'Waiting To Start Installation...';
            obj.updateProgressFields(0,tStrP0,'off');
            
            % resets the column format strings
            obj.prVer = obj.findDARTInstalls(obj.fDirB);
            obj.resetColumnFormatString([],NaN);
            
        end

        % ----------------------------------- %
        % --- DART INSTALLATION FUNCTIONS --- %
        % ----------------------------------- %          
        
        % --- installs DART for the version indicated by table row, iDir
        function dDir = installDART(obj,iDir,nDir)
            
            % sets the installation directory name
            pR = 1/nDir;
            dName = obj.tData{iDir,1};
            dDir = fullfile(obj.fDirB,dName);   
            obj.gDirB = fullfile(dDir,obj.gDirB0);
           
            % removes the GIT_DIR environment variable
            obj.sysCall('setx GIT_DIR ""');
            obj.sysCall('reg delete "HKCU\Environment" /v GIT_DIR /f');
            
            % creates the program and parent git directories
            if ~exist(dDir,'dir'); mkdir(dDir); end
            if ~exist(obj.gDirB,'dir'); mkdir(obj.gDirB); end
            cd(dDir);
            
            % removes any remote repository URLS (if set)
            [~,R] = obj.sysCall('git config --get remote.origin.url');
            if ~isempty(R)
                obj.sysCall('git remote remove origin');            
            end
            
            % clones each of the repositories 
            for i = 1:length(obj.rName)
                % updates the progressbar
                prStr = sprintf('Cloning "%s"',obj.rBase{i});
                pNw = pR*((iDir-1) + 0.1 + 0.8*(i/length(obj.rName)));
                obj.updateProgressFields(pNw,prStr);
                
                % creates the new repo directory
                dRepoNw = fullfile(dDir,obj.outDir{i});
                if ~exist(dRepoNw,'dir'); mkdir(dRepoNw); end
                
                % initialises the git repository directory
                gRepoNw = fullfile(obj.gDirB,obj.rName{i});
                if ~exist(gRepoNw,'dir'); mkdir(gRepoNw); end
                
                % changes the directory and creates the repo URL
                cd(dRepoNw)
                rURL = sprintf('https://%s%s%s',...
                                    obj.tKey,obj.rBaseURL,obj.rName{i});                
                                    
                % initialises the git repository in the current folder
                obj.sysCall(sprintf...
                        ('git init --separate-git-dir="%s"',gRepoNw));
                obj.sysCall('git config core.sparseCheckout true');
                obj.sysCall(sprintf('git remote add -f origin %s',rURL));
                
                % creates the repository description file
                dFileNw = fullfile(gRepoNw, 'description');
                obj.writeFile(obj.rDesc{i},dFileNw);
                
                % creates the respository exclusion file
                if ~isempty(obj.exDir{i})
                    % adds the fields to the exclusion file
                    exFileNw = fullfile(gRepoNw,obj.exFile);
                    for j = 1:length(obj.exDir{i})                    
                        obj.addFileLine(obj.exDir{i}{j},exFileNw);
                    end
                end
                
                % adds the default directories to the sparse checkout file
                chkFileNw = fullfile(gRepoNw, obj.chkFile);
                for j = 1:length(obj.gFiles{i})
                    obj.addFileLine(obj.gFiles{i}{j},chkFileNw);
                end                
                
                % pulls the repository from origin/master
                obj.sysCall(sprintf('setx GIT_DIR "%s"',dRepoNw));
                obj.sysCall('git pull origin master');
            
                % removes the GIT_DIR environment variable
                obj.sysCall('setx GIT_DIR ""');
                obj.sysCall('reg delete "HKCU\Environment" /v GIT_DIR /f');
                
                % removes the origin key
                obj.sysCall('git remote remove origin');
                
            end     
            
            % initalises the data directory structure
            obj.initDataDirStructure(dDir);
            
            % updates the progressbar objects
            pPr = pR*((iDir-1) + 0.95);
            obj.updateProgressFields(pPr,'Git Installation Complete!')            
            
        end        
           
        % --- initialises the data directory structure
        function initDataDirStructure(obj,dDir)
            
            % initialisations        
            dDirN = struct('Recording',[],'Tracking',[],'Combine',[],...
                           'Analysis',[],'Output',[]);
            
            % sets the data directory structure sub-fields
            dDirN.Recording = {'Video Presets',...
                               'Stimuli Playlists', ...
                               'Stimulus Traces'};
            dDirN.Tracking = {'Temporary Files'};
            dDirN.Combine = {'Temporary Files'};
            dDirN.Analysis = {'Analysis Functions','Temporary Files',...
                              'Temporary Data'};
            dDirN.Output = {'Recorded Movies','Solution Files (Video)',...
                            'Solution Files (Experiment)',...
                            'Analysis Figures','Analysis Data', ...
                            'Program Versions'};
                        
            % creates the data file directory (if it doesn't exist)
            dataDir = fullfile(dDir, 'Data');  
            if ~exist(dataDir,'dir'); mkdir(dataDir); end
            
            % sets up the data directories
            fldStr = fieldnames(dDirN);
            for i = 1:length(fldStr)
                % initialises the parent directory
                dataDirP = fullfile(dataDir,fldStr{i});
                if ~exist(dataDirP,'dir'); mkdir(dataDirP); end
                
                % creates the data folder sub-directories
                fDirS = obj.getStructField(dDirN,fldStr{i});
                for j = 1:length(fDirS)                    
                    subDir = sprintf('%i - %s',j,fDirS{j});
                    dataDirS = fullfile(dataDirP,subDir);
                    if ~exist(dataDirS,'dir'); mkdir(dataDirS); end
                end
            end
            
        end
        
        % --- initialises the data directory structure
        function initProgDefFile(obj,dDir,iDir)
                     
            % sets the program default file path
            paraDir = fullfile(dDir{iDir}, 'Para Files');
            progDefFile = fullfile(paraDir, 'ProgDef.mat');

            % sets the data directory path
            if strcmp(obj.tData{iDir,2},'No Link')
                % version isn't linked to any other
                dDirNw = dDir{iDir};                
            else
                % version is linked to another version
                strSp = strsplit(obj.tData{iDir,2},'"');
                dDirNw = fullfile(obj.fDirB,strSp{2});
            end
            
            % sets the common output directories
            cmDir = {'1 - Recorded Movies',...
                     '2 - Solution Files (Video)',...
                     '3 - Solution Files (Experiment)',...
                     '4 - Analysis Figures',...
                     '5 - Analysis Data',...
                     '6 - Program Versions'};            
            
            % sets the main data directory paths
            dataDir = fullfile(dDirNw, 'Data');
            rDir = fullfile(dataDir, 'Recording');
            tDir = fullfile(dataDir, 'Tracking');
            cDir = fullfile(dataDir, 'Combine');
            aDir = fullfile(dataDir, 'Analysis');
            oDir = fullfile(dataDir, 'Output');
            
            % sets the program default
            pdInfo = struct('Recording',[],'Tracking',[],'Combine',[],...
                            'Analysis',[],'DART',[]);            
            pdInfo.Recording = struct(...
                'DirMov',fullfile(oDir,cmDir{1}),...
                'CamPara',fullfile(rDir,'1 - Video Presets'),...
                'DirPlay',fullfile(rDir,'2 - Stimuli Playlists'),...
                'StimPlot',fullfile(rDir,'3 - Stimulus Traces'));
            pdInfo.Tracking = struct(...
                'DirMov',fullfile(oDir,cmDir{1}),...
                'DirSoln',fullfile(oDir,cmDir{2}),...
                'TempFile',fullfile(tDir,'1 - Temporary Files'));            
            pdInfo.Combine = struct(...
                'DirSoln',fullfile(oDir,cmDir{2}),...
                'DirComb',fullfile(oDir,cmDir{3}),...
                'TempFile',fullfile(cDir,'1 - Temporary Files'));        
            pdInfo.Analysis = struct(...                
                'DirSoln',fullfile(oDir,cmDir{2}),...
                'DirComb',fullfile(oDir,cmDir{3}),...
                'OutFig',fullfile(oDir,cmDir{4}),...
                'OutData',fullfile(oDir,cmDir{5}),...
                'DirFunc',fullfile(aDir,'1 - Analysis Functions'),...
                'TempFile',fullfile(aDir,'2 - Temporary Files'),...
                'TempData',fullfile(aDir,'3 - Temporary Data'));        
            pdInfo.DART = struct('DirVer',fullfile(oDir,cmDir{6}));
            
            % sets the field data information for each group
            fldStr = fieldnames(pdInfo);
            for i = 1:length(fldStr)
                % sets the field data key within the dictionary
                pStrS = obj.getStructField(pdInfo,fldStr{i});
                fldStrS = fieldnames(pStrS);
                pStrS.fldData = struct();
                
                % sets the field data for each of the sub-fields                
                for j = 1:length(fldStrS)
                    fldPath = obj.getStructField(pStrS,fldStrS{j});
                    fData = {fldStrS{j},obj.getFileName(fldPath)};
                    pStrS.fldData = obj.setStructField(...
                                    pStrS.fldData,fldStrS{j},fData);
                end
                
                % updates the struct field
                pdInfo = obj.setStructField(pdInfo,fldStr{i},pStrS);
            end
            
            % creates the parameter file directory (if it doesn't exist)
            if ~exist(paraDir,'dir'); mkdir(paraDir); end
                    
            % creates the super dictionary
            ProgDef = pdInfo;
            save(progDefFile, 'ProgDef')

            % excludes the file from the git repository
            excFile = fullfile(dDirNw, '.git', 'info', 'exclude');
            obj.addFileLine(progDefFile,excFile);
            
        end        
        
        % --- initialises the git configuration file
        function initGitConfigFields(obj)
            
            % status config fields
            obj.sysCall('git config --global status.showUntrackedFiles all');
            obj.sysCall('git config --global core.autocrlf false');
            obj.sysCall('git config --global credential.helper store');  
            
            % determines the location of the meld program file
            meldExe = obj.findMeldProgFile();
            if isempty(meldExe); return; end
            
            % merge config fields
            obj.sysCall('git config --global merge.tool meld');
            obj.sysCall('git config --global merge.ff false');

            % difftool config fields
            obj.sysCall('git config --global diff.tool meld');

            % difftool-meld config fields
            diffOut = '"""$LOCAL""" """$REMOTE"""';
            obj.sysCall(['git config --global ',...
                         'difftool.meld.trustExitCode true']);
            obj.sysCall(sprintf(['git config --global difftool.meld.cmd ',...
                        '"%s%s%s %s"'],"'",meldExe,"'",diffOut));

            % mergetool config fields
            obj.sysCall('git config --global mergetool.prompt false');
            obj.sysCall('git config --global mergetool.keepBackup false');

            % mergetool-meld config fields
            mergeOut = ['"""$BASE""" """$LOCAL""" """$REMOTE""" ',...
                        '--output """$MERGED"""'];
            obj.sysCall(['git config --global ',...
                         'mergetool.meld.trustExitCode true']);
            obj.sysCall(sprintf(['git config --global mergetool.meld.cmd ',...
                        '"%s%s%s %s"'],"'",meldExe,"'",mergeOut));
            
        end        
        
        % --- initialises the git-hub configuration files
        function initGitConfigFiles(obj)
                        
            % sets the configuration file directory path
            if ispc
                % case is pc
                dVol = getenv('HOMEDRIVE');
                uName = getenv('USERNAME');
                cFigDir = fullfile(dVol,'Users',uName,'.config','gh');
                
            else
                % case is mac (FINISH ME!)
                waitfor(msgbox('Finish Me!'));
                cFigDir = 1;
            end
            
            % creates the config directory (if it doesn't exist)
            if ~exist(cFigDir,'dir'); mkdir(cFigDir); end
            
            % sets the full config file names
            fName = {'config.yml','hosts.yml','state.yml'};            
            fFile = cellfun(@(x)(fullfile(cFigDir,x)),fName,'un',0);
            
            % if all the file already exist the exit
            if all(cellfun(@(x)(exist(x,'file')),fFile))
                return
            end
            
            % sets the configuration file data
            fData = {
                {['# What protocol to use when performing git ',...
                  'operations. Supported values: ssh, https'],...
                  'git_protocol: https',...
                 ['# What editor gh should run when creating ',...
                  'issues, pull requests, etc. If blank, will ',...
                  'refer to environment.'],...
                  'editor:',...
                 ['# Aliases allow you to create nicknames for ',...
                  'gh commands'],... 
                  'aliases:','    co: pr checkout'},...
                {'github.com:',...
                 sprintf('    user: %s',obj.gtUser),...
                 sprintf('    oauth_token: %s',obj.gtKey)},...
                {sprintf('checked_for_update_at: %s',obj.tUpdate),...
                 'latest_release:',...
                 sprintf('    version: %s',obj.relVer),...
                 sprintf('    url: %s',obj.relURL)}
            };
            
            % creates each of the git-hub configuration files
            for i = 1:length(fFile)
                for j = 1:length(fData{i})
                    if j == 1
                        obj.writeFile(fData{i}{j},fFile{i});
                    else
                        obj.addFileLine(fData{i}{j},fFile{i});
                    end
                end
            end
            
        end
                
        % --- updates the progress object fields
        function updateProgressFields(obj,pPr,prStr,eStr)
            
            % sets the default input string
            if ~exist('eStr','var'); eStr = 'on'; end
            
            % updates the progress field properties
            set(obj.hTxtP,'String',prStr,'Enable',eStr);
            obj.jBarP.setValue(pPr*1000);            
            
        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %           
        
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
        
        % --- sets the install button enabled properties
        function setButtonEnabledProps(obj)
            
            % initialisations
            eStr = {'off','on'};
            hasD = cellfun(@(x)(~isempty(strtrim(x))),obj.tData);
            pD = mean(hasD,2);
            
            % determines if the table data is feasible
            if pD(1) < 1
                % if the data has not been set for the first row, then do
                % not allow installation to proceed
                isFeas = false;                
            else
                % otherwise, determine if all fields (for each row that has
                % been started) have been filled out correctly
                isFeas = all(mod(pD,1) == 0);
            end
            
            % updates the button enabled properties
            set(obj.hTxtP,'Enable',eStr{1+isFeas});            
            set(obj.hButC{2},'Enable',eStr{1+isFeas});
            
        end        
        
        % --- sets the table columnformat strings
        function resetColumnFormatString(obj,prVal,iRow)
            
            % initialisations
            fDirPr = [];
            cForm = get(obj.hTable,'ColumnFormat');            
            
            % determines if there are matching link fields
            if ~isnan(prVal)
                isM = strcmp(obj.tData(:,2),sprintf('Link To "%s"',prVal));
                if any(isM)
                    % resets the link fields (if associated field changes)
                    nwFld = sprintf('Link To "%s"',obj.tData{iRow,1});
                    obj.tData(isM,2) = {nwFld};
                    set(obj.hTable,'Data',obj.tData);
                end
            end
            
            % retrieves the directory names of the previous versions
            if ~isempty(obj.prVer)
                fDirPr = cellfun(@(x)(obj.getFileName...
                                (fileparts(x))),obj.prVer,'un',0);
            end
            
            % determines the unique directory names
            fDir = cellfun(@strtrim,obj.tData(:,1),'un',0);
            fDirU = [fDirPr;unique(fDir(~cellfun('isempty',fDir)),'stable')];
            tStrU = cellfun(@(x)(sprintf('Link To "%s"',x)),fDirU,'un',0);
            
            % resets the column format strings            
            cForm{2} = [{' ','No Link'},tStrU(:)'];
            set(obj.hTable,'ColumnFormat',cForm)            
            
        end

        % --- determines the location of the meld program file
        function meldFile = findMeldProgFile(obj)
            
            if ispc
                % case is for pc
                
                % initialisations
                meldFile0 = fullfile('Meld','Meld.exe');

                % sets the location of the meld tool exe file
                meldFile = fullfile(obj.getProgramFileDir(1),meldFile0);
                if ~exist(meldFile,'file')
                    % if not in the 32-bit program files directory, 
                    % then try the 64-bit
                    meldFile = fullfile(obj.getProgramFileDir(0),meldFile0);
                    if ~exist(meldFile,'file')
                        % if the file still doesn't exist, then exit
                        meldFile = [];
                    end
                end
                
            else
                % case is for mac
                
                % initialisations
                meldFile0 = fullfile('Meld','Meld.dmg');
                
                % FINISH ME!!
                a = 1;
            end
            
        end        
        
        % adds the string, nwStr, to the file, fFile
        function addFileLine(obj,nwStr,fFile)

            obj.sysCall(sprintf('echo %s >> "%s"',nwStr,fFile));

        end                
        
        % --- finds all the finds
        function fName = findDARTInstalls(obj,snDir,varargin)

            % initialisations
            [fFileAll,fName] = deal(dir(snDir),[]);

            % determines the files that have the extension, fExtn
            fFile = dir(fullfile(snDir,'DART.m'));
            if ~isempty(fFile)
                fNameT = arrayfun(@(x)(x.name),fFile,'un',0);
                fName = cellfun(@(x)(fullfile(snDir,x)),fNameT,'un',0);    
            end
            
            % only search the directories one branch deep
            if ~isempty(varargin); return; end

            % searches all the subdirectories in the current directory
            isDir = find(arrayfun(@(x)(x.isdir),fFileAll));
            for i = isDir(:)'
                % if the sub-directory is valid, then search it for any files        
                if ~(strcmp(fFileAll(i).name,'.') || ...
                                        strcmp(fFileAll(i).name,'..'))        
                    fDirNw = fullfile(snDir,fFileAll(i).name);                                        
                    fNameNw = obj.findDARTInstalls(fDirNw,1);
                    if ~isempty(fNameNw)
                        % if there are any matches, then add them to the name array
                        fName = [fName;fNameNw];
                    end
                end
            end

        end        
        
    end

    % static class methods
    methods (Static)
    
        % --- determines if directory string, nwStr, is a feasible directory string
        function ok = chkDirString(nwStr)

            % initialisations
            spStr = './\:?"<>|@$!^&''';
            [ok,vStr] = deal(true,'String Input Error');

            % if the string is empty, then exit with a false flag
            if isempty(nwStr)
                % outputs the error dialog (if not outputing error string)
                [ok,eStr] = deal(false,'Error! String can''t be empty.');                
                waitfor(errordlg(eStr,vStr,'modal')); 
                return
            end

            % determines if any of the offending strings are in the new string
            for i = 1:length(spStr)
                % if so, then exit the function with a false flag
                if contains(nwStr,spStr(i))
                    % resets the flag and set the output error
                    ok = false;
                    eStr = sprintf(['Error! String can''t ',...
                        'contain the string "%s".'],spStr(i));
                    
                    % outputs the error message to screen and exits
                    waitfor(errordlg(eStr,vStr,'modal'));
                    return
                end
            end    
        
        end
    
        % --- runs the command string, cmdStr, in the command prompt
        function [Status,Result] = sysCall(cmdStr)
           
            [Status,Result] = system(cmdStr);
            
        end
        
        % --- retrieves the program files directory
        function pfDir = getProgramFileDir(is32)
        
            % initialisations
            volS = {'C','D','E','F','G'};

            % determines the program files directory path
            for i = 1:length(volS)
                % sets the program files directory
                pfDir = sprintf('%s:\\Program Files',volS{i});
                if is32
                    % appends the suffix for the 32-bit directory
                    pfDir = sprintf('%s (x86)',pfDir);
                end

                % exits the function if the directory 
                if exist(pfDir,'dir')
                    return
                end
            end
                
        end        
        
        % --- retrieves the sub-field, pStr, from the struct, p
        function pVal = getStructField(p,pStr,varargin)

            % sets up the parameter string
            pStrN = sprintf('p.%s',pStr);
            for i = 1:length(varargin)
                pStrN = sprintf('%s.%s',pStrN,varargin{i});
            end

            % evaluates the string
            pVal = eval(pStrN);

        end
        
        % --- retrieves the sub-field, pStr, from the struct, p
        function p = setStructField(p,pStr,pVal)

            % ensures the field name/values are stored in cell arrays
            if ~iscell(pStr)
                [pStr,pVal] = deal({pStr},{pVal});
            end

            % evaluates all the struct fields
            for i = 1:length(pStr)
                eval(sprintf('p.%s = pVal{i};',pStr{i}));
            end

        end
        
        % --- retrieves the file name from a full directory string
        function fName = getFileName(fFull,varargin)

            % splits the full string into its parts
            [~,fName,fExtn] = fileparts(fFull);
            if nargin == 2; fName = [fName,fExtn]; end

        end
        
        % --- writes the file, fFile, with the string, nwStr
        function writeFile(nwStr,fFile)
            
            fID = fopen(fFile,'w');
            fprintf(fID,'%s',nwStr);
            fclose(fID);
            
            % small pause to ensure file output...
            pause(0.01);
            
        end                
        
    end
    
end