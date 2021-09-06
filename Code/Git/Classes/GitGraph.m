classdef GitGraph < dynamicprops & handle
    
    % class properties
    properties
        % main class objects
        hFig
        hGUI

        % other gui object handles
        hAx
        hPanel
        hPanelP
        hScrollY
        hScrollX          
        cmObj
        
        % repo struct class object
        rObj
        cCol
        pLink
        pPos                        
        indL2G
        iRowCm
        headCol
        headInd
        
        % graph objects        
        hFillHd
        hFillH
        hFillS
        
        % axes/object dimensions
        axWid
        axHght
        scrlHght
        xLim0
        yLim0   
        axPosX
        axPosY 
        yFill
        
        % other parameters
        nRow  
        X0
        dX = 10;
        sWid = 15;
        txtHY = 20;
        txtHX = 18;
        fSz = 11;  
        mSz = 45;
        dxTxt = 5;
        wCID = 60;
        wDate = 85;
        
    end   
    
    % class methods
    methods
        
        % --- class constructor
        function obj = GitGraph(hFig,rObj)

            % sets the input arguments
            obj.hFig = hFig;
            obj.hGUI = guidata(hFig);
            
            % sets/initialises the repository struct class object
            if ~exist('rObj','var')
                obj.rObj = RepoStructure();
            else
                obj.rObj = rObj;
            end                                                                                     
            
            % initialises the class object fields
            obj.initClassFields()
            obj.setupGraphObjects();            
                             
            % sets up the repository axis object
            obj.setupRepoAxis(true);            
            
            % sets up the scrollbar objects
            obj.setupScrollbars(); 
            obj.setupCommitPatches();            
            
        end       
        
        % --------------------------------------- %
        % --- OBJECT INITIALISATION FUNCTIONS --- %
        % --------------------------------------- %              
        
        % --- initialises the class object fields
        function initClassFields(obj)
            
            % retrieves the distingishable colours
            obj.nRow = obj.rObj.nCommit;     
            obj.cCol = distinguishable_colors(obj.rObj.nBr,'k');                       
            
            % creates the linking marker coordinates
            [xL,k] = deal((-1:0.1:1)',5);
            obj.pLink = [1./(1+exp(-k*xL)),(xL+1)/2];

            % determines the local to global indices
            obj.indL2G = find(~cellfun(@isempty,obj.rObj.bInfo(:,1))); 
            obj.iRowCm = cumsum(~cellfun(@isempty,obj.rObj.bInfo(:,1)));                          
            
        end                
        
        % --- sets up the graph axes panel
        function setupGraphObjects(obj)
            
            % global variables
            global axPosX axPosY            
            
            % initialisations
            pOfs =  [0,-1,1,1]*obj.sWid;
            obj.hPanelP = obj.hGUI.panelVerHist; 
            
            % sets up the panel dimension vector
            pPosP = get(obj.hPanelP,'Position');
            obj.pPos = [obj.dX*[1,1],pPosP(3:4)-obj.dX*[2,3.5]]-pOfs;
            
            % creates the sub-panel
            obj.hPanel = uipanel('Title','','Units','Pixels',...
                                 'Position',obj.pPos,'BorderType',...
                                 'beveledin','Parent',obj.hPanelP);                
                             
            % sets the global axis limits
            axPos = getObjGlobalCoordGit(obj.hPanel);
            [obj.axPosX,axPosX] = deal(axPos(1)+[0,axPos(3)]);
            [obj.axPosY,axPosY] = deal(axPos(2)+[0,axPos(4)]);    
            
            % creates the axes object            
            obj.axHght = obj.nRow*obj.txtHY;
            [axPos,axUnits] = deal([0,0,1,1],'Normalized');
            [obj.yLim0,obj.xLim0] = deal([0,obj.pPos(4)],[0,obj.pPos(3)]);
            obj.hAx = axes(obj.hPanel,'Units',axUnits,'Position',axPos);                                            
            
        end                
        
        % --- sets up the commit patch objects
        function setupCommitPatches(obj)
            
            % parameters
            xP = [0;obj.axWid];
            pCol = 0.97*[1,1,1];   
            pColS = [110,150,200]/255;
            xi = (1:2:obj.rObj.nCommit)';
            [fAlphaS,fAlphaH] = deal(0.5,0.2);
            [ix,iy] = deal([1,1,2,2,1],[1,2,2,1,1]);            
            
            % turns the axes hold on
            hold(obj.hAx,'on');

            % ------------------------------ %
            % --- HIGHLIGHT PATCH OBJECT --- %
            % ------------------------------ %  
            
            % creates the highlight patch object            
            obj.yFill = (iy-1)*obj.txtHY;
            
            % creates the head patch object
            yFillHd = ((iy+obj.headInd)-2)*obj.txtHY;
            obj.hFillHd = patch(xP(ix),yFillHd,obj.headCol,...
                                'UserData',obj.headInd,...
                                'facealpha',1,'Visible','on');  
                            
            % creates the highlight/selection patch objects
            obj.hFillH = patch(xP(ix),NaN(1,5),pColS,'UserData',NaN,...
                                'facealpha',fAlphaH,'Visible','off');
            obj.hFillS = patch(xP(ix),NaN(1,5),pColS,'UserData',NaN,...
                                'facealpha',fAlphaS,'Visible','off'); 
                            
            % updates the fill object properties
            hFillAll = [obj.hFillHd,obj.hFillH,obj.hFillS];
            set(hFillAll,'Parent',obj.hAx)
            uistack(hFillAll,'bottom')            
            
            % -------------------------------- %
            % --- BACKGROUND PATCH OBJECTS --- %
            % -------------------------------- %
            
            % sets up the patch object coordinates            
            yP = arrayfun(@(x)(((x-1)+[0;1])*obj.txtHY),xi,'un',0);
            pP = cell2mat(cellfun(@(y)([xP(ix),y(iy)]),yP,'un',0));            
            
            % creates the patch object
            hP = patch(pP(:,1),pP(:,2),pCol,'edgecolor','None');
            set(hP,'Parent',obj.hAx)
            uistack(hP,'bottom')            
            
            % turns the axes hold off
            hold(obj.hAx,'off');
            
        end        
        
        % --- resets the head commit markers
        function resetHeadMarker(obj,iBr,iCm)
            
            % sets the new graph row index  
            wghtStr = {'Normal','Bold'};
            iSelNw = str2double(obj.rObj.gHist(iBr).brInfo.ID{iCm});                        
            obj.headInd = iSelNw;
            
            % retrieves the head, branch head and line text markers
            hTxtHead = findall(obj.hAx,'tag','hTxtHead');                        
            hTxtBrAll = findall(obj.hAx,'tag','hTxtBr');
            hTxtAll = findall(obj.hAx,'tag','hTxtDesc');
            hTxt = findall(hTxtAll,'UserData',iSelNw);
            
            % retrieves the currently selected row text object
            hTxt0 = findall(obj.hAx,'tag','hTxtDesc','Color','r');                              
            
            % determines if the current row select is on a branch end
            yTxtBr = get(hTxtBrAll,'Position');
            if iscell(yTxtBr); yTxtBr = cell2mat(yTxtBr); end
            isBrEnd = any(get(hTxt0,'UserData')==yTxtBr(:,2)/obj.txtHY+0.5);
            
            % resets the text 
            pTxtHead = get(hTxtHead,'Extent');
            resetObjPos(hTxt0,'Left',-(pTxtHead(3)+obj.dxTxt),1);
            set(hTxt0,'Color','k','FontWeight',wghtStr{1+isBrEnd});            
            
            % sets the x-coordinates of the         
            if iCm == 1
                hTxtBr = findall(hTxtBrAll,'UserData',iBr);
                pTxtBr = get(hTxtBr,'Extent');
                XDesc0 = sum(pTxtBr([1,3])) + obj.dxTxt;
            else
                XDesc0 = obj.X0+(obj.wCID+obj.wDate);
            end
                
            % sets the x/y coordinates of the head text object  
            resetObjPos(hTxtHead,'Left',XDesc0);
            resetObjPos(hTxtHead,'Bottom',(iSelNw-0.5)*obj.txtHY);
            
            % updates the location of the head patch object
            set(obj.hFillHd,'yData',obj.yFill+(iSelNw-1)*obj.txtHY);
            
            % resets the descripton marker on the new line
            pTxtHead = get(hTxtHead,'Extent');
            resetObjPos(hTxt,'Left',sum(pTxtHead([1,3]))+obj.dxTxt);
            set(hTxt,'Color','r','FontWeight','Bold');
            
            % resets the axes dimensions
            obj.resetAxesDimensions(hTxtAll)
            
        end
        
        % --- resets the graph axes dimensions    
        function resetAxesDimensions(obj,hTxtAll)
            
            % sets the default input arguments
            if ~exist('hTxtAll','var')
                hTxtAll = findall(obj.hAx,'tag','hTxtDesc');
            end
            
            % resets the axis limits
            pTxtAll = cell2mat(get(hTxtAll,'Extent'));
            xMaxAll = max(sum(pTxtAll(:,[1,3]),2))+obj.dxTxt;            
            obj.axWid = max(obj.xLim0(2),xMaxAll);
            
            % updates all the patch widths
            hPatch = findall(obj.hAx,'type','Patch');
            for i = 1:length(hPatch)
                xData0 = get(hPatch(i),'xData');
                set(hPatch(i),'xData',obj.axWid*(xData0/max(xData0)))
            end
            
            % sets the vertical scroll bar enabled properties (if the
            % scrollbar is necessary or not)
            if obj.xLim0(2) >= obj.axWid
                set(obj.hScrollX,'enable','off','Value',0)
            else
                xMax = obj.axWid-obj.xLim0(2);
                sStepX = min(1,(obj.txtHX/abs(xMax)))*[1,1];                
                set(obj.hScrollX,'Max',xMax,'SliderStep',sStepX,...
                                 'Enable','on','Value',0)                
            end
            
        end
        
        % --- sets up the repo commit graph axis
        function setupRepoAxis(obj,isInit)
                        
            % memory allocation            
            X = cell(obj.nRow,3);  
            nLog = obj.rObj.nLog;
            obj.nRow = obj.rObj.nCommit; 
            
            % if not initialising, then clear the axis
            if ~isInit          
                obj.initClassFields()
                cla(obj.hAx);
            end
            
            % turns the axis hold on
            hold(obj.hAx,'on')        
            set(obj.hAx,'ylim',obj.yLim0,'xlim',obj.xLim0);            
            
            % ----------------------------- %
            % --- COMMIT MARKER OBJECTS --- %
            % ----------------------------- %                                    
            
            % determines the non-empty graph symbols
            pBr = cell(obj.rObj.nBr,1);  
            gSym = obj.rObj.gSym(:,2:end-1);
            hasSym = ~cellfun(@isempty,gSym);
            hasCom = ~cellfun(@isempty,obj.rObj.bInfo(:,1)); 
            
            % determnes the points on the first column that belong to the
            % master branch
            iBrM = find(strcmp(obj.rObj.brData(:,1),'master'));
            isM = find(obj.rObj.indBr(:,1) == iBrM,1,'first'):nLog;
            BM = setGroup(isM,[nLog,1]);
            iBM0 = find(BM,1,'first');
            
            % creates the directed graph
            for i = nLog-1:-1:1
                % determines the indices of the symbols on the row
                x0 = find(hasSym(i,:));                
                
                % retrieves the branch coordinates (based on type)
                if hasCom(i)
                    % case is a commit line
                    
                    % sets the x/y line locations
                    xL = ceil(x0/2)-0.5;
                    yL = obj.iRowCm(i+[1;0])-0.5;
                    
                    % plots the vertical lines for the current row
                    for j = 1:length(xL)                        
                        % sets the new branch index
                        if (x0(j) == 1) && (i >= (iBM0-1))
                            % if on the master column, but not a master
                            % index, then set the branch index to master
                            iBrNw = iBrM;
                        else
                            % case is using the value from the index array
                            iBrNw = obj.rObj.indBr(i,x0(j));
                        end                        
                        
                        % sets the coordinates of the new branch segment
                        pBr{iBrNw}{end+1} = [[xL(j)*[1;1],yL(:)];NaN(1,2)];
                    end
                    
                else
                    % sets the 
                    y0 = obj.iRowCm(i)-0.5;
                    xL = ceil(x0/2)-0.5;
                    
                    % case is a non-commit line
                    for j = 1:length(x0)
                        switch gSym{i,x0(j)}
                            case '|'
                                % case is a straight line marker
                                pBrNw = [xL(j)*[1;1],y0+[0;1]];
                            case '/'
                                % determines the branch deviation
                                [xScl,gSym,hasSym] = ...
                                        obj.getBranchDeviation...
                                            (gSym,hasSym,i,x0(j),'/');                                                                             
                                pBrNw = [xL(j)+xScl*obj.pLink(:,1),...
                                         y0+flip(obj.pLink(:,2))];
                            case '\'
                                % determines the branch deviation
                                [xScl,gSym,hasSym] = ...
                                        obj.getBranchDeviation...
                                            (gSym,hasSym,i,x0(j),'\');                                  
                                pBrNw = [(xL(j)+1)-xScl*obj.pLink(:,1),...
                                         y0+flip(obj.pLink(:,2))];
                        end
                        
                        % appends the path coordinates to the branch
                        iBrNw = obj.rObj.indBr(i,x0(j));
                        pBr{iBrNw}{end+1} = [pBrNw;NaN(1,2)];
                    end
                end                
            end
            
            % creates the path plot markers
            for iBr = 1:obj.rObj.nBr
                pBrNw = cell2mat(pBr{iBr}(:));                   
                if ~isempty(pBrNw)
                    ii = sum(abs(diff([[-1,-1];pBrNw],[],1)),2) ~= 0;
                    plot(obj.hAx,pBrNw(ii,1)*obj.txtHX,...
                                 pBrNw(ii,2)*obj.txtHY,...
                                 'linewidth',2,'tag','hCommL',...
                                 'color',obj.cCol(iBr,:));
                end
            end                        
            
            % creates the commit markers
            for i = 1:obj.rObj.nBr
                % retrieves the marker colour and branch history data
                mCol0 = obj.cCol(i,:);
                gHist = obj.rObj.gHist(i);                
                
                % sets the commit marker x/y coordinates
                y0 = cellfun(@str2double,gHist.brInfo.ID);
                yC = (y0-0.5)*obj.txtHY;   
                
                %
                nCommitBr = size(gHist.brInfo,1);
                Z = num2cell(i*ones(nCommitBr,1));
                X(y0,:) = [Z,gHist.brInfo.mCID,gHist.brInfo.mName];
                
                % marker objects for all commits n the current branch                
                for j = nCommitBr:-1:1
                    % sets the commit node x-location
                    x0 = find(strcmp(gSym(obj.indL2G(y0(j)),:),'*'));
                    xC = (ceil(x0/2)-0.5)*obj.txtHX;
                    
                    % sets the edge colour of the marker object                    
                    if isempty(gHist.pName) || (j < nCommitBr)
                        % case is a normal marker
                        mColEdge = mCol0;
                    else
                        % case is a branch marker
                        iPr = strcmp(obj.rObj.brData(:,1),gHist.pName);
                        mColEdge = obj.cCol(iPr,:);
                    end
                    
                    % creates the commit marker object
                    scatter(obj.hAx,xC,yC(j),obj.mSz,mCol0,'filled',...
                                'UserData',y0(j),'tag','hComm',...
                                'MarkerEdgeColor',mColEdge,'linewidth',1)                          
                end                
            end       

            % updates the merge commit scatterplot marker edge colours
            for i = find(~cellfun(@isempty,X(:,2)'))
                % determines the index of the marker to be updated
                iMrg = strcmp(obj.rObj.brData(:,1),X{i,3});
                iComm = strcmp(obj.rObj.gHist(iMrg).brInfo.CID,X{i,2});                
                uData = str2double(obj.rObj.gHist(iMrg).brInfo.ID{iComm});
                
                % updates the merge commit marker edge colour
                hComm = findall(obj.hAx,'tag','hComm','UserData',uData);
                set(hComm,'MarkerEdgeColor',obj.cCol(X{i,1},:));
            end
            
            % ---------------------------------- %
            % --- COMMIT INFORMATION OBJECTS --- %
            % ---------------------------------- %
            
            % parameters and memory allocation
            tExt = zeros(obj.rObj.nBr,1);
            
            % sets the marker horizontal offset
            iColMx = ceil(find(any(~isnan(obj.rObj.indBr),1),1,'last')/2);
            obj.X0 = iColMx*obj.txtHX;
            
            % creates the text labels for each commit (over all branches)
            for i = 1:obj.rObj.nBr
                % retrieves the commit row ID numbers
                brInfo = obj.rObj.gHist(i).brInfo;
                iID = cellfun(@str2double,brInfo.ID);                
                for j = 1:size(brInfo,1)
                    % sets the marker vertical coordinates
                    k = iID(j);
                    Y = (k-0.5)*obj.txtHY;
                    
                    % creates the commit ID text object
                    txtID = sprintf('(%s)',brInfo.CID{j});
                    obj.createTextObj(obj.X0+obj.wCID/2,Y,txtID,k,'center');
                            
                    % creates the commit date text object
                    XDate = obj.X0+obj.wCID;
                    txtD = sprintf('%s',brInfo.Date{j});
                    obj.createTextObj(XDate+obj.wDate/2,Y,txtD,k,'center');  
                            
                    % sets the horizontal location of the description text
                    XDesc = obj.X0+(obj.wCID+obj.wDate);                    
                            
                    % if the branch end point, then add in the marker 
                    isBrEnd = strcmp(obj.rObj.brData{i,2},brInfo.CID{j});
                    if isBrEnd
                        % sets the branch head text object properties
                        txtB = sprintf(' %s ',obj.rObj.brData{i,1});
                        hTxtB = obj.createTextObj(XDesc,Y,txtB,i,'left');
                        
                        % creates the branch head text object
                        dsCol = obj.desaturateColour(obj.cCol(i,:),1/3);
                        set(hTxtB,'FontWeight','bold','tag','hTxtBr',...
                                  'EdgeColor','k','BackgroundColor',dsCol)
                              
                        % adds on the text object offset
                        pTxtH = get(hTxtB,'Extent');
                        XDesc = ceil(sum(pTxtH([1,3]))) + obj.dxTxt;
                    end     
                    
                    % if the current head, then add in the marker
                    isHead = strcmp(obj.rObj.headID,brInfo.CID{j});
                    if isHead
                        txtH = ' HEAD ';
                        hTxtH = obj.createTextObj(XDesc,Y,txtH,0,'left');                        
                        
                        % updates the text colour and head index
                        obj.headInd = iID(j);
                        obj.headCol = obj.desaturateColour([1,0.85,0],1/2);                      
                        set(hTxtH,'BackgroundColor',obj.headCol,...
                                  'EdgeColor','k','FontWeight','bold',...
                                  'tag','hTxtHead');                                             
                        
                        % adds on the text object offset                        
                        pTxtH = get(hTxtH,'Extent');
                        XDesc = ceil(sum(pTxtH([1,3]))) + obj.dxTxt;
                    end                    
                    
                    % sets the description text
                    txtDesc = sprintf('%s',brInfo.Desc{j});
                    if isHead && obj.rObj.isMod
                        txtDesc = sprintf('%s**',txtDesc);
                    end
                            
                    % creates the description string                    
                    hTxt = obj.createTextObj(XDesc,Y,txtDesc,k,'left'); 
                    set(hTxt,'tag','hTxtDesc');
                    
                    % updates the fontweight if branch end or head
                    if isHead || isBrEnd
                        set(hTxt,'FontWeight','bold')
                        if isHead
                            set(hTxt,'Color','r')
                        end
                    end
                          
                    % retrieves the extent of the commit description text
                    txtPos = get(hTxt,'Extent');
                    tExt(iID(j)) = sum(txtPos([1,3]));                    
                end
            end
            
            % ensures the commit markers are on top
            uistack(findall(obj.hAx,'tag','hComm'),'top');
           
            % resets the axes properties
            set(obj.hAx,'xcolor','w','ycolor','w','ticklength',[0,0],...
                        'box','off','xtick',[],'xticklabel',[],...
                        'ytick',[],'yticklabel',[])            
            
            % turns the axis hold off and flips in the vertical direction
            axis(obj.hAx,'ij')
            hold(obj.hAx,'off')    
            
            % sets the axis width
            xL0 = get(obj.hAx,'xlim');
            obj.axHght = obj.nRow*obj.txtHY;
            obj.axWid = max(xL0(2),max(10*ceil(tExt/10))+obj.dxTxt);            
               
            % resets the axis height
            
            
            % if not initialising, set up the commit patches
            if ~isInit
                obj.setupCommitPatches();
                obj.resetScrollbarLimits();
            end            
            
        end               
        
        % --- creates the text object
        function hTxt = createTextObj(obj,X,Y,tStr,uData,tAlign)

            hTxt = text(obj.hAx,X,Y,tStr,...
                        'fontunits','pixels','fontweight',...
                        'normal','fontsize',obj.fSz,'UserData',uData,...
                        'fontname','MS San Serif','fontunits','pixels',...
                        'horizontalalignment',tAlign,'Interpreter',...
                        'none','Margin',0.5);

        end        
        
        % --- sets up the horizontal/vertical scrollbars
        function setupScrollbars(obj)
            
            % creates the vertical scrollbar
            scrlPosY = [sum(obj.pPos([1,3])),...
                            obj.dX,obj.sWid,obj.pPos(4)+obj.sWid];
            obj.hScrollY = uicontrol('Parent',obj.hPanelP,'Units',...
                    'pixels','Position',scrlPosY,'Style','Slider',...
                    'Min',-1,'Max',0,'Value',0);
            addlistener(obj.hScrollY,'Value',...
                                     'PostSet',@obj.updateScrollBarY);                                       
                    
            % creates the horizontal scrollbar
            scrlPosX = [obj.dX,obj.pPos(2)-obj.sWid,obj.pPos(3),obj.sWid];
            obj.hScrollX = uicontrol('Parent',obj.hPanelP,'Style',...
                    'Slider','Units','pixels','Position',scrlPosX,...
                    'Min',0,'Max',1,'Value',0); 
            addlistener(obj.hScrollX,'Value',...
                                     'PostSet',@obj.updateScrollBarX);                
                
            % resets the scrollbar limits
            obj.resetScrollbarLimits();
            
        end
                                 
        function resetScrollbarLimits(obj)
    
            % sets the vertical scroll bar enabled properties (if the
            % scrollbar is necessary or not)
            if obj.xLim0(2) >= obj.axWid
                setObjEnable(obj.hScrollX,'off')
            else
                xMax = obj.axWid-obj.xLim0(2);
                sStepX = min(1,(obj.txtHX/abs(xMax)))*[1,1];                
                set(obj.hScrollX,'Max',xMax,'SliderStep',sStepX,...
                                 'Enable','on')                
            end   
            
            % sets the vertical scroll bar enabled properties (if the
            % scrollbar is necessary or not)
            if obj.yLim0(2) >= obj.axHght
                setObjEnable(obj.hScrollY,'off')
            else
                yMin = obj.yLim0(2)-obj.axHght;
                sStepY = min(1,(obj.txtHY/abs(yMin)))*[1,1];
                set(obj.hScrollY,'Min',yMin,'SliderStep',sStepY,...
                                 'Enable','on')
            end             
            
        end        

        % -------------------------- %
        % --- CALLBACK FUNCTIONS --- %
        % -------------------------- %
        
        % --- function for the scrollbar update
        function updateScrollBarY(obj,~,eventdata)
            
            % updates the axes limits
            nwVal = get(eventdata.AffectedObject,'Value'); 
            set(obj.hAx,'ylim',obj.yLim0-nwVal)
            
        end
        
        % --- function for the scrollbar update
        function updateScrollBarX(obj,~,eventdata)
            
            % updates the axes limits
            nwVal = get(eventdata.AffectedObject,'Value'); 
            set(obj.hAx,'xlim',obj.xLim0+nwVal)
            
        end                                
        
    end
    
    % static class methods
    methods (Static)
        
        % --- determines the column extent of a branch/merge deviation
        function [xScl,gSym,hasSym] = ...
                        getBranchDeviation(gSym,hasSym,iRow,iCol,dType)
            
            % initialisation
            xScl = 1;
            
            %
            if strcmp(dType,'/')
                while 1
                    % determines if there is a multi-column
                    % crossing from the current branch
                    if strcmp(gSym{iRow-1,iCol},'\')
                        % case is a left deviation line
                        xScl = xScl - 1;
                        gSym{iRow-1,iCol} = '';
                        hasSym(iRow-1,iCol) = false;
                        iRow = iRow - 1;
                    
                    elseif (iCol == size(gSym,2)) || (iRow == 1)
                        % if at the right edge of the array then exit 
                        break
                        
                    else
                        % otherwise, determine if the deviation line
                        % continues on over multiple columns
                        switch gSym{iRow-1,iCol+2}
                            case '/'
                                % case is a right deviation line
                                xScl = xScl + 1;
                                gSym{iRow-1,iCol+2} = '';
                                hasSym(iRow-1,iCol+2) = false;
                                [iRow,iCol] = deal(iRow-1,iCol+2);
                                
                            case '_'
                                % case is a horizontal line
                                xScl = xScl + 1;
                                gSym{iRow-1,iCol+2} = '';
                                hasSym(iRow-1,iCol+2) = false;
                                iCol = iCol + 2;
                                
                            otherwise
                                % if none of the above, then exit the loop
                                break
                        end 
                    end
                end
            else
                while 1
                    % determines if there is a multi-column
                    % crossing from the current branch
                    if (iCol == 2) || (iRow == 1)
                        % if at the left edge of the array then exit 
                        break
                    else
                        % otherwise, determine if the deviation line
                        % continues on over multiple columns
                        switch gSym{iRow-1,iCol-2}
                            case '\'
                                % case is a left deviation line
                                xScl = xScl + 1;
                                gSym{iRow-1,iCol-2} = '';
                                hasSym(iRow-1,iCol-2) = false;
                                [iRow,iCol] = deal(iRow-1,iCol-2);
                                
                            case '_'
                                % case is a horizontal line
                                xScl = xScl + 1;
                                gSym{iRow-1,iCol-2} = '';
                                hasSym(iRow-1,iCol-2) = false;
                                iCol = iCol - 2;
                                
                            otherwise
                                % if none of the above, then exit the loop
                                break
                        end 
                    end
                end                
            end
                                
        end        
        
        % --- desaturates a colour by the proportion, pSat
        function rgbColNw = desaturateColour(rgbCol,pSat)
            
            hsvCol = rgb2hsv(rgbCol);
            hsvCol(2) = hsvCol(2)*pSat;
            rgbColNw = hsv2rgb(hsvCol);
            
        end
        
    end
    
end