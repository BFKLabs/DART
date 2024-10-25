classdef CreateDARTExe < handle
    
    % class properties
    properties
       
        % input class fields
        hFigM
        
        % object handle fields
        hFig
        hPanelT
        hPanelF
        hPanelP
        hPanelC
        
        % analysis function panel objects
        hTableF
        hLblF
        hTxtF
        hButF
        
        % external package panel objects
        hTableP
        hLblP
        hTxtP
        hButP
        
        % executable type panel objects        
        hEditT
        hButT
        hRadioT
        
        % control button panel objects
        hButC
        
        % fixed object dimension fields
        dX = 10;        
        hghtBut = 25;
        hghtTxt = 16;
        hghtEdit = 22;
        hghtRow = 20;
        hghtRadio = 20;
        widFig = 410;
        widLbl = 175;
        widTxt = 25;
        hghtPanelC = 40;        
        widRatioT = [140,210];
        
        % calculated object dimension fields
        hghtFig
        hghtPanelF
        hghtPanelP
        hghtPanelT        
        widPanel
        widTable
        widEditT        
        widButC
        widButAdd
        hghtTableF
        hghtTableP
        
        % main directory/field fields
        exDir
        mainDir
        mainFile
        
        % output file class fields
        fDirB
        fDir        
        fName
        pDirB
        pDir
        pName        
        outDir
        
        % executable file/string fields
        pFile
        pkgFile
        rmvFile        
        toolStr
        warnStr
        
        % other executable creation object fields
        tObj
        hLoad
        hTimer
        
        % boolean class fields
        isConsoleApp = true;
        
        % other scalar fields
        H0T
        HWT        
        nButC
        nRadioT
        
        % static scalar fields
        nRowP = 4;
        nRowF = 10;
        fSzB = 16;        
        fSzH = 13;
        fSzL = 12;
        fSz = 10 + 2/3;
        
        % static character fields
        tagStr = 'figCreateExe';
        tagStrT = 'hTimerExe';
        figName = 'DART Executable Setup';        
        hdrStrP = 'EXTERNAL PACKAGES';
        hdrStrF = 'ANALYSIS FUNCTIONS';
        hdrStrT = 'EXECUTABLE INFORMATION';        
        fStr = {'Func','Name','Type','fType'};
        igDir = {'.','..','External Apps','Git'};
        bStrC = {'Create Executable','Close Window'};
        exeType = {'Console Application','Windows Standalone Application'};
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = CreateDARTExe(hFigM)
            
            % sets the input arguments
            obj.hFigM = hFigM;
            
            % initialises the class fields and objects
            obj.initClassFields();
            obj.initClassObjects();
            
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %        
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % global variables
            global H0T HWT
            
            % sets the object visibility
            setObjVisibility(obj.hFigM,0);
            
            % sets the java table height dimensions
            hghtHdr = 25 + 2*obj.dX;
            [obj.H0T,obj.HWT] = deal(H0T,HWT);
            
            % sets the default output directory
            mObj = getappdata(obj.hFigM,'mObj');
            [obj.outDir,obj.mainDir] = deal(mObj.mainDir);
            obj.fDirB = mObj.progDef.Analysis.DirFunc;
            obj.pDirB = getProgFileName('Code','External Apps');
            
            % other file name setup            
            obj.exDir = fullfile(obj.mainDir,'Executable');             
            obj.mainFile = fullfile(obj.mainDir,'DART.m');           
            obj.pFile = getParaFileName('AnalysisFunc.mat');            
            obj.pkgFile = fullfile(obj.mainDir,'ExternalPackages.mat');
            
            % array dimensioning
            obj.nButC = length(obj.bStrC);
            obj.nRadioT = length(obj.exeType);

            % --- TIMER OBJECT SETUP --- %
            % -------------------------- %
            
            % deletes any previous timer objects
            hTimerPr = timerfindall('tag',obj.tagStrT);
            if ~isempty(hTimerPr)
                stop(hTimerPr);
                delete(hTimerPr);
            end

            % creates and starts the timer object           
            obj.hTimer = timer('Period',1,'ExecutionMode','fixedRate',...
                             'BusyMode','queue','Tag',obj.tagStrT);            
                         
            % ------------------------------------- %
            % --- EXECUTABLE STRING FIELD SETUP --- %
            % ------------------------------------- %            
            
            % sets up the toolbox string
            spkgStr = obj.getSupportPackageDir();
            toolStr0 = ['-N -p daq -p imaq -p images -p signal ',...
                        '-p instrument -p optim -p stats -p nnet ',...
                        '-p curvefit -p shared -p wavelet -p vision'];
            obj.toolStr = sprintf('%s %s',toolStr0,spkgStr);            
            
            % warning string
            obj.warnStr = '-w disable:all_warnings';              
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %
            
            % pre-calculations
            wOfs = (obj.widLbl + obj.widTxt + 2*obj.dX);
            
            % calculated object dimension fields
            obj.widPanel = obj.widFig - 2*obj.dX;
            obj.widTable = obj.widPanel - 2*obj.dX;
            
            % object dimension calculations
            obj.widButAdd = obj.widPanel - wOfs;
            obj.widButC = (obj.widPanel - 2*obj.dX)/obj.nButC;
            obj.widEditT = obj.widPanel - (obj.hghtBut + 2.5*obj.dX);
            
            % calculates the table heights
            obj.hghtTableF = obj.H0T + obj.nRowF*obj.HWT;
            obj.hghtTableP = obj.H0T + obj.nRowP*obj.HWT;            
            
            % calculates the panel heights
            obj.hghtPanelF = obj.hghtTableF + hghtHdr + obj.hghtRow;
            obj.hghtPanelP = obj.hghtTableP + hghtHdr + obj.hghtRow;
            obj.hghtPanelT = obj.hghtRow + 2*obj.dX + hghtHdr;
            
            % calculates the figure dimensions
            obj.hghtFig = obj.hghtPanelC + obj.hghtPanelP + ...
                obj.hghtPanelF + obj.hghtPanelT + 5*obj.dX;
            
        end
        
        % --- initialises the class object
        function initClassObjects(obj)
            
            % deletes any previous GUIs
            hPrev = findall(0,'tag',obj.tagStr);
            if ~isempty(hPrev); delete(hPrev); end

            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- %
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % creates the figure object
            obj.hFig = createUIObj('figure','Position',fPos,...
                'tag',obj.tagStr,'MenuBar','None','Toolbar','None',...
                'Name',obj.figName,'Resize','off','NumberTitle','off',...
                'Visible','off','CloseRequestFcn',@obj.closeWindow);

            % -------------------------- %            
            % --- MAIN PANEL OBJECTS --- %
            % -------------------------- %
            
            % control button panel
            pPosC = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = createUIObj('panel',obj.hFig,...
                'Title','','Position',pPosC);

            % external package panel
            yPosP = sum(pPosC([2,4])) + obj.dX;
            pPosP = [obj.dX,yPosP,obj.widPanel,obj.hghtPanelP];
            obj.hPanelP = createUIObj('panel',obj.hFig,...
                'FontSize',obj.fSzH,'FontWeight','Bold',...
                'Title',obj.hdrStrP,'Position',pPosP);
            
            % added function panel
            yPosF = sum(pPosP([2,4])) + obj.dX;
            pPosF = [obj.dX,yPosF,obj.widPanel,obj.hghtPanelF];
            obj.hPanelF = createUIObj('panel',obj.hFig,...
                'FontSize',obj.fSzH,'FontWeight','Bold',...
                'Title',obj.hdrStrF,'Position',pPosF);                        
            
            % executable information panel
            yPosT = sum(pPosF([2,4])) + obj.dX;
            pPosT = [obj.dX,yPosT,obj.widPanel,obj.hghtPanelT];
            obj.hPanelT = createUIObj('buttongroup',obj.hFig,...
                'FontSize',obj.fSzH,'FontWeight','Bold',...
                'Title',obj.hdrStrT,'Position',pPosT,...
                'SelectionChangedFcn',@obj.radioInfoChange);
            
            % ---------------------------- %
            % --- CONTROL BUTTON PANEL --- %
            % ---------------------------- %
            
            % initialisations
            obj.hButC = cell(1,obj.nButC);
            cbFcnC = {@obj.compileExe,@obj.closeWindow};
            
            % creates the button objects
            for i = 1:obj.nButC                
                % creates the button objects
                lPosC = obj.dX + (i-1)*obj.widButC;
                pPosD = [lPosC,obj.dX-2,obj.widButC,obj.hghtBut];
                obj.hButC{i} = createUIObj('pushbutton',obj.hPanelC,...
                    'FontSize',obj.fSzL,'FontWeight','Bold',...
                    'Position',pPosD,'Text',obj.bStrC{i},...
                    'ButtonPushedFcn',cbFcnC{i},'Enable','on');
            end
            
            % ------------------------------- %
            % --- ANALYSIS FUNCTION PANEL --- %
            % ------------------------------- %
            
            % initialisations
            cWidF = {283,65};
            cEditF = [false,true];
            cFormF = {'char','logical'};
            cHdrF = {'Function Name','Include?'};            
            tLblF = 'Number of Added Functions: ';
            cbFcnTF = @obj.tableFunctionEdit;

            % button object initialisations
            bStrF = 'Add Function';
            cbFcnPF = @obj.addFunction;            
            
            % sets up the table data
            tDataF = obj.setupFuncTableData();            
            tTxtF = num2str(size(tDataF,1));
            
            % creates the table object
            pPosFT = [obj.dX*[1,1],obj.widTable,obj.hghtTableF];
            obj.hTableF = createUIObj('table',obj.hPanelF,...
                'Data',tDataF,'ColumnEditable',cEditF,'RowName',[],...
                'ColumnName',cHdrF,'Position',pPosFT,'FontSize',obj.fSz,...
                'ColumnFormat',cFormF,'ColumnWidth',cWidF,...
                'BackgroundColor',ones(1,3),'CellEditCallback',cbFcnTF);
            
            % creates the text label pair
            yPosFL = sum(pPosFT([2,4])) + obj.dX;
            obj.hTxtF = obj.createTextPair(obj.hPanelF,yPosFL,tLblF,tTxtF);

            % creates the button object
            lPosFB = sum(obj.hTxtF.Position([1,3]));
            pPosFB = [lPosFB,yPosFL-3,obj.widButAdd,obj.hghtBut];
            obj.hButP = createUIObj('pushbutton',obj.hPanelF,...
                'Position',pPosFB,'FontSize',obj.fSzL,'String',bStrF,...
                'FontWeight','Bold','Callback',cbFcnPF);            
            
            % ------------------------------ %
            % --- EXTERNAL PACKAGE PANEL --- %
            % ------------------------------ %
                        
            % initialisations
            cWidP = {283,65};
            cEditP = [false,true];
            cFormP = {'char','logical'};
            cHdrP = {'Function Name','Include?'}; 
            tLblP = 'Number of Added Packages: ';
            cbFcnTP = @obj.tablePackageEdit;            

            % button object initialisations
            bStrP = 'Add Package';
            cbFcnPB = @obj.addPackage;
            
            % sets up the table data
            tDataP = obj.setupPackageTableData;
            tTxtP = '0';
            
            % creates the table object
            pPosPT = [obj.dX*[1,1],obj.widTable,obj.hghtTableP];
            obj.hTableP = createUIObj('table',obj.hPanelP,...
                'Data',tDataP,'ColumnEditable',cEditP,...
                'ColumnName',cHdrP,'Position',pPosPT,'FontSize',obj.fSz,...
                'ColumnFormat',cFormP,'RowName',[],'ColumnWidth',cWidP,...
                'BackgroundColor',ones(1,3),'CellEditCallback',cbFcnTP);
            
            % creates the text label pair
            yPosPL = sum(pPosPT([2,4])) + obj.dX;
            obj.hTxtP = obj.createTextPair(obj.hPanelP,yPosPL,tLblP,tTxtP);

            % creates the button object
            lPosPB = sum(obj.hTxtP.Position([1,3]));
            pPosPB = [lPosPB,yPosPL-3,obj.widButAdd,obj.hghtBut];
            obj.hButP = createUIObj('pushbutton',obj.hPanelP,...
                'Position',pPosPB,'FontSize',obj.fSzL,...
                'FontWeight','Bold','String',bStrP,'Callback',cbFcnPB);
            
            % ----------------------------- %
            % --- EXECUTABLE INFO PANEL --- %
            % ----------------------------- %                        
            
            % initialisations
            cbFcnT = @obj.setDefDir;            
            tStrE = sprintf('  %s',obj.outDir);
            
            % creates the radio button objects
            obj.hRadioT = cell(1,obj.nRadioT);
            for i = 1:obj.nRadioT
                lPosTR = (1/2+i)*obj.dX + sum(obj.widRatioT(1:(i-1)));
                pPosTR = [lPosTR,obj.dX,obj.widRatioT(i),obj.hghtRadio];
                obj.hRadioT{i} = createUIObj('radiobutton',obj.hPanelT,...
                    'Position',pPosTR,'FontSize',obj.fSzL,...
                    'FontWeight','Bold','String',obj.exeType{i});
            end            
            
            % ensures the console application radio button is set
            obj.hRadioT{1}.Value = 1;
            
            % creates the editbox object
            yPosT0 = 3.5*obj.dX;
            pPosTE = [obj.dX,yPosT0,obj.widEditT,obj.hghtEdit];
            obj.hEditT = createUIObj('edit',obj.hPanelT,...
                'Position',pPosTE,'FontSize',obj.fSz,...
                'HorizontalAlignment','Left','String',tStrE,...
                'Enable','Inactive');
            
            % creates the button object
            lPosTB = sum(pPosTE([1,3])) + obj.dX/2;
            pPosTB = [lPosTB,yPosT0-1,obj.hghtBut*[1,1]];
            obj.hButT = createUIObj('pushbutton',obj.hPanelT,...
                'Position',pPosTB,'FontSize',obj.fSzB,...
                'FontWeight','Bold','String','...','Callback',cbFcnT);
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % resizes the column tables
            autoResizeTableColumns(obj.hTableF);
            autoResizeTableColumns(obj.hTableP);
            
            % centers the figure and makes it visible
            centerfig(obj.hFig);
            refresh(obj.hFig);
            pause(0.05);           
            
            % sets the object visibility
            setObjVisibility(obj.hFig,1);
            
        end
        
        % --- sets up the function table data
        function tDataF = setupFuncTableData(obj)
        
            % retrieves the function name
            dInfoF = dir(fullfile(obj.fDirB,'*.m'));
            fDir0 = field2cell(dInfoF,'folder');            
            fName0 = field2cell(dInfoF,'name');
            
            % determines the valid functions
            isOK = obj.checkFcnValidity(fDir0,fName0);
            obj.fDir = fDir0(isOK);
            obj.fName = fName0(isOK);
            
            % sets up the table data
            nFcn = size(obj.fName,1);
            tDataF = [obj.fName,num2cell(true(nFcn,1))];
            
        end        
        
        % --- sets up the external package table data
        function tDataP = setupPackageTableData(obj)
        
            if exist(obj.pDirB,'dir')
                % if it exists, then search the package directory 
                dInfoP = dir(obj.pDirB);
                pName0 = field2cell(dInfoP,'name');
                pDir0 = field2cell(dInfoP,'folder');
                
                % determines the valid package directories
                isOK = obj.checkPkgValidity(pName0);
                if any(isOK)
                    % sets the package names (if feasible)
                    obj.pDir = pDir0(isOK);                    
                    obj.pName = pName0(isOK);
                    tDataP = [obj.pName,num2cell(false(sum(isOK),1))];
                    
                else
                    % otherwise, return an empty table array
                    tDataP = [];
                end
                
            else
                % otherwise, return an empty array
                tDataP = [];
            end
            
        end        
            
        % ----------------------------------------- %
        % --- CONTROL BUTTON CALLBACK FUNCTIONS --- %
        % ----------------------------------------- %
        
        % --- create executable callback function
        function compileExe(obj, ~, ~)
            
            % clears the screen
            clc
            obj.tObj = tic;
            
            % changes directory to the main program directory
            cd(obj.mainDir);
            
            % determines the selected function/packages
            isSelP = cell2mat(obj.hTableP.Data(:,2));
            isSelF = cell2mat(obj.hTableF.Data(:,2));
            
            % makes the main window invisible
            setObjVisibility(obj.hFig,0);
            pause(0.05);
            
            % creates the loadbar object
            lStr = 'Creating DART Program Executable...';
            obj.hLoad = ProgressLoadbar(lStr);
            set(obj.hLoad.Control,'CloseRequestFcn',[]);
            
            % ---------------------------------- %
            % --- EXECUTABLE DIRECTORY SETUP --- %
            % ---------------------------------- %
            
            % sets the executable temporary file output directory. if it 
            % does not exist, then create the directory
            if ~exist(obj.exDir,'dir')
                mkdir(obj.exDir)
            end
            
            % deletes all previous files in the executable directory
            [isdir,name] = field2cell(dir(obj.exDir),{'isdir','name'});                        
            cellfun(@(x)(...
                delete(fullfile(obj.exDir,x))),name(~cell2mat(isdir)))
            
            % ------------------------------- %
            % --- ANALYSIS FUNCTION SETUP --- %
            % ------------------------------- %
            
            % retrieves the selected analysis functions
            fcnDir = obj.fDir(isSelF);
            fcnName = obj.fName(isSelF);
            
            % determines which are the non-default analysis functions
            isDef = strcmp(obj.fDir,obj.fDirB);
            if any(isDef)
                % if there are any non-default functions, then copy the
                % files to the analysis function directory
                cpyFile = cellfun(@(x,y)(fullfile(x,y)),...
                    fcnDir(~isDef),fcnName(~isDef),'un',0);
                obj.rmvFile = cellfun(@(x)(...
                    fullfile(obj.fDirB,x)),fcnName(~isDef),'un',0);
                
                % copies the files to the analysis function directory
                cellfun(@(x)(copyfile(x,obj.fDirB,'f')),cpyFile)     
                
            else
                % case is there are no default functions
                obj.rmvFile = [];
            end
            
            % retrieves the computer hostname
            [~, hName] = system('hostname');
            
            % retrieves the analysis function file sizes
            fFile = cellfun(@(x,y)(fullfile(x,y)),fcnDir,fcnName,'un',0); 
            A = cell2mat(cellfun(@(x)(dir(x)),fFile,'un',0));
            fSize = field2cell(A,'bytes',1);     
            
            % set the analysis function file name
            if exist(obj.pFile,'file')
                % if the file already exists, then rename it
                pFileT = getParaFileName('AnalysisFuncTemp.mat');
                copyfile(obj.pFile,pFileT);
            else
                % otherwise, set an empty temporary file name
                pFileT = '';
            end
            
            % saves the analysis function file
            [fDir,fName] = deal(fcnDir,fcnName);
            save(obj.pFile,'fDir','fName','fSize','hName');
            
            % ------------------------------ %
            % --- EXTERNAL PACKAGE SETUP --- %
            % ------------------------------ %            
            
            % retrieves the selected external packages
            pkgName = cellfun(@(x,y)(...
                fullfile(x,y)),obj.pDir(isSelP),obj.pName(isSelP),'un',0);
            
            % saves the package file
            save(obj.pkgFile,'pkgName');   
            
            % ------------------------------- %
            % --- EXECUTABLE STRING SETUP --- %
            % ------------------------------- %
            
            % sets the executable output string
            if obj.isConsoleApp
                % case is a console application (creates window)
                outStr = '-C -o DART -m';
                
            else
                % case is windows standalone application (no window)
                outStr = '-o DART -W WinMain:ImageStack -T link:exe';
            end
            
            % sets up the support package string
            srcStr = sprintf('-d ''%s''',obj.exDir);            
            
            % determines files the directories that need to be added
            cDirAll = dir(fullfile(obj.mainDir,'Code'));
            cDir = cell(length(cDirAll),1);
            for i = 1:length(cDir)
                if cDirAll(i).isdir && ...
                        ~any(strcmp(obj.igDir,cDirAll(i).name))
                    cDir{i} = fullfile(obj.mainDir,'Code',cDirAll(i).name);
                end
            end
            
            % sets the final code directory array
            cDir = [rmvEmptyCells(cDir);pkgName(:)];
            jFiles = {which('ColoredFieldCellRenderer.zip')};
            
            % sets up the main file, analysis function directory and other 
            % important file directories add string
            fStrAll = [cDir(:);jFiles(:);{'Para Files'}];
            addStr = sprintf('-v ''%s'' -a ''%s''',obj.mainFile,obj.fDirB);            
            for i = 1:length(fStrAll)
                addStr = sprintf('%s -a ''%s''',addStr,fStrAll{i});
            end     
            
            % --------------------------- %
            % --- EXECUTABLE CREATION --- %
            % --------------------------- %  
            
            % sets up the timer object fields
            set(obj.hTimer,'TimerFcn',{@obj.exeTimerFunc,pFileT});
            start(obj.hTimer);
            
            % runs the compiler to create the executable
            try
                eval(sprintf('mcc %s %s %s %s %s',...
                    outStr,srcStr,obj.toolStr,obj.warnStr,addStr));
                delete(obj.pkgFile)
                
            catch err
                % deletes any extraneous files
                delete(obj.hLoad);            
                obj.deleteRemoveFiles();
                obj.resetAnalysisParaFile(pFileT);                
                delete(obj.pkgFile)
                
                % stops the timer object
                stop(obj.hTimer);
                
                % makes the main window invisible
                setObjVisibility(obj.hFig,1);
                
                % outputs the error to screen
                waitfor(errordlg('Error while creating executable'))
                rethrow(err);                
            end
                
        end
        
        % --- create executable callback function
        function closeWindow(obj, ~, ~)
            
            % deletes the figure
            delete(obj.hFig);
            
            % makes the main figure visible again
            setObjVisibility(obj.hFigM,1);
            
        end
        
        % --------------------------------------- %
        % --- OTHER OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------------- %        

        % --- external package table cell edit callback function
        function tablePackageEdit(obj, hTable, ~)
            
            nFcnSel = sum(cell2mat(hTable.Data(:,2)));
            obj.hTxtP.String = num2str(nFcnSel);
            
        end
        
        % --- analysis function table cell edit callback function
        function tableFunctionEdit(obj, ~, ~)

            nFcnSel = sum(cell2mat(obj.hTableF.Data(:,2)));
            obj.hTxtF.String = num2str(nFcnSel);      
            setObjEnable(obj.hButC{1},nFcnSel > 0);
            
        end
        
        % --- button group radio button change callback function
        function radioInfoChange(obj, ~, evnt)
            
            obj.isConsoleApp = strcmp(evnt.NewValue.String,obj.exeType{1});
            
        end
        
        % --- callback function for the default directory setting buttons
        function setDefDir(obj, ~, ~)
            
            % initialisations
            tStr = 'Set Executable Output Directory';
            
            % prompts the user for the new default directory
            fDirNw = uigetdir(obj.outDir,tStr);
            if fDirNw
                % if successful, then update associated fields/objects
                obj.outDir = fDirNw;
                obj.hEditT.String = sprintf('  %s',fDirNw);
            end
            
        end

        % --- adds a function to the table
        function addFunction(obj, ~, ~)
            
            % initialisations
            fMode = {'*.m','MATLAB M-File (*.m)'};            
            
            % prompts the user to select the function m-files
            [fNameNw,fDirNw,fIndex] = uigetfile(...
                fMode,'Select A File',obj.mainDir,'MultiSelect','on');
            if ~fIndex
                % if the user cancelled, then exit
                return
            end
            
            % ensures the file name is stored in a cell array
            if ~iscell(fNameNw); fNameNw = {fNameNw}; end            
            fDirNw = repmat({fDirNw},size(fNameNw));
            
            % determines the unique file names
            [fNameNw,iB] = setdiff(fNameNw,obj.fName);
            if isempty(iB)
                % if there is no new files, then exit
                return
                
            else
                % otherwise, set the unique file names
                fDirNw = fDirNw(iB);
            end
            
            % determines which functions are valid
            isOK = obj.checkFcnValidity(fDirNw,fNameNw);
            if any(isOK)
                % if any are valid, then add them to the table
                AFcnNw = true(sum(isOK),1);
                tDataFNw = [arr2vec(fNameNw(isOK)),num2cell(AFcnNw)];
                obj.hTableF.Data = [obj.hTableF.Data;tDataFNw];
                
                % adds the new files to the function directory/name fields
                obj.fDir = [obj.fDir;arr2vec(fDirNw(isOK))];
                obj.fName = [obj.fName;arr2vec(fNameNw(isOK))];
                
                % updates the selection properties
                obj.tableFunctionEdit();
            end
            
        end                
        
        % --- adds a package to the table
        function addPackage(obj, ~, ~)

            % initialisations
            tStr = 'Select External Package Directory';
            
            % prompts the user for the new default directory
            pDirNw = uigetdir(obj.outDir,tStr);            
            if isempty(pDirNw)
                % if the user cancelled, then exit
                return
            end
            
            % converts the file/directory fields to cell arrays
            pNameNw = {getFileName(pDirNw)};
            pDirNw = {fileparts(pDirNw)};
            
            % determines the unique file names
            [pNameNw,iB] = setdiff(pNameNw,obj.pName);
            if isempty(iB)
                % if there is no new files, then exit
                return
                
            else
                % otherwise, set the unique file names
                pDirNw = pDirNw(iB);
            end
            
            % determines the valid package directories            
            if obj.checkPkgValidity(pNameNw)
                % appends the new package to the table
                tDataPNw = [pNameNw,{false}];
                obj.hTableP.Data = [obj.hTableP.Data;tDataPNw];
                
                % adds the new files to the package directory/name fields
                obj.pDir = [obj.pDir;pDirNw];
                obj.pName = [obj.pName;pNameNw];                
            end
            
        end        
        
        % ---------------------------------------- %        
        % --- EXECUTABLE COMPILATION FUNCTIONS --- %
        % ---------------------------------------- %
        
        % --- deletes the files flagged for removal
        function deleteRemoveFiles(obj)

            if ~isempty(obj.rmvFile)
                cellfun(@delete,obj.rmvFile); 
            end

        end        
        
        % --- resets the analysis function parameter file
        function resetAnalysisParaFile(obj,pFileT)
            
            if exist(pFileT,'file')
                copyfile(pFileT,obj.pFile);
                delete(pFileT);
            end
            
        end        
        
        % --- sets the executable timer function
        function exeTimerFunc(obj,~,~,pFileT)
            
            % determines if the executable file has been created
            exeFile = fullfile(obj.exDir,'DART.exe');
            if ~exist(exeFile,'file')
                % if not, then exit the function
                return
                
            elseif obj.isConsoleApp
                % otherwise, set the ctf filename (console app only)
                ctfFile = fullfile(obj.exDir,'DART.ctf');
            end
            
            % stops and delete the timer object
            tElapse = toc(obj.tObj);
            stop(obj.hTimer); 

            % updates the status message
            obj.hLoad.Indeterminate = false;
            obj.hLoad.FractionComplete = 1;
            obj.hLoad.StatusMessage = 'Finished Creating Executable';
            pause(0.2);
                
            % moves the file to the program directory. keep attempting to 
            % move the file until it has successfully been moved
            while true
                try
                    movefile(exeFile,obj.outDir);
                    break
                catch
                    pause(0.1);
                end
            end
                
            % deletes the extraneous files
            obj.deleteRemoveFiles();
            if exist(pFileT,'file'); delete(pFileT); end
               
            % moves the ctf file (console application only)
            if obj.isConsoleApp
                movefile(ctfFile,obj.outDir);            
            end
            
            % stops and deletes the timer object/loadbar figure
            pause(2.0); delete(obj.hLoad); pause(0.2);
            clc            
            
            % makes the main window invisible
            setObjVisibility(obj.hFig,1);            
            fprintf('Executable Compilation Time = %.2fs\n',tElapse);
            
            % creates the executable update zip file
            if obj.isConsoleApp
                zip('ExeUpdate.zip',{'DART.exe','DART.ctf'});
            else
                zip('ExeUpdate.zip',{'DART.exe'});                
            end
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- creates the text/label object pair
        function hTxt = createTextPair(obj,hP,yPos,tLblP,tTxtP)
            
            % creates the label object
            pPosL = [obj.dX/2,yPos,obj.widLbl,obj.hghtTxt];
            createUIObj('text',hP,'String',tLblP,...
                'Position',pPosL,'FontWeight','Bold',...
                'FontSize',obj.fSzL,'HorizontalAlignment','Right');
            
            % creates the text object
            lPosT = sum(pPosL([1,3]));
            pPosT = [lPosT,yPos,obj.widTxt,obj.hghtTxt];
            hTxt = createUIObj('text',hP,'String',tTxtP,...
                'Position',pPosT,'FontWeight','Bold',...
                'FontSize',obj.fSzL,'HorizontalAlignment','Left');
            
        end        
       
        % --- checks the function validity
        function isOK = checkFcnValidity(obj,fDir,fName)
            
            % memory allocation and other initialisations
            nFcn = length(fDir);
            isOK = true(nFcn,1);
            
            % determines if the directories are on the path
            fDirU = unique(fDir);            
            onPath = obj.detOnPathDir(fDirU);
            cellfun(@addpath,fDirU(~onPath));                        
            
            % checks the validity of each function
            for i = 1:length(fName)
                try
                    % runs the function
                    fcn = eval(sprintf('@%s',getFileName(fName{i})));
                    A = feval(fcn);
                    
                    % checks if correct fields are included in data struct
                    fldStr = fieldnames(A);
                    isOK(i) = all(cellfun(@(x)(...
                        any(strcmp(fldStr,x))),obj.fStr));
                    
                catch
                    % error occured, so not a valid function
                    isOK(i) = false;
                end
            end                        
            
            % removes any files that weren't on the path
            cellfun(@rmpath,fDirU(~onPath));
            
        end 
        
    end        
    
    % static class methods
    methods (Static)
        
        % --- determines which folder from fDir is on the path
        function onPath = detOnPathDir(fDir)

            % determines the current folders on the path
            pathCell = regexp(path, pathsep, 'split');
            
            % adds the function paths (if not already added)
            onPath = false(size(fDir));
            for i = 1:length(fDir)
                onPath(i) = any(strcmpi(fDir{i}, pathCell));
            end
            
        end

        % --- checks the package validity
        function isOK = checkPkgValidity(pkgName)
            
            isOK = ~(strContains(pkgName,'.') | ...
                     startsWith(pkgName,'Z - '));
            
        end
        
        % --- determines all the imaq support package directories
        function spkgDir = getSupportPackageDir()
            
            % determines the base support package directory
            mRel = matlabRelease;
            bDir = sprintf(['C:\\ProgramData\\MATLAB\\SupportPackages',...
                '\\%s\\toolbox\\imaq\\supportpackages'],mRel.Release);

            % removes the invalid support package directory strings
            dName = arrayfun(@(x)(x.name),dir(bDir),'un',0);
            dName = dName(~(strcmp(dName,'.') | strcmp(dName,'..')));

            % sets the full support package directories
            if isempty(dName)
                % case is there are no support packages installed
                spkgDir = [];
                
            else
                % otherwise, set the full support package directories
                spkgDir0 = cellfun(@(x)(fullfile(bDir,x)),dName,'un',0);    
                spkgDir = cellfun(@(x)(...
                    sprintf('-a ''%s''',x)),spkgDir0,'un',0);
                spkgDir = strjoin(spkgDir(:)',' ');
            end            
            
        end
        
    end
    
end