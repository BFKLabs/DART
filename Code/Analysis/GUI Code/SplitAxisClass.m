classdef SplitAxisClass < handle
    
    % class properties
    properties
        
        % main object fields
        hFigM
        hGUI
        
        % object handles
        hAx
        hFig        
        hEdit
        hTable
        hBut
        hButC
        
        % other object handles
        hTic
        hTimer        
        
        % class fields
        sPara
        sPara0
        
        % movement flags         
        hMove 
        tMove = 0.5;
        isMove = false;
        
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
        
        % sub-region parameters
        tCol = {'k',0.5*[1 1 1]};
        dXR = 0.01;
        dYR = 0.03;
        pTolN = 0.005;
        fSz = 24;
        lWid = 3;
        xyDel = 1.5;
        
        % parameters
        tol = 0.001;
        tol2 = 0.01;
        del = 0.05;
        tStr = {'V','H'};        
        
        % variable object dimensions
        y0Txt
        hghtFig
        widPanel
        hghtPanel
        widTable
        hghtTable        
        
        % other class fields
        isOld        
        dAtol = 1e-6;
        hasCtrl = false;
        isChange = false;
        isInit = false;      
        isUpdating = false;
        tlStr = 'top line';
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = SplitAxisClass(hFigM)
        
            % sets the input
            obj.hFigM = hFigM;
            obj.hGUI = guidata(hFigM);
            
            % initialises the class fields and objects
            obj.initClassFields();
            obj.initObjProps();
            obj.initMovementTimer();            
            obj.setMainGUIProps('off')
            
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
            
            % memory allocation
            obj.hMove = cell(1,3);
            obj.isOld = isOldIntObjVer();
            
            % retrieves the sub-plot parameter structs
            [obj.sPara,obj.sPara0] = deal(getappdata(obj.hFigM,'sPara'));
            
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
           
            % clears all the plot panel objects
            hPanelP = findall(obj.hGUI.panelPlot,'tag','subPanel');
            if ~isempty(hPanelP); delete(hPanelP); end            
            
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
            tStrP = {'Row Count: ','Column Count: '};
            bStr = {'Reset Regions','Combine Regions'};
            cNames = {'Region','Left','Bottom','Width','Height'};            
            [obj.hBut,obj.hEdit] = deal(cell(length(bStr),1));
            
            % callback functions
            eFcn = @obj.editChangePara; 
            bFcn = {@obj.clearRegions,@obj.combineRegions};
            
            % creates the experiment combining data panel
            yPos0 = 2*obj.dX + obj.hghtPanelC;
            pPos = [obj.dX,yPos0,obj.widPanel,obj.hghtPanel];
            hPanel = uipanel(obj.hFig,'Title','','Units',...
                                      'Pixels','Position',pPos);            
             
            % creates the table object
            tPos = [obj.dX,obj.hghtPanelC,obj.widTable,obj.hghtTable];
            obj.hTable = uitable(hPanel,'Position',tPos,'Data',[],...
                     'ColumnName',cNames,'RowName',[],...
                     'ColumnEditable',false(1,length(cNames)));           
           
            % creates the button/parameter objects
            for i = 1:length(pStr)
                % creates the text labels
                tPos = [obj.xTxt(i),obj.y0Txt-3,obj.widTxt(i),obj.hghtEdit];
                uicontrol(hPanel,'Style','Text','String',tStrP{i},...
                        'Units','Pixels','Position',tPos,...
                        'FontWeight','Bold','FontUnits','Pixels',...
                        'HorizontalAlignment','right',...
                        'FontSize',obj.tSz);  
                          
                % creates the text labels                
                xPos0 = obj.xTxt(i) + obj.widTxt(i);
                pVal = getStructField(obj.sPara,pStr{i});
                ePos = [xPos0,obj.y0Txt,obj.widEdit,obj.hghtEdit];
                obj.hEdit{i} = uicontrol(hPanel,'Style','Edit',...
                        'String',num2str(pVal),'Units','Pixels',...
                        'Position',ePos,'UserData',pStr{i},'Callback',eFcn);
                
                % creates the button objects
                bPos = [obj.xBut(i),obj.dX-2,obj.widBut,obj.hghtBut];
                obj.hBut{i} = uicontrol(hPanel,'Style','PushButton',...
                        'String',bStr{i},'Callback',bFcn{i},'FontWeight',...
                        'Bold','FontUnits','Pixels','FontSize',obj.tSz,...
                        'Units','Pixels','Position',bPos,'Enable','off');
            end
                     
            % sets the other object properties
            autoResizeTableColumns(obj.hTable);            
            setObjEnable(obj.hBut{1},size(obj.sPara.pos,1)>1)
            
            % sets up the axis table data
            obj.setupAxisTable();
            
            % ------------------------------ %
            % --- CONTROL BUTTON OBJECTS --- %
            % ------------------------------ %                          
                 
            % initialisations
            bStrC = {'Apply Changes','Close Window'};
            bFcnC = {@obj.applyChanges,@obj.closeWindow};
            obj.hButC = cell(length(bStrC),1);
            
            % creates the experiment combining data panel 
            pPosC = [obj.dX,obj.dX,obj.widPanel,obj.hghtPanelC];
            hPanelC = uipanel(obj.hFig,'Title','','Units',...
                                       'Pixels','Position',pPosC); 
            
            % creates the control button objects
            for i = 1:length(bStrC)
                bPosC = [obj.xBut(i),obj.dX-2,obj.widBut,obj.hghtBut];
                obj.hButC{i} = uicontrol(hPanelC,'Style','PushButton',...
                        'String',bStrC{i},'Callback',bFcnC{i},...
                        'FontWeight','Bold','FontUnits','Pixels',...
                        'FontSize',obj.tSz,'Units','Pixels',...
                        'Position',bPosC);
                setObjEnable(obj.hButC{i},i==2);
            end                        
            
            % ------------------------------ %
            % --- CONTROL BUTTON OBJECTS --- %
            % ------------------------------ %                
            
            % initialisations
            tagStr = 'axesCustomPlot';
            
            % clears the main axis of any existing axis
            hAxPr = findall(obj.hGUI.panelPlot,'type','axes'); 
            if ~isempty(hAxPr); delete(hAxPr); end
            
            % sets the key press/release functions
            fcnKP = @obj.keyPressFcn;
            fcnKR = @obj.keyReleaseFcn;    

            % sets the axis properties
            obj.hAx = axes();
            set(obj.hAx,'parent',obj.hGUI.panelPlot,'tag',tagStr,...
                    'position',[0 0 1 1],'units','pixels','box','on',...
                    'xticklabel',[],'xtick',[],'yticklabel',[],'ytick',[]); 
                
            % sets the main figure key press/release callback functions
            set(obj.hFigM,'KeyPressFcn',fcnKP,'KeyReleaseFcn',fcnKR)
            
            % creates the sub-region objects
            obj.createSubRegions();
            
        end
        
        % --- initialises the movement timer
        function initMovementTimer(obj)
            
            % removes any previous timer objects
            hTimerPr = timerfind('tag','hMoveTimer');
            if isempty(hTimerPr)
                wState = warning('off','all');
                delete(hTimerPr); 
                warning(wState);
            end
            
            % initialises the countdown timer object
            obj.hTimer = timer('tag','hMoveTimer');
            set(obj.hTimer,'Period',0.1,'ExecutionMode','FixedRate',...
                           'TimerFcn',@obj.timerCDownFcn);                       
                       
            % initialises the tic object and starts the timer
            obj.hTic = tic;
            start(obj.hTimer);
            
        end  
        
        % ----------------------------------- %
        % --- SUB-REGION OBJECT FUNCTIONS --- %
        % ----------------------------------- %        
        
        % --- creates the sub-region objects
        function createSubRegions(obj)
            
            % memory allocations and other initialsiations
            [pXL,pYL] = deal(cell(1,2));
            axPos = get(obj.hAx,'position');            
            [nReg,sz] = deal(size(obj.sPara.pos,1),roundP(axPos([4,3])));
            hNum = cell(nReg,1);
            
            % clears and sets up the axis object
            axis(obj.hAx);
            obj.clearAxesObjects();
            hold(obj.hAx,'on');         
            
            % ----------------------------------------- %
            % --- LINE OBJECT POSITION CALCULATIONS --- %
            % ----------------------------------------- %

            % retrieves the number of regions (only if regions are split)
            if nReg > 1
                [pXL,pYL] = obj.detRegionLines(sz);   
            end
            
            % ---------------------------- %
            % --- LINE OBJECT CREATION --- %
            % ---------------------------- %
            
            % button down callback function
            bdFcn = @obj.fillButtonDownFcn;

            % creates all the fill objects
            for i = 1:nReg
                % creates the fill/text objects
                [vX,vY] = obj.pos2vec(obj.sPara.pos(i,:));
                fill(vX,vY,'w','tag','hSel','UserData',i,'EdgeColor',...
                           'none','ButtonDownFcn',bdFcn,'parent',obj.hAx);        
            end

            % creates all the sub-region marker numbers
            for i = 1:nReg
                xT = obj.sPara.pos(i,1) + obj.dXR;
                yT = obj.sPara.pos(i,2) + obj.dYR;
                hNum{i} = text(xT,yT,num2str(i),'tag','hNum',...
                              'fontsize',obj.fSz,'parent',obj.hAx,...
                              'fontweight','bold','Color',obj.tCol{1});
            end      
            
            % add in the line objects
            if nReg > 1
                % retrieves the locations of the text number objects
                pNum0 = cellfun(@(x)(get(x,'position')),hNum,'un',0);    
                pNum = cell2mat(pNum0);

                % creates all the line objects
                for i = 1:length(pXL)
                    % converts the line objects into cell arrays
                    pXLC = num2cell(pXL{i},2);
                    pYLC = num2cell(pYL{i},2);
                    
                    % determines the number objects associated with each line
                    if i == 1
                        iReg = cellfun(@(x,y)(find((abs(...
                                (pNum(:,1)-obj.dXR) - x(1)) < obj.pTolN) & ...
                                (pNum(:,2) > y(1) & (pNum(:,2) < y(2))))),...
                                pXLC,pYLC,'un',0);   
                    else
                        iReg = cellfun(@(x,y)(find((abs(...
                                (pNum(:,2)-obj.dYR) - y(1)) < obj.pTolN) & ...
                                (pNum(:,1) > x(1) & (pNum(:,1) < x(2))))),...
                                pXLC,pYLC,'un',0);               
                    end

                    for j = 1:size(pXL{i},1)
                        % creates the line object
                        if isempty(iReg{j})
                            obj.createLineObj...
                                (pXL{i}(j,:),pYL{i}(j,:),j,i,[]);
                        else
                            obj.createLineObj(pXL{i}(j,:),...
                                pYL{i}(j,:),j,i,hNum(iReg{j}));
                        end
                    end
                end
            end            
            
            % plots the surrounding regions
            tStrS = 'hEdge';
            plot(obj.hAx,[0 1],[0 0],'k','linewidth',obj.lWid,'tag',tStrS);
            plot(obj.hAx,[0 1],[1 1],'k','linewidth',obj.lWid,'tag',tStrS);
            plot(obj.hAx,[0 0],[0 1],'k','linewidth',obj.lWid,'tag',tStrS);
            plot(obj.hAx,[1 1],[0 1],'k','linewidth',obj.lWid,'tag',tStrS);

            % sets the context-menu for the axis
            hold(obj.hAx,'on'); 
            set(obj.hAx,'xlim',[0 1],'ylim',[0 1])
            axis(obj.hAx,'ij');             
            
        end
        
        % --- Executes on mouse press over fill object.
        function fillButtonDownFcn(obj,~,~)
            
            % retrieves the parameter struct
            nReg = size(obj.sPara.pos,1);

            % if the window is split, and control is held, then change the 
            % selection properties of the fill object. otherwise, clear
            if obj.hasCtrl && (nReg > 1)    
                % determines the index/location of the clicked region
                iSub = obj.detClickSubplot();   
                hNum = findall(obj.hAx,'tag','hNum','String',num2str(iSub));

                % retrieves and updates the selection objects
                hSelT = findall(obj.hAx,'tag','hSel');    
                [~,iS] = sort(cell2mat(get(hSelT,'UserData')),'ascend');
                hSelT = hSelT(iS);

                % toggles the face color of the fill objects
                hSel = hSelT(iSub);    
                if isequal(get(hSel,'FaceColor'),[1 0 0])
                    % sets all the faces to white
                    set(hSel,'FaceColor','w');
                    set(hNum,'Color',obj.tCol{1});
                else
                    % retrieves and updates the number objects
                    set(hSel,'FaceColor','r');
                    set(hNum,'Color','w');        
                end       

                % resets the hit-test state for all the lines
                ii = cellfun(@(x)(isequal(x,[1 0 0])),get(hSelT,'FaceColor'));
                if any(ii)
                    % makes all lines immobile
                    obj.setLineHTState('off')        
                    setObjEnable(obj.hBut{2},sum(ii)>1)

                else
                    % makes all lines mobile again
                    obj.setLineHTState('on')
                    setObjEnable(obj.hBut{2},'off')
                end  
            else
            %     % retrieves and updates the selection objects
            %     if (~strcmp(get(handles.figSplitPlot,'SelectionType'),'alt'))
            %         hSel = findall(hAx,'tag','hSel','FaceColor','r');
            %         if (~isempty(hSel))
            %             % sets the face colours to white (unselected            
            %             hNum = findall(hAx,'tag','hNum','Color','w');
            %             
            %             % updates the properties of the number/selection fill objects            
            %             iNum = num2cell(sPara.isEmpty(str2double(get(hNum,'string'))));
            %             cellfun(@(x,y)(set(x,'Color',tCol{1+y})),num2cell(hNum),iNum)
            %             set(hSel,'FaceColor','w');            
            %         end
            %     end
            end            
            
        end
        
        % --- determines the subplot region that has been clicked
        function [iSub,pos] = detClickSubplot(obj)

            % retrieves the location of the click-point
            a = get(obj.hAx,'CurrentPoint');
            mP = [a(1,1) a(1,2)];

            % determines the 
            pos = obj.detAllRegionPos();

            % determines the string of the number whose location coincides 
            % with the clicked group region
            [L,LW] = deal(pos(:,1),sum(pos(:,[1 3]),2));
            [B,BH] = deal(pos(:,2),sum(pos(:,[2 4]),2));
            iSub = find((mP(1) > L) & (mP(1) < LW) & ...
                        (mP(2) > B) & (mP(2) < BH));

        end
        
        % --- determines the position vectors of all the subplot regions
        function pos = detAllRegionPos(obj)

            % retrieves the axis position vector
            aP = get(obj.hAx,'Position');

            % sets the indices of the horizontal/vertical lines
            [pSubV,pSubH] = obj.getAllLinePos(1);
            X = roundP(cellfun(@(x)(x(1,1)),pSubV),0.01);
            Y = roundP(cellfun(@(x)(x(1,2)),pSubH),0.01);

            % retrieves the positions of all the lines on the axis
            Im = obj.getRegionLineMap(pSubH,pSubV,aP);
            [~,bbGrp] = getGroupIndex(Im == 0,'BoundingBox');
            
            % calculates the global coordiantes
            posGSc = repmat(aP([3 4]),size(bbGrp,1),2);
            posG = [(bbGrp(:,1:2)) (bbGrp(:,3:4))]./posGSc;
            posG = roundP(posG,0.01);
            pos = zeros(size(posG,1),4);
            for i = 1:size(pos,1)
                % retrieves the x/y coordinates of the position vector
                [pX,pY] = obj.pos2vec(roundP(posG(i,:),0.01));

                % determines the x-points closes to the line objects
                if isempty(X)
                    % no vertical lines, so use frame limits
                    [xMin,xMax] = deal(0,1);
                else        
                    % otherwise, calculate the closest limits
                    xMin = min(1-any(pX == 0),X(argMin(abs(min(pX)-X))));
                    xMax = max(any(pX == 1),X(argMin(abs(max(pX)-X))));            
                end

                % determines the y-points closes to the line objects
                if isempty(Y)
                    % no horizontal lines, so use frame limits
                    [yMin,yMax] = deal(0,1);
                else
                    % otherwise, calculate the closest limits
                    yMin = min(1-any(pY == 0),Y(argMin(abs(min(pY)-Y))));
                    yMax = max(any(pY == 1),Y(argMin(abs(max(pY)-Y))));            
                end

                % sets the final position vector
                pos(i,:) = [xMin yMin (xMax-xMin) (yMax-yMin)];
            end

            % retrieves the locations of the subplot number objects
            [L,LW] = deal(pos(:,1),sum(pos(:,[1 3]),2));
            [B,BH] = deal(pos(:,2),sum(pos(:,[2 4]),2));            
            hNum = findall(obj.hAx,'tag','hNum');
            pNum = cell2mat(arrayfun(@(x)(get(x,'position')),hNum,'un',0));            
            iNum = arrayfun(@(x)(str2double(get(x,'string'))),hNum);
            [~,jj] = sort(iNum,'ascend');
            pNum = pNum(jj,:);

            % re-orders the position array to match the region numbering
            pos = pos(cellfun(@(x)(find((x(1) > L) & (x(1) < LW) & ...
                           (x(2) > B) & (x(2) < BH))),num2cell(pNum,2)),:);

        end        

        % --- determines the lines that surround each sub-region
        function [pXL,pYL] = detRegionLines(obj,sz)

            % memory allocation
            nReg = size(obj.sPara.pos,1);
            [pXL,pYL] = deal(cell(1,2));
            szScl = repmat(sz([2 1]),nReg,2);

            % calculates the side coordinates for each sub-region
            posG = obj.sPara.pos.*szScl + repmat([1 1 0 0],nReg,1);
            posXY = cellfun(@(x)...
                    (obj.calcPosSideCoord(x)),num2cell(posG,2),'un',0);

            % determines the region lines from the position array
            Bline = obj.getRegionLineBinary(posG,sz+1);
            iGrp = getGroupIndex(Bline);

            % sets the x/y coordinates of each line object
            [pX,pY] = deal(zeros(length(iGrp),2));
            for i = 1:length(iGrp)
                % sets the coordinates for the new line
                [Y,X] = ind2sub(sz+1,iGrp{i});

                % sets the edge extensions for horizontal/vertical lines
                if (range(X) < range(Y))
                    % line is vertical
                    pX(i,:) = mode(X)*[1 1];
                    pY(i,:) = [min(Y) max(Y)] + 2*[-1 1];
                else
                    % line is horizontal
                    pY(i,:) = mode(Y)*[1 1];
                    pX(i,:) = [min(X) max(X)] + 2*[-1 1];
                end
            end

            % determines which lines are horizontal or vertical
            isSet = NaN(length(iGrp),1);
            [isH,isV] = deal(diff(pY,[],2) == 0,diff(pX,[],2) == 0);

            % searches each of the sub-regions (from largest to smallest) 
            % determining which lines 
            [~,iPos] = sort(posG(:,3).*posG(:,4));
            for i = iPos'
                % goes through each of the 
                for j = 1:4    
                    if any(j == [1 2])
                        % checking a vertical side (has to have the same 
                        % x-location and y-location within limits of side)
                        ii = (abs(posXY{i}(j,1) - pX(:,1)) < 2) & isV & ...
                             ((pY(:,1)+obj.xyDel) >= posXY{i}(j,3)) & ...
                             ((pY(:,2)-obj.xyDel) <= posXY{i}(j,4));
                    else
                        % checking a horizontal side (has to have the same y-location
                        % and x-location within limits of side)            
                        ii = (abs(posXY{i}(j,3) - pY(:,1)) < 2) & isH & ...
                             ((pX(:,1)+obj.xyDel) >= posXY{i}(j,1)) & ...
                             ((pX(:,2)-obj.xyDel) <= posXY{i}(j,2));            
                    end

                    % if there are matching lines, then mark as being set
                    if any(ii)
                        isSet(ii) = true;
                        if sum(ii) > 1
                            % combines the coordinates of the two lines
                            k = find(ii);
                            pYnw = [min(pY(k,1),[],1) max(pY(k,2),[],1)];
                            pXnw = [min(pX(k,1),[],1) max(pX(k,2),[],1)];

                            % if so, then reset the coordinates of the lines
                            [pX(k(1),:),pY(k(1),:)] = deal(pXnw,pYnw);
                            [pX(k(2:end),:),pY(k(2:end),:)] = deal(NaN);                 
                        end
                    end
                end
            end

            % removes the nan rows from the arrays
            ii = ~isnan(pX(:,1));
            [pX,pY] = deal(pX(ii,:),pY(ii,:));   
            [isH,isV,isSet] = deal(isH(ii),isV(ii),isSet(ii));
            
            % determines if there are any orphan lines
            if any(~isSet)
                % if so, then determine the best match for these line     
                for i = find(~isSet)'
                    % determines the matching inline lines
                    if isH(i)
                        % case is for horizontal lines
                        pdY = abs(pX(:,[2 1])-repmat(pX(i,:),size(pX,1),1));
                        isMatch = (pY(:,1)==pY(i,1)) & isH & any(pdY==0,2); 
                    else
                        % case is for vertical lines
                        pdX = abs(pY(:,[2 1])-repmat(pY(i,:),size(pY,1),1));
                        isMatch = (pX(:,1)==pX(i,1)) & isV & any(pdX==0,2); 
                    end

                    % ensures the current line is not a match
                    isMatch(i) = false;

                    % combines the coordinates of the two lines
                    j = find(isMatch,1,'first');
                    pYnw = [min(pY([i,j],1),[],1) max(pY([i,j],2),[],1)];
                    pXnw = [min(pX([i,j],1),[],1) max(pX([i,j],2),[],1)];

                    % if so, then reset the coordinates of the lines
                    [pX(j,:),pY(j,:)] = deal(pXnw,pYnw);
                    [pX(i,:),pY(i,:)] = deal(NaN);        
                end

                % removes the nan rows from the arrays
                ii = ~isnan(pX(:,1));
                [pX,pY,isH,isV] = deal(pX(ii,:),pY(ii,:),isH(ii),isV(ii));    
            end

            % ensures the 
            [pX,pY] = deal(min(pX,sz(2)),min(pY,sz(1)));

            % sets the line coordinate arrays
            [pXL{1},pYL{1}] = deal(pX(isV,:)/sz(2),pY(isV,:)/sz(1));
            [pXL{2},pYL{2}] = deal(pX(isH,:)/sz(2),pY(isH,:)/sz(1));

        end
        
        % --------------------------------- %
        % --- GRIDLINE OBJECT FUNCTIONS --- %
        % --------------------------------- %         
        
        % --- create the line objects
        function hLine = createLineObj(obj,xL,yL,ind,type,hNum)

            % initialisations
            uData0 = [ind,type];
            
            % sets the limits based on the line type
            Lim = {xL,yL}; 
            Lim{type} = [0 1];
            tagStr = sprintf('hSub%s',obj.tStr{type});
            uData = {uData0,hNum,[xL(:),yL(:)],Lim};
            
            % creates the line object
            hLine = InteractObj('line',obj.hAx,{xL,yL});
            hLine.setObjMoveCallback(@obj.lineCallback);
            hLine.setConstraintRegion(Lim{1},Lim{2});
            hLine.setFields('tag',tagStr,'UserData',uData)

            % case is an old interactive object type
            hLine.setLineProps('Color','k','Linewidth',obj.lWid,...
                       'InteractionsAllowed','translate',...
                       'RemoveEnds','Yes');
            
            
        end
            
        % --- sets the line position callback
        function lineCallback(obj,varargin)

            % if updating or initialising then exit
            if obj.isUpdating || obj.isInit; return; end            
            
            % resets the clock timer
            isCont = true;
            obj.hTic = tic();
            obj.isChange = true;            

            % retrieves the line object handle
            switch length(varargin)
                case 1
                    [hLine,lPos] = deal(get(gco,'Parent'),varargin{1}); 
                case 2
                    if isa(varargin{1},'double')
                        [isCont,lPos] = deal(false,varargin{1});
                        if obj.isOld
                            hLine = get(varargin{2},'Parent');
                        else
                            hLine = varargin{2};
                        end
                    else
                        hLine = varargin{1};
                        lPos = varargin{2}.CurrentPosition();
                    end
            end

            % retrieves the userdata array
            uData = get(hLine,'UserData');
            [iType,hNum] = deal(uData{1},uData{2});
            
            % retrieves the locations of the numbers and
            % resets their locations depending on the type
            for i = 1:length(hNum)
                numPos = get(hNum{i},'Position');        
                if iType(2) == 1
                    % line is vertical
                    numPos(1) = (lPos(1,1)+obj.dXR);
                else
                    % line is horizontal
                    numPos(2) = (lPos(1,2)+obj.dYR);
                end

                % updates the positions
                set(hNum{i},'position',numPos);
            end

            % exits the function
            if ~isCont; return; end

            % determines if the line has moved recently
            if ~obj.isMove
                % if not, then determine if the line is free to move

                % initialisations and memory allocation
                [iP,iC] = deal(3-iType(2),iType(2));
                [obj.hMove,obj.isInit] = deal(cell(1,3),true);                    
                [A,p,jj] = deal(NaN(2),[4*obj.dXR,2*obj.dYR],cell(1,2));    

                % retrieves the stationary line ooordinates
                setappdata(obj.hAx,'hLine',hLine)

                % calculates the position offset for the line
                lPos0 = uData{3};
                [pSub{1},pSub{2}] = obj.getAllLinePos(1);
                dP = lPos0(1,iC) + obj.del*[-1 1];

                % determines if there are any matching perpendicular 
                % lines to the currently moving line
                for i = 1:2
                    for j = 1:2
                        % determines if the line is on the edge
                        if (lPos0(i,iP) == 0) || (lPos0(i,iP) == 1)
                            % if so, flag with a negative index
                            A(j,i) = -1;
                        else
                            % determines if the x/y locations of any of 
                            % the other lines match the moving line
                            ii = cellfun(@(x)(abs(x(i,iP)-lPos0(i,iP)) ...
                                <= obj.tol) && ((dP(j) >= x(1,iC)) && ...
                                (dP(j) <= x(2,iC))),pSub{iP});
                            if any(ii)
                                % if so, then set the index of the 
                                % perpendicular line
                                A(j,i) = find(ii);
                            end
                        end
                    end
                end                    

                % determines if all the perpendicular lines matched
                hSubP = findall(obj.hAx,'tag',['hSub',obj.tStr{iP}]);  
                if any(isnan(A(:)))
                    % if there are missing matches, then the line may have 
                    % to move with other co-linear lines. search for these 
                    % lines on either side until either (a) an edge is 
                    % reached, (b) the colinear line matches a 
                    % perpendicular line, or (c) there is no colinear line
                    % adjacent to the search line            

                    % retrieves the handles of the lines    
                    hSubC = findall(obj.hAx,'tag',['hSub',obj.tStr{iC}]);            
                    for i = 1:2
                        for j = 1:2                
                            % only search lines that are missing
                            if isnan(A(j,i))
                                [k,lPosC] = deal((1:2) ~= i,lPos0);                
                                while (1)                                        
                                    % determines the index of the line that is
                                    % coincident to the current line
                                    ii = obj.detCLIndices...
                                                    (lPosC,pSub,iC,iP,i,k);                                    
                                    if any(ii)
                                        % appends the coincident line to 
                                        % movement array
                                        obj.hMove{1} = [obj.hMove{1};...
                                                        hSubC(ii)];
                                        lPosC = obj.getLinePos(hSubC(ii));  

                                        % if new point is on edge, then exit the loop
                                        if (lPosC(i,iP) < obj.dAtol) || ...
                                           (lPosC(i,iP) > (1-obj.dAtol))
                                            break
                                        end

                                        % determines if the x/y locations of any of the
                                        % perperndicular lines match the current line                                        
                                        k1 = cellfun(@(x)(abs(x(i,iP)-lPosC(i,iP)) <= obj.tol) && ...
                                                ((dP(1) >= x(1,iC)) && (dP(1) <= x(2,iC))),pSub{iP});    
                                        k2 = cellfun(@(x)(abs(x(i,iP)-lPosC(i,iP)) <= obj.tol) && ...
                                                ((dP(2) >= x(1,iC)) && (dP(2) <= x(2,iC))),pSub{iP});                                                                                                    
                                        if any(k1) && any(k2)
                                            % if there is a match, then set 
                                            % the line into the movement 
                                            % array and exit the loop
                                            break
                                        end
                                    else
                                        % otherwise exit loop
                                        break
                                    end
                                end
                            end
                        end
                    end

                    % combines the lines into a single array
                    hC = num2cell([hLine;obj.hMove{1}(:)]);               
                else
                    % otherwise, set the colinear line to be the moved line
                    hC = num2cell(hLine);
                end

                % sets the limits of all the colinear lines
                hLineCL = cellfun(@(x)(obj.getLinePos(x)),hC(2:end),'un',0);
                lPosT = [lPos0;cell2mat(hLineCL)];        
                pLimC = [min(lPosT(:,iP)) max(lPosT(:,iP))];    

                % determines if  
                if ~isempty(pSub{iP})
                    % determines which perpendicular lines
                    ii = cellfun(@(x)((x(1,iP) >= pLimC(1)) && ...
                                      (x(1,iP) <= pLimC(2))),pSub{iP});
                    if any(ii)
                        %
                        dP = mean(lPosT(1,iC)) + obj.del*[-1 1];
                        
                        for i = 1:2
                            kk = cellfun(@(x)((x(i,iC) >= dP(1)) && ...
                                             (x(i,iC) <= dP(2))),pSub{iP});
                            obj.hMove{4-i} = hSubP(kk & ii);
                        end
                    end
                end

                % gets the userdata for the co-linear lines
                uDF = cell2cell(...
                        cellfun(@(x)(get(x,'UserData')),hC(:),'un',0));
                uD = cell2mat(uDF(:,1));

                % determines the parallel lines are in-line with the 
                % currently moving line (removes the current line from 
                % the index array). from this, determine which lines lie 
                % left/right (horizontally) or below/above
                % (vertically) wrt to the current moved line
                ii = cellfun(@(x)((x(2,iP)>=(pLimC(1)+obj.tol2)) && ...
                                  (x(1,iP)<(pLimC(2)-obj.tol2))),pSub{iC});

                ii((length(ii)+1)-uD(:,1)) = false;    
                jj{1} = ii & cellfun(@(x)(x(1,iC)<lPos0(1,iC)),pSub{iC});
                jj{2} = ii & cellfun(@(x)(x(1,iC)>lPos0(1,iC)),pSub{iC});

                % sets the limiting range for the currently moved line
                Lim = cellfun(@(x)(x'),num2cell(lPos0,1),'un',0);
                for i = 1:length(jj)
                    if ~any(jj{i})
                        % no other limit for limit, so use frame edge
                        Lim{iC}(i) = (i == 2);
                    else
                        if (i == 1)
                            % case is for the lower limit
                            Lim{iC}(i) = max(cellfun...
                                        (@(x)(x(1,iC)),pSub{iC}(jj{i})));
                        else
                            % case is for the upper limit
                            Lim{iC}(i) = min(cellfun...
                                        (@(x)(x(1,iC)),pSub{iC}(jj{i})));
                        end
                    end
                end

                % sets the offsets to the rectangle limits
                Lim{iC} = Lim{iC} + reshape(p(iC)*[1 -1],size(Lim{iC}));
                
                % updates the line constraining function               
                obj.updateLineConstrainFcn(hLine,Lim)        
                [obj.isInit,obj.isMove] = deal(false,true);
            end

            % updates the positions of the colinear/perpendicular lines
            obj.updateLinePos(obj.hMove{1},lPos,iType(2),1:2)
            obj.updateLinePos(obj.hMove{2},lPos,iType(2),2)
            obj.updateLinePos(obj.hMove{3},lPos,iType(2),1)

        end

        % --- updates the position of the line object
        function updateLinePos(obj,hLine,lPos,type,ind,varargin)

            % retrieves the line api handle and set the new position
            for i = 1:length(hLine)
                if nargin == 5
                    lPosNw = obj.getLinePos(hLine(i));
                    lPosNw(ind,type) = lPos(ind,type);
                else
                    lPosNw = lPos;
                end

                % resets the line position
                obj.isUpdating = true;
                setIntObjPos(hLine,lPosNw,obj.isOld,false);
                obj.isUpdating = false;

                if length(ind) == 2
                    if obj.isOld
                        hLineT = findall(hLine(i),'tag',obj.tlStr);
                    else
                        hLineT = hLine(i);
                    end
                    
                    % runs the line callback function
                    obj.lineCallback(lPosNw,hLineT);
                end
            end

        end

        % --- retrieves the location of all the line positions
        function [pSubV,pSubH] = getAllLinePos(obj,varargin)

            % retrieves the vertical marker positions
            hSubV = findall(obj.hAx,'tag','hSubV');
            if nargin == 1
                lPosV = arrayfun(@(x)(obj.getLinePos(x,1)),hSubV);
                pSubV = [0;sort(lPosV,'ascend');1];
            else
                pSubV = arrayfun(@(x)(obj.getLinePos(x)),hSubV,'un',0);
            end

            % retrieves the horizontal marker positions
            hSubH = findall(obj.hAx,'tag','hSubH');
            if nargin == 1
                lPosH = arrayfun(@(x)(obj.getLinePos(x,2)),hSubH);
                pSubH = [0;(1-sort(lPosH,'descend'));1];
            else
                pSubH = arrayfun(@(x)(obj.getLinePos(x)),hSubH,'un',0);
            end

        end

        % --- updates the line constrain function to the specified limits
        function updateLineConstrainFcn(obj,hLine,Lim)

            % exit if no lines
            if isempty(hLine); return; end

            % sets the line movement limits (if not provided)
            uData = get(hLine,'UserData');
            if nargin == 2                    
                lPos = obj.getLinePos(hLine);
                Lim = cellfun(@(x)(x'),num2cell(lPos,1),'un',0);
                Lim{uData{1}(2)} = [0 1];
            end

            % updates the line limits userdata field
            uData{4} = Lim;
            set(hLine,'UserData',uData);            
            
            % updates the constraining region for the line   
            setConstraintRegion(hLine,Lim{1},Lim{2},obj.isOld,'line');            

        end

        % --- updates the line hit-test state
        function setLineHTState(obj,state)

            % retrieves the horizontal/vertical line object handles
            hSubH = findall(obj.hAx,'tag','hSubH');
            hSubV = findall(obj.hAx,'tag','hSubV');
            
            if obj.isOld
                % retrieves the children objects of all the vertical lines
                if ~isempty(hSubV)
                    hSubVC = get(hSubV,'Children');
                    if ~iscell(hSubVC); hSubVC = {hSubVC}; end
                    cellfun(@(x)(set(x,'hittest',state)),hSubVC)
                end
                    
                % retrieves the children objects of all the vertical lines
                if ~isempty(hSubH)                
                    hSubHC = get(hSubH,'Children');
                    if ~iscell(hSubHC); hSubHC = {hSubHC}; end
                    cellfun(@(x)(set(x,'hittest',state)),hSubHC)
                end

            else
%                 % case is a new style interactive object
%                 intStr = 'InteractionsAllowed';
%                 if strcmp(state,'on')
%                     % case is enabling the hit-test flag
%                     arrayfun(@(x)(set(x,intStr,'translate')),hSubV)
%                     arrayfun(@(x)(set(x,intStr,'translate')),hSubH)                    
%                 else
%                     %
%                     arrayfun(@(x)(set(x,intStr,'none')),hSubV)
%                     arrayfun(@(x)(set(x,intStr,'none')),hSubH)
%                 end
            end

        end
        
        % -------------------------------------- %
        % --- MAIN FIGURE CALLBACK FUNCTIONS --- %
        % -------------------------------------- %        
        
        % --- main figure key press callback function
        function keyPressFcn(obj,~,event)
            
            obj.hasCtrl = strcmp(event.Key,'control');
            
        end
        
        % --- main figure key release callback function
        function keyReleaseFcn(obj,~,~)
            
            obj.hasCtrl = false;
            
        end             
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- the countdown timer callback function
        function timerCDownFcn(obj,~,~)
            
            % determines if the user has moved the line object
            if obj.isMove
                % determines the time since the last movement
                tF = toc(obj.hTic);

                % if greater than tolerance, then reset movement variables
                if tF > obj.tMove   
                    % turns off access to the line objects
                    obj.setLineHTState('off')  
                    
                    % retrieves the line indices
                    hh = cell2cell(obj.hMove);
                    if isempty(hh)
                        iL = [];
                    else
                        iL0 = arrayfun(@(x)(get(x,'UserData')),hh,'un',0);
                        iL1 = cell2cell(iL0);
                        iL = cell2mat(iL1(:,1));
                    end
                    
                    % retrieves the index data of the lines
                    hSub = {findall(obj.hAx,'tag','hSubV'),...
                            findall(obj.hAx,'tag','hSubH')};
                    
                    % retrieves the sub-region line object handles
                    [pL{1},pL{2}] = obj.getAllLinePos(1);

                    % resets the line locations    
                    for i = 1:length(hh)
                        k = hSub{iL(i,2)} == hh(i);
                        obj.updateLinePos(hh(i),pL{iL(i,2)}{k},[],[],1); 
                        
                        % updates the line object properties
                        uData = get(hh(i),'UserData');
                        uData{3} = pL{iL(i,2)}{k};
                        set(hh(i),'UserData',uData);
                    end

                    % resets the stationary location of the moved line
                    hLine = getappdata(obj.hAx,'hLine');
                    uData = get(hLine,'UserData');
                    uData{3} = obj.getLinePos(hLine);
                    set(hLine,'UserData',uData);
                    
                    % updates the line contrain functions
                    for i = find(~cellfun('isempty',obj.hMove(:)'))
                        arrayfun(@(x)...
                             (obj.updateLineConstrainFcn(x)),obj.hMove{i});
                    end      

                    % updates the positions of all the subplot regions
                    pos = obj.detAllRegionPos();
                    hSelT = findall(obj.hAx,'tag','hSel');
                    [~,ii] = sort(cell2mat(get(hSelT,'UserData')),'ascend');                            
                    V = cellfun(@(x)(obj.pos2vec(x)),num2cell(pos,2),'un',0);
                    cellfun(@(x,y)(set(x,'xdata',y{1},'ydata',y{2})),...
                                                num2cell(hSelT(ii)),V)        

                    % updates the position vector and table data
                    obj.sPara.pos = roundP(pos,0.005);
                    Data = [(1:size(obj.sPara.pos,1))',obj.sPara.pos];
                    set(obj.hTable,'Data',num2cell(Data))

                    % resets movement array/flags and reactivates the lines
                    [obj.hMove,obj.isMove] = deal(cell(1,3),false);
                    obj.setLineHTState('on')
                end
            end            

        end                
        
        % --- callback function for editting the parameters
        function editChangePara(obj,hObject,~)
            
            % retrieves the current string
            pStr = get(hObject,'UserData');            
            prVal = getStructField(obj.sPara,pStr);
            [nwVal,nwLim] = deal(str2double(get(hObject,'string')),[1,5]);
            
            % checks to see if the new value is valid
            if chkEditValue(nwVal,nwLim,1)
                % determines if the new value is unique
                if prVal ~= nwVal
                    % if so, then update the parameter field and struct
                    obj.sPara = setStructField(obj.sPara,pStr,nwVal);
                    setObjEnable(obj.hButC{1},'on')
                end
            else
                % otherwise, revert back to the previous valid value
                set(hObject,'string',num2str(prVal))
            end
            
        end      
        
        % --- callback function for clearing regions
        function clearRegions(obj,~,~)
            
            % initialisations
            qStr = {['Are you sure you want to clear the split ',...
                     'regions?'];'';'This action can not be reversed.'};
            
            % prompts the user if they want to continue
            uChoice = questdlg(qStr,'Clear Regions?','Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                % if not, then exit the function
                return
            else
                % otherwise, update the status flag
                obj.isChange = true;    
            end

            % reset the row/column edit box strings
            [obj.sPara.nRow,obj.sPara.nCol] = deal(1);
            cellfun(@(x)(set(x,'String','1')),obj.hEdit);            
            
            % updates the axis table and recreates the sub-regions
            obj.setupAxisTable(1)
            obj.createSubRegions()

            % disables the button
            cellfun(@(x)(setObjEnable(x,0)),obj.hBut)
            
        end
        
        % --- callback function for clearing regions
        function combineRegions(obj,hObject,~)

            % retrieves the indices of the selected region
            hNum = findall(obj.hAx,'tag','hNum','Color','w');
            iSel = sort(str2double(get(hNum,'string')),'ascend');

            % retrieves the positions of the selected regions
            [~,pos] = obj.detClickSubplot();
            pos = pos(iSel,:);

            % calculates the total max area, and the sum of the 
            % individual region areas
            Atot = prod(max(pos(:,1:2)+pos(:,3:4))-min(pos(:,1:2)));
            Asum = sum(pos(:,3).*pos(:,4));
            if abs(Atot - Asum) > obj.dAtol
                % if the total max area does not equal the area sum then 
                % exit with an error                
                eStr = ['Error! Can''t combine regions as they do ',...
                        'not form a rectangle'];
                waitfor(errordlg(eStr,'Combining Selected Region Error'))
                return
            else
                % otherwise, prompts the user if they wish to continue
                qStr = {['Are you sure you want to combine the selected ',...
                         'regions?'];'';'This action can not be reversed.'};
                uChoice = questdlg(qStr,'Combine Regions?','Yes','No','Yes');
                if ~strcmp(uChoice,'Yes')
                    % if the user cancelled, then exit
                    return
                end
            end

            % disables the button
            setObjEnable(hObject,'off')

            % retrieves the parameter struct
            indNw = true(size(obj.sPara.pos,1),1);
            [indNw(iSel(2:end)),obj.isChange] = deal(false,true);

            % sets the new position vector into the parameter struct
            pos0 = obj.sPara.pos(iSel,:);
            posNw = [min(pos0(:,1:2)) ...
                     (max(pos0(:,1:2) + pos0(:,3:4))-min(pos0(:,1:2)))];
            obj.sPara.pos(iSel(1),:) = posNw;

            % removes the extraneous rows from the parameter struct arrays
            obj.sPara.pos = obj.sPara.pos(indNw,:);
            obj.sPara.pData = obj.sPara.pData(indNw);
            obj.sPara.plotD = obj.sPara.plotD(indNw);
            obj.sPara.ind = obj.sPara.ind(indNw,:);            

            % updates the axis table info and the sub-regions
            obj.setupAxisTable()
            obj.createSubRegions()            
            
        end        
        
        % --- callback function for applying changes
        function applyChanges(obj,hObject,~)
            
            % initialisations
            qStr = {'Are you sure you want to update the axis split?';'';...
                    'This action will clear all current axis properties.'};

            % if so, then prompt the user if they still want to close the window
            uChoice = questdlg(qStr,'Apply Changes?','Yes','No','Yes');
            if ~strcmp(uChoice,'Yes')
                % if not, then exit the function
                return
            else
                % otherwise, update the status flag
                obj.isChange = true;
            end            
            
            % updates the axis table and recreates the sub-regions
            obj.setupAxisTable(1)
            obj.createSubRegions()

            % disables the button
            setObjEnable(hObject,0)
            setObjEnable(obj.hBut{1},1)
            
        end
        
        % --- callback function for closing the window
        function closeWindow(obj,~,~)
            
            % global variables
            global updateFlag 

            % initialisations
            qStr = 'Are you sure you want update the configuration changes?';
            
            % determines if the user has made a change 
            if obj.isChange
                % if so, prompt the user if they want to update the changes
                uChoice = questdlg(qStr,'Update Axis Changes?','Yes',...
                                   'No','Cancel','Yes');
                switch (uChoice)
                    case ('Yes') 
                        % case is wanting to update
                        sParaF = obj.sPara;          
                        
                        % deletes the parameter gui object
                        objP = getappdata(obj.hFigM,'objP');
                        if ~isempty(objP)
                            objP.deleteClass();
                            setappdata(obj.hFigM,'objP',[])
                        end
                        
                    case ('No') 
                        % case is not wanting to update
                        sParaF = obj.sPara0;                        
                        
                    otherwise % case is cancelling
                        return
                end
                
                % updates the sub-region parameter struct
                setappdata(obj.hFigM,'sPara',sParaF)  
            else
                % retrieves the original sub-region data struct
                sParaF = obj.sPara0;
            end          
            
            % resets the main GUI update flag
            updateFlag = 2;            
            
            % clears all the axis objects
            delete(obj.hAx);
            
            % clears all the plot panel objects
            hPanelP = findall(obj.hGUI.panelPlot,'tag','subPanel');
            if ~isempty(hPanelP); delete(hPanelP); end
            
            % sets the sub-index 
            cbFcn = [];
            nReg = size(sParaF.pos,1);
            hMenuSP = obj.hGUI.menuSubPlot;           
            obj.setMainGUIProps('on')
            
            % if more than one region, then update the figure properties
            if nReg > 1
                % updates the subplot index popup-menu
                setObjEnable(obj.hGUI.menuSaveSubConfig,'on')

                % creates the subplot panels
                setupSubplotPanels(obj.hGUI.panelPlot,sParaF)
                cbFcn = getappdata(obj.hFigM,'figButtonClick');                
                
                % determines how many subplot menu items there are
                resetSubplotMenuItems(obj.hFigM,hMenuSP,nReg,1);
                
                % updates the sub-index popup function
                spFcn = getappdata(obj.hFigM,'menuSubPlot');
                spFcn(obj.hFigM,[])                  
                
            else
                % deletes any previous subplot panels
                setObjEnable(obj.hGUI.menuSaveSubConfig,'off')
                hPanel = findall(obj.hGUI.panelPlot,'tag','subPanel');
                if ~isempty(hPanel); delete(hPanel); end                
            end        
            
            % sets the subplot menu visibility
            setObjVisibility(hMenuSP,nReg>1)            
            
            % updates the window down callback function
            set(obj.hFigM,'WindowButtonDownFcn',cbFcn);
            
            % stops and deletes the timer object
            stop(obj.hTimer)
            delete(obj.hTimer)
            
            % sets the main GUI properties            
            delete(obj.hFig);
            setObjVisibility(obj.hFigM,1)
            
            % ensures the main GUI doesn't update again
            pause(0.1); 
            updateFlag = 0;            
            
        end                        
        
        % ----------------------- %
        % --- OTHER FUNCTIONS --- %
        % ----------------------- % 
        
        % --- updates the main GUI properties
        function setMainGUIProps(obj,state)
            
            % updates the panel properties
            setPanelProps(obj.hGUI.panelSolnData,state)
            setPanelProps(obj.hGUI.panelExptInfo,state)
            setPanelProps(obj.hGUI.panelPlotFunc,state)
            setPanelProps(obj.hGUI.panelFuncDesc,state)

            % updates the menu item properties
            setObjEnable(obj.hGUI.menuFile,state)
            setObjEnable(obj.hGUI.menuPlot,state)
            setObjEnable(obj.hGUI.menuGlobal,state) 
            setObjEnable(obj.hGUI.menuSubPlot,state) 
            
            % sets the key/press functions into the main GUI
            set(obj.hFigM,'resize',state)

            % makes the parameter GUI invisible (if disabling objects)
            if strcmp(state,'off')
                objP = getappdata(obj.hFigM,'objP');
                if ~isempty(objP)
                    objP.setVisibility(0); 
                end    
            end            
            
        end        
        
        % --- resets the subplot axis information table
        function setupAxisTable(obj,varargin)
            
            % recalculates the position array (if required)
            if nargin == 2
                obj.recalcPosArray();
            end
            
            % updates the table data
            nReg = size(obj.sPara.pos,1);
            Data = num2cell([(1:nReg)',obj.sPara.pos]);
            set(obj.hTable,'Data',Data)
            
        end
        
        % --- clears all plot objects from the axes 
        function clearAxesObjects(obj)
            
            % array of tag strings for objects to be removed
            tagStr = {'hSub','hNum','hSel','hEdge','hSubV','hSubH'};
            
            % deletes any objects with the specified tag (if they exist)
            for i = 1:length(tagStr)
                hAxObj = findall(obj.hAx,'tag',tagStr{i});
                if ~isempty(hAxObj); delete(hAxObj); end
            end
            
            % clears the axis
            cla(obj.hAx)
            
        end        
        
        % --- recalculates the subplot postional array
        function recalcPosArray(obj)

            % memory allocation
            [nR,nC] = deal(obj.sPara.nRow,obj.sPara.nCol);
            [obj.sPara.pos,nReg] = deal(zeros(nR*nC,4),nC*nR);

            % memory allocation
            obj.sPara.ind = NaN(nReg,3);
            obj.sPara.calcReqd = true(nReg,1);
            [obj.sPara.pData,obj.sPara.plotD] = deal(cell(nReg,1));

            % for each row/column initialise the subplot structs
            [H,W] = deal(1/nR,1/nC);
            for i = 1:nR
                for j = 1:nC
                    % sets the parameter struct index/position
                    obj.sPara.pos((i-1)*nC + j,:) = [(j-1)*W (i-1)*H W H];
                end
            end

        end
        
    end
    
    % static class methods
    methods (Static)
        
        % --- converts a postion array into the x/y location vectors
        function [vX,vY] = pos2vec(pos)

            % sets the positions of the edges, and the sets the vector
            [iX,iY] = deal([1 1 2 2],[1 2 2 1]);
            [pX,pY] = deal(pos(1)+[0 pos(3)],pos(2)+[0 pos(4)]);
            [vX,vY] = deal(pX(iX),pY(iY));

            % ensures the vertices are within the limits [0,1]
            [vX,vY] = deal(min(max(0,vX),1),min(max(0,vY),1));

            % outputs in one array (if only one output variable)
            if (nargout == 1); vX = {vX,vY}; end

        end
        
        % --- retrieves the line position for the line object, hLine
        function lPos = getLinePos(hLine,ind)

            % retrieves the line's position
            lPos = getIntObjPos(hLine);
            if exist('ind','var')
                % sets the position of the line (depending on orientation)
                lPos = lPos(1,ind);
            end

        end        
        
        % --- determines the co-linear indices
        function ii = detCLIndices(lPosC,pSub,iC,iP,i,k)
            
            % THIS LINE OF CODE IS INCORRECT?! FIX THIS TO
            % ENSURE CORRECT SELECTION OF COINCIDENT LINES

            % parameters
            tol = 0.001;

            % determines the co-linear indices
            ii = cellfun(@(x)((abs(x(1,iC)-lPosC(1,iC))<=tol) && ...
                              (abs(x(k,iP)-lPosC(i,iP))<=tol)),pSub{iC});

        end        
        
        % --- calculates the coordinates of the sides of a position vector
        function posXY = calcPosSideCoord(pos)

            % memory allocation
            posXY = zeros(4);

            % sets the coordinates for the left, right, top and bottom
            posXY(1,:) = [pos(1)*[1 1],pos(2)+[0 pos(4)]];
            posXY(2,:) = [sum(pos([1 3]))*[1 1],pos(2)+[0 pos(4)]];
            posXY(3,:) = [pos(1)+[0 pos(3)],pos(2)*[1 1]];
            posXY(4,:) = [pos(1)+[0 pos(3)],sum(pos([2 4]))*[1 1]];

        end
        
        % --- creates a binary mask from the line regions
        function Im = getRegionLineMap(pSubH,pSubV,aP)

            % initialisations and memory allocation
            Im = zeros(aP(4)+1,aP(3)+1);

            % sets the vertical lines
            for i = 1:length(pSubH)
                iC = (max(0,floor(pSubH{i}(1,1)*aP(3))):min(aP(3),...
                                        ceil(pSubH{i}(2,1)*aP(3)))) + 1;
                Im(roundP(pSubH{i}(1,2)*aP(4)) + 1,iC) = 1;
            end

            % sets the vertical lines
            for i = 1:length(pSubV)
                iR = (max(0,floor(pSubV{i}(1,2)*aP(4))):min(aP(4),...
                                        ceil(pSubV{i}(2,2)*aP(4)))) + 1;
                Im(iR,roundP(pSubV{i}(1,1)*aP(3)) + 1) = 1;
            end

            % removes the frame outer edge 
            [Im(1,:),Im(end,:),Im(:,1),Im(:,end)] = deal(1);

        end        
        
        % --- creates a binary mask of each of the subregion lines
        function Bline = getRegionLineBinary(posG,sz)

            % memory allocations
            [Btot,nReg] = deal(false(sz),size(posG,1));

            % appends the regions to each of the total binary mask
            for i = 1:nReg
                % sets up the row indices
                iR = ceil(posG(i,2)):floor(posG(i,2)+posG(i,4));
                iR = iR((iR > 0) & (iR <= sz(1)));
                
                % sets up the column indices                
                iC = ceil(posG(i,1)):floor(posG(i,1)+posG(i,3));
                iC = iC((iC > 0) & (iC <= sz(2)));

                % sets the new binary mask
                Bnw = false(sz);
                [Bnw(iR(1),iC),Bnw(iR(end),iC)] = deal(true);
                [Bnw(iR,iC(1)),Bnw(iR,iC(end))] = deal(true);

                % appends the new binary mask to the total binary mask
                Btot = Btot | Bnw;
            end

            % determines the line segments linear indices
            Breg = bwmorph(Btot & ~bwmorph(true(sz),'remove'),'thin',inf);
            Bline = Breg & ~bwmorph(bwmorph(Breg,'branchpoints'),'dilate');

        end        
        
    end
    
end
    
