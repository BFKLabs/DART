classdef EmptyCheck < handle

    properties
    
        % important fields
        fP
        iApp
        iTube        
        hFigM
        isAnom
        isEmpty
        showMark
        hasPos
        
        % object properties
        hFig        
        hPanelB
        hPanelT
        hTable
        hButC
        hTube
        hMark
        
        % parameters
        dY = 10;
        dYB = 8;
        mSz = 10;
        nBut = 3;
        
    end
    
    methods
        
        % class contructor
        function obj = EmptyCheck(fPos,isAnom)
            
            % main field set
            obj.fP = fPos;
            obj.isAnom = isAnom;
            obj.hFigM = findall(0,'tag','figFlyTrack');
            
            % sets the table fields            
            [obj.iTube,obj.iApp] = find(isAnom);
            obj.isEmpty = true(length(obj.iApp),1);
            
            % determines the region position flags
            obj.hasPos = obj.detRegionPosFlags();
            obj.showMark = obj.hasPos;

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
            cEdit = [false(1,2),true(1,2)];
            cHdr = {'Region','Sub-Region','Marker','Empty?'};
            tData0 = num2cell([obj.iApp(:),obj.iTube(:)]);
            tData = [tData0,num2cell([obj.showMark,obj.isEmpty])];
            cForm = {'numeric','numeric','logical','logical'};
            
            % retrieves the tube object handles
            hTube0 = obj.hFigM.mkObj.hTube;
            obj.hTube = cellfun(@(x)(hTube0{x{1}}{x{2}}),...
                                        num2cell(tData0(:,1:2),2),'un',0);
            cellfun(@(x)(setObjVisibility(x,'on')),obj.hTube)
            arrayfun(@(x)(obj.updateTubeColour(x)),1:length(obj.hTube))
            
            % sets the callback functions
            cbFcnT = @obj.tableEditCallback;
            cbFcnB = {@obj.buttonAddAll,...
                      @obj.buttonRemoveAll,...
                      @obj.buttonCont};
            
            % sets the table/button panel dimensions
            tPos = [obj.dY*[1,1],tWid,tHght];
            pPosB = [obj.dY*[1,1],tPos(3)+2*obj.dY,pHght];            
            
            % sets the dimensions of the table panel
            yPosT = sum(pPosB([2,4]))+obj.dY;
            pPosT = [obj.dY,yPosT,pPosB(3),tPos(4)+2*obj.dY];
            
            % sets the figure height
            fHght = sum(pPosT([2,4]))+obj.dY;
            fPos = [500,500,pPosB(3)+2*obj.dY,fHght];
            
            % sets up the table background colours
            bgCol = ones(size(tData,1),3);
            bgCol(~obj.hasPos,:) = 0.8;

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
            
            % creates the table             
            obj.hTable = uitable(obj.hPanelT,'Units','Pixels', ...
                'Position',tPos,'ColumnName',cHdr,'Data',tData,...
                'ColumnEditable',cEdit,'ColumnFormat',cForm,...
                'CellEditCallback',cbFcnT,'BackgroundColor',bgCol);
                                  
            % creates the control button objects
            obj.hButC = cell(obj.nBut,1);
            bWid = (tPos(3)-(obj.nBut-1)*obj.dY)/obj.nBut;
            bStr = {'Add All','Remove All','Finalise Tracking'};            
            for i = 1:obj.nBut
                lbPos = i*obj.dY + (i-1)*bWid;
                bPos = [lbPos,obj.dYB,bWid,bHght];
                obj.hButC{i} = uicontrol('Parent',obj.hPanelB,...
                        'Style','PushButton','Units','Pixels',...
                        'Position',bPos,'String',bStr{i},...
                        'FontUnits','Pixels','FontSize',12,...
                        'FontWeight','bold','Callback',cbFcnB{i});
            end
            
            % disables the add all button 
            setObjEnable(obj.hButC{1},0)
            setObjEnable(obj.hButC{2},any(obj.hasPos))
                                
            % retrieves the main axes image handle
            hPanelP = findall(obj.hFigM,'tag','panelImg');
            hAx = findall(hPanelP,'type','axes');
            
            % creates the plot markers
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
        
        % --- determines the region position flags
        function hasP = detRegionPosFlags(obj)

            % memory allocation
            hasP = true(length(obj.iApp),1);

            % determines if each "empty" region has registered any
            % positional values (if not, they can't be selected)
            for i = 1:length(obj.iApp)
                [iT,iA] = deal(obj.iTube(i),obj.iApp(i));
                fPT = cell2mat(cellfun(@(z)(cell2mat(cellfun...
                    (@(x)(x(iT,:)),z(iA,:)','un',0))),obj.fP,'un',0));
                hasP(i) = ~all(isnan(fPT(:)));
            end

        end

        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- callback function for editing the table
        function tableEditCallback(obj,hTable,evnt)
            
            % updates the empty flag
            [iRow,iCol] = deal(evnt.Indices(1),evnt.Indices(2));
            
            switch iCol
                case 3
                    if obj.hasPos(iRow)
                        obj.showMark(iRow) = evnt.NewData;
                        obj.updatePlotMarkers()                    
                    else
                        hTable.Data{iRow,iCol} = false;
                    end

                case 4
                    if obj.hasPos(iRow)
                        obj.isEmpty(iRow) = evnt.NewData;
                        obj.updateTubeColour(iRow)

                        hP = obj.hasPos;
                        setObjEnable(obj.hButC{1},any(~obj.isEmpty & hP))
                        setObjEnable(obj.hButC{2},any(obj.isEmpty & hP))
                    else
                        hTable.Data{iRow,iCol} = true;
                    end
            end
            
        end
        
        % --- closes the window
        function closeGUI(obj)
            
            delete(obj.hFig)
            
        end        
        
        % -------------------------------- %
        % --- CONTROL BUTTON FUNCTIONS --- %
        % -------------------------------- %        

        % --- callback function for clicking the add all button
        function buttonAddAll(obj,hObj,~)
            
            % updates the marker flags
            hP = obj.hasPos;
            [obj.showMark(hP),obj.isEmpty(hP)] = deal(true);
            
            % updates the plot markers and tube colours
            obj.updatePlotMarkers()
            obj.updateTubeColour()             
            
            % updates the table data
            Data = get(obj.hTable,'Data');
            Data(:,3:4) = num2cell([obj.showMark,obj.isEmpty]);
            set(obj.hTable,'Data',Data)
            
            % updates the button enabled properties
            setObjEnable(hObj,0);
            setObjEnable(obj.hButC{2},1);
            
        end
                
        % --- callback function for clicking the remove all button
        function buttonRemoveAll(obj,hObj,~)
            
            % updates the marker flags   
            hP = obj.hasPos;
            [obj.showMark(hP),obj.isEmpty(hP)] = deal(false);
                
            % updates the table data
            Data = get(obj.hTable,'Data');
            Data(:,3:4) = num2cell([obj.showMark,obj.isEmpty]);
            set(obj.hTable,'Data',Data)            
            
            % updates the plot markers and tube colours
            obj.updatePlotMarkers()
            obj.updateTubeColour()    

            % updates the button enabled properties
            setObjEnable(hObj,0);
            setObjEnable(obj.hButC{1},1);            
            
        end        
        
        % --- callback function for clicking the continue button
        function buttonCont(obj,~,~)
            
            % makes the tube region invisible again
            cellfun(@(x)(setObjVisibility(x,'off')),obj.hTube)
            
            % deletes the plot markers
            delete(obj.hMark);
            
            % closes the object
            obj.closeGUI();
            
        end                        

        % ----------------------- %
        % --- OTHER FUNCTIONS --- %
        % ----------------------- %        
        
        % --- updates the tube colours based on the selection
        function updateTubeColour(obj,iTube)
            
            % initialisations
            col = 'gr';
            
            % updates the tube colours
            if exist('iTube','var')
                set(obj.hTube{iTube},'facecolor',col(1+obj.isEmpty(iTube)))
            else
                cellfun(@(x,y)(set(x,'facecolor',col(1+y))),...
                                        obj.hTube,num2cell(obj.isEmpty))
            end
            
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

end
