classdef PlotFigure < handle
    
    % class properties
    properties
        
        % class object handles
        hFig
        hPanelAx
        
        % main class fields
        pData
        plotD
        
        % fixed object dimensions
        dX = 10;
        widFig;
        hghtFig;
        
        % calculate object dimensions
        widPanel
        hghtPanel
        
        % static class fields
        fPosMax
        tagStr = 'figPlotFigure';
        
    end
    
    % class methods
    methods
    
        % --- class constructor
        function obj = PlotFigure(widFig,hghtFig)

            % sets the input dimensions
            obj.widFig = widFig;
            obj.hghtFig = hghtFig;
            
            % initialises the class fields and objects
            obj.initClassFields();
            obj.initClassObjects();
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % retrieves the maximum screen dimensions
            obj.fPosMax = getMaxScreenDim();
            
            % calculate object dimensions
            obj.widPanel = obj.widFig - 2*obj.dX;
            obj.hghtPanel = obj.hghtFig - 2*obj.dX;
            
        end
    
        % --- initialises the class fields
        function initClassObjects(obj)
                    
            % removes any previous GUIs
            hFigPr = findall(0,'tag',obj.tagStr);
            if ~isempty(hFigPr); delete(hFigPr); end            
            
            % ------------------------------ %
            % --- CONTROL BUTTON OBJECTS --- %
            % ------------------------------ %            
            
            % creates the figure object
            fPos = obj.setupFigurePosVector();             
            obj.hFig = figure('Position',fPos,'tag',obj.tagStr,...
                'MenuBar','None','Toolbar','None','Name','',...
                'NumberTitle','off','Visible','off','Resize','off',...
                'Color','w');
            
            % creates the plot panel
            pPosAx = [obj.dX*[1,1],fPos(3:4)-2*obj.dX];
            obj.hPanelAx = uipanel(obj.hFig,'Units','Pixels',...
                'Position',pPosAx,'Title','','BackgroundColor',[1,1,1]);
            obj.hPanelAx.Units = 'Normalized';            
                          
        end        
        
        % -------------------------- %
        % --- PLOTTING FUNCTIONS --- %
        % -------------------------- %        
        
        % --- outputs the plot figure to file
        function setupPlotFig(obj)
            
            % updates the plot figure
            updatePlotFigure(obj,obj.pData,[]);
            
        end                
        
        % --- creates the axis object
        function hAx = setupPlotAxes(obj)
           
            % clears any previous axes
            hAxPr = findall(obj.hPanelAx,'type','axes');
            if ~isempty(hAxPr); delete(hAxPr); end
            
            % creates the new axes object
            hAx = axes(obj.hPanelAx);            
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- sets up the figure position vector
        function fPos = setupFigurePosVector(obj)
            
            % memory allocation
            y0 = obj.fPosMax(2);
            fPos = [NaN(1,2),obj.widFig,obj.hghtFig];            
            
            % sets the left/bottom coordinates
            fPos(1) = (obj.fPosMax(3) - fPos(3))/2;
            fPos(2) = y0 + (obj.fPosMax(4) - (fPos(4)-y0))/2;
            
        end
        
        % --- resets the figure position
        function resetFigurePos(obj,W,H)
            
            % updates the figure dimensions
            [obj.widFig,obj.hghtFig] = deal(W,H);
            
            % resets the position figure vector
            obj.hFig.Position = obj.setupFigurePosVector();
            
        end
        
        % --- closes the plot object
        function closePlotObject(obj)
            
            delete(obj.hFig);
                
        end
            
    end
        
end