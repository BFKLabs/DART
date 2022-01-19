classdef EmptyCheck < handle

    properties
    
        % important fields
        fP
        iApp
        iTube
        Qval
        hFigM
        isAnom
        isEmpty
        showMark
        
        % object properties
        hFig        
        hPanelB
        hPanelT
        hTable
        hButton
        hTube
        hMark
        
        % parameters
        dY = 10;
        dYB = 8;
        mSz = 10;
        
    end
    
    methods
        
        % class contructor
        function obj = EmptyCheck(fPos,Qval,isAnom)
            
            % main field set
            obj.fP = fPos;
            [obj.Qval,obj.isAnom] = deal(Qval,isAnom);            
            obj.hFigM = findall(0,'tag','figFlyTrack');
            
            % sets the table fields            
            [obj.iTube,obj.iApp] = find(isAnom);
            obj.showMark = true(length(obj.iApp),1);
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
            tWid = 400;
            nRowMax = 20;
            
            % table dimensions
            nRow = min(nRowMax,length(obj.iApp));
            tHght = nRow*HWT+H0T;
            
            % sets up the table data fields
            cEdit = [false(1,3),true(1,2)];
            cHdr = {'Region','Sub-Region','Quality','Marker','Empty?'};
            Qscore = obj.Qval(obj.isAnom);
            tData0 = num2cell([obj.iApp(:),obj.iTube(:),Qscore(:)]);
            tData = [tData0,num2cell([obj.showMark,obj.isEmpty])];
            cForm = {'numeric','numeric','numeric','logical','logical'};
            
            % retrieves the tube object handles
            hTube0 = get(obj.hFigM,'hTube');
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
                              'CloseRequestFcn',[],...
                              'Tag','figCheckEmpty');
            
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
                                
            % creates the plot markers
            hAx = findall(obj.hFigM,'type','axes');
            hold(hAx,'on')
            obj.hMark = plot(hAx,NaN,NaN,'yo','MarkerSize',obj.mSz,...
                                 'tag','hMarkE');
            hold(hAx,'off')
            
            % updates the plot markers
            obj.updatePlotMarkers()
            
            % resizes the table columns
            autoResizeTableColumns(obj.hTable)
            
            % sets the object into the gui
            setappdata(obj.hFig,'obj',obj)
            centreFigPosition(obj.hFig,2);
            
            % adds a wait until the user is finished
            uiwait(obj.hFig)
                                
        end        
        
        % --- closes the window
        function closeGUI(obj)
            
            delete(obj.hFig)
            
        end
        
        % --- updates the tube colours based on the selection
        function updateTubeColour(obj,iTube)
            
            col = 'gr';
            set(obj.hTube{iTube},'facecolor',col(1+obj.isEmpty(iTube)))
            
        end
        
        % --- updates the plot markers
        function updatePlotMarkers(obj)
            
            % retrieves the current phase/frame
            bgObj = get(obj.hFigM,'bgObj');
            [iPh,iFrm] = deal(bgObj.iPara.cPhase,bgObj.iPara.cFrm);
            fP0 = obj.fP{iPh}(:,iFrm);            
            
            % sets the marker plot coordinates (removes unselected)
            fPT = cell2mat(arrayfun(@(x,y)...
                            (fP0{x}(y,:)),obj.iApp,obj.iTube,'un',0));
            fPT(~obj.showMark,:) = NaN;            
                        
            % updates the plot coordinates
            set(obj.hMark,'xdata',fPT(:,1),'ydata',fPT(:,2))     
            
        end
        
    end
    
    methods(Static)

        % --- callback function for editing the table
        function tableEditCallback(hObj,evnt,obj)
            
            % updates the empty flag
            [iRow,iCol] = deal(evnt.Indices(1),evnt.Indices(2));
            
            switch iCol
                case 4
                    obj.showMark(iRow) = evnt.NewData;
                    obj.updatePlotMarkers()                    
                case 5
                    obj.isEmpty(iRow) = evnt.NewData;
                    obj.updateTubeColour(iRow)
            end
            
        end
        
        % --- callback function for clicking the continue button
        function buttonCont(hObj,evnt,obj)
            
            % makes the tube region invisible again
            cellfun(@(x)(setObjVisibility(x,'off')),obj.hTube)
            
            % deletes the plot markers
            delete(obj.hMark);
            
            % closes the object
            obj.closeGUI();
            
        end        
        
    end

end
