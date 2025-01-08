classdef GlobalPara < handle
    
    % class properties
    properties
        
        % input arguments
        hFigM        
        objP
        
        % output class fields
        gParaU
        isChange = false;        
        
        % main class objects
        hFig
        
        % global variable panel objects
        hPanelV
        hObjV
        
        % control button panel objects
        hPanelC
        hButC
        
        % fixed dimension fields
        dX = 10;    
        hghtRow = 25;
        hghtHdr = 20;        
        widPanel = 460;
        widLblV = 300;
        
        % calculated dimension fields
        widFig
        hghtFig
        hghtPanelV
        hghtPanelC
        widButC        
        
        % static class fields
        nButC = 3;
        nParaV = [4,3,1];
        fSzH = 13;
        fSzL = 12;
        fSz = 10 + 2/3;
        
        % static string fields
        tagStr = 'figGlobalPara';
        figName = 'Setting Global Parameters';
        tHdrV = 'ANALYSIS FUNCTION GLOBAL VARIABLES';
        
    end
    
    % class methods
    methods
        
        % --- class constuctor
        function obj = GlobalPara(hFigM)
            
            % sets the input arguments
            obj.hFigM = hFigM;
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();                
            
            % clears the output object (if not required)
            if (nargout == 0) && ~isdeployed
                clear obj
            end     
            
            % waits for the user response
            uiwait(obj.hFig);
            
        end        
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % memory allocation
            obj.hObjV = cell(sum(obj.nParaV),1);
            
            % field retrieval
            obj.objP = getappdata(obj.hFigM,'objP');            
            obj.gParaU = getappdata(obj.hFigM,'gPara');
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %

            % panel dimension calculations
            obj.hghtPanelV = 2*obj.dX + ...
                obj.hghtHdr + sum(obj.nParaV)*obj.hghtRow;
            obj.hghtPanelC = obj.dX + obj.hghtRow;
            
            obj.widFig = obj.widPanel + 2*obj.dX;
            obj.hghtFig = obj.hghtPanelV + obj.hghtPanelC + 3*obj.dX;

            % other object dimension calculations
            obj.widButC = (obj.widPanel - 2*obj.dX)/obj.nButC;
            
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
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % creates the figure object
            obj.hFig = createUIObj('figure','Position',fPos,...
                'tag',obj.tagStr,'MenuBar','None','Toolbar','None',...
                'Name',obj.figName,'Resize','on','NumberTitle','off',...
                'Visible','off','AutoResizeChildren','off',...
                'BusyAction','Cancel','GraphicsSmoothing','off',...
                'DoubleBuffer','off','Renderer','painters','CloseReq',[]);            
            
            % ----------------------- %
            % --- SUB-PANEL SETUP --- %
            % ----------------------- %
                        
            % sets up the sub-panel objects
            obj.setupControlButtonPanel();
            obj.setupGlobalParaPanel();
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % initialises the object properties
            obj.initObjectProps();            
            
            % opens the class figure
            openClassFigure(obj.hFig);
            
        end      
        
        % --- initialises the object properties
        function initObjectProps(obj)
            
            % updates the values for each parameter object
            for i = 1:sum(obj.nParaV)
                % field retrieval
                pStr = obj.hObjV{i}.UserData;
                
                % updates/set the parameter values
                switch obj.hObjV{i}.Style
                    case 'edit'
                        % updates the editbox value
                        
                        % sets the editbox string
                        obj.hObjV{i}.String = num2str(obj.gParaU.(pStr));
                        
                    case 'popupmenu'
                        % case is a popup menu
                        
                        % retrieves the popupmenu strings
                        if strcmp(pStr,'movType')
                            pL = {'Absolute Location';'Midline Crossing'};
                        end
                        
                        % resets the popupmenu properties
                        iSel = find(strcmp(pL,obj.gParaU.(pStr)));
                        set(obj.hObjV{i},'String',pL,'Value',iSel);
                end
                
            end
            
        end
        
        % ------------------------------------ %
        % --- PANEL OBJECT SETUP FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- sets up the control button parameter panel
        function setupControlButtonPanel(obj)
            
            % initialisations
            cbFcnB = {@obj.buttonResetPara;@obj.buttonUpdatePara;...
                      @obj.buttonCloseWindow};
            bStrC = {'Reset Default','Update Parameters','Close Window'};
                        
            % creates the panel object
            pPos = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = createPanelObject(obj.hFig,pPos);
            
            % creates the panel objects
            obj.hButC = createObjectRow(obj.hPanelC,obj.nButC,...
                'pushbutton',obj.widButC,'pStr',bStrC,'dxOfs',0,...
                'yOfs',obj.dX/2);
            cellfun(@(x,y)(set(x,'Callback',y)),obj.hButC,cbFcnB);
            cellfun(@(x)(setObjEnable(x,0)),obj.hButC(1:2));
            
        end
        
        % --- sets up the global parameter panel
        function setupGlobalParaPanel(obj)
            
            % initialisations
            nParaVS = cumsum(obj.nParaV);
            iTypeE = [(1:2),(4:sum(obj.nParaV))];            
            pStrV = {'Tgrp0','TdayC','movType','pWid',...
                     'tNonR','nAvg','tSleep','dMove'};
            tLblV = {'Day Cycle Start Hour',...
                     'Day Cycle Duration (Hours)',...
                     'Movement Calculation Type',...
                     'Mid-Line Crossing Location',...
                     'Post-Stimuli Event Response Time (sec)',...
                     'Stimuli Response Averaging Time-Window (frames)',...
                     'Sleep Inactivity Duration (min)',...
                     'Activity Movement Distance (mm)'};
                                  
            % function handles
            cbFcnE = @obj.editParaUpdate;
            cbFcnP = @obj.popupParaUpdate;
            
            % creates the panel object
            yPos = sum(obj.hPanelC.Position([2,4])) + obj.dX;
            pPos = [obj.dX,yPos,obj.widPanel,obj.hghtPanelV];
            obj.hPanelV = createPanelObject(obj.hFig,pPos,obj.tHdrV);            
            
            % creates the popupmenu/editbox objects
            for i = 1:sum(obj.nParaV)
                % calculates the vertical offset
                j = sum(obj.nParaV) - (i-1);
                hOfs = (obj.dX/2)*sum(i <= nParaVS);
                yOfs = obj.dX/2 + (j-1)*obj.hghtRow + hOfs;
                
                % sets the object type string (based on type)
                if any(iTypeE == i)
                    [pTypeV,cbFcn] = deal('edit',cbFcnE);
                else
                    [pTypeV,cbFcn] = deal('popupmenu',cbFcnP);
                end
                
                % creates the parameter object
                obj.hObjV{i} = createObjectPair(obj.hPanelV,tLblV{i},...
                    obj.widLblV,pTypeV,'yOfs',yOfs,'cbFcnM',cbFcn);
                set(obj.hObjV{i},'UserData',pStrV{i});
            end
            
            % disables the movement type popupmenu object (2D setup only)
            snTot = getappdata(obj.hFigM,'snTot');
            if is2DCheck(snTot(1).iMov)
                hPopupMT = findobj(obj.hPanelV,'UserData','movType');
                setObjEnable(hPopupMT,'off');
            end
            
        end
        
        % --------------------------------------- %
        % --- OTHER OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- parameter update editbox callback function
        function editParaUpdate(obj, hEdit, ~)
            
            % field retrieval
            pStr = hEdit.UserData;
            nwVal = str2double(hEdit.String);
            [nwLim,isInt] = obj.getParaLimits(pStr);
            
            % determines if the new value is valid
            if chkEditValue(nwVal,nwLim,isInt)
                % updates the parameter value
                obj.gParaU.(pStr) = nwVal;
                
                % sets the other object properties
                cellfun(@(x)(setObjEnable(x,1)),obj.hButC(1:2))
                
            else
                % otherwise, revert back to the previous value
                hEdit.String = num2str(obj.gParaU.(pStr));
            end
            
        end
        
        % --- parameter update popupmenu callback function
        function popupParaUpdate(obj, hPopup, ~)
            
            % resets the parameter value
            pStr = hPopup.UserData;
            obj.gParaU.(pStr) = hPopup.String{hPopup.Value};
            
            % sets the other object properties
            cellfun(@(x)(setObjEnable(x,1)),obj.hButC(1:2))
            
        end        
        
        % --- reset parameter button callback function
        function buttonResetPara(obj, ~, ~)
           
            % prompts the user if they wish to update the struct
            tStr = 'Reset Global Parameters?';
            qStr = ['Are sure you wish to update the ',...
                    'default global parameters?'];
            uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
            
            % if the user cancelled, then exit
            if ~strcmp(uChoice,'Yes'); return; end  
            
            % overwrites the global parameter struct in the program 
            gPara = obj.gParaU;
            save(getParaFileName('ProgPara.mat'),'gPara','-append');
            
            % resets the other flag/object properties
            obj.isChange = true;
            cellfun(@(x)(setObjEnable(x,0)),obj.hButC(1:2));
            
        end
        
        % --- update parameter button callback function
        function buttonUpdatePara(obj, hBut, evnt)
           
            if ~isempty(evnt)
                % prompts the user if they really want to update
                tStr = 'Update Global Parameters?';
                qStr = {'Do you wish to update the global parameters?',...
                        'Note - this will clear all current calculations.'};
                uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
                
                % if the user cancelled, then exit
                if ~strcmp(uChoice,'Yes'); return; end
            end
            
            % resets the change flag and disables the button
            obj.isChange = true;
            setObjEnable(hBut,0);
            
        end
        
        % --- close window button callback function
        function buttonCloseWindow(obj, ~, ~)        
           
            if strcmp(obj.hButC{2}.Enable,'on')
                % prompts the user if they wish to update the struct
                uChoice = questdlg({'Do you wish to update the global parameters?',...
                    'Note - this will clear all current calculations'},...
                    'Update Global Parameters?','Yes','No','Cancel','Yes');

                switch uChoice
                    case 'Yes' 
                        % case is user does want to update
                        obj.buttonUpdatePara(obj.hButC{2},[]);
                    
                    case 'No'
                        % flag that no changes were made
                        obj.isChange = false;
                    
                    otherwise
                        % case is the user cancelled so exit
                        return
                end
            end
            
            % closes the GUI
            setObjVisibility(obj.hFig,0);
            setObjVisibility(obj.hFigM,1);
            obj.objP.setVisibility(1);
            
            % delete the dialog window
            delete(obj.hFig)            
            
        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- deletes the class object
        function deleteClass(obj)            
            
            % deletes and clears the class object
            delete(obj)
            clear obj
            
        end
        
    end
    
    % class methods
    methods (Static)
        
        function [nwLim,isInt] = getParaLimits(pStr)
            
            % sets the parameter limits/integer flags
            switch pStr
                case 'Tgrp0'
                    % case is the start of the day
                    [nwLim,isInt] = deal([0 23.99],0);
                    
                case 'TdayC'
                    % case is the day cycle duration
                    [nwLim,isInt] = deal([0 24],1);
                    
                case 'pWid'
                    % case is the midline location
                    [nwLim,isInt] = deal([0 1],0);
                    
                case 'tNonR'
                    % case is the post-stimuli non-reactive duration
                    [nwLim,isInt] = deal([1 600],0);
                    
                case 'nAvg'
                    % case is the stimuli averaging time bin size
                    [nwLim,isInt] = deal([1 300],1);
                    
                case 'dMove'
                    % case is the activity movement distance
                    [nwLim,isInt] = deal([0 inf],0);
                    
                case 'tSleep'
                    % case is the inactivity sleep duration
                    [nwLim,isInt] = deal([1 60],1);
            end
            
        end
        
    end    
    
end