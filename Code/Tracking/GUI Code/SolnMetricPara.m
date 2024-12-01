classdef SolnMetricPara < handle
    
    % class properties
    properties
        
        % input class fields
        hFigM        
        iPara
        
        % main figure class fields
        hFig
        
        % speed parameter object class fields
        hPanelS
        hRadioS 
        
        % derivative window object class fields
        hPanelW
        hEditW
        
        % control button object class fields
        hPanelC
        hButC        
        
        % fixed object dimension fields
        dX = 10;
        dHght = 25;
        hghtTxt = 16;
		hghtBut = 25;
	    hghtEdit = 22;
	    hghtRow = 25;
        hghtRadio = 20;
        hghtPanelC = 40;
        hghtPanelW = 35;
        widRadioS = 90;
        widPanel = 300;
        widTxtW = 215;
        
        % calculated object dimension fields
        widFig
        hghtFig 
        widPanelW
        hghtPanelS
        widButC
        
        % static scalar fields
        nButC = 2;
        nRadioS = 3;
        fSzH = 13;
        fSzL = 12;
        fSz = 10 + 2/3;
        
        % static string fields
        tagStr = 'figMetricPara';
        figName = 'Metric Parameters';        
        
    end
    
    % class methods
    methods
    
        % --- class constructor
        function obj = SolnMetricPara(hFigM)
            
            % sets the input arguments
            obj.hFigM = hFigM;
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();            
            
        end

        % -------------------------------------- %        
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
             
            % field retrieval
            obj.iPara = obj.hFigM.iPara;
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %
            
            % speed panel dimension calculations
            obj.widPanelW = obj.widPanel - 2*obj.dX;
            obj.hghtPanelS = obj.dX + ...
                obj.hghtRow + obj.hghtPanelW + obj.dHght;
            
            % figure dimension calculations
            obj.hghtFig = obj.hghtPanelC + obj.hghtPanelS + 2*obj.dX;
            obj.widFig = obj.widPanel + 2*obj.dX;        
            
            % other object dimension calculations
            obj.widButC = (obj.widPanel - 2.5*obj.dX)/obj.nButC;
            
        end
        
        % --- initialises the class objects
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
                'Name',obj.figName,'NumberTitle','off','Visible','off',...
                'AutoResizeChildren','off','CloseRequestFcn',[]);            
            
            % ------------------------------ %
            % --- CONTROL BUTTON OBJECTS --- %
            % ------------------------------ %
            
            % initialisations
            bStrC = {'Update Trace','Close Window'};
            cbFcnC = {@obj.buttonUpdate,@obj.buttonClose};
            
            % creates the control button objects
            pPosC = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = createUIObj(...
                'Panel',obj.hFig,'Position',pPosC,'Title',''); 
            
            % other initialisations
            obj.hButC = cell(length(bStrC),1);
            for i = 1:length(bStrC)
                % sets up the button position vector
                lBut = obj.dX + (i-1)*(obj.widButC + obj.dX/2);
                bPos = [lBut,obj.dX-2,obj.widButC,obj.hghtBut];
                
                % creates the button object
                obj.hButC{i} = createUIObj('Pushbutton',obj.hPanelC,...
                    'Position',bPos,'Callback',cbFcnC{i},...
                    'FontUnits','Pixels','FontSize',obj.fSzL,...
                    'FontWeight','Bold','String',bStrC{i});
            end                        
            
            % disable the update trace button
            setObjEnable(obj.hButC{1},0);
            
            % ------------------------------- %
            % --- SPEED PARAMETER OBJECTS --- %
            % ------------------------------- %
            
            % initialisations
            tHdrS = 'SPEED PARAMETERS';
            rStrS = {'Central','Forward','Backward'};
            tStrW = 'Derivative Calculation Window Size';
            yStrW = num2str(obj.iPara.vP.nPts);
            cbFcnW = @obj.editWindowSize;
            cbFcnS = @obj.panelSelectionChanged;
            
            % creates the panel object
            yPosS = sum(pPosC([2,4])) + obj.dX;
            pPosS = [obj.dX,yPosS,obj.widPanel,obj.hghtPanelS];
            obj.hPanelS = createUIObj('ButtonGroup',obj.hFig,...
                'Position',pPosS,'Title',tHdrS,'FontSize',obj.fSzH,...
                'FontWeight','Bold','SelectionChangedFcn',cbFcnS);
            
            % creates the window size parameter panel
            pPosW = [obj.dX*[1,1],obj.widPanelW,obj.hghtPanelW];
            obj.hPanelW = createUIObj(...
                'Panel',obj.hPanelS,'Position',pPosW,'Title','');             
            
            % creates the radiobutton objects
            yPosS = sum(pPosW([2,4])) + obj.dX/2;
            obj.hRadioS = cell(obj.nRadioS,1);
            for i = 1:obj.nRadioS
                % sets up the object position vector
                xPosS = 2*obj.dX + (i-1)*obj.widRadioS;
                pPosS = [xPosS,yPosS,obj.widRadioS,obj.hghtRadio];
                
                % creates the button object
                obj.hRadioS{i} = createUIObj('radiobutton',obj.hPanelS,...
                    'Position',pPosS,'String',rStrS{i},...
                    'FontSize',obj.fSzL,'FontWeight','Bold',...
                    'UserData',rStrS{i});
                
                % sets the radio button value
                if strcmp(obj.iPara.vP.Type,rStrS{i})
                    obj.hRadioS{i}.Value = 1;
                end
            end
            
            % creates the editbox group
            obj.hEditW = obj.createEditGroup(obj.hPanelW,tStrW);
            set(obj.hEditW,'String',yStrW,'Callback',cbFcnW);
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % centers the figure and makes it visible
            centerfig(obj.hFig);
            refresh(obj.hFig);
            pause(0.05);
            
            % makes the figure visible
            set(obj.hFig,'Visible','on');            
            
        end
        
        %---------------------------------- %
        % --- OBJECT CREATION FUNCTIONS --- %
        %---------------------------------- %
        
        % --- creates the text label combo objects
        function hEdit = createEditGroup(obj,hP,tTxt)
            
            % initialisations
            yOfs = 6;
            tTxtL = sprintf('%s: ',tTxt);
            widEdit = hP.Position(3) - (2*obj.dX + obj.widTxtW);
            
            % sets up the text label
            pPosL = [obj.dX,yOfs+2,obj.widTxtW,obj.hghtTxt];
            createUIObj('text',hP,'Position',pPosL,'FontWeight','Bold',...
                'FontSize',obj.fSzL,'HorizontalAlignment','Right',...
                'String',tTxtL);
            
            % creates the text object
            pPosE = [sum(pPosL([1,3])),yOfs,widEdit,obj.hghtEdit];
            hEdit = createUIObj(...
                'edit',hP,'Position',pPosE,'FontSize',obj.fSz);
            
        end                
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- % 
                
        % --- radio buttongroup selection change callback function
        function panelSelectionChanged(obj, hPanel, ~)
            
            hRadio = hPanel.SelectedObject;
            obj.iPara.vP.Type = hRadio.UserData;
            setObjEnable(obj.hButC{1},1);
            
        end
        
        % --- window size editbox callback function
        function editWindowSize(obj, hEdit, ~)
            
            % field retrieval
            nwVal = str2double(hEdit.String);
                        
            % determines if the new value is valid
            if chkEditValue(nwVal,[1,20],1)
                % if so, then update the 
                obj.iPara.vP.nPts = nwVal;
                setObjEnable(obj.hButC{1},1);
                
            else
                % otherwise, reset to the previous valid value
                hEdit.String = num2str(obj.iPara.vP.nPts);
            end
            
        end        
    
        % --- update trace pushbutton callback function
        function buttonUpdate(obj, hBut, ~)
           
            % resets the parameter struct into the parent window
            obj.hFigM.iPara = obj.iPara;            
            obj.hFigM.updateFunc(guidata(obj.hFigM));
            
            % disables the button
            setObjEnable(hBut,0);
            
        end
        
        % --- close window pushbutton callback function
        function buttonClose(obj, ~, ~)
                        
            % determines if there is a change
            if strcmp(get(obj.hButC{1},'Enable'),'on')
                % if there was a change, prompt user if they wish to close
                tStr = 'Update Changes?';
                qStr = 'Do you want to update your changes before closing?';
                uChoice = questdlg(qStr,tStr,'Yes','No','Cancel','Yes');
                switch uChoice
                    case 'Yes'
                        % user chose to update
                        obj.buttonUpdate(obj.hButC{1},[]);
                        
                    case 'No'
                        % user chose to not update (do nothing...)
                        
                    otherwise
                        % otherwise, the user cancelled
                        return
                end
            end
           
            % removes the parent window menu item check
            hMenu = findall(obj.hFigM,'tag','menuMetricOptions');
            set(hMenu,'Checked','Off');
            
            % deletes the window
            delete(obj.hFig);
            
        end        
        
    end
    
end