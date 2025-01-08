classdef AnalysisParaObj < handle
    
    % class properties
    properties
        
        % main class objects
        hFig  
        
        % panel object class fields 
        hPanel
        hPanelS
        Hpanel
        nPanel 
        hVB
        Hmin        
        
        % fixed dimension fields
        dX = 10;     
        hghtTxt = 16;
        hghtRow = 25;
        hghtHdr = 20;
        hghtPanel0 = 30;
        widLbl = 145;
        widTxt = 140;
        widFig = 350;
        hghtFig = 200;
        
        % static class fields
        fSzH = 13;
        fSzL = 12;
        fSz = 10 + 2/3;        
        txtCol = ones(1,3);
        hdrCol = 0.8*ones(1,3);
        
        % text label objects
        textCalcReqd
        textFuncDesc
        textFuncName
        textCalcReqdL
        textFuncDescL
        textFuncNameL        
        
        % panel objects
        panelFuncInfo
        panelCalcPara
        panelPlotPara
        panelStimResPara
        panelSubPara
        panelTimePara
        
        % static string fields
        tagStr = 'figAnalysisPara';
        figName = 'Analysis Parameters';
        
        % cell array class fields
        tStrH = {'Recalculation Required','textCalcReqd';...
                 'Function Description','textFuncDesc';...
                 'Function File Name','textFuncName'};
        pStrH = {'FUNCTION INFORMATION','panelFuncInfo';...
                 'CALCULATION PARAMETERS','panelCalcPara';...
                 'PLOTTING PARAMETERS','panelPlotPara';...
                 'STIMULI RESPONSE','panelStimResPara';...
                 'SUBPLOT CONFIGURATION','panelSubPara';...
                 'TIME PARAMETERS','panelTimePara'};        
        
    end
    
    % class methods
    methods
        
        % --- class constuctor
        function obj = AnalysisParaObj()
            
            % initialises the class fields/objects
            obj.initParaClassFields();
            obj.initParaClassObjects();            
            
            % clears the output object (if not required)
            if (nargout == 0) && ~isdeployed
                clear obj
            end            
            
        end        
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initParaClassFields(obj)
            
            % field retrieval
            obj.nPanel = size(obj.pStrH,1);
            
            % memory allocation
            obj.hPanel = cell(obj.nPanel,1);
            obj.Hmin = (obj.hghtRow + obj.hghtPanel0)*ones(obj.nPanel,1);            
            
        end
        
        % --- initialises the class fields
        function initParaClassObjects(obj)
            
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
            
            % sets up the panel objects
            obj.setupParaPanels();
            
        end      
        
        % ------------------------------------ %
        % --- PANEL OBJECT SETUP FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- sets up the parameter panel objects
        function setupParaPanels(obj)
            
            % initialisations            
            pPos = [0,0,obj.widFig,obj.hghtPanel0];
            
            % creates the vertical panel box
            obj.hVB = uix.VBox('Parent',obj.hFig);
        
            % creates the sub-panel objects
            for i = 1:obj.nPanel
                % creates the box panel object
                cbFcnP = {@obj.boxPanelClick,i};
                obj.hPanel{i} = uix.BoxPanel('Title',obj.pStrH{i,1},...
                    'Parent',obj.hVB,'UserData',i,...
                    'tag',obj.pStrH{i,2},'Minimized',false,...
                    'TitleColor',obj.hdrCol,'ForegroundColor',obj.txtCol,...
                    'FontWeight','Bold','FontUnits','Pixels',...
                    'FontSize',obj.fSzH,'MinimizeFcn',cbFcnP);
                obj.(obj.pStrH{i,2}) = obj.hPanel{i};                
                
                % creates the panel object for the box panel
                obj.hPanelS{i} = createPanelObject(obj.hPanel{i},pPos);
                set(obj.hPanelS{i},...
                    'tag','hPanelS','UserData',obj.hghtPanel0);
            end

            % sets the first panel minimum height
            hNew = obj.dX*(2*size(obj.tStrH,1) + 1);
            set(obj.hPanelS{1},'UserData',hNew);
            obj.Hmin(1) = obj.hghtRow + hNew;
            
            % creates the function description objects
            for i = 1:size(obj.tStrH,1)
                % initialisations          
                yOfsT = (obj.dX/2)*(1 + 4*(i-1));
                tagStrL = sprintf('%sL',obj.tStrH{i,2});                
                
                % creates the label marker object
                [hTxtR,hTxtL] = createObjectPair(obj.hPanelS{1},...
                    obj.tStrH{i,1},obj.widLbl,'text','wObjM',obj.widTxt,...
                    'yOfs',yOfsT,'fSzM',obj.fSzL);
                set(hTxtL,'HorizontalAlignment','Right');
                set(hTxtR,'HorizontalAlignment','Left');
                
                % sets the object handles
                obj.(tagStrL) = hTxtL;
                obj.(obj.tStrH{i,2}) = hTxtR;
            end
            
            % updates the panel/figure dimensions
            set(obj.hVB,'MinimumHeights',obj.Hmin,'Heights',obj.Hmin);
            [obj.hFig.Position(4),obj.hghtFig] = deal(sum(obj.Hmin));
            
        end
        
        % --------------------------------------- %
        % --- OTHER OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- box panel minimise/maximise callback function
        function boxPanelClick(obj, ~, ~, iPanel)
        
            % field retrieval
            hPanelC = obj.hPanel{iPanel};
            pPosS0 = obj.hPanelS{iPanel}.UserData;
            pbHght = obj.hVB.Heights;
            
            % updates the minimisation flag
            hPanelC.Minimized = ~hPanelC.Minimized;
            
            % updates the panel heights
            nwHght = obj.hghtRow + double(~hPanelC.Minimized)*pPosS0;
            pbHght(iPanel) = nwHght;
            resetObjPos(obj.hPanelS{iPanel},'Height',nwHght-obj.hghtRow)
            set(obj.hVB,'Heights',pbHght,'MinimumHeights',pbHght);
            
            % updates the figure position
            dHght = sum(pbHght) - obj.hFig.Position(4);
            resetObjPos(obj.hFig,'Bottom',-dHght,1);
            resetObjPos(obj.hFig,'Height',dHght,1);
            
        end        
        
    end
    
    % static class methods
    methods (Static)
        
        % --- retrieves the current plot data struct
        function pData = getPlotData(hPara)
            
            % retrieves the plot data struct
            pObj = getappdata(hPara,'pObj');
            pData = pObj.pData;
            
        end
        
    end    
    
end