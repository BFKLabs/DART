classdef DART < handle
    
    % class properties
    properties (Hidden)
        
        % main properties
        hFig        
        hProg
        cData        
        jFiles
        mainDir
        progDef
        hFigSub
        
        % object handles        
        hPanel
        hEdit
        hBut
        hTxt
        hMenuP
        hTrack
        
        % dummy object handles
        hTableD
        hListD
        
        % fixed object dimensions   
        dX = 10;
        dY = 70;
        dXH = 5;
        szBut = 56;
        widPanel = 500;
        hghtPanel = 365;
        widTxt = 415;
        hghtTxt = 40;        
        
        % variable object dimensions   
        widFig
        hghtFig
        szEdit
        
        % other fields
        uType
        hasSep        
        tSz = 30;
        nMenu = 5;        
        tagStr = 'figDART';
        prDir = {'Code','Git','External Files','Para Files'};
        
    end
    
    % class methods
    methods
    
        % --- class constructor
        function obj = DART(varargin)
            
            % performs a program diagnostic check 
            if ~obj.progDiagnosticCheck()
                % if there was an error, then exit
                return                
            end
            
            % loads the program directories
            obj.loadProgDir();             
            
            % initialises the class fields and objects
            obj.initClassFields();
            obj.initClassObjects();                       
            
            % ------------------------------- %    
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %

            % deletes the loadbar
            delete(obj.hProg);
            
            % makes the GUI object visible
            setObjVisibility(obj.hFig,1)
            centreFigPosition(obj.hFig);
            
            % updates the figure
            obj.getJavaObjectDim();
            
        end            
        
        % --- performs the program diagnostic check
        function ok = progDiagnosticCheck(obj)
                    
            % global variables
            global mainProgDir
            
            % clears the screen
            clc            
            
            % initialisations
            ok = true;
            [obj.mainDir,mainProgDir] = deal(pwd);                    
            
            % determines if there are any existing DART sessions
            hFigPr = findall(0,'tag',obj.tagStr);
            if ~isempty(hFigPr) && ~isdeployed
                % if so, then prompt the user if they wish to re-initialise
                tStr = 'Existing DART Session';
                mStr = sprintf(['A DART session is already running.\n',...
                    'Do you wish to re-initialise the DART session?']);                
                uChoice = questdlg(mStr,tStr,'Yes','No','Yes');
                if strcmp(uChoice,'Yes')
                    % deletes the previous DART session and continues
                    delete(hFigPr);
                    
                else
                    % exits the function flagging an error
                    ok = false;
                    return
                end
            end            
            
            % if the parameter files sub-directory is not located in the 
            % main program directory, then exit with an error
            paraDir = fullfile(obj.mainDir,'Para Files');
            if ~exist(paraDir,'dir')
                % outputs the error message to screen
                tStr = 'Parameter Files Directory Missing?';
                eStr = sprintf(['The parameter files sub-directory ',...
                    '("Para Files") is not present in the location ',...
                    'where you are attempting to run DART from.\n\n',...
                    'Move the DART executable file (DART.exe) or ',...
                    'Matlab entry file (DART.m) to where this ',...
                    'directory is located and then restart the program']);
                waitfor(errordlg(eStr,tStr,'modal'))
                
                % exits the program
                ok = false;
                return
            end      
            
            % ensures DART is being run from the correct directory
            if ~exist(fullfile(obj.mainDir,'DART.m'),'file') && ~isdeployed
                % if not, then output an error to screen and exit
                eStr = {'DART is being run from the incorrect directory.';...
                    ['Alter the Matlab path to the DART program ',...
                    'directory and restart']};
                waitfor(errordlg(eStr,'Incorrect Start Directory','modal'))
                
                % exits the function with a false flag
                ok = false;
                return
            end
            
            % ensures environment variables are set correctly (mac only)
            if ismac && ~verLessThan('matlab','9.2')
                ePath = getenv('PATH');
                if ~any(strcmp(regexp(ePath,'[:]','split'),'/bin/bash'))
                    % if not, then update them
                    setenv('PATH',[ePath,':/bin/bash'])
                end
            end
            
            % attempts to write a temporary file to the parameter directory 
            % (checks if the user has valid write permissions)
            try
                tmpFile = fullfile(paraDir,'TempFile.mat');
                save(tmpFile,'paraDir');
                delete(tmpFile);
            catch
                % if not, then output an error to screen 
                eStr = {['Error! Matlab does not have valid Write ',...
                        'Permissions.'];'';['You will need to re-open ',...
                        'Matlab with Administrative Permissions']};
                waitfor(errordlg(eStr,'Invalid Write Permissions','modal'))
                
                % exits the function with a false flag
                ok = false;
                return
            end
        
            % sets up the java file directories
            cDir0 = obj.getProgFileName('Code','Common');
            jDir0 = {{'File Exchange','xlwrite','poi_library'},...
                     {'Utilities','CondCheckTable'},...
                     {'File Exchange','ColoredFieldCellRenderer.zip'}};
            
            % sets up the java file directory paths
            jFiles0 = cell(length(jDir0),1);
            for i = 1:length(jDir0)
                jDirNw = obj.setupJavaDirPath(cDir0,jDir0{i});
                
                % adds the java files to the path
                if obj.strContains(jDirNw,'xlwrite')
                    % case is the xlwrite java files
                    jFileNw = dir(fullfile(jDirNw,'*.jar'));
                    jFiles0{i} = strjoin(arrayfun(@(x)...
                        (fullfile(jDirNw,x.name)),jFileNw,'un',0),';');
                                        
                else                    
                    % case is the other files/directories
                    jFiles0{i} = jDirNw;
                end
            end
            
            % sets the file java file string array
            obj.jFiles = strsplit(strjoin(jFiles0,';'),';')';
                 
        end        
        
        % --- loads the program directories
        function loadProgDir(obj)
        
            % adds in the progress dialog menu
            if ~isdeployed
                baseDir = fullfile(obj.mainDir,'Code','Common');
                addpath(fullfile(baseDir,'File Exchange','ProgressDialog'));
                addpath(fullfile(baseDir,'Progress Bars'));
            end
            
            % creates the initialisation load bar
            obj.hProg = ProgressLoadbar('Initialising DART Program...');
            
            % adds in the program directories (non-executable only)
            if ~isdeployed            
                % adds the main program paths
                addpath(obj.mainDir);

                % removes the main folders from the path
                for i = 1:length(obj.prDir)
                    addDir = obj.getProgFileName(obj.prDir{i});
                    obj.updateSubDir(addDir,1)
                end                                               
            end            
            
            % adds the java files to the path
            obj.updateJavaFiles(true);             
            
            % loads/initialises the default directory path file
            defFile = getParaFileName('ProgDef.mat');
            if exist(defFile,'file')
                % if the file exists, load the data from file
                obj.progDef = obj.checkAllDefaultDir(defFile); 
                
            else
                % if the file doesn't exist, then re-initialise it
                set(obj.hProg.Control,'visible','off');
                eStr = [{['The DART Program Data File Has Not ',...
                    'Been Initialised Or Is Missing']};...
                    {['DART Will Now Automatically Create ',...
                    'The Default Program Data File.']}];
                waitfor(warndlg(eStr,'Program Default File Missing'))
                
                % sets up the directories here
                obj.progDef = obj.setupAllDefaultDir(defFile);
                set(obj.hProg.Control,'visible','on');
                uistack(obj.hProg.Control,'top');
            end
            
            % determines if the analysis functions folder exists in the 
            % main program directory (this will occur after initial setup)
            analyDir = obj.getProgFileName('Analysis Functions');
            if exist(analyDir,'dir')
                % if is does, then copy the folder to the correct location 
                % and remove the directory from the main folder
                copyAllFiles(analyDir,obj.progDef.Analysis.DirFunc);
                rmvAllFiles(analyDir);
            end
            
        end              
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % global variables
            global tDay hDay
        
            % turns off the required warnings
            warning('off','MATLAB:load:classNotFound');
            warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
            
            % main field initialisation
            obj.uType = runDevFunc('isDev');
            obj.hasSep = obj.uType && ~isdeployed;  
            
            % calculates the variable dimensions
            obj.widFig = obj.widPanel + 2*obj.dX;
            obj.hghtFig = obj.hghtPanel + 2*obj.dX;
            obj.szEdit = obj.szBut + obj.dX;
            
            % loads the button image data file
            cdFile = fullfile(obj.mainDir,'Para Files','ButtonCData.mat');
            A = load(cdFile);
            obj.cData = A.cDataStr;           
            
            % loads global analysis parameters from program parameter file
            A = load(getParaFileName('ProgPara.mat'));
            [tDay,hDay] = deal(A.gPara.Tgrp0,A.gPara.TdayC);
            
            % uses software opengl format
            opengl('save','software')
            
            % turns off the warnings
            warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
        
        end
        
        % --- initialises the class object properties
        function initClassObjects(obj)
            
            % initialisations
            fPos = [100,100,obj.widFig,obj.hghtFig];            
            titleStr = 'Drosophila ARousal Tracking Experiment Suite';            
            
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- %                        
            
            % creates the figure object
            obj.hFig = figure('Position',fPos,'tag',obj.tagStr,...
                              'MenuBar','None','Toolbar','None',...
                              'Name',titleStr,'NumberTitle','off',...
                              'NumberTitle','off','Visible','off');
        
            % creates the main panel 
            pPos = [obj.dX,obj.dX,obj.widPanel,obj.hghtPanel];
            obj.hPanel = uipanel(obj.hFig,'Title','','Units',...
                                          'Pixels','Position',pPos);                          
             
            % sets the main object into the figure
            setappdata(obj.hFig,'mObj',obj); 
            
            % -------------------------- %
            % --- DUMMY OBJECT SETUP --- %
            % -------------------------- %
            
            % creates the dummy table object
            Data = {'Temp Data'};
            tPosD = [168,159,130,35];
            obj.hTableD = uitable(obj.hPanel,'Position',tPosD,'Data',Data);
            
            % creates the dummy listbox object
            lPosD = [520,490,520,385];
            obj.hListD = uicontrol(obj.hPanel,'Position',lPosD,...
                                   'Style','Listbox','String',{''});
                          
            % ------------------------- %
            % --- MENU ITEM OBJECTS --- %
            % ------------------------- %                          
            
            % initialisations
            txtStr = {'Exit Program','Quantitative Analysis',...
                      'Experiment Data Output','Fly Tracking',...
                      'Experimental Setup'};
            fldStr = {'Exit','Analysis','Combine','Tracking','Recording'};
            bFcnCB = {@obj.buttonExitDART,...
                      @obj.buttonFlyAnalysis,...
                      @obj.buttonFlyCombine,...
                      @obj.buttonFlyTrack,...
                      @obj.buttonFlyRecord};                              
            
            % creates the label/button objects
            obj.hBut = cell(length(txtStr),1);
            for i = 1:length(txtStr)
                % creates the text objects
                yPosT = (i-1)*obj.dY + (2*obj.dX - 1);
                tPos = [obj.dXH-2,yPosT,obj.widTxt,obj.hghtTxt];
                uicontrol(obj.hPanel,'Style','Text','String',txtStr{i},...
                          'Units','Pixels','FontUnits','Pixels',...
                          'FontWeight','bold','FontSize',obj.tSz,...
                          'HorizontalAlignment','Center','Position',tPos);                    
                                          
                % creates the editbox/button objects
                lPosE = sum(tPos([1,3]));
                yPosE = yPosT - (obj.dX + 3);
                ePos = [lPosE,yPosE,obj.szEdit*[1,1]];
                uicontrol(obj.hPanel,'Style','Edit','String','',...
                          'Units','Pixels','BackgroundColor',[0,0,0],...
                          'Position',ePos,'Enable','Inactive');   
                      
                % creates the button objects
                bPos = [ePos(1:2)+obj.dXH,obj.szBut*[1,1]];
                ImgNw = getStructField(obj.cData,fldStr{i});
                obj.hBut{i} = uicontrol(obj.hPanel,'Style','Pushbutton',...
                          'Units','Pixels','FontUnits','Pixels',...
                          'FontWeight','bold','Position',bPos,...
                          'Callback',bFcnCB{i},'CData',ImgNw); 
                
            end
                                      
            % ------------------------- %
            % --- MENU ITEM OBJECTS --- %
            % ------------------------- % 
            
            % initialisations            
            A = cell(obj.nMenu,2);            
            [mStrC,mFcnCB,mSep,mTagC,mAccC,eStateM] = deal(A);            
            hasPkgFile = exist('runPackageInstaller','file') > 0;
            hasExeU = (exist('ExeUpdate.exe','file') > 0) && ~isdeployed;
            
            % menu label strings
            mStrC(:,1) = {'Program Code I/O',...
                'Program Installation Information',...
                'Configure Serial Devices','Default Directories',...
                'About DART'};
            mStrC{1,2} = {'Output Program','Update Executable',...
                'Create DART Executable','Run DART Installer Wizard',...
                'Add External Package'};

            % menu item tag strings
            mTagC(:,1) = {'menuProgCode','menuProgInstallInfo',...
                'menuConfigSerial','menuProgPara','menuAboutDART'};
            mTagC{1,2} = {'menuOutputProg','menuExeUpdate',...
                'menuDeployExe','menuRunInstaller','menuAddPackage'};
            
            % menu item accelarator
            mAccC(:,1) = {'','I','S','D','A'};
            mAccC{1,2} = {'S','X','E','N','P'};
            
            % menu item enabled state
            eStateM(:,1) = {'on','on','off','on','on'};
            eStateM{1,2} = {'on','on','off','on','on'};            
            
            % menu item callback function
            mFcnCB(:,1) = {[],...
                           @obj.menuProgInstallInfo,@obj.menuConfigSerial,...
                           @obj.menuProgPara,@obj.menuAboutDART};
            mFcnCB{1,2} = {@obj.menuOutputProg,@obj.menuExeUpdate,...
                           @obj.menuDeployExe,@obj.menuRunInstaller,...
                           @obj.menuAddPackage};
            
            % sets the separator flags
            mSep(:,1) = {'off','on','off','off','on'};
            mSep{1,2} = {'off','on','off','on','on'};
            
            % creates the main menu item
            obj.hMenuP = uimenu(obj.hFig,'Label','DART');
            
            % creates the other menu items
            for i = 1:obj.nMenu
                % creates the sub-menu item
                hMenuC = uimenu(obj.hMenuP,'Label',mStrC{i,1},...
                                           'Callback',mFcnCB{i,1},...                                           
                                           'Tag',mTagC{i,1},...
                                           'Accelerator',mAccC{i,1},...
                                           'Enable',eStateM{i,1});
                obj.setMenuSeparatorField(hMenuC,mSep{i,1});                                       
                   
                % creates the sub-sub-menu items (if they exist)
                for j = 1:length(mStrC{i,2})
                    hMenuS = uimenu(hMenuC,'Label',mStrC{i,2}{j},...
                                           'Callback',mFcnCB{i,2}{j},...
                                           'Tag',mTagC{i,2}{j},...
                                           'Accelerator',mAccC{i,2}{j},...
                                           'Enable',eStateM{i,2}{j});
                    obj.setMenuSeparatorField(hMenuS,mSep{i,2}{j});
                end
            end                                    
            
            % only include the add package menu item if the function exists
            obj.setMenuProp('menuAddPackage','Visible',hasPkgFile);
            
            % sets the GUI properties based on how the program is being run
            if isdeployed
                % case is DART is run through the executable version
                obj.setMenuProp('menuConfigSerial','Enable','on')
                
            elseif ispc
                % case is DART is being run via Matlab on PC
                obj.setMenuProp('menuDeployExe','Enable','on')
                obj.setMenuProp('menuConfigSerial','Enable','on')
                obj.setMenuProp('menuExeUpdate','Enable',hasExeU)                                
                
            end
            
            % sets the I/O menu item properties
            obj.setMenuProp('menuUpdateProg','Visible',obj.hasSep)
            obj.setMenuProp('menuOutputProg','Visible',obj.hasSep)
            obj.setMenuProp('menuDeployExe','Visible',obj.hasSep)
            obj.setMenuProp('menuRunInstaller','Visible',~isdeployed)
            
            % ----------------------------- %
            % --- VERSION CONTROL SETUP --- %
            % ----------------------------- %
            
            % creates the Git menu items
            if exist('GitFunc','file') && ~isdeployed
                % updates the loadbar message
                obj.hProg.StatusMessage = 'Updating Version Control';
                
                % sets up the git menu
                setupGitMenus(obj.hFig);
                obj.checkGitFuncVer();
            end            
            
        end                    
        
        % --- checks that the git function version is up to date 
        %     (for non-developed users only)
        function checkGitFuncVer(obj)
            
            % sets up the GitFunc class object
            GF0 = GitFunc();
            
            % if a developer, then exit the function
            if GF0.uType
                return
            end
            
            % initialisations
            rType = 'Git';
            gDirP = obj.getProgFileName('Git');
            gRepoDir = fullfile(gDirP,'Repo','DARTGit');
            gName = 'Git Functions';
            
            % creates the git function object
            gitEnvVarFunc('add','GIT_DIR',gRepoDir)
            GF = GitFunc(rType,gDirP,gName);
            
            % removes/sets the origin url
            GF.gitCmd('rmv-origin')
            GF.gitCmd('set-origin')
            
            % determines the current/head commit ID
            cID0 = GF.gitCmd('commit-id','origin/master');
            cIDH = GF.gitCmd('branch-head-commits','master');
            if ~startsWith(cID0,cIDH)
                % if they don't match, then reset the repository so that 
                % it matches the remote repository
                GF.matchRemoteBranch('master');
            end
            
            % removes the git directory environment variables
            gitEnvVarFunc('remove','GIT_DIR');
            GF.gitCmd('rmv-origin');
            
            % sets the directory to the main
            cd(obj.getProgFileName())
            
        end        
        
        % -------------------------- %
        % --- CALLBACK FUNCTIONS --- %
        % -------------------------- %            
        
        % --- experimental setup button callback function
        function buttonFlyRecord(obj, ~, ~)
            
            iStim0 = initTotalStimParaStruct();
            AdaptorInfo('hFigM',obj.hFig,'iType',1,'iStim',iStim0);
            
        end
        
        % --- tracking sub-GUI button callback function
        function buttonFlyTrack(obj, ~, ~)
            
            FlyTrack(obj.hFig)
            
        end
        
        % --- data combining sub-GUI button callback function
        function buttonFlyCombine(obj, ~, ~)
            
            FlyCombine(obj.hFig);
            
        end
        
        % --- analysis sub-GUI button callback function
        function buttonFlyAnalysis(obj, ~, ~)
            
            FlyAnalysis(obj.hFig);
            
        end        
        
        % --- DART close button callback function
        function buttonExitDART(obj, ~, ~)
            
            % adds in the program directories
            if ~isdeployed
                % initialisations
                lStr = 'Closing Down DART Program...';   
                wState = warning('off','all');
                
                % creates a loadbar figure
                h = ProgressLoadbar(lStr);
                pbDir = fileparts(which('ProgressDialog'));                                
                
                % removes the java files
                obj.updateJavaFiles(false);                
                
                % removes the main folders from the path
                for i = 1:length(obj.prDir)
                    rmvDir = obj.getProgFileName(obj.prDir{i});
                    obj.updateSubDir(rmvDir,0)
                end
                
                % removes the main code directory
                rmpath(obj.getProgFileName())                
                
                % delete the progressbar and removes the progress dialog
                h.delete();
                rmpath(pbDir)
                warning(wState);
            end
            
            % deletes the GUI
            delete(obj.hFig);
            
        end        
        
        % ------------------------------------------------ %
        % --- PROGRAM CODE I/O MENU CALLBACK FUNCTIONS --- %
        % ------------------------------------------------ %

        % --- update program menu item callback function
        function menuProgInstallInfo(~, ~, ~)
           
            % runs the installation information GUI
            InstallInfo();
            
        end
        
        % --- update program menu item callback function
        function menuConfigSerial(obj, ~, ~)
            
            % runs the diagnostic tool GUI
            SerialConfig(obj.hFig);
            
        end
        
        % --- update program menu item callback function
        function menuProgPara(obj, ~, ~)
            
            % runs the program default GUI
            ProgDefaultDef(obj.hFig,'DART');
            
        end
        
        % --- about DART menu item callback function
        function menuAboutDART(~, ~, ~)
            
            % runs the about DART GUI
            AboutDARTClass();
            
        end

        % ------------------------------------- %
        % --- OTHER MENU CALLBACK FUNCTIONS --- %
        % ------------------------------------- %                       
        
        % --- output program menu item callback function
        function menuOutputProg(obj, ~, ~)
            
            % global variables
            global isFull
            
            % initialisations
            tStr = 'Select Program Zip File';            
            fMode = {'*.zip;','Zip File (*.zip)'};
            wStr0 = 'Creating Temporary Code Directories';
            
            % sets the default file name
            dDir = obj.progDef.DART.DirVer;
            dName = sprintf('DART (%s).zip',datestr(clock,'yyyy_mm_dd'));
            dFile = fullfile(dDir,dName);
            
            % prompts the user for the program update .zip file
            [zName,zDir,zIndex] = uiputfile(fMode,tStr,dFile);
            if zIndex == 0
                % if the user cancelled, then exit the function
                return
            end
            
            % sets up the temporary file directory
            tmpDir = obj.getProgFileName('Temp Files');
            zFile = fullfile(zDir,zName);
            mkdir(tmpDir)
            
            % sets whether the full file is being output
            tStrQ = 'Program Output Type';
            qStr = ['Do you want to output the A) full code ',...
                    'or B) partial code'];
            uChoice = questdlg(qStr,tStrQ,'Full','Partial','Full');
            isFull = strcmp(uChoice,'Full');
            
            % creates the loadbar figure
            wState = warning('off','all');
            h = ProgressLoadbar('Initialising...');
            set(h.Control,'CloseRequestFcn',[]);
            
            % sets the file directory names
            sName = {'DART Main';'Analysis';'Common';'Combine';...
                     'Recording';'Tracking';'Analysis Functions'};
            if isFull
                sName = [sName;{'External Files';'Para Files'}];
            end            
            
            % prepares the directories for outputting the data
            nwDir = cell(length(sName),1);
            for i = 1:length(sName)
                % updates the loadbar
                wStr = sprintf('%s (%s)',wStr0,sName{i});
                h.StatusMessage = wStr;
                
                % sets the new temporary directory to copy
                nwDir{i} = fullfile(tmpDir,sName{i}); mkdir(nwDir{i});
                
                % copies over the directories
                switch sName{i}
                    case ('DART Main')
                        % case is the main DART directory
                        copyAllFiles(obj.mainDir,nwDir{i},1);
                        
                    case {'External Files','Para Files'}
                        % case is the external/parameter files
                        cDir = obj.getProgFileName(sName{i});
                        copyAllFiles(cDir,nwDir{i});
                        
                    case ('Analysis Functions')
                        % case is the analysis functions
                        copyAllFiles(obj.progDef.Analysis.DirFunc,nwDir{i});
                        
                    otherwise
                        % case is the other code directories
                        cDir = obj.getProgFileName('Code',sName{i});
                        copyAllFiles(cDir,nwDir{i});
                end
            end
            
            % saves the zip file
            h.StatusMessage = 'Saving Zip File...';
            zip(zFile,nwDir);
            
            % updates the log-file
            obj.updateLogFile(zFile);
            
            % removes the temporary directory
            h.StatusMessage = 'Removing Temporary Directories...';
            rmvAllFiles(tmpDir);
            
            % updates the status message
            [h.Indeterminate,h.FractionComplete] = deal(false,1);
            h.StatusMessage = 'Update File Creation Complete!'; pause(0.2)
            try; delete(h); end
            
            % turns on all the warnings again            
            warning(wState);
            
        end
        
        % --- update executable menu item callback function
        function menuExeUpdate(obj, ~, ~)
            
            % runs the executable update GUI
            ExeUpdate(obj.hFig);
            
        end
        
        % --- executable redeployment menu item callback function
        function menuDeployExe(obj, ~, ~)
            
            % initialisations
            titleStr = 'Set The Executable Output Directory';
            
            % prompts the user to set the output directory
            outDir = uigetdir(obj.mainDir,titleStr);
            if outDir
                % runs the executable creation code
                createDARTExecutable(obj.mainDir,outDir,obj.progDef)
            end
            
        end
        
        % --- DART installer menu item callback function
        function menuRunInstaller(obj, ~, ~)
            
            % runs the dart installer wizard
            DARTInstallerL(obj.hFig);
            
        end
        
        % --- external package addition menu item callback function
        function menuAddPackage(obj, ~, ~)
           
            % initialisations
            tStr = 'Select DART Package';
            fMode = {'*.dpkg','DART Package (*.dpkg)'};
            
            % prompts the user for the external package
            [fName,fDir,fIndex] = uigetfile(fMode,tStr,obj.mainDir);
            if fIndex == 0
                % if the user cancelled, then exit
                return
            end
            
            % ensures the external apps folder exists (create/add if not)
            fDirExApp = obj.getProgFileName('Code','External Apps');
            if ~exist(fDirExApp,'dir')
                mkdir(fDirExApp);
                pause(0.05);
                addpath(fDirExApp);
            end
            
            % sets the output directory
            fDirOut = fullfile(fDirExApp,getFileName(fName));
            if ~exist(fDirOut,'dir')
                mkdir(fDirOut);
                pause(0.05);
                addpath(fDirOut);
            end
            
            % runs the package installer
            runPackageInstaller(fullfile(fDir,fName),fDirOut);
            
        end
        
        % ------------------------------------- %
        % --- JAVA FILE/DIRECTORY FUNCTIONS --- %
        % ------------------------------------- %
        
        % --- removes the java files from the path
        function updateJavaFiles(obj,isAdd)
            
            % turns off any warnings
            wState = warning('off','all');
        
            if isAdd
                % adds the java files to the path
                cellfun(@javaaddpath,obj.jFiles)
            else
                % removes the java files from the path
                cellfun(@javarmpath,obj.jFiles)
            end
            
            % turns off any warnings
            warning(wState);            
                
        end        
        
        % --- retrieves the java object dimensions
        function getJavaObjectDim(obj)
            
            % global variables
            global H0T HWT W0T HWL
            
            % re-draws
            drawnow; pause(0.05);
            
            % keep determining the object dimensions until they are found
            while true
                try
                    % attempts to retrieve the object dimensions
                    [H0T,HWT,W0T] = getTableDimensions(findjobj(obj.hTableD));
                    HWL = getListDimensions(findjobj(obj.hListD));
                    
                    % exits the loop
                    break
                catch
                    % if it failed then pause and then retry
                    pause(0.1);
                end
            end            
            
        end        
        
        % --------------------------------- %
        % --- PROGRAM DEFAULT FUNCTIONS --- %
        % --------------------------------- %
        
        % --- 
        function progDef0 = getDefaultDirStruct(obj)
            
            progDef0 = obj.progDef;
            
        end
        
        % --- 
        function setDefaultDirStruct(obj,progDefNw)
           
            obj.progDef = progDefNw;
            
        end
        
        % --- checks that all default directories paths exist
        function ProgDef = checkAllDefaultDir(obj,defFile)
            
            % loads the data file
            defData = load(defFile); 
            ProgDef = defData.ProgDef;
            
            % retrieves the struct field names
            fNames = fieldnames(defData.ProgDef);
            defFile = getParaFileName('ProgDef.mat');
            
            % loops through all of the program directories determining if 
            % the default directories exist. if they do not, then run 
            % the program default GUI
            for i = 1:length(fNames)                
                % sets the new sub-struct and its field names
                nwStr = getStructField(ProgDef,fNames{i});
                fNamesS = fieldnames(nwStr.fldData);
                
                % memory allocation
                nFlds = length(fNamesS);
                [ok,dDetails] = deal(true(nFlds,1),cell(nFlds,1));
                
                % loops through all dir fields determining if they exist
                for j = 1:nFlds
                    % evaluates the new directory
                    nwDir = getStructField(nwStr,fNamesS{j});
                    dDetails{j} = getStructField(nwStr.fldData,fNamesS{j});
                    
                    % check to see if the directory exists
                    if ~exist(nwDir,'dir')
                        % if the directory does not exist, then clear the 
                        % directory field and flag a warning
                        ok(j) = false;
                        nwStr = setStructField(nwStr,fNamesS{j},[]);
                    end
                    
                end
                
                % if any of the directories do not exist, then prompt the 
                % user to reset the default directories
                if any(~ok)
                    % outputs a warning for the user
                    wStr = [{sprintf('The Following Directories Are Missing For The %s Program:',fNames{i})};...
                        {''};cellfun(@(x)(['    => ',x]),cellfun(@(x)(x{2}),dDetails(~ok),'un',0),'un',0)];
                    waitfor(warndlg(wStr,'Program Default File Missing'));
                    
                    % runs the program default directory reset GUI
                    ddObj = ProgDefaultDef(obj.hFig,fNames{i},nwStr);
                    
                    % updates the data struct with the new data struct
                    ProgDef = setStructField...
                        (ProgDef,fNames{i},ddObj.ProgDef);
                    save(defFile,'ProgDef');
                end
            end
            
        end
        
        % --- sets up all the default program directories --- %
        function ProgDef = setupAllDefaultDir(obj,defFile)
            
            % allocates memory for the program default struct
            ProgDef = struct('Recording',[],'Tracking',[],'Combine',[],...
                             'Analysis',[],'DART',[]);
            
            % sets up the record data struct fields
            strDART = struct();
            strDART.DirVer = {'Output','6 - Program Versions'};
            
            % sets up the record data struct fields
            strRec = struct();
            strRec.DirMov = {'Output','1 - Recorded Movies'};
            strRec.CamPara = {'Recording','1 - Video Presets'};
            strRec.DirPlay = {'Recording','2 - Stimuli Playlists'};
            strRec.StimPlot = {'Recording','3 - Stimulus Traces'};
            
            % sets up the tracking data struct fields
            strTrk = struct();
            strTrk.DirMov = {'Output','1 - Recorded Movies'};
            strTrk.DirSoln = {'Output','2 - Solution Files (Video)'};
            strTrk.TempFile = {'Tracking','1 - Temporary Files'};
            
            % sets up the tracking data struct fields
            strComb = struct();
            strComb.DirSoln = {'Output','2 - Solution Files (Video)'};
            strComb.DirComb = {'Output','3 - Solution Files (Experiment)'};
            strComb.TempFile = {'Combine','1 - Temporary Files'};
            
            % sets up the tracking data struct fields
            strAnl = struct();
            strAnl.DirSoln = {'Output','2 - Solution Files (Video)'};
            strAnl.DirComb = {'Output','3 - Solution Files (Experiment)'};
            strAnl.OutFig = {'Output','4 - Analysis Figures'};
            strAnl.OutData = {'Output','5 - Analysis Data'};
            strAnl.DirFunc = {'Analysis','1 - Analysis Functions'};
            strAnl.TempFile = {'Analysis','2 - Temporary Files'};
            strAnl.TempData = {'Analysis','3 - Temporary Data'};
            
            % creates the new data directories from the structs listed above
            dataDir = obj.getProgFileName('Data');
            ProgDef.DART = obj.createDataDir(strDART,dataDir);
            ProgDef.Recording = obj.createDataDir(strRec,dataDir);
            ProgDef.Tracking = obj.createDataDir(strTrk,dataDir);
            ProgDef.Combine = obj.createDataDir(strComb,dataDir);
            ProgDef.Analysis = obj.createDataDir(strAnl,dataDir);
            
            % saves the program default file
            save(defFile,'ProgDef');
            
        end        
        
        % --- retrieves the sub-field, pFldS, from the program defaults
        function ProgDefNew = getProgDefField(obj,pFldS)
            
            ProgDefNew = getStructField(obj.progDef,pFldS);
            
        end
        
        % ----------------------------------- %
        % --- PROGRAM PARAMETER FUNCTIONS --- %
        % ----------------------------------- %
        
        % --- checks the program parameter file
        function checkProgParaFile(obj)
            
            % retrieves the program parameter file
            pDir = obj.getProgFileName('Para Files');
            pFile = fullfile(pDir,'ProgPara.mat');
            
            % determines if the program parameter file exists
            if ~exist(pFile,'file')
                % if the file is missing, then initialise it
                initProgParaFile(pDir);
                
            else
                % loads the parameter file
                [A,isChange] = deal(load(pFile),false);
                
                % determines if the tracking parameters have been set
                if ~isfield(A,'trkP')
                    % initialises the tracking parameter struct
                    [mSzP,mSzM,isChange] = deal(20,8,true);
                    A.trkP = struct('nFrmS',25,'nPath',1,'PC',[],...
                                    'Mac',[],'calcPhi',false);
                    
                    % sets the PC classification parameters
                    A.trkP.PC.pNC = obj.setMarkProps([1,1,0],'.',mSzP);
                    A.trkP.PC.pMov = obj.setMarkProps([0,1,0],'.',mSzP);                    
                    A.trkP.PC.pStat = obj.setMarkProps([1,0.4,0],'.',mSzP);                    
                    A.trkP.PC.pRej = obj.setMarkProps([1,0,0],'.',mSzP);
                    
                    % sets the Mac classification parameters
                    A.trkP.Mac.pNC = obj.setMarkProps([1,1,0],'*',mSzM);                    
                    A.trkP.Mac.pMov = obj.setMarkProps([0,1,0],'*',mSzM);                    
                    A.trkP.Mac.pStat = obj.setMarkProps([1,0.4,0],'*',mSzM);                    
                    A.trkP.Mac.pRej = obj.setMarkProps([1,0,0],'*',mSzM);                    
                    
                else
                    % if the orientatation field is missing, then add it in
                    if ~isfield(A.trkP,'calcPhi')
                        [A.trkP.calcPhi,isChange] = deal(false,true);
                    end
                end
                
                % ensures the optimal down-sampling field is set
                if ~isfield(A.bgP,'pPhase')
                    isChange = true;
                    A.bgP = DetectPara.initDetectParaStruct('pPhase');
                end
                
                % determines if the serial device names have been set
                if ~isfield(A,'sDev')
                    % initialises the serial device names
                    isChange = true;
                    A.sDev = {'STMicroelectronics STLink COM Port',...
                        'STMicroelectronics STLink Virtual COM Port',...
                        'STMicroelectronics Virtual COM Port',...
                        'USB Serial Device'};
                end
                
                % updates the parameter file
                if isChange
                    save(pFile,'-struct','A');
                end
            end
                
        end                      
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %             
        
        % --- updates the sub-directories from the base dir, mainDir
        function updateSubDir(obj,pDir,isAdd)
            
            % initialisations
            sepStr = sprintf('%s+',filesep);
            
            % determines the                    
            dList0 = dir(fullfile(pDir, '**\*.*'));
            dList0 = dList0([dList0.isdir]);
            dList = unique(arrayfun(@(x)(x.folder),dList0,'un',0));
            
            % removes the non-feasible folders
            isOK = ~(obj.strContains(dList,'Executable Only') | ...
                     obj.strContains(dList,'Repo') | ...
                     obj.strContains(dList,sepStr));
            if ~isAdd
                isOK = isOK & ~obj.strContains(dList,'ProgressDialog');
            end
                                         
            % adds/removes the directories 
            dList = strjoin(dList(isOK),';');
            if isAdd
                % case is adding files to the path
                addpath(dList)
            else
                % case is removing files from the path
                rmpath(dList)
            end
            
        end        
        
        % --- wrapper function for determining if a string has a pattern. 
        %     this is necessary because there are 2 different ways of 
        %     determining this depending on the Matlab version 
        function hasPat = strContains(obj,str,pat)
            
            if isempty(pat)
                hasPat = false;
                return
            elseif iscell(str)
                hasPat = cellfun(@(x)(obj.strContains(x,pat)),str);
                return
            end
            
            try
                % attempts to use the newer version of the function
                hasPat = contains(str,pat);
            catch
                % if that fails, use the older version of the function
                hasPat = ~isempty(strfind(str,pat));
            end
            
        end           
        
        % --- retrieves the full name of a program directory or file
        function pFile = getProgFileName(obj,varargin)
            
            % sets the main program directory
            pFile = obj.mainDir;
            
            % sets the full program file name path
            for i = 1:length(varargin)
                pFile = fullfile(pFile,varargin{i});
            end
            
        end                
        
        % --- updates the menu item visibility fields
        function setMenuProp(obj,tStrM,pFld,pVal)
            
            % finds the object handle corresponding to tStrM
            hMenu = findall(obj.hMenuP,'tag',tStrM);
            
            % sets the menu item field property based on type
            switch pFld
                case 'Enable'
                    % case is the enabled field 
                    setObjEnable(hMenu,pVal)
                    
                case 'Visible'
                    % case is the visibility field
                    setObjVisibility(hMenu,pVal)
                    
                case 'Separator'
                    % case is another field type
                    eStr = {'off','on'};
                    set(hMenu,pFld,eStr{1+pVal})
            end
            
        end
        
        % --- updates the log-file with the new information
        function updateLogFile(obj,zFile)
            
            % determines the zip-file name parts
            [~,fName,fExtn] = fileparts(zFile);
            
            % resaves the log-file
            [Time,File] = deal(clock,[fName,fExtn]);
            logFile = obj.getProgFileName('Para Files','Update Log.mat');
            save(logFile,'File','Time')
            
        end         
        
    end
        
    % static class methods
    methods (Static)
        
        % --------------------------------- %
        % --- CONTROL VERSION FUNCTIONS --- %
        % --------------------------------- %        
        
        % --- removes the git environment variable
        function gitEnvVarFunc(vN)
            
            % case is removing an environment variable
            cmdStr = sprintf('reg delete "HKCU\\Environment" /v %s /f',vN);
            setenv(vN,'');
            
            % runs the string from the command line
            [~,~] = system(cmdStr);
            
        end                 
      
        % ----------------------------------------------- %
        % --- PROGRAM DIRECTORY/FILE UPDATE FUNCTIONS --- %
        % ----------------------------------------------- %
                
        % --- sets up the java directory path
        function jDirP = setupJavaDirPath(cDir,jDirS)
            
            jDirP = fullfile(cDir,strjoin(jDirS,filesep));
            
        end                        
   
        % --- creates the data directories (if not already created)
        function strComb = createDataDir(strData,dataDir)
            
            % initialises the output data struct
            strNw = struct('fldData',strData);
            
            % creates the new default directories (if they do not exist)
            b = fieldnames(strData);
            for i = 1:length(b)
                % retrieves the new field information cell array
                nwCell = getStructField(strData,b{i});
                
                % sets the parent directory. create if it doesn't exist
                topDir = fullfile(dataDir,nwCell{1});
                if ~exist(topDir,'dir')
                    mkdir(topDir);
                end
                
                % sets the new directory name and adds to the struct
                nwDir = fullfile(topDir,nwCell{2});
                strNw = setStructField(strNw,b{i},nwDir);
                
                % if the directory does not exist, then create it
                if ~exist(nwDir,'dir')
                    mkdir(nwDir)
                end
            end
            
            % sets the combined struct
            strComb = strNw;
            
        end          
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %                        
        
        % --- sets up the marker properties sub-struct
        function pStr = setMarkProps(pCol,pMark,mSz)
            
            pStr = struct('pCol',pCol,'pMark',pMark,'mSz',mSz);
            
        end        
        
        % --- sets the menu separator field
        function setMenuSeparatorField(hMenu,mSep)
                
            try
                set(hMenu,'Separator',mSep)
            catch
                set(hMenu,'Separator',strcmp(mSep,'on'))
            end                
                
        end              
        
    end
    
end
