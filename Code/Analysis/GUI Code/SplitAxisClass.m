classdef SplitAxisClass < handle
    
    % class properties
    properties
        % main object fields
        hFigM
        
        % object handles
        hFig        
        hEdit
        hTable
        hBut
        
        % fixed object dimensions        
        dX = 10;
        dXH = 5;
        tSz = 12;
        nRowT = 4;
        widTxt = [75,95];
        xBut = [8,137];
        xTxt = [5,125];
        hghtTxt = 16;
        hghtBut = 25;
        hghtEdit = 22;
        hghtPanelC = 40;
        widBut = 125;
        widFig = 290;
        widEdit = 40;
        
        % variable object dimensions
        y0Txt
        hghtFig
        widPanel
        hghtPanel
        widTable
        hghtTable        
        
        % other class fields
        nRow
        nCol
        
        
    end
    
    % class methods
    methods
        % --- class constructor
        function obj = SplitAxisClass(hFigM)
        
            % sets the input
            obj.hFigM = hFigM;
            
            % initialises the class fields and objects
            obj.initClassFields();
            obj.initObjProps();
            
            % centers the figure and makes it visible
            centreFigPosition(obj.hFig,2);
            setObjVisibility(obj.hFig,1);
            
        end
        
        % --------------------------------------- %
        % --- OBJECT INITIALISATION FUNCTIONS --- %
        % --------------------------------------- %        
        
        % --- initialises the object class fields
        function initClassFields(obj)
            
            % global variables
            global H0T HWT              
            
            % calculates the panel dimensions
            obj.widPanel = obj.widFig - 2*obj.dX;
            obj.widTable = obj.widPanel - 2*obj.dX;
                        
            % calculates the table dimensions
            obj.hghtTable = H0T + HWT*obj.nRowT;    
            obj.hghtPanel = obj.hghtPanelC + obj.hghtTable + ...
                            obj.hghtTxt + 2*obj.dX;
            
            % sets the figure height
            obj.hghtFig = obj.hghtPanelC + obj.hghtPanel + 3*obj.dX;
            
            % sets the text object vertical location
            obj.y0Txt = obj.dXH + obj.hghtPanelC + obj.hghtTable;
            
        end
        
        % --- initialises the class objects
        function initObjProps(obj)
            
            % deletes any previous GUIs
            hPrev = findall(0,'tag','figSplitAxis');
            if ~isempty(hPrev); delete(hPrev); end            
           
            % --------------------------- %
            % --- MAIN FIGURE OBJECTS --- %
            % --------------------------- %            
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % creates the figure object
            obj.hFig = figure('Position',fPos,'tag','figSplitAxis',...
                              'MenuBar','None','Toolbar','None',...
                              'Name','Split Plot Axes','Resize','off',...
                              'NumberTitle','off','Visible','off');               

            % -------------------------------------- %
            % --- SPLIT AXES INFORMATION OBJECTS --- %
            % -------------------------------------- %
            
            % field strings
            pStr = {'nRow','nCol'};
            tStr = {'Row Count: ','Column Count: '};
            bStr = {'Reset Regions','Combine Regions'};
            cNames = {'Region','Left','Bottom','Width','Height'};            
            
            % callback functions
            eFcn = @obj.editChangePara;  
            tFcn = @obj.tableCellChange;
            bFcn = {@obj.applyChanges,@obj.closeWindow};
            
            % creates the experiment combining data panel
            yPos0 = 2*obj.dX + obj.hghtPanelC;
            pPos = [obj.dX,yPos0,obj.widPanel,obj.hghtPanel];
            hPanel = uipanel(obj.hFig,'Title','','Units',...
                                      'Pixels','Position',pPos);
             
            % creates the table object
            tPos = [obj.dX,obj.hghtPanelC,obj.widTable,obj.hghtTable];
            obj.hTable = uitable(hPanel,'Position',tPos,'Data',[],...
                     'ColumnName',cNames,'CellEditCallback',tFcn,...
                     'ColumnEditable',false(1,length(cNames)),...
                     'RowName',[]);           
           
            %
            for i = 1:length(pStr)
                % creates the text labels
                tPos = [obj.xTxt(i),obj.y0Txt-3,obj.widTxt(i),obj.hghtEdit];
                uicontrol(hPanel,'Style','Text','String',tStr{i},...
                              'Units','Pixels','Position',tPos,...
                              'FontWeight','Bold','FontUnits','Pixels',...
                              'HorizontalAlignment','right',...
                              'FontSize',obj.tSz);  
                          
                % creates the text labels
                xPos0 = obj.xTxt(i) + obj.widTxt(i);
                ePos = [xPos0,obj.y0Txt,obj.widEdit,obj.hghtEdit];
                uicontrol(hPanel,'Style','Edit','String','1',...
                              'Units','Pixels','Position',ePos,...
                              'Callback',eFcn,'UserData',pStr{i});                          
                
                % creates the button objects
                bPos = [obj.xBut(i),obj.dX-2,obj.widBut,obj.hghtBut];
                uicontrol(hPanel,'Style','PushButton','String',bStr{i},...
                              'Callback',bFcn{i},'FontWeight','Bold',...
                              'FontUnits','Pixels','FontSize',obj.tSz,...
                              'Units','Pixels','Position',bPos);                
            end
                     
            % resizes the table columns
            autoResizeTableColumns(obj.hTable);            
            
            % ------------------------------ %
            % --- CONTROL BUTTON OBJECTS --- %
            % ------------------------------ %                          
                 
            % initialisations
            bStrC = {'Apply Changes','Close Window'};
            bFcnC = {@obj.applyChanges,@obj.closeWindow};
            
            % creates the experiment combining data panel 
            pPosC = [obj.dX,obj.dX,obj.widPanel,obj.hghtPanelC];
            hPanelC = uipanel(obj.hFig,'Title','','Units',...
                                       'Pixels','Position',pPosC); 
            
            % creates the control button objects
            for i = 1:length(bStrC)
                bPosC = [obj.xBut(i),obj.dX-2,obj.widBut,obj.hghtBut];
                uicontrol(hPanelC,'Style','PushButton','String',bStrC{i},...
                              'Callback',bFcnC{i},'FontWeight','Bold',...
                              'FontUnits','Pixels','FontSize',obj.tSz,...
                              'Units','Pixels','Position',bPosC);
            end            
            
        end
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- callback function for editting the table
        function tableCellChange(obj,hObject,event)
            
            
            
        end
        
        % --- callback function for editting the parameters
        function editChangePara(obj,hObject,event)
            
            
        end        
        
        % --- callback function for applying changes
        function applyChanges(obj,hObject,event)
            
            
        end
        
        % --- callback function for closing the window
        function closeWindow(obj,hObject,event)
            
            delete(obj.hFig);
            
        end        
        
        % ----------------------- %
        % --- OTHER FUNCTIONS --- %
        % ----------------------- %        
        
    end
    
    % static class methods
    methods (Static)
        
        
    end
    
end
    