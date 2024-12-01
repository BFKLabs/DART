classdef SampleRate < handle
    
    % class properties
    properties
    
        % main figure class fields
        hFig
        hPanelO
        
        % video parameter panel fields
        hPanelP
        hTxtP
        hEditP
        
        % video information panel fields        
        hPanelI
        hTxtI
        
        % control button panel fields        
        hPanelC
        hButC
                
        % fixed object dimension fields
        dX = 10;
        hghtTxt = 16;
		hghtBut = 25;
	    hghtEdit = 22;
        hghtRow = 25;
        hghtPanelC = 40;
        widPanel = 250;
        widTxtL = 125;
        
        % calculated object dimension fields
        hghtFig
        widFig
        hghtPanelO
        hghtPanelP
        hghtPanelI
        widPanelPI
        widTxtTE
        widButC
        
        % main class fields
        iData
        sRate = 5;
        iFrm0 = 1;
        
        % static scalar fields
        nTxtP = 2;
        nEditP = 2;
        nTxtI = 2;
        fSzL = 12;
        fSz = 10 + 2/3;
        
        % static string fields
        tagStr = 'figSampleRate';
        figName = 'Video Sample Rate';        
        
    end
    
    % class methods
    methods
    
        % --- class constructor
        function obj = SampleRate(iData)
            
            % sets the input arguments
            obj.iData = iData;
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();
            
            % waits for the user response
            uiwait(obj.hFig);
            
        end

        % -------------------------------------- %        
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % ------------------------------------- %
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %
            
            % calculates the inner panel dimensions
            obj.hghtPanelP = ...
                obj.dX*(2*obj.nTxtP + 1.5) + obj.nEditP*obj.hghtRow;
            obj.hghtPanelI = obj.dX*(2*obj.nTxtI + 1.5);
            obj.widPanelPI = obj.widPanel - 2*obj.dX;
            obj.hghtPanelO = (obj.hghtPanelP + obj.hghtPanelI) + 3*obj.dX;

            % calculates the figure dimensions
            obj.hghtFig = obj.hghtPanelC + obj.hghtPanelO + 3*obj.dX;
            obj.widFig = obj.widPanel + 2*obj.dX;
            
            % other object dimension calculations
            obj.widTxtTE = obj.widPanelPI - (2*obj.dX + obj.widTxtL);
            obj.widButC = obj.widPanel - 2*obj.dX;
            
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
            
            % creates the outer panel object
            yPosO = 2*obj.dX + obj.hghtPanelC;
            pPosO = [obj.dX,yPosO,obj.widPanel,obj.hghtPanelO];
            obj.hPanelO = createUIObj(...
                'Panel',obj.hFig,'Position',pPosO,'Title',''); 
            
            % ------------------------------ %
            % --- CONTROL BUTTON OBJECTS --- %
            % ------------------------------ %
            
            % initialisations
            bStrC = 'Open Movie';
            cbFcnC = @obj.buttonOpenMovie;
            
            % creates the panel object
            pPosC = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = createUIObj(...
                'Panel',obj.hFig,'Position',pPosC,'Title',''); 
                            
            % creates the button object
            bPos = [obj.dX-[0,2],obj.widButC,obj.hghtBut];            
            obj.hButC = createUIObj('Pushbutton',obj.hPanelC,...
                'Position',bPos,'Callback',cbFcnC,...
                'FontUnits','Pixels','FontSize',obj.fSzL,...
                'FontWeight','Bold','String',bStrC);
            
            % --------------------------------- %
            % --- VIDEO INFORMATION OBJECTS --- %
            % --------------------------------- %
            
            % initialisations            
            tStrIT = {'New Total Frames','New Time Step'};

            % creates the panel object
            pPosI = [obj.dX*[1,1],obj.widPanelPI,obj.hghtPanelI];
            obj.hPanelI = createUIObj(...
                'Panel',obj.hPanelO,'Position',pPosI,'Title','');
            
            % creates the information label combo groups
            obj.hTxtI = cell(obj.nTxtI,1);            
            for i = 1:obj.nTxtI
                % sets the group bottom location
                j = obj.nTxtI - (i-1);
                yPosTI = obj.dX*(1 + 2*(j-1)) - 2;
                
                % creates the label group
                obj.hTxtI{i} = obj.createLabelGroup(...
                    obj.hPanelI,tStrIT{i},yPosTI);
            end
            
            % -------------------------------- %
            % --- VIDEO PARAMETERS OBJECTS --- %
            % -------------------------------- %            
            
            % initialisations
            pStrP = {'sRate','iFrm0'};            
            cbFcnP = @obj.editParaUpdate;
            tStrPE = {'Sample Rate','Start Video Frame'};
            tStrPT = {'Video Total Frames','Video Time Step'};
            yOfs = obj.dX + obj.nEditP*obj.hghtRow;                        
            
            % creates the panel object
            yPosP = sum(pPosI([2,4])) + obj.dX;
            pPosP = [obj.dX,yPosP,obj.widPanelPI,obj.hghtPanelP];
            obj.hPanelP = createUIObj(...
                'Panel',obj.hPanelO,'Position',pPosP,'Title','');
            
            % creates the parameter editbox combo groups
            obj.hEditP = cell(obj.nEditP,1);
            for i = 1:obj.nEditP
                % sets the group bottom location
                j = obj.nEditP - (i-1);
                yPosEP = obj.dX + (j-1)*obj.hghtRow - 2;                             
                yStrEP = num2str(obj.(pStrP{i}));
                
                % creates the edibox group
                obj.hEditP{i} = obj.createEditGroup(...
                    obj.hPanelP,tStrPE{i},yPosEP);
                set(obj.hEditP{i},'String',yStrEP,...
                    'Callback',cbFcnP,'UserData',pStrP{i})
            end
            
            % creates the parameter label combo groups
            obj.hTxtP = cell(obj.nTxtP,1);
            for i = 1:obj.nTxtP
                % sets the group bottom location
                j = obj.nTxtP - (i-1);
                yPosTP = 2*obj.dX*(j-1) + yOfs;
                
                % creates the label group
                obj.hTxtP{i} = obj.createLabelGroup(...
                    obj.hPanelP,tStrPT{i},yPosTP);
            end
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % sets the video parameter/information fields
            obj.setVideoParaFields();
            
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
        function hEdit = createEditGroup(obj,hP,tTxt,yPos)
            
            % sets the default input arguments
            if ~exist('xOfs','var'); xOfs = obj.dX; end
            
            % initialisations
            tTxtL = sprintf('%s: ',tTxt);
            widEdit = hP.Position(3) - (2*obj.dX + obj.widTxtL);
            
            % sets up the text label
            pPosL = [xOfs,yPos+2,obj.widTxtL,obj.hghtTxt];
            createUIObj('text',hP,'Position',pPosL,'FontWeight','Bold',...
                'FontSize',obj.fSzL,'HorizontalAlignment','Right',...
                'String',tTxtL);
            
            % creates the text object
            pPosE = [sum(pPosL([1,3])),yPos,widEdit,obj.hghtEdit];
            hEdit = createUIObj(...
                'edit',hP,'Position',pPosE,'FontSize',obj.fSz);
            
        end
        
        % --- creates the text label combo objects
        function hTxt = createLabelGroup(obj,hP,tTxt,yPos)
            
            % sets the default input arguments
            if ~exist('xOfs','var'); xOfs = obj.dX; end
            
            % initialisations
            tTxtL = sprintf('%s: ',tTxt);
            widEdit = hP.Position(3) - (2*obj.dX + obj.widTxtL);
            
            % sets up the text label
            pPosL = [xOfs,yPos,obj.widTxtL,obj.hghtTxt];
            createUIObj('text',hP,'Position',pPosL,'FontWeight','Bold',...
                'FontSize',obj.fSzL,'HorizontalAlignment','Right',...
                'String',tTxtL);
            
            % creates the text object
            pPosE = [sum(pPosL([1,3])),yPos,widEdit,obj.hghtTxt];
            hTxt = createUIObj('text',hP,'Position',pPosE,...
                'FontSize',obj.fSzL,'HorizontalAlignment','Left',...
                'FontWeight','Bold');
            
        end
        
        %---------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        %---------------------------------- %
        
        % --- open movie pushbutton callback function
        function buttonOpenMovie(obj, ~, ~)
            
            delete(obj.hFig);
            
        end
        
        % --- parameter update editbox callback function
        function editParaUpdate(obj, hEdit, ~)
            
            % field retrieval
            pStr = hEdit.UserData;
            nwVal = str2double(hEdit.String);
            
            % sets the parameter limits
            switch pStr
                case 'sRate'
                    % case is
                    nwLim = [1,25];
                    
                case 'iFrm0'
                    % case is the start frame
                    nFrmT = floor(obj.iData.nFrmT/obj.sRate) - 1;
                    nwLim = [1,nFrmT];                    
            end
            
            % determines if the new value is valid
            if chkEditValue(nwVal,nwLim,1)
                % if so, update the parameter and information fields
                obj.(pStr) = nwVal;
                obj.setVideoInfoFields();
                
            else
                % otherwise, reset to the previous valid value
                hEdit.String = num2str(obj.(pStr));
            end
            
        end

        % ---------------------------------------- %        
        % --- OBJECT PROPERTY UPDATE FUNCTIONS --- %
        % ---------------------------------------- %
        
        % --- updates the video parameter fields
        function setVideoParaFields(obj)
            
            % pre-calculations
            tStepStr = sprintf('%.2f sec',1/obj.iData.exP.FPSest);
            
            % sets the video parameter label/editbox strings
            obj.hTxtP{1}.String = num2str(obj.iData.nFrmT);
            obj.hTxtP{2}.String = tStepStr;
            obj.hEditP{1}.String = num2str(obj.sRate);
            obj.hEditP{2}.String = num2str(obj.iFrm0);

            % sets the video information fields
            obj.setVideoInfoFields()
            
        end
        
        % --- updates the video information fields
        function setVideoInfoFields(obj)
            
            % retrieves the total frame count
            nFrmT = floor(obj.iData.nFrmT/obj.sRate) - (obj.iFrm0-1);
            tStepStr = sprintf('%.2f sec',obj.sRate/obj.iData.exP.FPSest);
            
            % sets the new frame count and frame time step fields
            obj.hTxtI{1}.String = num2str(nFrmT);
            obj.hTxtI{2}.String = tStepStr;
            
        end
    
    end
    
end