classdef SaveFigure < handle
    
    % class properties
    properties
        
        % main class objects
        hFig
        hFigM
        hPanelO
        pltObj
        
        % class menu item objects
        hMenuF
        hMenuE
        hMenuO
        
        % other class fields
        iPara
        fDir
        fDirS
        fExtn
        iDesc
        iSel
        indFcn
        outFile
        sName
        
        % plot type indices
        eInd0
        fInd0
        pInd0
        
        % temporary figure output data fields
        fIndO
        pIndO
        eIndO
        pDataO
        plotDO
        hNodeO
        nFigO
        hProgO
        
        % main figure data structs
        pData
        plotD
        hPara
        sPara
        
        % main figure object/function handles
        hPS
        ppFcn
        exFcn
        selFcn
        chngFcn
        hPopupP
        hPopupE
        
        % figure output directory panel objects
        hPanelF
        hEditF
        hButF
        hChkF
        widEditFD
        widEditFS
        widChkF = 130;
        
        % image type panel objects
        hPanelI
        hPopupI
        widPopupI
        
        % image dimension panel objects
        hPanelD
        hChkD
        hEditD
        widChkD
        widEditD
        widTxtD = 90;
        
        % function explorer panel objects
        objT
        hPanelE
        hTxtE
        hRoot
        hTree
        fTree
        jTree
        widTxtE
        widTxtEL = 180;
        
        % image preview axes panel objects
        hPanelAx
        hAx
        hImg
        
        % main object fixed dimensions
        widFig
        hghtFig = 650;
        widPanelO = 350;
        hghtPanelE
        hghtPanelD
        hghtPanelI
        hghtPanelF
        
        % other object fixed dimensions
        dX = 10;
        dRow = 25;
        dimBut = 25;
        hghtTxt = 16;
        hghtEdit = 22;
        hghtPopup = 23;
        hghtChk = 20;
        
        % calculated object dimensions
        widPanel
        hghtPanel
        widPanelAx
        
        % boolean fields
        isOldVer
        fixAR = true;
        useSP = false;
        isInit = true;
        useFull = false;
        useSubF = false;
        isPaint = false;
        splitSR = false;
        splitMet = false;
        
        % fixed class objects
        tSz = 11;
        fSz = 12;
        hSz = 13;
        imgType
        fRes = '-r100'
        tagStr = 'figSaveFig';
        rootStr = 'FIGURE OUTPUT LIST';
        wStr0 = 'Outputing Figures To File';
        sStr = {'Unchecked','Mixed','Checked'};
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = SaveFigure(hFigM)
            
            % sets the input arguments
            obj.hFigM = hFigM;
            
            % initialises the class fields and updates the plot parameters
            obj.initClassFields();
            obj.updatePlotPara();
            
            % initialises the class objects
            obj.initClassObjects();
            
        end
        
        % --- updates the plot parameters
        function updatePlotPara(obj)
            
            % retrieves the current plot indices
            hGUIM = guidata(obj.hFigM);
            [obj.eInd0,obj.fInd0,obj.pInd0] = getSelectedIndices(hGUIM);
            
            % updates the current plotting data struct parameters
            pDataH = getStructField(getappdata(obj.hPara,'pObj'),'pData');
            obj.pData{obj.pInd0}{obj.fInd0,obj.eInd0} = pDataH;
            setappdata(obj.hFigM,'pData',obj.pData);
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % initialises the parameter struct
            obj.initParaStruct();
            obj.setupImageTypeStrings();
            
            % panel sizes
            obj.widPanel = obj.widPanelO - 2*obj.dX;
            obj.hghtPanel = obj.hghtFig - 2*obj.dX;
            
            % figure output directory objects
            obj.hghtPanelF = 2*obj.dRow + 3.5*obj.dX;
            obj.widEditFD = obj.widPanel - (2.5*obj.dX + obj.dimBut);
            obj.widEditFS = obj.widPanel - (2*obj.dX + obj.widChkF);
            
            % image type objects
            obj.hghtPanelI = obj.dRow + 3*obj.dX;
            obj.widPopupI = obj.widPanel - 2*obj.dX;
            
            % image dimensions objects
            obj.hghtPanelD = obj.dRow + 7*obj.dX;
            obj.widChkD = obj.widPanel - 2*obj.dX;
            obj.widEditD = (obj.widPanel - 2*(obj.dX+obj.widTxtD))/2;
            
            % function explorer objects
            dHghtE = (obj.hghtPanelF + obj.hghtPanelD + obj.hghtPanelI);
            obj.hghtPanelE = obj.hghtPanel - (dHghtE + 3*obj.dX);
            obj.widTxtE = obj.widPanel - (2*obj.dX + obj.widTxtEL);
            
            % image preview object dimensions
            obj.widPanelAx = ceil(obj.iPara.rAR*obj.hghtFig);
            obj.widFig = obj.widPanelO + obj.widPanelAx + 3*obj.dX;
            
            % retrieves the other main gui fields
            iProg = getappdata(obj.hFigM,'iProg');
            obj.plotD = getappdata(obj.hFigM,'plotD');
            obj.pData = getappdata(obj.hFigM,'pData');
            obj.hPara = getappdata(obj.hFigM,'hPara');
            obj.sPara = getappdata(obj.hFigM,'sPara');
            obj.sName = getappdata(obj.hFigM,'sName');
            
            % sets the main gui function/object handles
            obj.ppFcn = getappdata(obj.hFigM,'popupPlotType');
            obj.exFcn = getappdata(obj.hFigM,'popupExptIndex');
            obj.selFcn = getappdata(obj.hFigM,'setSelectedNode');
            obj.chngFcn = getappdata(obj.hFigM,'treeSelectChng');
            obj.hPopupP = findall(obj.hFigM,'tag','popupPlotType');
            obj.hPopupE = findall(obj.hFigM,'tag','popupExptIndex');
            
            % retrieves the main figure fields
            obj.fDir = iProg.OutFig;
            obj.iDesc = obj.imgType{1,1};
            obj.fExtn = obj.imgType{1,2};
            
            % sets up the unique sub-folder name
            obj.resetSubFolderName();
            
        end
        
        % --- initialises the class objects
        function initClassObjects(obj)
            
            % sets the main GUI to be invisible
            setObjVisibility(obj.hFigM,0);
            setObjVisibility(obj.hPara,0);
            
            % removes any previous GUIs
            hFigPr = findall(0,'tag',obj.tagStr);
            if ~isempty(hFigPr); delete(hFigPr); end
            
            % -------------------------- %
            % --- MAIN CLASS OBJECTS --- %
            % -------------------------- %
            
            % initialisations
            fStr = 'Analysis Figure Output Options';
            
            % creates the figure object
            fPos = [100*[1,1],obj.widFig,obj.hghtFig];
            obj.hFig = figure('Position',fPos,'tag',obj.tagStr,...
                'MenuBar','None','Toolbar','None','Name',fStr,...
                'NumberTitle','off','Visible','off','Resize','off',...
                'CloseRequestFcn',[]);
            
            % creates the outer panel object
            pPosO = [obj.dX*[1,1],obj.widPanelO,obj.hghtPanel];
            obj.hPanelO = uipanel(obj.hFig,'Title','','Units',...
                'Pixels','Position',pPosO);
            
            % creates the plot object
            obj.pltObj = PlotFigure(obj.iPara.W,obj.iPara.H);
            
            % sets the version flag
            try
                obj.isOldVer = ~matlab.ui.internal.isUIFigure(obj.hFig);
            catch
                obj.isOldVer = true;
            end
            
            % ------------------------- %
            % --- MENU ITEM OBJECTS --- %
            % ------------------------- %
            
            % initialisations
            cbFcnF = {@obj.menuSave,@obj.menuExit};
            cbFcnE = {@obj.menuNodeSel,@obj.menuAddAll,@obj.menuRemoveAll};
            [accStrF,accStrE] = deal({'S','X'},{'A','F','E','N','D'});
            [uDO,accStrO] = deal({'splitSR','splitMet'},{'G','M'});

            mStrF = {'Output Figures','Close Window'};
            mStrE = {'Expand All Nodes','Collapse All Nodes',...
                     'Show Experiment Levels Nodes Only',....
                     'Select All Nodes','De-Select All Nodes'};
            mStrO = {'Output All Group Types','Output All Metrics'};
                             
            % creates the menu items
            hMenuF0 = uimenu(obj.hFig,'Label','File');
            obj.hMenuF = cell(length(accStrF),1);
            for i = 1:length(mStrF)
                obj.hMenuF{i} = uimenu(hMenuF0,'Label',mStrF{i},...
                    'Callback',cbFcnF{i},'Accelerator',accStrF{i});
            end
            
            % creates the menu items
            hMenuT = uimenu(obj.hFig,'Label','Explorer Tree');
            obj.hMenuE = cell(length(accStrE),1);
            for i = 1:length(mStrE)
                cbFcnNw = cbFcnE{max(1,i-2)};
                obj.hMenuE{i} = uimenu(hMenuT,'Label',mStrE{i},...
                    'Callback',cbFcnNw,'Accelerator',accStrE{i},...
                    'UserData',i);
            end                       
            
            % creates the menu items
            hMenuP = uimenu(obj.hFig,'Label','Plot Outputs');
            obj.hMenuO = cell(length(accStrO),1);
            for i = 1:length(mStrO)
                obj.hMenuO{i} = uimenu(hMenuP,'Label',mStrO{i},...
                    'Callback',@obj.menuOutput,'Accelerator',accStrO{i},...
                    'UserData',uDO{i},'Checked','off');
            end
            
            % sets the separator field
            obj.hMenuF{2}.Separator = 'on';
            obj.hMenuE{4}.Separator = 'on';
            
            % --------------------------------------- %
            % --- FUNCTION EXPLORER PANEL OBJECTS --- %
            % --------------------------------------- %
            
            % initialisations
            pStrE = 'FUNCTION LIST';
            tStrEL = 'Selected Output Figure Count: ';
            
            % creates the panel object
            pPosE = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelE];
            obj.hPanelE = uipanel(obj.hPanelO,'Title',pStrE,'Units',...
                'Pixels','FontUnits','Pixels','Position',pPosE,...
                'FontSize',obj.hSz,'FontWeight','bold');
            
            % creates
            pPosEL = [obj.dX*[1,1],obj.widTxtEL,obj.hghtTxt];
            createUIObj('text',obj.hPanelE,'Position',pPosEL,...
                'String',tStrEL,'HorizontalAlignment','right',...
                'FontWeight','Bold','FontSize',obj.fSz);
            
            % creates the text object
            lPosE = sum(pPosEL([1,3]));
            pPosTE = [lPosE,obj.dX,obj.widTxtE,obj.hghtTxt];
            obj.hTxtE = createUIObj('text',obj.hPanelE,'Position',pPosTE,...
                'String','0','HorizontalAlignment','left',...
                'FontWeight','Bold','FontSize',obj.fSz);
            
            % creates the function checkbox tree
            obj.indFcn = obj.setFuncExptDep();
            obj.createCheckBoxTree();
            
            % -------------------------------------- %
            % --- IMAGE DIMENSIONS PANEL OBJECTS --- %
            % -------------------------------------- %
            
            % initialisations
            pStr = {'W','H'};
            pStrD = 'IMAGE DIMENSIONS';
            tStrD = {'Image Width','Image Height'};
            cStrD = {'Keep GUI Image Aspect Ratio',...
                'Create Fullscreen Image FIgure'};
            obj.hEditD = cell(1,length(pStr));
            
            % callback functions
            cbStrE = @obj.editDimChange;
            cbStrC = {@obj.checkKeepAR,@obj.checkFullScreen};
            
            % creates the panel object
            yPosD = sum(pPosE([2,4])) + obj.dX/2;
            pPosD = [obj.dX,yPosD,obj.widPanel,obj.hghtPanelD];
            obj.hPanelD = uipanel(obj.hPanelO,'Title',pStrD,'Units',...
                'Pixels','FontUnits','Pixels','Position',pPosD,...
                'FontSize',obj.hSz,'FontWeight','bold');
            
            % creates the label/editbox pairs
            for i = 1:length(tStrD)
                % creates the label string
                tStrDNw = sprintf('%s: ',tStrD{i});
                lPosT = obj.dX + (i-1)*(obj.widTxtD + obj.widEditD);
                tPosD = [lPosT,obj.dX,obj.widTxtD,obj.hghtTxt];
                createUIObj('text',obj.hPanelD,'Position',tPosD,...
                    'FontWeight','Bold','FontSize',obj.fSz,...
                    'String',tStrDNw,'HorizontalAlignment','right');
                
                % creates the exitbox
                lPosE = sum(tPosD([1,3]));
                pValE = obj.iPara.(pStr{i});
                ePosD = [lPosE,obj.dX-2,obj.widEditD,obj.hghtEdit];
                obj.hEditD{i} = createUIObj('edit',obj.hPanelD,...
                    'Position',ePosD,'FontSize',obj.tSz,...
                    'UserData',pStr{i},'ValueChangedFcn',cbStrE,...
                    'String',num2str(pValE),'HorizontalAlignment','Center');
            end
            
            % creates the checkbox objects
            obj.hChkD = cell(1,length(cStrD));
            for i = 1:length(cStrD)
                yPosC = (1+2*(i-1))*obj.dX + obj.dRow;
                cPosD = [obj.dX,yPosC,obj.widChkD,obj.hghtChk];
                obj.hChkD{i} = createUIObj('CheckBox',obj.hPanelD,...
                    'Position',cPosD,'FontSize',obj.fSz,'FontWeight',...
                    'Bold','String',cStrD{i},'ValueChangedFcn',...
                    cbStrC{i});
            end
            
            % updates the other fields
            obj.hChkD{1}.Value = obj.fixAR;
            
            % -------------------------------- %
            % --- IMAGE TYPE PANEL OBJECTS --- %
            % -------------------------------- %
            
            % initialisations
            pStrI = 'OUTPUT IMAGE TYPE';
            ppStrI = cellfun(@(x)(sprintf('%s (%s)',x{1},x{2})),...
                num2cell(obj.imgType,2),'un',0);
            
            % creates the panel object
            yPosI = sum(pPosD([2,4])) + obj.dX/2;
            pPosI = [obj.dX,yPosI,obj.widPanel,obj.hghtPanelI];
            obj.hPanelI = uipanel(obj.hPanelO,'Title',pStrI,'Units',...
                'Pixels','FontUnits','Pixels','Position',pPosI,...
                'FontSize',obj.hSz,'FontWeight','bold');
            
            % ceates the popup menu item
            ppPosI = [obj.dX*[1,1],obj.widPopupI,obj.hghtPopup];
            obj.hPopupI = createUIObj('PopupMenu',obj.hPanelI,...
                'Position',ppPosI,'ValueChangedFcn',@obj.popupImageType);
            if obj.isOldVer
                set(obj.hPopupI,'String',...
                    ppStrI,'Value',1,'FontUnits','Pixels');
            else
                set(obj.hPopupI,'Items',ppStrI,'Value',ppStrI{1});
            end
            
            % resets the font size
            obj.hPopupI.FontSize = obj.tSz;
            
            % --------------------------------------------- %
            % --- FIGURE OUTPUT DIRECTORY PANEL OBJECTS --- %
            % --------------------------------------------- %
            
            % initialisations
            cStrF = 'Create Sub-Folder';
            pStrF = 'FIGURE OUTPUT DIRECTORY';
            obj.hEditF = cell(1,2);
            
            % callback functions
            cbStrC = @obj.checkSubDir;
            cbStrE = @obj.editSubDir;
            cbStrB = @obj.buttonSetDir;
            
            % creates the panel object
            yPosF = sum(pPosI([2,4])) + obj.dX/2;
            pPosF = [obj.dX,yPosF,obj.widPanel,obj.hghtPanelF];
            obj.hPanelF = uipanel(obj.hPanelO,'Title',pStrF,'Units',...
                'Pixels','FontUnits','Pixels','Position',pPosF,...
                'FontSize',obj.hSz,'FontWeight','bold');
            
            % creates the sub-folder checkbox
            cPosF = [obj.dX*[1,1],obj.widChkF,obj.hghtChk];
            obj.hChkF = createUIObj('checkbox',obj.hPanelF,...
                'Position',cPosF,'FontSize',obj.fSz,'FontWeight',...
                'Bold','String',cStrF,'ValueChangedFcn',cbStrC);
            
            % creates the sub-folder name box
            lPosE = sum(cPosF([1,3]));
            ePosFS = [lPosE,obj.dX,obj.widEditFS,obj.hghtEdit];
            obj.hEditF{1} = createUIObj('edit',obj.hPanelF,'Position',...
                ePosFS,'FontSize',obj.tSz,'ValueChangedFcn',cbStrE,...
                'HorizontalAlignment','Left','Enable','off',...
                'String',obj.fDirS);
            
            % creates the folder name editbox
            yPosE = 1.5*obj.dX + (obj.dRow - 2);
            ePosFD = [obj.dX,yPosE,obj.widEditFD,obj.hghtEdit];
            obj.hEditF{2} = createUIObj('edit',obj.hPanelF,'Position',...
                ePosFD,'FontSize',obj.tSz,'String',obj.fDir,...
                'HorizontalAlignment','Left');
            if obj.isOldVer
                set(obj.hEditF{2},'Enable','Inactive');
            else
                set(obj.hEditF{2},'Editable',false);
            end
            
            % creates the directory selection button
            lPosB = sum(ePosFD([1,3])) + obj.dX/2;
            bPosF = [lPosB,yPosE-1,obj.dimBut*[1,1]];
            obj.hButF = createUIObj('pushbutton',obj.hPanelF,...
                'Position',bPosF,'FontSize',obj.fSz,...
                'String','...','FontWeight','Bold',...
                'ButtonPushedFcn',cbStrB,'ToolTip',obj.fDir);
            
            % ----------------------------------- %
            % --- IMAGE PREVIEW PANEL OBJECTS --- %
            % ----------------------------------- %
            
            % creates the panel object
            lPosAx = sum(pPosO([1,3])) + obj.dX;
            pPosAx = [lPosAx,obj.dX,obj.widPanelAx,obj.hghtPanel];
            obj.hPanelAx = uipanel(obj.hFig,'Title','','Units',...
                'Pixels','Position',pPosAx);
            
            % creates the axes object
            axPos = [0,0,pPosAx(3:4)] + [1,1,-2,-2]*obj.dX;
            obj.hAx = axes(obj.hPanelAx,'Units','Pixels',...
                'Position',axPos,'box','on');
            axis(obj.hAx,'normal')
            
            % sets up the image object
            obj.hImg = imagesc(obj.hAx,255*ones([flip(axPos(3:4)),3]));
            set(obj.hAx,'ytick',[],'xtick',[],...
                'xticklabel',[],'yticklabel',[],'clim',[0,255]);
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % resets the initalisation flag
            obj.isInit = false;
            
            % centres the figure and makes it visible
            centerfig(obj.hFig);
            setObjVisibility(obj.hFig,1);
            
        end
        
        % ------------------------------------ %
        % --- MENU ITEM CALLBACK FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- save figure menu item callback function
        function menuSave(obj,~,~)
            
            % retrieves the currently selected node indices
            obj.iSel = obj.getCurrentSelectedNodes();
            if all(cell2mat(obj.iSel(:,1)) == 0)
                % if there are none, output an error message to screen
                eStr = 'At least one figure must be selected for output.';
                waitfor(msgbox(eStr,'Selection Error','Modal'))
                
                % exits the function
                return
            end
            
            % expands all the nodes
            obj.expandSelectedNodes();
            
            % sets up the image file paths
            if obj.setupImagePaths()
                % sets up the output plot data values
                obj.setupOutputPlotData();
            else
                % if there was an issue then exit the function
                return
            end
            
            % creates the loadbar figure
            obj.hProgO = ProgressLoadbar(obj.wStr0);
            pause(0.01);
            
            % other initialisations
            obj.hImg.CData(:) = 255;
            hGUIM = guidata(obj.hFigM);
            
            % outputs all the figures
            for iFig = 1:obj.nFigO
                try
                    % updates the loadbar string
                    wStrNw = sprintf(...
                        '%s (Image %i of %i)',obj.wStr0,iFig,obj.nFigO);
                    obj.hProgO.StatusMessage = wStrNw;
                catch
                    % if there was an error then exit the loop
                    break
                end
                
                % runs the plot type callback if the indices don't match
                if obj.getPopupValue(obj.hPopupP) ~= obj.pIndO(iFig)
                    obj.setPopupValue(obj.hPopupP,obj.pIndO(iFig));
                    obj.ppFcn(obj.hPopupP,'1',guidata(obj.hFigM));
                end
                
                % runs the plot type callback if the indices don't match
                if obj.getPopupValue(obj.hPopupE) ~= obj.eIndO(iFig)
                    obj.setPopupValue(obj.hPopupE,obj.eIndO(iFig));
                    obj.exFcn(obj.hPopupE,1,guidata(obj.hFigM));
                end
                
                % runs the function selection update
                obj.selFcn(hGUIM,obj.fIndO(iFig));
                
                % sets the figure to file
                obj.savePlotFig(iFig);
            end
            
            % closes the loadbar and deletes the temporary figure
            obj.hProgO.delete();
            
            % resets focus to the current figure
            set(0,'CurrentFigure',obj.hFig)
            
        end
        
        % --- close window menu item callback function
        function menuExit(obj,~,~)
            
            % resets the sub-panel highlight (if one exists)
            if obj.useSP && ~isempty(obj.hPS)
                set(obj.hPS,'HighlightColor',[1,0,0])
            end
            
            % resets the experiment index (if required)
            if obj.getPopupValue(obj.hPopupE) ~= obj.eInd0
                obj.setPopupValue(obj.hPopupE,obj.eInd0);
                obj.exFcn(obj.hPopupE,1,guidata(obj.hFigM));
            end
            
            % resets the scope index (if required)
            if obj.getPopupValue(obj.hPopupP) ~= obj.pInd0
                obj.setPopupValue(obj.hPopupP,obj.pInd0);
                obj.ppFcn(obj.hPopupP,'1',guidata(obj.hFigM));
            end
            
            % runs the function reselection function
            obj.selFcn(guidata(obj.hFigM),obj.fInd0);
            
            % closes the windows
            obj.pltObj.closePlotObject();
            delete(obj.hFig);
            
            % updates the plot axes
            hLoad = ProgressLoadbar('Updating Main Analysis Window...');
            obj.chngFcn([],'1',guidata(obj.hFigM))
            pause(0.05);
            
            % sets the main GUI to be invisible
            setObjVisibility(obj.hFigM,1);
            setObjVisibility(obj.hPara,1);
            hLoad.delete();
            
        end
        
        % --- output plot type menu iteam callback function
        function menuOutput(obj,hMenu,~)
            
            % toggles the menu checkmark
            toggleMenuCheck(hMenu);
            
            % updates the parameter value
            uD = get(hMenu,'UserData');
            obj.(uD) = strcmp(get(hMenu,'Checked'),'on');
            
            % resets the tree explorer
            obj.createCheckBoxTree();
            obj.updatePlotImage();
            
        end
        
        % --- tree explorer menu item callback function
        function menuNodeSel(obj,hMenu,~)
                        
            % updates the tree based on the selection
            switch get(hMenu,'UserData')
                case 1
                    % case is expanding all nodes
                    obj.resetTreeExpansion(4)
                    
                case 2
                    % case is expanding function nodes only
                    obj.resetTreeExpansion(1)
                    
                case 3
                    % case is expanding function + expt nodes
                    obj.resetTreeExpansion(2)
                    
            end
            
        end
        
        % --- tree explorer menu item callback function
        function menuAddAll(obj,~,~)

            hLoad = ProgressLoadbar('Updating Figure Explorer Tree...');            
            obj.objT.updateChildNodeIcons(obj.hRoot,'Checked')
            hLoad.delete();
            
        end
        
        % --- tree explorer menu item callback function
        function menuRemoveAll(obj,~,~)
            
            hLoad = ProgressLoadbar('Updating Figure Explorer Tree...');
            obj.objT.updateChildNodeIcons(obj.hRoot,'Unchecked')
            hLoad.delete();
            
        end
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- sub-directory checkbox callback function
        function checkSubDir(obj,hObj,~)
            
            if hObj.Value
                % determine if the full file path already exists
                if exist(fullfile(obj.fDir,obj.fDirS),'dir')
                    % if so, prompt the user if they wish to reset
                    tStr = 'Output Folder Already Exists';
                    bStr = {'Reset Folder Name','Reset Checkbox'};
                    qStr = ['The specified output folder already ',...
                        'exists. Do you want to reset the sub-folder ',...
                        'name, or reset the checkbox selection?'];
                    
                    % prompts the user
                    uChoice = questdlg(qStr,tStr,bStr{1},bStr{2},bStr{1});
                    if strcmp(uChoice,bStr{1})
                        % case is resetting the folder name
                        obj.resetSubFolderName();
                        obj.setEditString(obj.hEditF{1},obj.fDirS);
                    else
                        % case is resetting the checkbox
                        hObj.Value = false;
                        return
                    end
                end
            end
            
            % updates the editbox enabled properties
            obj.useSubF = hObj.Value;
            setObjEnable(obj.hEditF{1},obj.useSubF);
            
        end
        
        % --- sub-directory name editbox callback function
        function editSubDir(obj,hObj,~)
            
            % retrieves the new folder name
            nwDirS = obj.getEditString(hObj);
            
            % determines if the new string is feasible
            [ok,eStr] = chkDirString(nwDirS);
            if ok
                % if so, then check if the folder exists
                fDirNw = fullfile(obj.fDir,nwDirS);
                if exist(fDirNw,'dir')
                    % if the folder exists, flag an error
                    eStr = 'Specified folder path already exists!';
                else
                    % otherwise, update the sub-directory string
                    obj.fDirS = nwDirS;
                end
            end
            
            % if there was an error then output it to screen
            if ~isempty(eStr)
                % outputs the error to screen
                tStr = 'Sub-Folder Naming Error';
                waitfor(msgbox(eStr,tStr,'modal'));
                
                % resets the previous folder name
                obj.setEditString(hObj,obj.fDirS);
            end
            
        end
        
        % --- main directory set
        function buttonSetDir(obj,~,~)
            
            % prompts the user for the new default directory
            tStr = 'Set The Base Figure Output Directory';
            dirName = uigetdir(obj.fDir,tStr);
            figure(obj.hFig);
            
            if dirName
                if exist(fullfile(dirName,obj.fDirS),'dir') && obj.useSubF
                    % if the folder exists (and using sub-folder) then
                    % output an error message to screen
                    eStr = ['The full output path already exists! ',...
                        'Either choose another parent folder, or ',...
                        'alter the sub-folder parameters'];
                    waitfor(msgbox(eStr,'Parent Folder Error','modal'));
                else
                    % resets the base directory editbox string
                    obj.fDir = dirName;
                    obj.setEditString(obj.hEditF{2},['  ',obj.fDir])
                end
            end
            
        end
        
        % --- image type popupmenu callback function
        function popupImageType(obj,hObj,~)
            
            % determines the popup list selected index
            if obj.isOldVer
                iSelP = hObj.Value;
            else
                iSelP = strcmp(hObj.Items,hObj.Value);
            end
            
            % updates the description/type fields
            obj.iDesc = obj.imgType{iSelP,1};
            obj.fExtn = obj.imgType{iSelP,2};
            obj.isPaint = strcmp(obj.fExtn,'.epsp');
            
            % sets the figure resolution (based on figure extension type)
            if strcmp(obj.fExtn,'.pdf')
                obj.fRes = '-r0';
            else
                obj.fRes = '-r150';
            end
            
        end
        %
        % --- dimension editbox change callback function
        function editDimChange(obj,hObj,~)
            
            % field retrieval
            uD = get(hObj,'UserData');
            nwVal = str2double(obj.getEditString(hObj));
            
            % sets the limits
            switch uD
                case 'W'
                    % case is the width
                    if obj.fixAR
                        nwLim = [1,obj.iPara.WmaxAR];
                    else
                        nwLim = [1,obj.iPara.Wmax];
                    end
                    
                case 'H'
                    % case is the height
                    if obj.fixAR
                        nwLim = [1,obj.iPara.HmaxAR];
                    else
                        nwLim = [1,obj.iPara.Hmax];
                    end
            end
            
            % determines if the new value is valid
            if chkEditValue(nwVal,nwLim,1)
                % if so, the update the parameters
                obj.iPara.(uD) = nwVal;
                
                % if fixing aspect ratio, then reset the other dimension
                if obj.fixAR
                    obj.resetOtherDimensions(uD);
                end
                
                % resizes the plot figure
                obj.pltObj.resetFigurePos(obj.iPara.W,obj.iPara.H);
                
            else
                % otherwise, reset to the previous valid value
                obj.setEditString(hObj,num2str(obj.iPara.(uD)))
            end
            
        end
        
        % --- aspect ratio checkbox callback function
        function checkKeepAR(obj,hObj,~)
            
            % updates the fixed aspect ratio
            obj.fixAR = hObj.Value;
            
            % resets the other dimensions
            if obj.fixAR
                % resets the other dimensions
                if obj.iPara.H == obj.iPara.HmaxAR
                    obj.resetOtherDimensions('H');
                else
                    obj.resetOtherDimensions('W');
                end
                
                % disables the other
                obj.useFull = false;
                obj.hChkD{2}.Value = false;
                
                % resizes the plot figure
                obj.pltObj.resetFigurePos(obj.iPara.W,obj.iPara.H);
                
                % enables the editboxes
                cellfun(@(x)(setObjEnable(x,obj.fixAR)),obj.hEditD);
            end
            
        end
        
        % --- full screen checkbox callback function
        function checkFullScreen(obj,hObj,~)
            
            % updates the fixed aspect ratio
            obj.useFull = hObj.Value;
            
            % resets the other dimensions
            if obj.useFull
                % resets the other dimensions
                obj.iPara.W = obj.iPara.Wmax;
                obj.iPara.H = obj.iPara.Hmax;
                
                % resizes the plot figure
                obj.pltObj.resetFigurePos(obj.iPara.W,obj.iPara.H);
                
                % disables the other
                obj.fixAR = false;
                obj.hChkD{1}.Value = false;
                obj.setEditString(obj.hEditD{1},num2str(obj.iPara.W))
                obj.setEditString(obj.hEditD{2},num2str(obj.iPara.H))
            end
            
            % sets the editbox properties
            cellfun(@(x)(setObjEnable(x,~obj.useFull)),obj.hEditD);
            
        end        
        
        % ------------------------------------- %
        % --- EXPLORER TREE SETUP FUNCTIONS --- %
        % ------------------------------------- %
        
        % --- creates the checkbox tree object
        function createCheckBoxTree(obj)
            
            % parameters
            N = 2.5;
            
            % retrieves the function dependency
            dtPos = [1,(N),-2,-(4+N)]*obj.dX;
            tPos = [0,0,obj.hPanelE.Position(3:4)] + dtPos;
            
            % deletes any previous explorer trees
            if obj.isInit
                hTreePr = findall(obj.hPanelE,'Type','uicheckboxtree');
                if isempty(hTreePr)
                    hTreePr = findall(obj.hPanelE,'Type','hgjavacomponent');
                    if ~isempty(hTreePr); delete(hTreePr); end
                else
                    delete(hTreePr);
                end
            end
            
            % imports the checkbox tree
            if obj.isOldVer
                % sets up th\e function tree struct
                fTreeNw = obj.setupFcnTreeStruct();
                
                if obj.isInit
                    % creates the checkbox node tree
                    obj.fTree = fTreeNw;
                    obj.objT = CheckNodeTree(obj.hPanelE,fTreeNw,obj.isInit);
                    
                    % sets the class fields
                    obj.hRoot = obj.objT.hRoot;
                    obj.hTree = obj.objT.hTree;
                    obj.jTree = obj.objT.jTree;
                    obj.objT.postToggleFcn = @obj.postToggleFcn;
                    
                    % expands all the top rows
                    obj.objT.jTree.expandRow(0);
                    for i = obj.objT.jTree.getRowCount:-1:2
                        obj.objT.jTree.expandRow(i-1);
                    end
                else
                    % compares the new and old tree structs
                    obj.resetCheckBoxTree(fTreeNw);
                    obj.fTree = fTreeNw;
                end
                
                % sets the tree callback function
                set(obj.hTree,'NodeSelectedCallback',@obj.nodeSelect);
                
            else
                % creates the tree object
                obj.hTree = uitree(obj.hPanelE,'CheckBox','Position',...
                    tPos,'FontWeight','Bold','FontSize',obj.tSz);
                
                % creates the root-tree node
                obj.hRoot = obj.createTreeNode(obj.hTree,obj.rootStr);
                for i = 1:size(obj.indFcn,1)
                    obj.setupFuncBranch(i);
                end
                
                % sets all nodes as being checked
                obj.hTree.CheckedNodes = obj.hRoot;
                set(obj.hTree,'SelectionChangedFcn',@obj.nodeSelect);
                
                % expands the tree
                expand(obj.hTree,'All');
                uistack(obj.hPanelF,'top')
            end
            
            % updates the selection count
            nFigS = obj.getTotalFigureCount();
            obj.hTxtE.String = num2str(nFigS);
            setObjEnable(obj.hMenuF{1},nFigS>0);
            
        end
        
        % --- sets up the function explorer branch
        function setupFuncBranch(obj,indF)
            
            % creates the parent tree node
            indFcnB = obj.indFcn(indF,:);
            hRootF = obj.createTreeNode(obj.hRoot,indFcnB{1});
            
            % creates the nodes for each branch
            for i = 1:length(indFcnB{end})
                obj.createTreeNode(hRootF,indFcnB{end}{i},0);
            end
            
        end
        
        % --- creates the tree node (dependent on type)
        function hNode = createTreeNode(obj,hP,pStr,hasChild)
            
            % sets the default input arguments
            if ~exist('hasChild','var'); hasChild = true; end
            
            % imports the checkbox tree
            if obj.isOldVer
                % checkbox tree import
                import com.mathworks.mwswing.checkboxtree.*
                hNode = DefaultCheckBoxNode(pStr);
                hNode.setAllowsChildren(hasChild)
                
                % sets the node selection state
                if obj.isInit
                    hNode.setSelectionState(SelectionState.SELECTED);
                else
                    hNode.setSelectionState(SelectionState.UNSELECTED);
                end
                
                % appends the new node to the parent
                if ~isempty(hP)
                    hP.add(hNode);
                end
            else
                % case is the newer matlab version object
                hNode = uitreenode(hP,'Text',pStr);
            end
            
        end
        
        % --- sets up the function tree struct
        function fTree = setupFcnTreeStruct(obj)
            
            % initialises the tree struct
            fTree = obj.initTreeStruct(obj.rootStr);
            
            % sets the children objects
            fTree.Child = cell(size(obj.indFcn,1),1);
            for i = 1:length(fTree.Child)
                % field retrieval
                fType = obj.indFcn{i,5};
                expStr = obj.indFcn{i,end};
                
                % sets up the child object
                fTree.Child{i} = obj.initTreeStruct(obj.indFcn{i,1});
                
                % retrieves
                if fType > 0
                    pDataF = obj.getPlotParaStruct(obj.indFcn(i,:));
                end
                
                % sets up the function fields
                cObjNw = cell(length(expStr),1);
                for j = 1:length(expStr)
                    % initialises the tree struct
                    cObjNw{j} = obj.initTreeStruct(expStr{j});
                    
                    % case is that the plots are split by grouping
                    if (mod(fType,2) == 1) && obj.splitSR
                        % adds another child element
                        pStr = 'Region Groupings';
                        cObjNw{j}.Child{end+1} = obj.initTreeStruct(pStr);
                        
                        % sets up the sub-nodes
                        gName = pDataF{j}.appName;
                        cObjNw{j} = obj.setSubNodes(cObjNw{j},gName);
                    end
                    
                    % case is that there are metrics to add
                    if (floor(fType/2) > 0) && obj.splitMet
                        % adds another child element
                        pStr = 'Plotting Metrics';
                        cObjNw{j}.Child{end+1} = obj.initTreeStruct(pStr);
                        
                        % sets up the sub-nodes
                        pStr = field2cell(pDataF{j}.pP,'Para');
                        pMet = pDataF{j}.pP(strcmp(pStr,'pMet')).Value{2};
                        cObjNw{j} = obj.setSubNodes(cObjNw{j},pMet);
                    end                                        
                end
                
                % sets the new child object
                fTree.Child{i}.Child = cObjNw;
            end
            
        end
        
        % --- determines the difference between fTreeNw and the stored tree
        %     data struct, obj.fTree
        function resetCheckBoxTree(obj,fTreeNw)
            
            % determines the function nodes which have changed
            isChng = ~cellfun(@(x,y)(isequal(...
                x.Child,y.Child)),fTreeNw.Child,obj.fTree.Child);
            if ~any(isChng); return; end
            
            % makes the requisite changes to the experiment nodes
            for iFcn = find(isChng(:)')
                % retrieves the children fields of the functions
                fTreeE = obj.fTree.Child{iFcn}.Child;
                fTreeNwE = fTreeNw.Child{iFcn}.Child;                
                
                % loops through each experiment
                for j = 1:length(fTreeE)
                    % retrieves the node of the current expt
                    hNodeE = obj.getTreeNode([iFcn,j]);
                    if length(fTreeNwE{j}.Child) < length(fTreeE{j}.Child)
                        % case is children nodes need to be removed
                        if isempty(fTreeNwE{j}.Child)
                            % case is there are no children
                            iSub = 1;
                        else
                            % case is there at least one child
                            tTree = cellfun(@(x)...
                                (x.Text),fTreeE{j}.Child,'un',0);
                            tTreeNw = cellfun(@(x)...
                                (x.Text),fTreeNwE{j}.Child,'un',0);
                            [~,iSub] = setdiff(tTree,tTreeNw);
                        end                        
                        
                        % removes the children nodes
                        hNodeE.remove(iSub-1)                        
                    else
                        % case is children nodes need to be removed
                        if ~isempty(fTreeE{j}.Child)
                            % case is there at least one child
                            tTree = cellfun(@(x)...
                                (x.Text),fTreeE{j}.Child,'un',0);
                            tTreeNw = cellfun(@(x)...
                                (x.Text),fTreeNwE{j}.Child,'un',0);
                            [~,iSub] = intersect(tTreeNw,tTree);
                            
                            % removes 
                            B = ~setGroup(iSub,size(fTreeNwE{j}.Child));
                            fTreeNwE{j}.Child = fTreeNwE{j}.Child(B);
                        end                                                
                        
                        % case is children nodes need to be added
                        obj.objT.initVal = 'Unchecked';
                        obj.objT.createChildNodes(hNodeE,fTreeNwE{j});
                    end
                    
                    % reloads the tree node
                    obj.hTree.reloadNode(hNodeE)
                end
            end
            
            % repaints the tree
            obj.hTree.repaint;
            
        end
        
        % ------------------------------------- %
        % --- OTHER EXPLORER TREE FUNCTIONS --- %
        % ------------------------------------- %
        
        % --- sets up the tree sub-nodes
        function cObj = setSubNodes(obj,cObj,Y)
            
            % memory allocation
            cObj.Child{end}.Child = cell(length(Y),1);
            
            % sets up the child nodes
            for i = 1:length(Y)
                cObj.Child{end}.Child{i} = obj.initTreeStruct(Y{i});
            end
            
        end
        
        % --- retrieves the total selected function count
        function nFunc = getTotalFigureCount(obj)
            
            % determines the currently selected nodes
            iSelNw = obj.getCurrentSelectedNodes();
            
            % retrieves the sub-counts for each function
            fGrp = cell(size(iSelNw,1),1);
            for i = 1:length(fGrp)
                fGrp{i} = obj.getSubFuncCount(iSelNw(i,:),i);
            end
            
            % combines the selection/node index arrays
            fGrpT = cell2cell(fGrp);
            nGrp = cellfun('length',fGrpT(:,2));
            indG = cell2mat(cellfun(@(x)(x(1:2)),fGrpT(:,2),'un',0));
            
            % determines the unique function/experiment groupings
            [~,~,iC] = unique(indG,'rows');
            indC = arrayfun(@(x)(find(iC==x)),1:max(iC),'un',0)';
            
            % determines the selection count for each grouping
            nFuncG = zeros(length(indC),1);
            for i = 1:length(indC)
                % determines which nodes are selected
                isSel = cell2mat(fGrpT(indC{i},1));
                if any(isSel)
                    if nGrp(indC{i}(1)) == 2
                        % case is there are no sub-groupings
                        nFuncG(i) = sum(isSel);
                    else
                        % determines the unique sub-groups
                        indGC = cell2mat(fGrpT(indC{i}(isSel),2));
                        [~,~,iCC] = unique(indGC(:,3));
                        
                        % determines the unique grouping indices
                        xiCC = 1:max(iCC);
                        indCC = arrayfun(@(x)(find(iCC==x)),xiCC,'un',0);
                        indCC = indCC(~cellfun(@isempty,indCC));

                        % calculates the total metric count
                        nFuncG(i) = prod(cellfun('length',indCC));
                    end
                end
            end
            
            % returns the total selection count
            nFunc = sum(nFuncG);
        end
        
        % --- determines the sub-node counts
        function nFuncS = getSubFuncCount(obj,iSel,indS)
            
            if isempty(iSel{2})
                % if this is a leaf node, then determine the selection
                nFuncS = {iSel{1} == 2, indS};
            else
                % otherwise, sum up the selections
                nFuncS = cell(size(iSel{2},1),1);
                for i = 1:size(nFuncS,1)
                    nFuncS{i} = obj.getSubFuncCount(iSel{2}(i,:),[indS,i]);
                end  
                
                %
                nFuncS = cell2cell(nFuncS);
            end
            
        end
        
        % --- resets the tree expansion
        function resetTreeExpansion(obj,iLvlL)
            
            % initialisations
            nRow = obj.jTree.getRowCount;
            
            % retrieves the trees nodes
            if obj.isOldVer
                % retrieves the visible nodes
                xiR = 2:nRow;
                hNode = arrayfun(@(x)(...
                    obj.jTree.getPathForRow(x-1)),xiR(:),'un',0);
                hNodeF = cellfun(@(x)(x.getLastPathComponent),hNode,'un',0);                
                
                % retrieves the visible leaf nodes
                iLvlN = cellfun(@(x)(x.getLevel),hNodeF);
                
                %
                isC = false(length(iLvlN),1);
                while any(~isC)
                    % determines the next available node
                    i0 = find(~isC,1,'last');
                    
                    % determines if leaf node needs expanding/collapsing
                    if iLvlN(i0) > iLvlL
                        % case is node needs collapsing
                        lChk = true;
                        hNodeP = hNodeF{i0}.getParent;
                        while hNodeP.getLevel >= iLvlL
                            % retrieves the child nodes of the parent
                            hNodeC = obj.getChildNodes(hNodeP);
                            
                            % removes the nodes from the search (first
                            % iteration only)
                            if lChk
                                indC = cellfun(@(x)(find(cellfun(...
                                    @(y)(isequal(y,x)),hNodeF))),hNodeC);
                                [isC(indC),lChk] = deal(true,false);
                            end
                            
                            % collapses the node and retrieves the parent
                            obj.hTree.collapse(hNodeP)
                            hNodeP = hNodeP.getParent;
                        end
                        
                    elseif iLvlN(i0) < iLvlL
                        % case is node needs expanding
                        hNodeC = obj.getChildNodes(hNodeF{i0});
                        
                        % expands the children nodes of the current
                        for i = 1:length(hNodeC)
                            obj.expandChildNodes(hNodeC{i},iLvlL);
                        end
                        
                        % updates the flag
                        isC(i0) = true;
                        
                    else
                        % case is node doesn't need altering
                        isC(i0) = true;
                    end
                end
                
            else
                
                
            end
            
        end
        
        % --- expands the children nodes
        function expandChildNodes(obj,hNodeP,iLvlL)
            
            % expands the parent node
            obj.hTree.expand(hNodeP);
            obj.hTree.collapse(hNodeP);
            
            % retrieves the children nodes
            hNodeC = obj.getChildNodes(hNodeP);
            if isempty(hNodeC)
                % if there are none, then exit
                return
            else
                % expands the children nodes whose level is < iLvlL
                for i = 1:length(hNodeC)
                    if hNodeC{i}.getLevel <= iLvlL
                        obj.expandChildNodes(hNodeC{i},iLvlL);
                    end
                end
            end
            
        end
        
        % --- retrieves the tree node with path indices, indN
        function hNode = getTreeNode(obj,indN,hNode)
            
            % retrieves the root node
            if ~exist('hNode','var'); hNode = obj.hRoot; end
            
            % retrieves the node at the end of the index array
            for i = 1:length(indN)
                hNode = obj.getChildAt(hNode,indN(i));
            end
            
        end
        
        % --- retrieves all child nodes of the parent node, hNodeP
        function hNodeC = getChildNodes(obj,hNodeP)
            
            xiF = (1:obj.getChildCount(hNodeP))';
            hNodeC = arrayfun(@(x)(...
                obj.getChildAt(hNodeP,x)),xiF,'un',0);
            
        end
        
        % --- retrieves the node state index based on the node value
        function iState = getNodeStateIndex(obj,nVal)
            
            iState = find(strcmp(obj.sStr,nVal)) - 1;
            
        end
        
        % --- expands all the selected nodes
        function expandSelectedNodes(obj,hNodeP,iSelP)
            
            % sets the default input arguments
            if ~exist('hNodeP','var')
                [hNodeP,iSelP] = deal(obj.hRoot,obj.iSel);
            end
           
            % retrieves all the function nodes
            hNodeF = obj.getChildNodes(hNodeP);            
            for i = 1:length(hNodeF)
                if iSelP{i,1} > 0
                    % expands all the selected children nodes                    
                    obj.hTree.expand(hNodeF{i});                    
                    obj.expandSelectedNodes(hNodeF{i},iSelP{i,2});
                    
                else
                    % if there are no selections, then collapse the node
                    obj.hTree.collapse(hNodeF{i});
                end
            end
            
        end        
        
        % --- checkbox tree post toggle function
        function postToggleFcn(obj)
            
            % updates the count
            nFunc = obj.getTotalFigureCount();
            obj.hTxtE.String = num2str(nFunc);
            setObjEnable(obj.hMenuF{1},nFunc>0);
            
        end
        
        % ---------------------------------------- %
        % --- NODE SELECTION CALLBACK FUNCTION --- %
        % ---------------------------------------- %
        
        % --- tree update callback function
        function nodeSelect(obj, ~, evnt)
            
            % retrieves the currently selected node
            if obj.isOldVer
                hNodeS = evnt.getCurrentNode;
            else
                hNodeS = evnt.SelectedNodes;
            end
            
            % updates the axes based on the selection
            if (hNodeS.getLevel == 2)
                % case is a leaf node
                [iScope,iFunc,iExpt] = obj.getNodeIndices(hNodeS);                
                if isnan(iScope)
                    obj.updatePlotImage();
                else
                    obj.updatePlotImage(iScope,iFunc,iExpt);
                end
            else
                % case is not a leaf node
                obj.updatePlotImage();
            end
            
        end
        
        % --- retrieves the indices of the selected node
        function [iScope,iFunc,iExpt] = getNodeIndices(obj,hNodeS)
            
            % sets up the selected function node
            hNodeP = obj.getParent(hNodeS);
            while true
                hNodePP = hNodeP.getParent;
                if isempty(hNodePP)
                    [iScope,iFunc,iExpt] = deal(NaN);                    
                    return
                    
                elseif hNodePP.isRoot
                    % case is the parent node
                    break
                    
                else
                    % resets the current/parent nodes
                    [hNodeS,hNodeP] = deal(hNodeP,hNodePP);
                end
            end
            
            % retrieves the node/parent node texts
            nStr = obj.getName(hNodeS);
            nStrP = obj.getName(obj.getParent(hNodeS));
            
            % determines the matching row/experiment indices
            iRow = strcmp(obj.indFcn(:,1),nStrP);
            iRowT = strcmp(obj.indFcn{iRow,end},nStr);
            
            % sets the scope/function indices
            iScope = obj.indFcn{iRow,2}(iRowT);
            iFunc = obj.indFcn{iRow,3}(iRowT);
            
            % experiment indices
            if iScope == 3
                iExpt = 1;
            else
                iExpt = find(strcmp(obj.sName,nStr));
            end
            
        end
        
        % --- retrieves the indices of the currently selected nodes
        function iSel = getCurrentSelectedNodes(obj)
            
            if obj.isOldVer
                % case is the old figure version
                
                % retrieves the function node
                iSel = obj.getSelectedChildNodes(obj.hRoot);
                
            else
                % case is the new figure version
                hNodeF = obj.hRoot.Children;
                hNodeS = obj.hTree.CheckedNodes;
                nStr = arrayfun(@(x)(x.Text),hNodeF,'un',0);
                
                % determines the selected node indices
                iSel = cell(size(obj.indFcn,1),1);
                for i = 1:length(iSel)
                    % retrieves the parent node
                    hNodeP = hNodeF(strcmp(nStr,obj.indFcn{i,1}));
                    
                    % sets the indices for each selected child node
                    hNodeX = intersect(hNodeP.Children,hNodeS);
                    if ~isempty(hNodeX)
                        nStrX = arrayfun(@(x)(x.Text),hNodeX,'un',0);
                        [~,iSel{i}] = intersect(obj.indFcn{i,end},nStrX);
                    end
                end
            end
            
        end
        
        % --- searches for the selected children nodes
        function iSel = getSelectedChildNodes(obj,hNodeP)
            
            % retrieves the children nodes
            hNode = obj.getChildNodes(hNodeP);
            
            % determines the indices of the selected nodes
            iSel = cell(length(hNode),2);
            for i = 1:length(hNode)
                % child node index array
                % sets the selection indices for each node
                nodeVal = char(hNode{i}.getValue);
                if hNode{i}.getChildCount == 0
                    % if there are no children, then return the node value
                    iSel{i,1} = obj.getNodeStateIndex(nodeVal);
                else
                    % retrieves the selected node state indices
                    iSel{i,2} = obj.getSelectedChildNodes(hNode{i});
                    
                    % resets the selection index for the current node
                    iSelC = cell2mat(iSel{i,2}(:,1));
                    if all(iSelC == 2)
                        iSel{i,1} = 2;
                    else
                        iSel{i,1} = double(any(iSelC > 0));
                    end
                    
%                     % resets the node value (if not the same)
%                     if ~strcmp(nodeVal,obj.sStr{iSel{i,1}+1})
%                         hNode{i}.setValue(obj.sStr{iSel{i,1}+1})
%                     end
                end
            end
            
        end       
        
        % ------------------------------- %
        % --- FIGURE OUTPUT FUNCTIONS --- %
        % ------------------------------- %
        
        % --- sets up the output image file paths
        function ok = setupImagePaths(obj)
            
            % initialisations
            ok = true;
            nFig = obj.getTotalFigureCount;
            
            % sets the image file paths based on the selection count
            if nFig == 1
                % case is there is only one output figure
                
                % sets up the mode string
                if strcmp(obj.fExtn,'.tiff')
                    % case is a tiff file
                    fDesc = 'Tagged Image File Format (*.tiff, *.tif)';
                    uiStr = {'*.tiff;*.tif',fDesc};
                else
                    % case are other file types
                    uiStr = {['*',obj.fExtn],obj.iDesc};
                end
                
                % prompts the user for the output file name
                tStr = 'Save Analysis Figure';
                [fNameO,fDirO,fIndex] = uiputfile(uiStr,tStr,obj.fDir);
                if fIndex == 0
                    % if the user cancelled, then exit the function
                    ok = false;
                    return
                else
                    % otherwise set the image name
                    obj.outFile = {fullfile(fDirO,fNameO)};
                end
                
            else
                % case is there are multiple output figures
                
                % sets the full output figure directory string
                fDirO = obj.fDir;
                if obj.useSubF
                    fDirO = fullfile(fDirO,obj.fDirS);
                end
                
                % if the output directory does not exist, then create it
                if ~exist(fDirO,'dir'); mkdir(fDirO); end
                
                % sets the file paths for all selected nodes
                fFile = cell(size(obj.indFcn,1),1);
                for i = 1:length(fFile)
                    % memory allocation
                    fType = obj.indFcn{i,5};
                    fcnName = obj.indFcn{i,1};
                    iSelF = cell2mat(obj.iSel{i,2}(:,1)) > 0;
                    expName = obj.indFcn{i,end}(iSelF);
                    hChild = obj.iSel{i,2}(iSelF,2);
                    
                    % retrieves the plot data structs
                    pDataF = obj.getPlotParaStruct(obj.indFcn(i,:));
                    pDataF = pDataF(iSelF);
                    
                    % sets the full file path
                    fFile{i} = cell(length(expName),1);
                    for j = 1:length(fFile{i})
                        % sets the base file name
                        fName0 = {sprintf('%s (%s)',fcnName,expName{j})};
                        fName = obj.setSubGroupNames(...
                                fName0,fType,pDataF{j},hChild{j},i);
                        
                        % sets the file extensions
                        fFile{i}{j} = cellfun(@(x)...
                            ([fullfile(fDirO,x),obj.fExtn]),fName,'un',0);
                    end
                    
                    % combines all paths into a single array
                    if ~isempty(fFile{i})
                        fFile{i} = cell2cell(fFile{i});
                    end
                end
                
                % sets full image name strings and determines if any exist
                outFile0 = cell2cell(fFile);
                if any(cellfun(@(x)(exist(x,'file')),outFile0))
                    % if the image file already exists, then prompt the
                    % user if they actually wish to overwrite them
                    tStr = 'Overwrite Image Files';
                    qStr = ['Image file(s) already exist. Do you wish ',...
                        'to overwrite these files?'];
                    uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
                    if ~strcmp(uChoice,'Yes')
                        % case is the user cancelled
                        ok = false;
                        return
                    end
                end
                
                % sets the final field value
                obj.outFile = outFile0;
            end
            
        end        
        
        % --- sets up the output plot data structs
        function setupOutputPlotData(obj)
            
            % initialisations
            nFunc = size(obj.iSel,1);
            obj.nFigO = obj.getTotalFigureCount;
            
            % memory allocation
            [obj.pIndO,obj.fIndO,obj.eIndO] = deal(cell(nFunc,1));
            [obj.pDataO,obj.plotDO,obj.hNodeO] = deal(cell(nFunc,1));
            
            % loops through each function setting the plot values
            iSelF = cell2mat(obj.iSel(:,1));
            for i = find(iSelF(:)')
                % retrieves the fields for the current function                
                fType = obj.indFcn{i,5};
                xiE = arr2vec(find(cell2mat(obj.iSel{i,2}(:,1))'));
                
                % retrieves and reduces down the plotting para struct
                pDataF0 = obj.getPlotParaStruct(obj.indFcn(i,:));
                plotDF0 = obj.getPlotParaStruct(obj.indFcn(i,:),1);
                [pDataF0,plotDF0] = deal(pDataF0(xiE),plotDF0(xiE));
                
                % retrieves the function node
                hNodeF0 = obj.getChildAt(obj.hRoot,i);
                
                % sets the nodes
                noSplit = (fType == 0) || ...
                    (~((mod(fType,2) == 1) && obj.splitSR) && ...
                    ~((floor(fType/2) > 0) && obj.splitMet));
                if noSplit
                    % case is there is no separation
                    obj.pDataO{i} = pDataF0(:);
                    obj.plotDO{i} = plotDF0(:);
                    obj.hNodeO{i} = arrayfun(@(x)(...
                        obj.getChildAt(hNodeF0,x)),xiE,'un',0);
                    
                    % sets the plot, function and experiment indices
                    obj.pIndO{i} = obj.indFcn{i,2}(xiE);
                    obj.fIndO{i} = obj.indFcn{i,3}(xiE);
                    obj.eIndO{i} = cellfun(@(x,y)(obj.getExptIndex(...
                        x,y)),num2cell(obj.pIndO{i}),...
                        obj.indFcn{i,end}(xiE));
                    
                else              
                    % flag initialisations
                    isSep = false;                    
                    
                    % case is that the plots are split by grouping
                    iNode = obj.getSubNodeIndex('Region Groupings',i);                    
                    if (mod(fType,2) == 1) && obj.splitSR && ~isnan(iNode)
                        % retrieves the leaf nodes
                        iSelM = cellfun(@(x)(obj.getLeafNodeSel(...
                            x,iNode)),obj.iSel{i,2}(xiE,2),'un',0);
                        ii = ~cellfun(@isempty,iSelM);
                        
                        % sets the plotting data structs and tree nodes for
                        % each metric permutation
                        if any(ii)
                            % removes any empty elements from the arrays
                            if ~all(ii)
                                [iSelM,pDataF0] = ...
                                    deal(iSelM(ii),pDataF0(ii));
                            end
                        
                            % retrieves the indices of the selected regions
                            % (over all selected experiments)
                            isSep = true;
                            gName = cellfun(@(x)(x.appName),pDataF0,'un',0);                        

                            % retrieves the plotting data structs
                            pDataF = cellfun(@(x,y,z)(obj.expandPlotData(...
                                x,z(y),1)),pDataF0,iSelM,gName,'un',0);
                            plotDF = cellfun(@(x,y,z)(obj.expandPlotData(...
                                x,z(y),3)),plotDF0,iSelM,gName,'un',0);

                            % retrieves the tree nodes for each end point
                            xiM = num2cell(1:length(iSelM))';
                            hNodeF = cellfun(@(ie,y)(arrayfun(@(z)(...
                                obj.getTreeNode([ie,1,z],hNodeF0)),...
                                y,'un',0)),xiM,iSelM,'un',0);
                        end
                    end                    
                    
                    % case is that the plots are split by metrics
                    iNode = obj.getSubNodeIndex('Plotting Metrics',i);
                    if (floor(fType/2) > 0) && obj.splitMet && ~isnan(iNode)
                        % retrieves the indices of the selected metrics
                        % (over all selected experiments)
                        pMet = obj.getFuncMetrics(pDataF0{1});                        
                        
                        % retrieves the indices of the selected leaf nodes
                        iSelM = cellfun(@(x)(obj.getLeafNodeSel(...
                            x,iNode)),obj.iSel{i,2}(xiE,2),'un',0);
                        ii = ~cellfun(@isempty,iSelM);                        
                        
                        % reduces down the data structs (if required)
                        if ~any(mean(ii) == [0,1])
                            [pDataF,plotDF,iSelM] = ...
                                deal(pDataF(ii),plotDF(ii),iSelM(ii));
                        end
                        
                        % sets the plotting data structs and tree nodes for
                        % each metric permutation
                        if isSep && any(ii)
                            % expands the plot data structs  
                            pDataF = cellfun(@(x,y)(cell2cell(...
                                cellfun(@(xx)(obj.expandPlotData(xx,...
                                pMet(y),2)),x,'un',0))),pDataF,iSelM,'un',0);
                            plotDF = cellfun(@(x,y)(cell2cell(...
                                cellfun(@(xx)(obj.expandPlotData(xx,...
                                pMet(y),3)),x,'un',0))),plotDF,iSelM,'un',0);
                            
                            % retrieves the tree nodes for each end point
                            hNodeF = cellfun(@(x,y)(repmat(...
                                x,length(y),1)),hNodeF,iSelM,'un',0);
                        
                        elseif any(ii)
                            % expands the plot data structs                            
                            pDataF = cellfun(@(x,y)(obj.expandPlotData(...
                                x,pMet(y),2)),pDataF0,iSelM,'un',0);
                            plotDF = cellfun(@(x,y)(obj.expandPlotData(...
                                x,pMet(y),3)),plotDF0,iSelM,'un',0);

                            % retrieves the tree nodes for each end point
                            xiF = num2cell(1:length(iSelM))';
                            hNodeF = cellfun(@(ie,y)(arrayfun(@(z)(...
                                obj.getTreeNode([ie,iNode,z],hNodeF0)),...
                                y,'un',0)),xiF,iSelM,'un',0);
                        end
                    end                    
                    
                    % sets the initial plot scope indices
                    pIndO0 = num2cell(obj.indFcn{i,2}(xiE));
                    
                    %
                    obj.pIndO{i} = cell2mat(cellfun(@(x,y)...
                        (repmat(y,length(x),1)),pDataF,pIndO0,'un',0));
                    obj.fIndO{i} = cell2mat(cellfun(@(x,y)...
                        (repmat(y,length(x),1)),pDataF,...
                        num2cell(obj.indFcn{i,3}(xiE)),'un',0));  
                    obj.eIndO{i} = cell2mat(cellfun(@(x,y,z)(repmat(...
                        obj.getExptIndex(y,z),length(x),1)),pDataF,...
                        pIndO0,obj.indFcn{i,end}(xiE),'un',0));
                    
                    % sets the data output fields
                    obj.pDataO{i} = cell2cell(pDataF);
                    obj.plotDO{i} = cell2cell(plotDF);
                    obj.hNodeO{i} = cell2cell(hNodeF);
                end
            end
            
            % collapses down the metric arrays
            obj.eIndO = cell2mat(obj.eIndO);
            obj.fIndO = cell2mat(obj.fIndO);
            obj.pIndO = cell2mat(obj.pIndO);
            obj.pDataO = cell2cell(obj.pDataO);
            obj.plotDO = cell2cell(obj.plotDO);
            obj.hNodeO = cell2cell(obj.hNodeO);
            
            % sorts the output values by the plot scope
            [~,iS] = sortrows([obj.pIndO,obj.eIndO,obj.fIndO]);
            [obj.pDataO,obj.plotDO,obj.hNodeO] = ...
                deal(obj.pDataO(iS),obj.plotDO(iS),obj.hNodeO(iS));
            [obj.fIndO,obj.eIndO,obj.pIndO] = ...
                deal(obj.fIndO(iS),obj.eIndO(iS),obj.pIndO(iS));
            
            % determines if subplots are being used
            obj.useSP = size(obj.sPara,1) > 1;
            if obj.useSP
                % if so, remove any figure highlights
                obj.hPS = findall(obj.hFigM,...
                    'tag','subPanel','HighlightColor',[1,0,0]);
                if ~isempty(obj.hPS)
                    set(obj.hPS,'HighlightColor',[1,1,1])
                end
            end
            
        end
        
        % --- saves the figure to file
        function savePlotFig(obj,iFig)
            
            % updates the selected nodes
            obj.hTree.setSelectedNode(obj.hNodeO{iFig});
            
            % sets up the plot figure
            obj.pltObj.pData = obj.pDataO{iFig};
            obj.pltObj.plotD = obj.plotDO{iFig};
            obj.pltObj.setupPlotFig();
            
            % outputs the plot figure to file
            obj.outputPlotFig(iFig);
            
        end
        
        % --- outputs the plot figure to file
        function outputPlotFig(obj,iFig)
            
            % field retrieval
            hFigO = obj.pltObj.hFig;
            fPath = obj.outFile{iFig};
            
            % if there is no plot axes then exit
            if isempty(findobj(hFigO,'type','axes')); return; end
            
            % outputs the figure based on the file extension
            switch obj.fExtn
                case {'eps','epsp'}
                    % case is an .eps image file
                    if obj.isPaint
                        % case is a painters file
                        figNameP = sprintf('%s.eps',fPath(1:(end-4)));
                        set(hFigO,'Renderer','painters',...
                            'RendererMode','manual');
                        hgexport(hFigO,figNameP);
                    else
                        % output the figure (dependent on OS type)
                        if ispc
                            wState = warning('off','all');
                            export_fig(hFigO,fPath,obj.fRes);
                            warning(wState);
                        else
                            print('-depsc2',obj.fRes,fPath)
                        end
                    end
                    
                case ('fig')
                    % case is a Matlab figure
                    setObjVisibility(hFigO,'on');
                    saveas(hFigO,fPath)
                    
                otherwise
                    % case is the other image types
                    try
                        % NB - increase resolution to desired amount...
                        wState = warning('off','all');
                        export_fig(hFigO,fPath,obj.fRes);
                        warning(wState);
                        
                    catch ME
                        % error occured when creating figure
                        
                        % outputs the message to screen
                        tStr = 'Figure Output Error';
                        eStr = {sprintf(['Error outputting the ',...
                            'image file:\n\n => %s\n'],fPath);...
                            ['Ensure that the image file is ',...
                            'closed and the filename is valid.']};
                        waitfor(msgbox(eStr,tStr,'modal'))
                        
                        % outputs the error message to screen
                        fprintf('Error = %s\n',ME.message);
                    end
            end
            
        end
        
        % ------------------------------------- %
        % --- SUB-GROUPING NAMING FUNCTIONS --- %
        % ------------------------------------- %        
        
        % --- sets the region specific file names
        function fName = setRegionFileNames(...
                obj,fName,fType,pDataG,hChildG,iNodeR)
           
            % adds in the group names (if required)
            if (mod(fType,2) == 1) && obj.splitSR && ~isnan(iNodeR)
                gName = pDataG.appName;
                iSelR = obj.getLeafNodeSel(hChildG,iNodeR);
                
                if ~isempty(iSelR)
                    fName = cell2cell(cellfun(@(x)(cellfun(@(y)...
                        (sprintf('%s (%s)',x,y)),gName(iSelR),...
                        'un',0)),fName,'un',0));
                end
            end            
            
        end
        
        % --- sets the region specific file names
        function fName = setMetricFileNames(...
                obj,fName,fType,pDataG,hChildG,iNodeM)
           
            % adds in the metric names (if required)
            if (floor(fType/2) > 0) && obj.splitMet && ~isnan(iNodeM)
                pMet = obj.getFuncMetrics(pDataG);
                iSelM = obj.getLeafNodeSel(hChildG,iNodeM);
                
                if ~isempty(iSelM)
                    fName = cell2cell(cellfun(@(x)(cellfun(@(y)...
                        (sprintf('%s - %s',x,y)),pMet,'un',0)),...
                        fName,'un',0));
                end
            end            
            
        end        
        
        % --- sets the sub-grouped file names
        function fName = setSubGroupNames(obj,fName,fType,pDataG,hChildG,i)
            
            % if there is no sub-grouping, then exit
            if fType == 0
                return
            end
            
            % determines the region/metric node indices
            iNodeR = obj.getSubNodeIndex('Region Groupings',i);
            iNodeM = obj.getSubNodeIndex('Plotting Metrics',i);
            
            % sets the sub-group file names
            if iNodeR == 1
                % split names by region then metric
                fName = obj.setRegionFileNames(...
                    fName,fType,pDataG,hChildG,iNodeR);
                fName = obj.setMetricFileNames(...
                    fName,fType,pDataG,hChildG,iNodeM);
            else
                % split names by metric then region
                fName = obj.setMetricFileNames(...
                    fName,fType,pDataG,hChildG,iNodeM);
                fName = obj.setRegionFileNames(...
                    fName,fType,pDataG,hChildG,iNodeR);
            end
            
        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- resets the sub-folder path name
        function resetSubFolderName(obj)
            
            % initialisations
            [fBase,iDir] = deal('Sub-Folder #',1);
            
            % keep looping until a unique name has been found
            while 1
                obj.fDirS = sprintf('%s%i',fBase,iDir);
                if exist(fullfile(obj.fDir,obj.fDirS),'dir')
                    iDir = iDir + 1;
                else
                    break
                end
            end
            
        end
        
        % --- sets up the parameter struct
        function initParaStruct(obj)
            
            % retrieves the panel units
            hPanel = findall(obj.hFigM,'tag','panelPlot');
            pUnits = get(hPanel,'Units');
            set(hPanel,'Units','Pixels');
            
            % memory allocation
            obj.iPara = struct('W',[],'H',[],'Wmax',[],...
                'Hmax',[],'WmaxAR',[],'HmaxAR',[],'rAR',[]);
            
            % retrieves the plot panel position
            pPos = get(hPanel,'position');
            set(hPanel,'Units',pUnits);
            
            % calculates the max screen dimensions
            [fPos,fPosMx] = getMaxScreenDim(pPos);
            
            % sets the max width/height parameters and strings
            obj.iPara.rAR = pPos(3)/pPos(4);
            [obj.iPara.W,obj.iPara.WmaxAR] = deal(pPos(3),fPos(3));
            [obj.iPara.H,obj.iPara.HmaxAR] = deal(pPos(4),fPos(4));
            [obj.iPara.Wmax,obj.iPara.Hmax] = deal(fPosMx(3),fPosMx(4));
            
        end
        
        % --- sets up the image type strings
        function setupImageTypeStrings(obj)
            
            obj.imgType = {...
                'Portable Network Graphic','.png';...
                'Encapsulated Postscript','.eps';...
                'Painters Encapsulated PS','.eps';...
                'Portable Data File','.pdf';...
                'Bitmap Image','.bmp';...
                'JPG Image','.jpg'
                'Tagged Image File Format','.tiff';...
                'Matlab Figure','.fig';...
                };
            
        end
        
        % --- resets the other dimension value value
        function resetOtherDimensions(obj,uD)
            
            switch uD
                case 'W'
                    % case is width has been updated
                    obj.iPara.H = roundP(obj.iPara.W/obj.iPara.rAR);
                    obj.setEditString(obj.hEditD{2},num2str(obj.iPara.H))
                    
                case 'H'
                    % case is height has been updated
                    obj.iPara.W = roundP(obj.iPara.H*obj.iPara.rAR);
                    obj.setEditString(obj.hEditD{1},num2str(obj.iPara.W))
            end
            
        end
        
        % --- sets up the function/experiment dependency struct
        function indF = setFuncExptDep(obj)
            
            % memory allocation
            indF = [];
            hasD = cellfun(@(x)(~cellfun(@isempty,x)),obj.plotD,'un',0);
            
            % sets the field matches for each type
            for i = 1:length(hasD)
                % determines the functions/experiments which have
                % calculated data
                [iFunc,iExpt] = find(hasD{i});
                for j = 1:length(iFunc)
                    % sets the new string
                    k = iExpt(j);
                    if i == 3
                        nwVal = 'Multi-Experiment';
                    else
                        nwVal = obj.sName{k};
                    end
                    
                    % adds the field to the data struct
                    pDataF = obj.pData{i}{iFunc(j),k};
                    fType = obj.getFuncType(pDataF);
                    
                    % appends the value to the array
                    nwFld = pDataF.Name;
                    indNw = {nwFld,i,iFunc(j),k,fType,{nwVal}};
                    
                    if isempty(indF)
                        indF = indNw;
                    else
                        isM = strContains(indF(:,1),nwFld);
                        if any(isM)
                            % case is there is a previous match
                            indF{isM,2} = [indF{isM,2};i];
                            indF{isM,3} = [indF{isM,3};iFunc(j)];
                            indF{isM,4} = [indF{isM,4};k];
                            indF{isM,6} = [indF{isM,6};nwVal];
                        else
                            % case is the field doesn't exist
                            indF = [indF;indNw];
                        end
                    end
                end
            end
            
        end
        
        % --- updates the image on the plot axes
        function updatePlotImage(obj,iScope,iFunc,iExpt)
            
            if exist('iScope','var')
                % updates the image object
                pImg = getappdata(obj.hFigM,'pImg');
                obj.hImg.CData = pImg{iScope}{iFunc,iExpt};
                pause(0.05);
                
                % sets the axis limits
                obj.hAx.XLim = [0,size(obj.hImg.CData,2)];
                obj.hAx.YLim = [0,size(obj.hImg.CData,1)];
                
                % turns on the axes
                axis(obj.hAx,'on');
            else
                % turns off the axes
                obj.hImg.CData(:,:,:) = 255;
            end
            
        end
        
        % --- retrieves the plot data structs
        function pDataF = getPlotParaStruct(obj,indFcn,getPlot)
            
            % sets the default input arguments
            if ~exist('getPlot','var'); getPlot = false; end
            
            % memory allocation
            pDataF = cell(length(indFcn{2}),1);
            
            for i = 1:length(pDataF)
                % retrieves the scope, function and experiment indices
                iScope = indFcn{2}(i);
                iFcn = indFcn{3}(i);
                iExpt = indFcn{4}(i);
                
                % retrieves the plot data struct
                if getPlot
                    pDataF{i} = obj.plotD{iScope}{iFcn,iExpt};
                else
                    pDataF{i} = obj.pData{iScope}{iFcn,iExpt};
                end
            end
            
        end        
        
        % --- retrieves the experiment index for plot scope, pI, and
        %     experiment name, exName
        function eI = getExptIndex(obj,pI,exName)
            
            % sets the experiment index
            if pI == 3
                eI = 1;
            else
                eI = find(strcmp(obj.sName,exName));
            end
            
        end
        
        % --- retrieves the sub-node index by given by nStrN
        function iNode = getSubNodeIndex(obj,nStrN,iFcn)
            
            % retrieves the tree node string
            hNodeE = obj.getTreeNode([iFcn,1]);
            hNodeC = obj.getChildNodes(hNodeE);
            nStr = cellfun(@(x)(char(x.getName)),hNodeC,'un',0);
            
            % determines the matching node index
            ii = strContains(nStr,nStrN);
            if any(ii)
                iNode = find(ii);
            else
                iNode = NaN;
            end
            
        end
        
    end
    
    % static methods
    methods (Static)
        
        % --- retrieves the editbox string based on type
        function nwStr = getEditString(hEdit)
            
            if isprop(hEdit,'String')
                nwStr = hEdit.String;
            else
                nwStr = hEdit.Value;
            end
            
        end
        
        % --- retrieves the editbox string based on type
        function setEditString(hEdit,nwStr)
            
            if isprop(hEdit,'String')
                hEdit.String = nwStr;
            else
                hEdit.Value = nwStr;
            end
            
        end
        
        % --- retrieves the child count
        function nChild = getChildCount(hNodeP)
            
            if isa(hNodeP,'matlab.ui.container.TreeNode')
                nChild = length(get(hNodeP,'Children'));
            else
                nChild = hNodeP.getChildCount;
            end
            
        end
        
        % --- retrieves the child node at the index, iNode
        function hNode = getChildAt(hNodeP,iNode)
            
            if isa(hNodeP,'matlab.ui.container.TreeNode')
                hNode = hNodeP.Children(iNode);
            else
                hNode = hNodeP.getChildAt(iNode-1);
            end
            
        end
        
        % --- node is leaf function
        function isL = isLeaf(hNode)
            
            if isa(hNode,'matlab.ui.container.TreeNode')
                isL = isempty(hNode.Children);
            else
                isL = hNode.isLeaf();
            end
            
        end
        
        % --- retrieves the node text
        function nStr = getName(hNode)
            
            if isa(hNode,'matlab.ui.container.TreeNode')
                nStr = hNode.Text;
            else
                nStr = char(hNode.getName);
            end
            
        end
        
        % --- retrieves the parent node
        function hNodeP = getParent(hNode)
            
            if isa(hNode,'matlab.ui.container.TreeNode')
                hNodeP = hNode.Parent;
            else
                hNodeP = hNode.getParent;
            end
            
        end
        
        % --- retrieves the popup index
        function iSel = getPopupValue(hPopup)
            
            if isa(hPopup,'matlab.ui.control.UIControl')
                iSel = hPopup.Value;
            else
                iSel = find(strcmp(hPopup.Items,hPopup.Value));
            end
            
        end
        
        % --- retrieves the popup index
        function setPopupValue(hPopup,iSel)
            
            if isa(hPopup,'matlab.ui.control.UIControl')
                hPopup.Value = iSel;
            else
                hPopup.Value = hPopup.Items{iSel};
            end
            
        end
        
        % --- initialises the checkbox tree struct
        function fTree = initTreeStruct(nodeStr)
            
            fTree = struct('Text',nodeStr,'Child',[]);
            
        end
        
        % --- calculates the function type index value
        function fType = getFuncType(pDataF)
            
            % function type convention
            %  * hasSR - figures are separated by each regional grouping
            %  * hasMet - the function has multiple metrics
            
            % determines what features the function has
            hasSR = pDataF.hasSR;
            hasMet = any(strcmp(field2cell(pDataF.pP,'Para'),'pMet'));
            
            % returns the function type index
            fType = hasSR + 2*hasMet;
            
        end
        
        % --- retrieves a functions metric parameters
        function pMet = getFuncMetrics(pData)
        
            pStr = field2cell(pData.pP,'Para');
            pMet = arr2vec(pData.pP(strcmp(pStr,'pMet')).Value{2});
            
        end
        
        % --- retrieves the leaf node selection values
        function iSelL = getLeafNodeSel(iSelE,iNode)
            
            if isempty(iSelE{iNode,2})
                iSelL = NaN;
            else
                iSelL = find(cell2mat(iSelE{iNode,2}(:,1)) > 0);
            end
            
        end        
        
        % --- expands the plot data and update the required fields
        function pData = expandPlotData(pData,pVal,pType)
            
            % replicates the plot data struct
            pData = repmat({pData},length(pVal),1);
            
            %
            for i = 1:length(pVal)
                switch pType
                    case 1
                        % case is setting the plot group
                        iSelP = find(strcmp(pData{i}.appName,pVal{i}));
                        pData{i}.sP(3).Lim = iSelP;
                        
                        % if the function has subplotting, then set up the
                        % plot to only show the current group
                        if pData{i}.hasSP
                            % updates the dimensions/plot flags
                            sP = pData{i}.sP(2).Value;
                            [sP.nRow,sP.nCol] = deal(1);
                            sP.isPlot = setGroup(...
                                iSelP,[length(sP.isPlot),1]);
                            
                            % resets the special parameter struct
                            pData{i}.sP(2).Value = sP;
                        end
                        
                    case 2
                        % case is setting the plot metric
                        
                        % determines field belonging to plot metrics
                        if i == 1
                            pMet = field2cell(pData{i}.pP,'Para');
                            iM = strcmp(pMet,'pMet');
                            pList = pData{i}.pP(iM).Value{2};
                        end
                        
                        % updates the plot metric index
                        iMet = find(strcmp(pList,pVal{i}));
                        pData{i}.pP(iM).Value{1} = iMet;
                end
            end
            
        end                
        
    end
    
end