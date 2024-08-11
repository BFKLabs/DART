classdef TimeCycle < handle
    
    % class properties
    properties
        
        % input arguments
        hFigM
        
        % object handle fields
        hFig
        hPanelC
        hButC        
        
        % tab group handle fields
        hPanelTG
        hTabG
        hObjT             
        
        % fixed object dimension fields
        dX = 10;
        dR0 = 22;
        dRW = 18;
        hghtRow = 25;
        hghtTxt = 16;
        hghtEdit = 21;
        hghtChk = 21;
        hghtPopup = 23;
        hghtRadio = 25;
        hghtBut = 25;
        widFig = 370;
        hghtPanelC = 40;
        
        % calculated object dimension fields
        hghtFig
        widPanelO        
        hghtPanelP
        hghtPanelBG
        hghtPanelTG
        hghtPanelN
        hghtPanelF
        hghtPanelV        
        hghtTableV
        widButC
        
        % other class fields
        tcPara0
        exName
        
        % boolean class fields
        canClick = false;
        isUpdating = false;
        
        % static class fields
        nExpt
        nButV = 3;
        nButM = 2;
        nButC = 4;
        nParaF = 2;
        nParaP = 2;
        nRowMax = 6;        
        fSzL = 12;
        fSz = 10 + 2/3;        
        
        % static string fields
        tagStr = 'figTimeCycle';                
        figName = 'Experiment Time Cycle';        
        rStrR0 = 'Light/Dark Cycle Duration';
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = TimeCycle(hFigM)
            
            % sets the input arguments
            obj.hFigM = hFigM;
            
            % initialises the class objects/fields
            obj.initClassFields();  
            obj.initClassObjects();            
            
            % clears the output object (if not required)
            if nargout == 0
                clear obj
            end            
            
        end

        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)

            % --------------------------- %
            % --- PARAMETER RETRIEVAL --- %
            % --------------------------- %
            
            % retrieves the solution file data structs
            switch obj.hFigM.Tag
                case 'figOpenSoln'
                    % case is loading from the file load window
                    sObj = getappdata(obj.hFigM,'sObj');
                    snTot = cellfun(@(x)(x.snTot),sObj.sInfo,'un',0);
                    
                case 'figFlyCombine'
                    % case is the data combining window
                    sInfo = getappdata(obj.hFigM,'sInfo');
                    snTot = cellfun(@(x)(x.snTot),sInfo,'un',0);
                    
                case 'figFlyAnalysis'
                    % case is the quantitative analysis window                    
                    snTot = num2cell(getappdata(obj.hFigM,'snTot'));
            end
            
            % field retrieval
            obj.nExpt = length(snTot);
            
            % sets any missing time cycle parameter fields
            hasTC = cellfun(@(x)(isfield(x,'tcPara')),snTot);
            for i = find(~hasTC(:)')
                snTot{i}.tcPara = setupTimeCyclePara();
            end
            
            % retrieves the time cycle parameter struct
            obj.exName = cellfun(@(x)(x.iExpt.Info.Title),snTot,'un',0);
            obj.tcPara0 = cellfun(@(x)(x.tcPara),snTot,'un',0);                            
            
            % ------------------------------ %
            % --- DIMENSION CALCULATIONS --- %
            % ------------------------------ %
            
            % calculates the variable dimensions
            obj.widPanelO = obj.widFig - 2*obj.dX;            
            
            % calculates the control button sizes
            obj.widButC = (obj.widPanelO - 2*obj.dX)/obj.nButC;
            
            % experiment name objects
            obj.hghtPanelN = obj.hghtRow + obj.dX;
            
            % fixed parameter objects
            obj.hghtPanelF = 2*obj.hghtRow + obj.dX;            
            
            % variable duration panel objects            
            obj.hghtTableV = obj.dR0 + obj.nRowMax*obj.dRW;
            obj.hghtPanelV = obj.hghtTableV + 4.5*obj.dX;            
            
            % parameter panel objects
            obj.hghtPanelP = obj.nParaP*obj.hghtRow + 1.5*obj.dX;            
            
            % calculates the other object heights            
            obj.hghtPanelBG = obj.hghtPanelF + ...
                obj.hghtPanelV + 2*obj.hghtRadio + obj.dX;
            obj.hghtPanelTG = obj.hghtPanelN + obj.hghtPanelBG + ...
                obj.hghtPanelP + 6*obj.dX;
            obj.hghtFig = obj.hghtPanelTG + ...
                obj.hghtPanelC + 2*obj.dX;
            
        end
        
        % --- initialises the class objects
        function initClassObjects(obj)
            
            % removes any previous GUIs
            hFigPr = findall(0,'tag',obj.tagStr);
            if ~isempty(hFigPr); delete(hFigPr); end
            
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- % 
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % creates the figure object
            obj.hFig = createUIObj('figure','Position',fPos,...
                'tag',obj.tagStr,'MenuBar','None','Toolbar','None',...
                'Name',obj.figName,'Resize','off','NumberTitle','off',...
                'Visible','off','CloseRequestFcn',[]);
            
            % ------------------------------------ %
            % --- CONTROL BUTTON PANEL OBJECTS --- %
            % ------------------------------------ %
            
            % initialisations
            bStrC = {'Update','Reset','Synchronise','Close'};
            cbFcnC = {@obj.updatePara,@obj.resetPara,...
                      @obj.syncPara,@obj.closeWindow};
            
            % creates the panel object
            pPosC = [obj.dX*[1,1],obj.widPanelO,obj.hghtPanelC];
            obj.hPanelC = createUIObj(...
                'Panel',obj.hFig,'Title','','Position',pPosC);
            
            % creates the button object
            for i = 1:obj.nButC
                % sets up the positional vector
                lPosB = obj.dX + (i-1)*obj.widButC;
                pPosB = [lPosB,obj.dX-2,obj.widButC,obj.hghtBut];
                
                % creates the button objects
                obj.hButC{i} = createUIObj('pushbutton',obj.hPanelC,...
                    'String',bStrC{i},'Position',pPosB,...
                    'FontWeight','Bold','FontSize',obj.fSzL,...
                    'ButtonPushedFcn',cbFcnC{i});
            end            
            
            % ------------------------------ %
            % --- TAG GROUP OBJECT SETUP --- %
            % ------------------------------ %            
            
            % creates the panel object
            yPosTG = sum(pPosC([2,4])) + obj.dX;
            pPosTG = [obj.dX,yPosTG,obj.widPanelO,obj.hghtPanelTG];
            obj.hPanelTG = createUIObj(...
                'Panel',obj.hFig,'Title','','Position',pPosTG);
            
            % creates the tab panel group object
            obj.hTabG = createTabPanelGroup(obj.hPanelTG,1);
            tabPos = getTabPosVector(obj.hPanelTG,[4,5,-10,-10]);
            set(obj.hTabG,'position',tabPos)
            
            % creates the time cycle parameter tab objects
            obj.hObjT = cell(obj.nExpt,1);
            for i = 1:obj.nExpt
                obj.hObjT{i} = TimeCycleTab(obj,i);
            end            
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %

            % disables the update/reset buttons
            cellfun(@(x)(setObjEnable(x,0)),obj.hButC(1:2))
            obj.setSyncParaProps();
            
            % centers the figure and makes it visible
            centerfig(obj.hFig);
            refresh(obj.hFig);
            pause(0.05);
            
            % makes the figure visible
            set(obj.hFig,'Visible','on');
                        
        end
        
        % ----------------------------------------- %
        % --- CONTROL BUTTON CALLBACK FUNCTIONS --- %
        % ----------------------------------------- %        

        % --- updates the time cycle parameter        
        function updatePara(obj,~,~)

            % updates the solution fields (depending on the opening window)
            % retrieves the solution file data structs
            switch obj.hFigM.Tag
                case 'figOpenSoln'
                    % case is loading from the file load window
                    
                    % retrieves and updates fields within solution data
                    sObj = getappdata(obj.hFigM,'sObj');
                    for i = 1:length(sObj.sInfo)
                        sObj.sInfo{i}.snTot.tcPara = obj.hObjT{i}.tcPara;
                    end                    
                    
                    % updates the field within the master window
                    setappdata(obj.hFigM,'sObj',sObj)                    
                    
                case 'figFlyCombine'
                    % case is the data combining window
                    
                    % retrieves and updates fields within solution data
                    sInfo = getappdata(obj.hFigM,'sInfo');
                    for i = 1:length(sInfo)
                        sInfo{i}.snTot.tcPara = obj.hObjT{i}.tcPara;
                    end
                    
                    % updates the field within the master window
                    setappdata(obj.hFigM,'sInfo',sInfo)
                    
                case 'figFlyAnalysis'
                    % case is the quantitative analysis window

                    % retrieves and updates fields within solution data
                    snTot = getappdata(obj.hFigM,'snTot');
                    for i = 1:length(snTot)
                        snTot(i).tcPara = obj.hObjT{i}.tcPara;
                    end                    
                    
                    % updates the field within the master window
                    setappdata(obj.hFigM,'snTot',snTot)
            end
            
            % resets the class object fields
            obj.tcPara0 = cellfun(@(x)(x.tcPara),obj.hObjT,'un',0);
            cellfun(@(x)(x.resetOrigPara),obj.hObjT);

            % updates the synchronisation properties
            obj.setUpdateParaProps();
            obj.setSyncParaProps();                        
            
        end        
        
        % --- resets the time cycle parameters
        function resetPara(obj,~,~)
            
            % prompts the user if they want to reset the parameters
            tStr = 'Reset Parameters?';
            qStr = 'Do you want to reset the original parameters?';
            uChoice = questdlg(qStr,tStr,'Yes','No','Yes');

            % resets the parameters (if the user chose to)
            if strcmp(uChoice,'Yes')
                % resets the tab parameter fields
                for i = 1:obj.nExpt
                    % resets the experiments time cycle struct
                    if ~isequal(obj.hObjT{i}.tcPara,obj.hObjT{i}.tcPara0)
                        obj.hObjT{i}.tcPara = obj.hObjT{i}.tcPara0;
                        obj.hObjT{i}.resetAllParaFields();
                    end
                end
                
                % updates button properties
                obj.setUpdateParaProps();
                obj.setSyncParaProps();
                
                % refreshes the figure
                refresh(obj.hFig);
                drawnow
            end
            
        end
        
        % --- synchronises the time cycle parameters
        function syncPara(obj,hBut,~)
            
            % prompts the user if they want to synchronise the parameters
            tStr = 'Synchronise Changes?';
            qStr = 'Do you want to synchronise the changes you have made?';
            uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
            
            % synchronises the parameters (if the user chose to)
            if strcmp(uChoice,'Yes')
                % retrieves the parameter from the current tab
                iTab = obj.hTabG.SelectedTab.UserData;
                tcParaS = obj.hObjT{iTab}.tcPara;
                useRelTimeS = obj.hObjT{iTab}.useRelTime;
                
                % resets the tab parameter fields
                for i = 1:obj.nExpt
                    % ignore the currently selected tab
                    if i == iTab
                        continue
                    end
                    
                    % resets the experiments time cycle struct
                    obj.hObjT{i}.tcPara = tcParaS;
                    obj.hObjT{i}.useRelTime = useRelTimeS;
                    obj.hObjT{i}.resetAllParaFields();
                end
                
                % updates button properties
                obj.setUpdateParaProps();
                setObjEnable(hBut,0);
                
                % refreshes the figure
                refresh(obj.hFig);
                drawnow                
            end
            
        end
        
        % --- close window callback function
        function closeWindow(obj,~,~)
            
            % determines if there are outstanding changes
            if strcmp(obj.hButC{1}.Enable,'on')
                % if so, prompts the user if they want to update
                tStr = 'Update Changes?';
                qStr = 'Do you want to update the changes you have made?';
                uChoice = questdlg(qStr,tStr,'Yes','No','Cancel','Yes');
                
                % updates based on the user's choice
                switch uChoice
                    case 'Yes'
                        % user chose to update changes
                        obj.updatePara([],[]);
                        
                    case 'Cancel'
                        % user chose to cancel
                        return
                end                
            end
            
            % closes the window
            delete(obj.hFig);
            
        end

        % ------------------------------- %        
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- sets the update parameter properties
        function setUpdateParaProps(obj)
            
            % sets the update button properties
            isOn = cellfun(@(x)(x.getUpdateParaProps),obj.hObjT);
            cellfun(@(x)(setObjEnable(x,any(isOn))),obj.hButC(1:2));
            
            % updates the synchronisation propertiess
            obj.setSyncParaProps();
            
        end
        
        % --- sets the synchronisation parameters
        function setSyncParaProps(obj)
            
            % if there is only one experiment then exit the function
            if obj.nExpt == 1
                setObjEnable(obj.hButC{2},0);
                return
            end
            
            % retrieves the time cycle parameters
            tcPara = cellfun(@(x)(x.tcPara),obj.hObjT,'un',0);
            isEq = cellfun(@(x)(isequal(tcPara{1},x)),tcPara(2:end));
            setObjEnable(obj.hButC{3},any(~isEq))
            
        end
        
    end    
    
end