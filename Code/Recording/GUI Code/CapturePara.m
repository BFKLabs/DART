classdef CapturePara < handle
    
    % class properties
    properties
        
        % main class objects
        hFig
        
        % capture parameter panel objects
        hPanelP
        hEditP
        
        % control button panel objects
        hPanelC
        hButC
        
        % fixed dimension fields
        dX = 10;     
        hghtRow = 25;
        widPanel = 260;
        widLblP = 140;
        
        % calculated dimension fields
        widFig
        hghtFig
        hghtPanelP
        hghtPanelC
        widButC
        
        % capture parameters
        Nframe = 10;
        wP = 1;                
        isCapture
        
        % static class fields
        nObjP = 2;
        nButC = 2;
        fSzH = 13;
        fSzL = 12;
        fSz = 10 + 2/3;
        
        % static string fields
        tagStr = 'figCapturePara';
        figName = 'Capture Parameters';
        
    end
    
    % class methods
    methods
        
        % --- class constuctor
        function obj = CapturePara()
            
            % sets the input arguments
        
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();            
            
            % clears the output object (if not required)
            if (nargout == 0) && ~isdeployed
                clear obj
            end            
            
            % waits for the user to respond...
            uiwait(obj.hFig);
            
        end        
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % memory allocation
            obj.hEditP = cell(obj.nObjP,1);
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %
            
            % other panel dimension calculations
            obj.hghtPanelP = obj.nObjP*obj.hghtRow + obj.dX;
            obj.hghtPanelC = obj.hghtRow + obj.dX;                        
            
            % figure dimension calculations
            obj.widFig = obj.widPanel + 2*obj.dX;
            obj.hghtFig = obj.hghtPanelP + obj.hghtPanelC + 3*obj.dX;
            
            % other object dimension calculations
            obj.widButC = (obj.widPanel - obj.dX)/obj.nButC;
            
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
            obj.setupCaptureParaPanel();
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %                              
            
            % opens the class figure
            openClassFigure(obj.hFig);
            
        end      
                
        % ------------------------------------ %
        % --- PANEL OBJECT SETUP FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- sets up the control button panel objects        
        function setupControlButtonPanel(obj)
            
            % initialisations
            tStrB = {'Start Capture','Cancel'};
            cbFcnB = {@obj.buttonStartCapture;@obj.buttonCancel};
            
            % creates the panel object
            pPos = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = createPanelObject(obj.hFig,pPos);
            
            % creates the control button objects
            obj.hButC = createObjectRow(obj.hPanelC,length(tStrB),...
                'pushbutton',obj.widButC,'dxOfs',0,'xOfs',obj.dX/2,...
                'yOfs',obj.dX/2,'pStr',tStrB);
            cellfun(@(x,y)(set(x,'Callback',y)),obj.hButC,cbFcnB);
            
        end
        
        % --- sets up the capture parameter panel objects
        function setupCaptureParaPanel(obj)
            
            % initialisations
            pStr = {'Nframe','wP'};            
            cbFcnE = @obj.editParaUpdate;
            tStrB = {'Frame Capture Count','Inter-Frame Pause (s)'};
            pVal = cellfun(@(x)(num2str(obj.(x))),pStr,'un',0);
            
            % creates the panel object
            yPos = sum(obj.hPanelC.Position([2,4])) + obj.dX;
            pPos = [obj.dX,yPos,obj.widPanel,obj.hghtPanelP];
            obj.hPanelP = createPanelObject(obj.hFig,pPos);
            
            % creates the parameter objects
            for i = 1:obj.nObjP
                % calculates the vertical offset
                j = obj.nObjP - (i-1);
                yOfs = obj.dX/2 + (j-1)*obj.hghtRow + 3;
                
                % creates the label/editbox grouping
                obj.hEditP{i} = createObjectPair(obj.hPanelP,tStrB{i},...
                    obj.widLblP,'edit','yOfs',yOfs,'cbFcnM',cbFcnE);
                set(obj.hEditP{i},'UserData',pStr{i},'String',pVal{i})
            end
            
        end        
        
        % --------------------------------------- %
        % --- OTHER OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- capture parameter editbox callback function
        function editParaUpdate(obj, hEdit, ~)
           
            % field retrieval
            pStr = hEdit.UserData;
            nwVal = str2double(hEdit.String);
            
            % sets the parameter limits
            switch pStr
                case 'Nframe'
                    [nwLim,isInt] = deal([5,100],true);
                case 'wP'
                    [nwLim,isInt] = deal([1,20],false);
            end
            
            % determines if the new value is valid
            if chkEditValue(nwVal,nwLim,isInt)
                % if so, then update the class fields
                obj.(pStr) = nwVal;
                
            else
                % otherwise, revert back to the last valid value
                hEdit.String = num2str(obj.(pStr));
            end
        end
        
        % --- start capture pushbutton callback function
        function buttonStartCapture(obj, ~, ~)
            
            % sets the capture flag
            obj.isCapture = true;
            
            % deletes the figure
            delete(obj.hFig);            
            
        end
        
        % --- cancel pushbutton callback function
        function buttonCancel(obj, ~, ~)
            
            % sets the capture flag
            obj.isCapture = false;
            
            % deletes the figure
            delete(obj.hFig);
            
        end                       
        
    end
    
end