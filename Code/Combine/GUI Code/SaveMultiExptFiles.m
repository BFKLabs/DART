classdef SaveMultiExptFiles < handle
    
    % class properties
    properties
        
        % input arguments
        hFigM
        
        % main class objects
        hFig
        objG
        hParent
        
        % compatible grouping panel objects
        hPanelG
        
        % file chooser panel objects
        hPanelF
        jChooserF
        
        % control button panel objects
        hPanelC
        hButC
        
        % fixed dimension fields
        dX = 10;     
        hghtBut = 25;
        hghtRow = 25;
        widPanelR = 470;
        widPanelG = 620;
        hghtPanelF = 310;
        
        % calculated dimension fields
        widFig
        hghtFig
        hghtPanelC
        hghtPanelG
        widButC
        
        % function handle class fields
        postSaveFcn
        
        % other class fields
        iProg
        hGUIInfo
        
        % boolean class fields
        isUpdating = false;
        
        % static class fields
        nButC = 3;
        nExpMin = 7;
        nExpMax = 7;        
        fSzH = 13;
        fSzL = 12;
        fSz = 10 + 2/3;
        
        % static string fields
        tagStr = 'figMultiSave';
        figName = 'Multi-Experiment Solution File Output';
        tStrH = 'Creating Multi-Experimental Solution File';        
        objStr = 'javahandle_withcallbacks.com.sun.java.swing.plaf.windows.WindowsFileChooserUI$7';
        
        % cell array class fields
        fSpec = {{'DART Multi-Experiment Solution File (*.msol)',{'msol'}}};
        wStrH = {'Overall Progress','Current Field Progress',...
                 'Solution File Output'};
        
    end
    
    % class methods
    methods
        
        % --- class constuctor
        function obj = SaveMultiExptFiles(hFigM)
            
            % sets the input arguments
            obj.hFigM = hFigM;
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();            
            
            % clears the output object (if not required)
            if (nargout == 0) && ~isdeployed
                clear obj
            end            
            
        end        
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % sets the 
            setappdata(obj.hFigM,'nRow',obj.nExpMin);
            
            % function handles
            obj.postSaveFcn = getappdata(obj.hFigM,'postSolnSaveFunc');
            
            % field retrieval
            obj.iProg = getappdata(obj.hFigM,'iProg');
            obj.hGUIInfo = getappdata(obj.hFigM,'hGUIInfo');
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %
            
            % panel height calculations
            obj.hghtPanelC = obj.dX + obj.hghtRow;            

            % figure dimension calculations
            obj.widFig = 3*obj.dX + obj.widPanelG + obj.widPanelR;
            obj.hghtFig = 2*obj.dX + obj.hghtPanelG;
            
            % other object dimension calculations
            obj.widButC = (obj.widPanelR - obj.dX)/obj.nButC;
            
        end
        
        % --- initialises the class fields
        function initClassObjects(obj)
            
            % deletes any previous GUIs
            hPrev = findall(0,'tag',obj.tagStr);
            if ~isempty(hPrev); delete(hPrev); end
            
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- %
            
            % creates the figure object
            fPos = [100,100,obj.widFig,100];
            
            % creates the figure object
            obj.hFig = createUIObj('figure','Position',fPos,...
                'tag',obj.tagStr,'MenuBar','None','Toolbar','None',...
                'Name',obj.figName,'Resize','on','NumberTitle','off',...
                'Visible','off','AutoResizeChildren','off',...
                'BusyAction','Cancel','GraphicsSmoothing','off',...
                'DoubleBuffer','off','Renderer','painters','CloseReq',[]);                        
            
            % ------------------------------ %
            % --- MAIN SUB-PANEL OBJECTS --- %
            % ------------------------------ %
            
            % sets up the sub-panel objects
            obj.setupExptCompatibilityPanels();
            obj.setupControlButtonPanel();
            obj.setupFileChooserPanel();
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %            
            
            % opens the class figure
            openClassFigure(obj.hFig);
            
        end
        
        % --- creates the file chooser object
        function createFileChooser(obj)
            
            % file chooser parameters
            defDir = obj.objG.expDir{1};
            defFile = fullfile(defDir,obj.objG.expName{1});
            
            % creates the file chooser object
            obj.jChooserF = setupJavaFileChooser(obj.hPanelF,'fSpec',...
                obj.fSpec,'defDir',defDir,'defFile',defFile,'isSave',true);
            
            % sets the file chooser properties
            obj.jChooserF.setName(obj.objG.expName{1});
            obj.jChooserF.setFileSelectionMode(0)
            obj.jChooserF.PropertyChangeCallback = @obj.chooserPropChange;                        
            
            % retrieves correct object for keyboard callback func
            jPanel = obj.jChooserF.getComponent(2).getComponent(2);
            hFn = handle(jPanel.getComponent(2).getComponent(1),...
                         'CallbackProperties');
            if isa(hFn,obj.objStr)
                % if the object is feasible, set the callback function
                hFn.KeyTypedCallback = @obj.saveFileNameChng;
            end
            
        end
        
        % ------------------------------------ %
        % --- PANEL OBJECT SETUP FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- sets up the experiment compatibility panel objects
        function setupExptCompatibilityPanels(obj)
        
            % creates the panel object
            pPos = [obj.dX*[1,1],obj.widPanelG,100];
            obj.hPanelG = createPanelObject(obj.hFig,pPos);
            obj.hPanelG.Tag = 'panelExptGroup';
            
            % creates the experiment group objects
            obj.objG = OpenSolnFiles(obj.hFigM,2);
        
            % resets the figure dimensions
            hPosG = sum(obj.objG.objT.hPanelG.Position([2,4]));
            obj.hPanelG.Position(4) = hPosG + obj.dX;
            obj.hFig.Position(4) = obj.hPanelG.Position(4) + 2*obj.dX;
            
            % resets the other panel dimensions
            obj.hghtFig = obj.hFig.Position(4);
            obj.hghtPanelG = obj.hPanelG.Position(4);
            obj.hghtPanelF = obj.hghtPanelG - (obj.dX + obj.hghtPanelC);

            % resets the checkbox values
            hChk = obj.objG.objT.hChkGC;
            uD = cellfun(@(x)(get(x,'UserData')),hChk,'un',0);
            cellfun(@(h,i)(set(h,'Value',obj.objG.cObj.iSel(i))),hChk,uD)            
            cellfun(@(x)(setObjEnable(x,0)),hChk([1,3]));
            
        end
        
        % --- sets up the control button panel objects
        function setupControlButtonPanel(obj)
            
            % initialisations
            pStr = {'Refresh File Explorer',...
                    'Create Multi-Expt File','Close Window'};
            cbFcnB = {@obj.buttonRefreshExplorer;@obj.buttonSaveFile;...
                      @obj.buttonCloseWindow};        
                  
            % creates the panel object
            xPos = sum(obj.hPanelG.Position([1,3])) + obj.dX;
            pPos = [xPos,obj.dX,obj.widPanelR,obj.hghtPanelC];
            obj.hPanelC = createPanelObject(obj.hFig,pPos);
            
            % creates the button objects
            obj.hButC = createObjectRow(obj.hPanelC,obj.nButC,...
                'pushbutton',obj.widButC,'xOfs',obj.dX/2,'dxOfs',0,...
                'yOfs',obj.dX/2,'pStr',pStr);
            cellfun(@(x,y)(set(x,'Callback',y)),obj.hButC,cbFcnB);
            
        end
        
        % --- sets up the file chooser panel objects
        function setupFileChooserPanel(obj)
        
            % creates the panel object
            xPos = sum(obj.hPanelG.Position([1,3])) + obj.dX;
            yPos = sum(obj.hPanelC.Position([2,4])) + obj.dX;
            pPos = [xPos,yPos,obj.widPanelR,obj.hghtPanelF];
            obj.hPanelF = createPanelObject(obj.hFig,pPos);
            
            % creates the file chooser object
            obj.createFileChooser();
            
        end            

        % ------------------------------ %
        % --- FILE CHOOSER FUNCTIONS --- %
        % ------------------------------ %        
        
        % --- file chooser property change callback function
        function chooserPropChange(obj, ~, evnt)
            
            % if updating elsewhere, then exit the function
            if obj.isUpdating
                return
            end
            
            % field retrieval            
            objChng = evnt.getNewValue;
            iTabG = obj.getCurrentTab();            
            
            switch get(evnt,'PropertyName')
                case 'directoryChanged'
                    % case is the folder change
                    
                    % retrieves the new file path
                    obj.objG.expDir{iTabG} = char(objChng.getPath);
                    
                case 'SelectedFileChangedProperty'
                    % case is the directory has been created
                    nwVal = char(removeFileExtn(char(get(evnt,'NewValue'))));
                    prVal = char(removeFileExtn(char(get(evnt,'OldValue'))));
                    
                    % case is a file was selected
                    if ~isempty(nwVal)
                        % determines if the new/old values differ
                        if ~strcmp(prVal,nwVal)
                            % updates the new file/directory names
                            [expD,expN] = fileparts(nwVal);
                            obj.objG.expDir{iTabG} = expD;
                            obj.objG.expName{iTabG} = expN;
                            
                            % updates the explorer tree name and the table
                            obj.resetChooserFile();
                            
                        else
                            % updates the file name string
                            hFn = getFileNameObject(obj.jChooserF);
                            [~,fName,~] = fileparts(char(nwVal));
                            
                            % updates the textbox string
                            obj.isUpdating = true;
                            hFn.setText(getFileName(fName));
                            obj.isUpdating = false;
                        end
                    end
            end
            
        end
        
        % --- updates when the file name is changed
        function saveFileNameChng(obj, hObj, ~)
            
            % if updating elsewhere, then exit the function
            if obj.isUpdating
                return
            end
            
            % updates the experiment file name field
            iTabG = obj.getCurrentTab();
            obj.objG.expName{iTabG} = char(get(hObj,'Text'));
                    
            % enables the create button enabled properties (disable if no file name)
            setObjEnable(obj.hButC{2},~isempty(obj.objG.expName{iTabG}))
            
        end  
        
        % --- resets the file chooser 
        function resetChooserFile(obj,iTabG)
            
            % if there is no file chooser, then exit
            if isempty(obj.jChooserF); return; end
            
            % sets the default input arguments
            if ~exist('forceUpdate','var'); forceUpdate = false; end            
            if ~exist('iTabG','var')
                iTabG = obj.getCurrentTab();
            end
            
            % initialisations
            expDir = obj.objG.expDir{iTabG}; 
            expName = obj.objG.expName{iTabG}; 
            
            % retrieves the current file name and the new file name  
            fFileS = char(obj.jChooserF.getSelectedFile());
            fFileNw = fullfile(expDir,expName);  
            
            % if the new and selected files are not the same then update
            if ~strcmp(fFileS,fFileNw) || forceUpdate
                % flag that the object is updating indirectly
                obj.isUpdating = true;
                
                % resets the selected file
                obj.jChooserF.setSelectedFile(java.io.File(fFileNw));
                obj.jChooserF.repaint();
                
                % updates the file name string
                hFn = getFileNameObject(obj.jChooserF);
                hFn.setText(getFileName(fFileNw));
                pause(0.05);
                
                % resets the update flag
                obj.isUpdating = false;
            end
            
        end        
        
        % --------------------------------------- %
        % --- OTHER OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- refresh explorer button callback function
        function buttonRefreshExplorer(obj, ~, ~)
            
            % rescans the current file explorer directory
            obj.jChooserF.rescanCurrentDirectory()           
            
        end
        
        % --- save file button callback function
        function buttonSaveFile(obj, ~, ~)
            
            % field retrieval
            iTabG = obj.getCurrentTab();
            [expDir,expName] = deal(obj.objG.expDir,obj.objG.expName);
            
            % sets the full multi-experiment solution file path
            expFile = fullfile(expDir{iTabG},[expName{iTabG},'.msol']);
            if exist(expFile,'file')
                % prompt the user to overwrite any existing files
                tStr = 'Overwrite Solution Files?';
                qStr = sprintf(['The multi-experiment file with this ',...
                    'name already exists.\nDo you want to overwrite ',...
                    'the file?']);
                uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
                if ~strcmp(uChoice,'Yes')
                    % if the user cancelled, then quit the function
                    return
                end
            end
            
            % --------------------------------------- %
            % --- EXPERIMENT SOLUTION FILE OUTPUT --- %
            % --------------------------------------- %
            
            % creates the waitbar figure
            hProg = ProgBar(obj.wStrH,obj.tStrH);  
            
            % field retrieval
            sInfo0 = obj.objG.sInfo;
            gName0 = obj.objG.gName;
            gNameU0 = obj.objG.gNameU;
            tmpDir = obj.iProg.TempFile;
            tmpFile = fullfile(tmpDir,'Temp.tar');  
            
            % determines the currently selected experiment
            iTabG = obj.getCurrentTab();              
            indG = obj.objG.cObj.detCompatibleExpts();
            
            % reduces stimuli inforation/group names for specified grouping
            iS = indG{iTabG};
            grpName = gNameU0{iTabG};
            [sInfo,gName] = deal(sInfo0(iS),gName0(iS));
            fName = cellfun(@(x)(x.expFile),sInfo,'un',0);            
            
            % memory allocation
            nFile = length(fName);
            tarFiles = cell(nFile,1);     
            
            % removes any group names that are not linked to any experiment
            hasG = cellfun(@(x)(any(cellfun(@(y)(any(strcmp(y,x))),gName))),grpName);
            grpName = grpName(hasG);
            
            % loops through all the variable strings loading the data from the
            % individual experiment solution files, and adding it to the
            % multi-experiment solution file
            for i = 1:nFile
                % updates the waitbar figure
                fNameNw = simpFileName(fName{i},15);
                wStr1 = sprintf('Appending "%s" (%i of %i)',fNameNw,i,nFile);
                if hProg.Update(1,wStr1,i/nFile)
                    % if the user cancelled, delete the solution files and exits
                    cellfun(@delete,tarFiles(1:(i-1)))
                    return
                elseif i > 1
                    % otherwise, clear the lower waitbars (for files > 1)
                    hProg.Update(2,obj.wStrH{2},0);
                    hProg.Update(3,obj.wStrH{3},0);
                end
                
                % ---------------------------------- %
                % --- SOLUTION DATA STRUCT SETUP --- %
                % ---------------------------------- %
                
                % sets the experiment solution data struct
                snTot = sInfo{i}.snTot;
                
                % sets the group to overall group linking indices
                ok = snTot.iMov.ok;
                gName{i}(~ok) = {''};
                indL = cellfun(@(y)(find(strcmp(gName{i},y))),grpName,'un',0);
                
                % reduces the arrays to remove any missing arrays
                if detMltTrkStatus(snTot.iMov)
                    snTot = reduceMultiTrackExptSolnFiles(snTot,indL,grpName);
                else
                    snTot = reduceExptSolnFiles(snTot,indL,grpName);
                end
                
                % ---------------------------------- %
                % --- TEMPORARY DATA FILE OUTPUT --- %
                % ---------------------------------- %
                
                % outputs the single combined solution file
                tarFiles{i} = fullfile(tmpDir,[fName{i},'.ssol']);
                if ~saveExptSolnFile(tmpDir,tarFiles{i},snTot,hProg)
                    % otherwise, delete the solution files and exits
                    cellfun(@delete,tarFiles(1:(i-1)))
                    return
                end
                
                % updates the waitbar figure
                hProg.Update(2,'Solution File Update Complete!',1);
            end
            
            % creates and renames the tar file to a solution file extension
            tar(tmpFile,tarFiles)
            movefile(tmpFile,expFile,'f');
            cellfun(@delete,tarFiles)
            
            % deletes the progressbar
            hProg.closeProgBar()
            
            % resets the experiment table background colours
            obj.buttonRefreshExplorer([], []);
            
        end
        
        % --- close window button callback function
        function buttonCloseWindow(obj, ~, ~)
            
            if obj.objG.isChange
                % prompts the user if they want to update any changes
                tStr = 'Update Changes?';
                qStr = 'Do you want to update the changes you have made?';
                uChoice = questdlg(qStr,tStr,'Yes','No','Cancel','Yes');
    
                switch uChoice
                    case 'Yes'
                        % case is the user chose to update
                        sInfo = obj.objG.sInfo;
                        gName = obj.objG.gName;                        
                        
                        % resets the group names into the solution data structs
                        for i = 1:length(sInfo)
                            sInfo{i}.gName = gName{i};
                        end
                        
                        % updates the solution information into the main gui
                        setappdata(obj.hFigM,'sInfo',sInfo);
                        obj.postSaveFcn(obj.hFigM,1);
                        
                    case 'Cancel'
                        % case is the user cancelled
                        return
                end
            end
            
            % closes the GUI
            setObjVisibility(obj.hGUIInfo.hFig,'on')
            setObjVisibility(obj.hFigM,'on')
            
            % deletes the class object
            obj.deleteClass();      
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- retrieves the currently selected group tab
        function iTabG = getCurrentTab(obj)
            
            iTabG = obj.objG.objT.getCurrentTab();
            
        end
        
        % --- deletes the class object
        function deleteClass(obj)
            
            % deletes the figure object
            delete(obj.hFig);
            
            % deletes and clears the class object
            delete(obj)            
            clear obj
            
        end
        
    end    
    
end