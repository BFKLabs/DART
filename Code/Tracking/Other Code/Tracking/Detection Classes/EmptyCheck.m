classdef EmptyCheck < handle

    properties
    
        % important fields
        iApp
        iTube
        Qval
        isAnom
        isEmpty
        
        % object properties
        hFig        
        hPanelB
        hPanelT
        hTable
        hButton
        hTube
        
        %
        dY = 10;
        dYB = 8;
        
    end
    
    methods
        
        % class contructor
        function obj = EmptyCheck(Qval,isAnom)
            
            % sets the table fields
            [obj.Qval,obj.isAnom] = deal(Qval,isAnom);            
            [obj.iTube,obj.iApp] = find(isAnom);
            obj.isEmpty = true(length(obj.iApp),1);
            
            % initialises the gui objects
            obj.initObjects();
            
        end
        
        % gui initialisations
        function initObjects(obj)
            
            % global variables
            global H0T HWT
            
            % fixed dimensions
            bHght = 25;
            pHght = 40;
            tWid = 350;            
            
            % table dimensions
            nRow = length(obj.iApp);
            tHght = nRow*HWT+H0T;
            
            % sets up the table data fields
            cEdit = [false(1,3),true];
            cHdr = {'Region','Sub-Region','Quality (%)','Empty?'};
            Qscore = obj.Qval(obj.isAnom);
            tData0 = num2cell([obj.iApp(:),obj.iTube(:),Qscore(:)]);
            tData = [tData0,num2cell(obj.isEmpty)];
            cForm = {'numeric','numeric','numeric','logical'};
            
            % retrieves the tube object handles
            hTube0 = get(findall(0,'tag','figFlyTrack'),'hTube');
            obj.hTube = cellfun(@(x)(hTube0{x{1}}{x{2}}),...
                                        num2cell(tData0(:,1:2),2),'un',0);
            cellfun(@(x)(setObjVisibility(x,'on')),obj.hTube)
            arrayfun(@(x)(obj.updateTubeColour(x)),1:length(obj.hTube))
            
            % sets the callback functions
            cbFcnT = {@EmptyCheck.tableEditCallback,obj};
            cbFcnB = {@EmptyCheck.buttonCont,obj};
            
            % sets the table/button panel dimensions
            tPos = [obj.dY*[1,1],tWid,tHght];
            pPosB = [obj.dY*[1,1],tPos(3)+2*obj.dY,pHght];
            bPos = [obj.dY,obj.dYB,tPos(3),bHght];
            
            % sets the dimensions of the table panel
            yPosT = sum(pPosB([2,4]))+obj.dY;
            pPosT = [obj.dY,yPosT,pPosB(3),tPos(4)+2*obj.dY];
            
            % sets the figure height
            fHght = sum(pPosT([2,4]))+obj.dY;
            fPos = [500,500,pPosB(3)+2*obj.dY,fHght];
            
            % creates the figure object
            obj.hFig = figure('Unit','Pixels',...
                              'Position',fPos,...
                              'NumberTitle','off',...
                              'Name','Anomalous Region Check',...
                              'ToolBar','none',...
                              'MenuBar','none',...
                              'CloseRequestFcn',[]);
            
            % creates the panels
            obj.hPanelT = uipanel('Title','',...
                                  'Units','Pixels',...
                                  'Position',pPosT);
            obj.hPanelB = uipanel('Title','',...
                                  'Units','Pixels',...
                                  'Position',pPosB);
            
            % creates the table and button
            obj.hTable = uitable(obj.hPanelT,'Units','Pixels',...
                                             'Position',tPos,...
                                             'ColumnName',cHdr,...
                                             'ColumnEditable',cEdit,...
                                             'ColumnFormat',cForm,...
                                             'Data',tData,...
                                             'CellEditCallback',cbFcnT);
            obj.hButton = uicontrol('Parent',obj.hPanelB,...
                                    'Style','PushButton',...
                                    'Units','Pixels',...
                                    'Position',bPos,...
                                    'String','Finish Initial Tracking',...
                                    'FontUnits','Pixels',...
                                    'FontSize',12,...
                                    'FontWeight','bold',...
                                    'Callback',cbFcnB);
            
            % resizes the table columns
            autoResizeTableColumns(obj.hTable)
            
            % adds a wait until the user is finished
            uiwait(obj.hFig)
                                
        end        
        
        % --- closes the window
        function close(obj)
            
            delete(obj.hFig)
            
        end
        
        % --- updates the tube colours based on the selection
        function updateTubeColour(obj,iTube)
            
            col = 'gr';
            set(obj.hTube{iTube},'facecolor',col(1+obj.isEmpty(iTube)))
            
        end
        
    end
    
    methods(Static)

        % --- callback function for editing the table
        function tableEditCallback(hObj,evnt,obj)
            
            % updates the empty flag
            iRow = evnt.Indices(1);
            obj.isEmpty(iRow) = evnt.NewData;
            obj.updateTubeColour(iRow)
            
        end
        
        % --- callback function for clicking the continue button
        function buttonCont(hObj,evnt,obj)
            
            % makes the tube region invisible again
            cellfun(@(x)(setObjVisibility(x,'off')),obj.hTube)
            
            % closes the object
            obj.close();
            
        end        
        
    end

end
