classdef CreateDARTExe < handle
    
    % class properties
    properties
       
        % input class fields
        hFigM
        
        % object handle fields
        hFig
        
        % analysis function panel objects
        hPanelF
        hTableF
        hLblF
        hTxtF
        
        % external package panel objects
        hPanelP
        hTableP
        hLblP
        hTxtP
        
        % control button panel objects
        hPanelC
        bButC
        
        % fixed object dimension fields
        dX = 10;
        hghtBut = 25;
        hghtTxt = 16;
        widFig = 410;
        widLbl = 260;
        hghtPanelC = 40;        
        
        % calculated object dimension fields
        hghtFig
        widPanel
        widTable
        widTxt
        
        % static scalar fields
        nRowP = 12;
        nRowF = 4;
        
        % static character fields
        tagStr = 'figCreateExe';
        tagStrT = 'hTimerExe';
        figName = 'DART Executable Setup';
        
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
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % centers the figure and makes it visible
            centerfig(obj.hFig);
            refresh(obj.hFig);
            pause(0.05);            
            
        end
        

        % ----------------------------------------- %        
        % --- CONTROL BUTTON CALLBACK FUNCTIONS --- %
        % ----------------------------------------- %
        
        % --- create executable callback function
        function compileExe(obj, ~, ~)
            
            %
            
            
        end
        
        % --- create executable callback function
        function closeWindow(obj, ~, ~)
            
            % deletes the figure
            delete(obj.hFig);
            
            % makes the main figure visible again
            setObjVisibility(obj.hFigM,1);
            
        end        
        
    end
    
end