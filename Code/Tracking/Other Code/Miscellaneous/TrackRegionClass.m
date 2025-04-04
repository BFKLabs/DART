classdef TrackRegionClass < handle

    % class properties
    properties
        
        % main class objects
        hFig
        hAx         
        
        % main gui object handles
        hChkSR
        hButU
        hMenuSR        
        
        % plot object fields
        hMark
        hTube
        hDir
        hROI
        
        % other class objects
        objRS
        
        % other class fields
        iMov
        Type        
        isMain
        isMove
        showNum
        isMltTrk
        isAutoDetect
        isSet = false;
        isUpdating = false;
        
        % sub-region location arrays
        pX 
        pY 
        pH 
        pW      
        
        % other fields 
        hHL
        hVL
        hVLUD
        xHL  
        ImapR
        iSelR
        indS
        
        % plot parmeters
        lWid
        fSize    
        iAppInner
        del = 5;
        xGap = 5;
        yGap = 5;        
        fAlpha = 0.2;
        ix = [1,1,2,2,1];
        iy = [1,2,2,1,1];
        manReset = false;
        isOld 
        use2D        
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = TrackRegionClass(hFig,hAx)
           
            % sets the input arguments
            obj.hFig = hFig;
            obj.hAx = hAx; 
            obj.isMain = true;
            
            % retrieves the other main GUI object handles
            obj.hChkSR = findall(hFig,'tag','checkSubRegions');                           
                        
            % sets the window label font sizes and linewidths
            if ispc
                [obj.fSize,obj.lWid] = deal(20,1);
            else
                [obj.fSize,obj.lWid] = deal(26,1.25);    
            end            
            
            % sets the interactive object type flag
            obj.isOld = isOldIntObjVer();
            
        end
        
        % ------------------------------------- %
        % --- REGION MARKER SETUP FUNCTIONS --- %
        % ------------------------------------- %
        
        % --- creates the new division figure for the apparatus sub-regions 
        function rPos = setupDivisionFigure(obj,isSet)
            
            % initialisations
            obj.isSet = isSet;
            obj.iMov = get(obj.hFig,'iMov');
            obj.Type = getDetectionType(obj.iMov);            
            obj.getRegionSetupClassObject();            
            
            % sets the other sub-region flags
            if ~isfield(obj.iMov,'isOpt'); obj.iMov.isOpt = false; end

            % sets the apparatus dimensions and show number flag 
            obj.showNum = nargin == 3;
            [nRow,nCol] = deal(obj.iMov.pInfo.nRow,obj.iMov.pInfo.nCol);

            % sets the movement flag
            if obj.isMain
                % for the main GUI viewing, so don't allow box movement 
                obj.isMove = false;
            else
                % otherwise, allow movement of the boxes
                obj.isMove = true;
            end

            % turns the axis hold on
            hold(obj.hAx,'on')

            % retrieves the vertical/horizontal line handles
            hLine = findall(obj.hAx,'tag','hLine');
            vLine = findall(obj.hAx,'tag','vLine');

            % sets the horizontal seperators    
            if isempty(hLine)
                % if the objects don't exist, then create them
                for i = 1:(nRow-1)
                    for j = 1:nCol 
                        line(obj.hAx,[0 0],[0 0],'color','r',...
                                'linestyle',':','tag','hLine',...
                                'Userdata',[i,j],'linewidth',obj.lWid);
                    end
                end
            else
                % otherwise, make the regions visible
                setObjVisibility(hLine,'on');
            end

            % sets the vertical seperators
            if isempty(vLine)
                % if the objects don't exist, then create them
                for j = 1:(nCol-1)
                    line(obj.hAx,[0 0],[0 0],'color','r',...
                            'linestyle',':','tag','vLine',...
                            'Userdata',j,'linewidth',obj.lWid);   
                end
            else
                % otherwise, make the object visible
                setObjVisibility(vLine,'on');
            end

            % sets the number markers
            if obj.showNum
                hNum = findall(obj.hAx,'tag','hNum');
                if isempty(hNum)
                    % if the objects don't exist, then create them
                    for i = 1:nRow
                        for j = 1:nCol
                            k = (i-1)*nCol+j;
                            hText = text(0,0,num2str(k),'visible','off',...
                                    'fontweight','bold','fontsize',...
                                    obj.fSize,'tag','hNum','color','r',...
                                    'parent',obj.hAx);                
                            if ~isempty(obj.iMov.iR)    
                                if ~obj.iMov.ok(k)
                                    set(hText,'color','k')
                                end
                            end
                        end
                    end
                else
                    % otherwise, make the object visible
                    setObjVisibility(hNum,'on');
                end
            end

            % turns the axis hold off
            hold(obj.hAx,'off')

            % sets up the sub-image rectangle windows
            if obj.isSet
                obj.setupMainFrameRect();
                obj.setupIndivFrameRect();
            else
                rPos = obj.setupMainFrameRect();    
                obj.setupIndivFrameRect(rPos);
            end

        end
        
        % --- removes all the sub-movie division markers from the main axis 
        function removeDivisionFigure(obj,forceDelete)

            % sets the default input arguments
            if ~exist('forceDelete','var'); forceDelete = true; end

            % plot object tag strings
            tStr = {'hInner','hOuter','hLine','vLine','hNum'};            
            
            % updates the plot object properties
            for i = 1:length(tStr)
                % determines the plot object type
                hObj = findobj(obj.hAx,'tag',tStr{i});
                if ~isempty(hObj)
                    % deletes/makes the plot object invisible
                    if forceDelete
                        delete(hObj)
                    else
                        setObjVisibility(hObj,'off')
                    end
                end
            end

            % deletes/makes the tube regions invisible
            if forceDelete
                delete(obj.hTube)
            else
                setObjVisibility(obj.hTube,'off')
            end

        end        
        
        % --- sets up the main sub-window frame --- %
        function [rPos,hROI] = setupMainFrameRect(obj)

            % retrieves the outer region handle
            hOuter = findall(obj.hAx,'Tag','hOuter');            
            delete(hOuter); hOuter = [];

            % updates the position of the outside rectangle
            if isempty(hOuter)
                if obj.isSet
                    hROI = InteractObj('rect',obj.hAx,obj.iMov.posG);
                else    
                    hROI = InteractObj('rect',obj.hAx);
                end
                                
                % if moveable, then set the position callback function
                hROI.setColour('r');
                hROI.setFields('Tag','hOuter');
                
                % updates for the region configuration setup
                rPos = hROI.getPosition();
                if ~obj.isMain
                    % determines if the outer region is feasible                   
                    [dszF,rPos0] = deal(getCurrentImageDim - 1,rPos);
                    xL = min(max(1,[rPos0(1),sum(rPos0([1,3]))]),dszF(2));
                    yL = min(max(1,[rPos0(2),sum(rPos0([2,4]))]),dszF(1));
                    rPos = [xL(1),yL(1),[(xL(2)-xL(1)),(yL(2)-yL(1))]+1];

                    % resets the region if there is a change in size
                    if ~isequal(rPos,rPos0)
                        hROI.setPosition(rPos);
                    end                                        
                end

                % force the object to be fixed
                hROI.setResizeFlag(false);
                hROI.disableObj();                

                % sets the constraint function for the rectangle object
                [xL,yL] = deal(rPos(1)+[0 rPos(3)],rPos(2)+[0 rPos(4)]);
                hROI.setConstraintRegion(xL,yL);
                
                % if not running from the main GUI, then exit
                if ~obj.isMain
                    return
                end
            else
                % if the object exists, then make it visible
                setObjVisibility(hOuter,'on')
                return
            end

            % ---------------------------------- %
            % --- SUB-WINDOW SEPERATOR SETUP --- %
            % ---------------------------------- %

            % initialisations
            [nRow,nCol] = deal(obj.iMov.nRow,obj.iMov.nCol);
%             [nRow,nCol] = deal(obj.iMov.pInfo.nRow,obj.iMov.pInfo.nCol);
            
            % sets the region position vectors
            if obj.use2D
                pPos = obj.iMov.autoP.pPos';                
            else
                pPos = obj.iMov.pos;
            end
            
            % sets the region dimension vectors            
            useOuter = cellfun('isempty',pPos);
            pPos(useOuter) = obj.iMov.posO(useOuter);

            % retrieves the handles to the horizontal/vertical lines
            vLine = findobj(obj.hAx,'tag','vLine');
            hLine = findobj(obj.hAx,'tag','hLine');

            % sets the horizontal 
            rPos = roundP(rPos,0.1);
            [L,T,W,H] = deal(rPos(1),rPos(2),rPos(3),rPos(4));
            yPltV = repmat(T + [0 H],nCol-1,1);

            % sets the horizontal marker regions
            if obj.iMov.isOpt
                % memory allocation
                [yPltH,xPltV] = deal(zeros(nRow-1,2),zeros(nCol-1,2));

                % sets the y locations of the horizontal separators   
                for i = 1:(nRow-1)
                    % sets the indices of the lower/upper groups
                    iLo = (i-1)*nCol+(1:nCol)';
                    iHi = i*nCol+(1:nCol);

                    % sets locations of lower top/upper bottom indices
                    yT = max(cellfun(@(x)(sum(x([2 4]))),obj.iMov.pos(iLo)));
                    yB = min(cellfun(@(x)(x(2)),obj.iMov.pos(iHi)));

                    % sets vertical location of horizontal separator
                    yPltH(i,:) = 0.5*(yT+yB); 
                end

                % sets the x locations of the vertical separators   
                for i = 1:(nCol-1)
                    % sets the indices of the left/right groups
                    iLf = nCol*(0:(nRow-1))'+i;

                    % sets locations of lower top/upper bottom indices
                    xR = max(cellfun(@(x)(sum(x([1 3]))),obj.iMov.pos(iLf)));
                    xL = min(cellfun(@(x)(x(1)),obj.iMov.pos(iLf+1)));

                    % sets horizontal location of vertical separator
                    xPltV(i,:) = 0.5*(xR+xL);                 
                end   
            else    
                % sets the x locations of the vertical separators  
                [dW,dH] = deal(W/obj.iMov.pInfo.nCol,H/obj.iMov.pInfo.nRow); 
                xPltV = repmat(L + (1:(nCol-1))'*dW,1,2);    
            end

            % sets the location of the horizontal seperators
            xPltH = [L;xPltV(:,1);(L+W)];
            for i = 1:(nRow-1)
                for j = 1:nCol
                    % determines the apparatus index
                    iApp = ((i-1)*nCol + j) + [0 nCol];            
                    yPltH = 0.5*(sum(pPos{iApp(1)}([2 4]))+...
                                     pPos{iApp(2)}(2));

                    % retrieves the line
                    hLineNw = findobj(hLine,'UserData',[i,j]);  
                    set(hLineNw,'xData',xPltH(j+(0:1)),...
                                'yData',yPltH*[1 1],'Visible','on');
                end
            end

            % sets the location of the vertical seperators
            for j = 1:(nCol-1)
                vLineNw = findobj(vLine,'UserData',j);    
                set(vLineNw,'xData',xPltV(j,:),...
                            'yData',yPltV(j,:),'Visible','on');
            end

            % retrieves the handles to the numbers 
            hNum = findobj(obj.hAx,'tag','hNum');

            % sets the region index text (if set)
            for i = 1:nRow
                for j = 1:nCol
                    k = (i-1)*nCol+j;
                    hText = findobj(hNum,'string',num2str(k));
                    if ~isempty(hText)
                        % sets the base x/y location of the text object
                        if isfield(obj.iMov,'iC')
                            if isempty(obj.iMov.iC{k})
                                X = L+(j-0.5)*dW;
                                Y = T+(i-0.5)*dH;                    
                            else
                                X = mean(obj.iMov.iC{k}([1 end]));
                                Y = mean(obj.iMov.iR{k}([1 end]));
                            end
                        else
                            X = L+(j-0.5)*dW;
                            Y = T+(i-0.5)*dH;
                        end

                        % updates the text object position
                        hEx = get(hText,'Extent');        
                        set(hText,'position',[X-(hEx(3)/2) Y 0],...
                                  'visible','on')
                    end
                end
            end    

        end

        % --- creates the individual sub-image rectangle frames
        function setupIndivFrameRect(obj,rPos)

            % sets the number of apparatus to set up
            nApp = obj.iMov.pInfo.nRow*obj.iMov.pInfo.nCol;
            PosNw = zeros(1,4);            

            % sets the colours for the inner rectangles
            if obj.isMove
                % case is for movable inner objects (different colours)
                if mod(obj.iMov.pInfo.nCol,2) == 1
                    col = 'gmyc';    
                else
                    col = 'gmy';    
                end
            else
                % case is for the fixed inner objects (same colours)
                col = 'g';
            end

            % checks to see if the outer rectangles has just been set
            [xLim,yLim] = deal(get(obj.hAx,'xlim'),get(obj.hAx,'ylim'));
            if exist('rPos','var')
                % if so, then initialise the locations of the inner rectangles
                rPosS = cell(nApp,1);
                [nRow,nCol] = deal(obj.iMov.pInfo.nRow,obj.iMov.pInfo.nCol);
                [L,T,W,H] = deal(rPos(1),rPos(2),rPos(3),rPos(4));
                [dW,dH] = deal((W/nCol),(H/nRow));    

                % if there are any negative dimensions, then exit the function
                if any([dW,dH] < 0)
                    return
                end

                % calculates the new locations for all apparatus
                for i = 1:nRow
                    for j = 1:nCol
                        % sets the left/right locations of the sub-window
                        PosNw(1) = min(xLim(2),...
                                max(xLim(1),L+((j-1)*dW+obj.del)));
                        PosNw(2) = min(yLim(2),...
                                max(yLim(1),T+((i-1)*dH+obj.del)));                                               
                        PosNw(3) = (dW-2*obj.del) + ...
                                min(0,xLim(2)-(PosNw(1)+(dW-2*obj.del)));
                        PosNw(4) = (dH-2*obj.del) + ...
                                min(0,yLim(2)-(PosNw(2)+(dH-2*obj.del)));      

                        % updates the sub-image position vectos
                        rPosS{(i-1)*obj.iMov.pInfo.nCol+j} = PosNw;
                    end
                end
            else
                % otherwise, use the previous rectangle positions
                [rPos,rPosS] = deal(obj.iMov.posG,obj.iMov.pos);
            end

            % sets the inner rectangle objects for all apparatus
            for i = find(obj.iMov.ok(:)')
                % determines the new image sub-limits
                [xLimS,yLimS] = obj.setSubImageLimits(xLim,yLim,rPos,i);
                xLimS = [max(rPos(1),...
                    xLimS(1)) min(rPos(1)+rPos(3),xLimS(2))];
                yLimS = [max(rPos(2),...
                    yLimS(1)) min(rPos(2)+rPos(4),yLimS(2))];

                % creates the new rectangle object (region config only)
                if ~obj.iMov.isSet
                    % creates the interactive object
                    hROIF = InteractObj('rect',obj.hAx,rPosS{i});
                    indCol = mod(i-1,length(col))+1;
                    hROIF.setFields('Tag','hInner');

                    % set the position callback function/rectangle colour
                    hROIF.setColour(col(indCol));
                    hROIF.setObjMoveCallback(@obj.roiCallback);
                    
                end

                if obj.isMove                      
                    % sets the constraint region and userdata flag
                    hROIF.setField('UserData',i);
                    hROIF.setConstraintRegion(xLimS,yLimS);

                    % sets the tube seperator lines
                    if obj.isSet
                        % sets the tube x/y coordinates/offsets
                        xTube = obj.iMov.xTube{i};
                        yTube = obj.iMov.yTube{i};
                        xOfs = obj.iMov.pos{i}(1);
                        yOfs = obj.iMov.pos{i}(2);
                        
                        % retrieves the tube count
                        if obj.iMov.isOpt
                            nTube = size(yTube,1)-1;
                        else
                            nTube = getSRCount(obj.iMov,i)-1;
                        end

                        % sets the x/y coordinates of the tube region
                        xTubeS = repmat(xTube+xOfs,nTube,1)';            
                        yTubeS = 0.5*(yTube(1:end-1,2) + ...
                                      yTube(2:end,1))' + yOfs;            
                        yTubeS = repmat(yTubeS,2,1);
                    else
                        % retrieves the tube count
                        nTube = getSRCount(obj.iMov,i);            

                        % sets the x/y coordinates of the tube region
                        xTubeS = repmat(rPosS{i}(1) + ...
                                        [0,rPosS{i}(3)],nTube-1,1)';
                        yTubeS = rPosS{i}(2) + ...
                                        (rPosS{i}(4)/nTube)*(1:(nTube-1));         
                        yTubeS = repmat(yTubeS,2,1);
                    end

                    % plots the tube markers
                    hold(obj.hAx,'on')
                    tagStr = sprintf('hTubeEdge%i',i);
                    line(obj.hAx,xTubeS,yTubeS,'color',col(indCol),...
                            'linestyle','--','tag',tagStr,...
                            'UserData','hTube');        
                    hold(obj.hAx,'off')
                    
                else                                    
                    % sets the constraint function for the rectangle object
                    switch obj.Type
                        case {'GeneralR','Circle','Rectangle','Circ','Rect'}
                            % retrieves the inner region object handles
                            hInner = findall(obj.hAx,'tag','hInner',...
                                                     'UserData',i);
                            if isempty(hInner)
                                % create the objects if the don't exist
                                XX = obj.iMov.iC{i}([1,end]);
                                YY = obj.iMov.iR{i}([1,end]);
                                hold(obj.hAx,'on') 
                                line(XX(obj.ix),YY(obj.iy),'color','g',...
                                            'tag','hInner','UserData',i);
                                hold(obj.hAx,'off')
                            else
                                % otherwise, make the object visible
                                setObjVisibility(hInner,'on')
                            end

                        otherwise
                            % force the object to be fixed
                            if exist('hROIF','var')
                                % sets the x/y extent
                                xLim = rPos(1) + [0,rPos(3)];
                                yLim = rPos(2) + [0,rPos(4)];
                                
                                % updates the resize flag
                                hROIF.setResizeFlag(false); 
                                hROIF.setConstraintRegion(xLim,yLim);
                                hROIF.setFields('Hittest','off')
                            end
                    end
                end            
            end

        end
        
        % ----------------------------------------- %
        % --- MAIN SUB-REGION OUTLINE FUNCTIONS --- %
        % ----------------------------------------- %
        
        % --- sets up the sub-region objects
        function iMov = setupRegionConfig(obj,iMov,isSet,isAutoDetect)
        
            % sets the setup flag
            if ~exist('isSet','var'); isSet = false; end
            if ~exist('isAutoDetect','var'); isAutoDetect = false; end
            
            % initialisations
            obj.iMov = iMov;
            obj.isSet = isSet;
            obj.isAutoDetect = isAutoDetect;
            obj.isMltTrk = detMltTrkStatus(obj.iMov);
            obj.getRegionSetupClassObject();
            
            % removes any previous sub-regions
            obj.deleteRegionConfig()
            
            % determines if the regions have been set
            if obj.isSet
                % otherwise, setup the outer frame from the previous values
                obj.setupMainFrameRect();

            else
                % if not, then prompt the user to set them up
                obj.iMov.posG = obj.setupMainFrameRect();
                obj.iMov = obj.objRS.initSubPlotStruct(obj.iMov);
                
                % updates the sub-region data struct (if not on main)
                if ~obj.isMain
                    obj.objRS.iMov = obj.iMov;
                end
            end        
            
            % resets the tube count/use flags (multi-fly tracking only)
            if obj.isMltTrk
                if isempty(obj.iMov.nFlyR)
                    pInfo = obj.iMov.pInfo;
                    obj.iMov.nFlyR = pInfo.nFly;        
                    obj.iMov.nTubeR = ones(pInfo.nRow,pInfo.nCol);
                end    
            end
            
            % sets the output region data struct
            iMov = obj.iMov;   
            
%             % creates a loadbar (if there are lots of regions to set up)
%             if obj.iMov.is2D || obj.isMltTrk
%                 if numel(iMov.pInfo.iGrp) > 20
%                     lStr = 'Setting Up Separate Regions...';
%                     hProg = ProgressLoadbar(lStr);
%                 end
%             end
            
            % removes any previous markers and updates
            obj.createRegionConfig();            
            
%             % deletes the progress bar
%             if exist('hProg','var')
%                 hProg.delete
%             end
            
        end
        
        % --- creates the subplot regions and line objects
        function createRegionConfig(obj)

            % initialisations
            pInfo = obj.iMov.pInfo;

            % retrieves the GUI objects            
            hold(obj.hAx,'on')

            % sets the region position vectors
            obj.iSelR = [];
            rPosS = obj.iMov.pos;            
            if obj.isMltTrk
                [iColR,iRowR] = deal([]);
            else
                [iColR,iRowR] = deal(1:pInfo.nCol,2:pInfo.nCol);
            end            
            
            % ------------------------------ %
            % --- VERTICAL LINE CREATION --- %
            % ------------------------------ %
            
            % memory allocation
            xVL = cell(pInfo.nCol-1,1);
            [obj.hVL,obj.hVLUD] = deal(cell(1,pInfo.nCol-1));  
            yVL = obj.iMov.posG(2) + [0 obj.iMov.posG(4)];
            obj.use2D = obj.iMov.is2D || obj.isMltTrk;
            
            % sets the position vector
            if obj.use2D
                if ~isempty(obj.iMov.autoP.pPos)
                    pPos = obj.iMov.autoP.pPos';
                end                
            else
                if ~isempty(obj.iMov.pos)
                    pPos = obj.iMov.pos;
                    pPos(~obj.iMov.ok) = obj.iMov.posO(~obj.iMov.ok);
                end
            end

            % only set up vertical lines if there is more than one column
            for i = iRowR
                % sets the x-location of the lines
                if ~isempty(pPos{i})
                    % sets indices of the groups to the left of the line
                    iLf = pInfo.nCol*(0:(pInfo.nRow-1)) + (i-1);

                    % sets locations of the lower top/upper bottom indices
                    xR = max(cellfun(@(x)(sum(x([1 3]))),pPos(iLf)));
                    xL = min(cellfun(@(x)(x(1)),pPos(iLf+1)));  

                    % sets horizontal location of the vertical separator
                    xVL{i-1} = 0.5*(xR+xL)*[1 1];
                else
                    % if no position data, then use the outer region
                    xVL{i-1} = obj.iMov.posO{i}(1)*[1 1];
                end

                % creates the line object and sets the flags
                obj.hVL{i-1} = InteractObj('line',obj.hAx,{xVL{i-1},yVL});
                obj.hVL{i-1}.setFields('Tag','hVert','UserData',i-1);
                
                % updates the version specific interactive object props
                if obj.isOld
                    % case is the old version interactive objects
                    hVLnw = obj.hVL{i-1};
                    tStr = {'end point 1','end point 2'};
                    set(findobj(hVLnw,'tag',tStr{1}),'hittest','off');
                    set(findobj(hVLnw,'tag',tStr{2}),'hittest','off');
                else
                    % case is the new version interactive objects
                    tStr = 'translate';
                    obj.hVL{i-1}.setFields('InteractionsAllowed',tStr);                    
                end
                
                % updates the marker properties/callback function
                obj.hVL{i-1}.setColour('r');
                obj.hVL{i-1}.setObjMoveCallback(@obj.vertCallback);                
                obj.setVertMarkerConstrainFcn(i);                
            end

            % -------------------------------- %
            % --- HORIZONTAL LINE CREATION --- %
            % -------------------------------- % 
            
            % memory allocation
            obj.xHL = cell(pInfo.nCol,1);
            obj.hHL = cell(pInfo.nRow-1,pInfo.nCol);
            
            % only set up the horizontal lines if more than one column
            for j = iColR
                % sets the x-location of the lines
                pO = obj.iMov.posO{j};
                if pInfo.nCol == 1
                    % case is there is only one column group
                    obj.xHL{j} = pO(1)+[0,pO(3)];
                else
                    % case is there are multiple column groups
                    switch j
                        case 1
                            obj.xHL{j} = [pO(1),xVL{j}(1)];

                        case obj.iMov.pInfo.nCol
                            obj.xHL{j} = [xVL{j-1}(1),sum(pO([1,3]))];

                        otherwise
                            obj.xHL{j} = [xVL{j-1}(1),xVL{j}(1)];

                    end        
                end

                % creates the line objects
                for i = 2:pInfo.nRow
                    % sets the y-location of the line
                    if ~isempty(obj.iMov.pos)
                        iLo = (i-2)*pInfo.nCol + j;
                        iHi = (i-1)*pInfo.nCol + j;
                        yHL = 0.5*(sum(pPos{iLo}([2 4])) + ...
                                   sum(pPos{iHi}(2)))*[1 1];
                    else
                        k = pInfo.nCol + (j-1);
                        yHL = obj.iMov.posO{k}(2)*[1 1];
                    end

                    % creates the line object and sets the properties
                    hHL0 = InteractObj('line',obj.hAx,{obj.xHL{j},yHL});
                    hHL0.setFields('Tag','hHorz','UserData',[i,j]);
                    
                    % updates the other line object properties                                        
                    hHL0.setColour('r')                                        
                    obj.setHorzMarkerConstrainFcn(hHL0,i,j);
                    hHL0.setObjMoveCallback(@obj.horzCallback);
                    
                    % sets the left-coordinate for the vertical line
                    if j > 1
                        obj.hVLUD{j-1} = [obj.hVLUD{j-1};{hHL0,1,i,j}];
                    end

                    % sets the right-coordinate for the vertical line
                    if j < pInfo.nCol
                        obj.hVLUD{j} = [obj.hVLUD{j};{hHL0,2,i,j}]; 
                    end
                    
                    % sets the horizontal line object handle
                    obj.hHL{i-1,j} = hHL0;
                end
            end                        

            % ----------------------------------- %
            % --- TUBE REGION OBJECT CREATION --- %
            % ----------------------------------- %
            
            % memory allocation            
            okF = obj.iMov.ok;            
            cbFcnR = @obj.roiCallback2D;       
            cbFcnMT = @obj.roiCallbackMT;
            
            % case is for movable inner objects (different colours)
            obj.hROI = cell(size(okF));                            
            if mod(pInfo.nCol,2) == 1
                col = 'gmyc';    
            else
                col = 'gmy';    
            end
            
            if obj.use2D
                iReg = 1:pInfo.nCol;                
            else
                iReg = find(obj.iMov.ok);
            end

            % sets the inner rectangle objects for all apparatus
            for i = iReg(:)'
                % sets the row/column indices
                iCol = mod(i-1,pInfo.nCol) + 1;
                iRow = floor((i-1)/pInfo.nCol) + 1;

                % sets the sub-region limits
                if ~obj.isMltTrk
                    xLimS = obj.getRegionXLim(iCol);
                    yLimS = obj.getRegionYLim(iRow,iCol);
                end

                % retrieves the new fly count index
                nTubeNw = getSRCount(obj.iMov,i);
                indCol = mod(i-1,length(col))+1;  
%                 xTubeS0 = rPosS{i}(1)+[0 rPosS{i}(3)];
%                 xTubeS = repmat(xTubeS0,nTubeNw-1,1)';
                
                % creates the new rectangle object
                if obj.use2D
                    % memory allocation
                    if i == 1
                        [obj.pX,obj.pY,obj.pH,obj.pW] = deal([]); 
                    end                    
                    
                    % calculates the vertical tube region coordinates
                    xiN = num2cell(1:nTubeNw)';
                    widPos = sum(rPosS{i}([2,4]));
                    col = distinguishable_colors(pInfo.nGrp,'k');
                    yTube0 = linspace(rPosS{i}(2),widPos,nTubeNw+1)';
                    yTubeS = num2cell([yTube0(1:end-1),yTube0(2:end)],2);                    

                    % calculates the sub-region outline coordinates
                    pPosV = obj.getRegionPosVec(i);
                    
                    % case is 2D setup expt
                    switch obj.iMov.mShape
                        case {'Rect','Rectangle'}
                            % case is using rectangular shapes
                            
                            % creates the objects for each region
                            obj.hROI{i} = cellfun(@(x)(InteractObj...
                                    ('rect',obj.hAx,x)),pPosV,'un',0);

                        case {'Circ','Circle'}
                            % case is using circular shapes

                            % creates the circle objects
                            obj.hROI{i} = cell(length(pPosV),1);
                            for j = 1:length(pPosV)
                                % retrieves the original dimensions
                                p0 = pPosV{j}(1:2);
                                szObj = pPosV{j}(3:4);                    
                                
                                % resets the position vector
                                pPosV{j}(1) = ...
                                        p0(1) + (szObj(1)-pPosV{j}(3))/2;
                                pPosV{j}(2) = ...
                                        p0(2) + (szObj(2)-pPosV{j}(4))/2;
                                pPosV{j}(3:4) = min(szObj); 
                                    
                                % creates the circle object
                                obj.hROI{i}{j} = InteractObj(...
                                        'ellipse',obj.hAx,pPosV{j});
                                obj.hROI{i}{j}.setAspectRatioFlag(true);
                            end
                    end        

                    % updates the ROI object properties
                    cellfun(@(h,x)(h.setFields('tag','hInner',...
                                'UserData',[x,iCol])),obj.hROI{i},xiN);
                    
                    % if moveable, then set the position callback function
                    for j = 1:length(obj.hROI{i})
                        % determines the region index
                        indF = pInfo.iGrp(j,i);
                        if ~indF
                            obj.hROI{i}{j}.setLineProps('Visible','off')
                            continue
                        end
                        
                        % sets main object properties/callback functions
                        obj.hROI{i}{j}.setColour(col(indF,:));                           
                        
                        % sets the region constraint function
                        if obj.isMltTrk
                            obj.hROI{i}{j}.setObjMoveCallback(cbFcnMT);                            
                        else
                            obj.hROI{i}...
                                {j}.setConstraintRegion(xLimS,yTubeS{j});
                            obj.hROI{i}{j}.setObjMoveCallback(cbFcnR);
                        end
                        
                        % resets the marker sizes
                        mSz = ceil(mean(pPosV{j}(3:4))/100);
                        obj.hROI{i}{j}.setMarkerSize(mSz); 
                    end

                    % resets the axes properties
                    set(obj.hAx,'Layer','Bottom','SortMethod','childorder')

                else
                    % memory allocation
                    if i == 1
                        A = zeros(pInfo.nRow*pInfo.nCol,1);
                        [obj.pX,obj.pY,obj.pH,obj.pW] = deal(A);                        
                    end
                    
                    % case is 1D setup expt
                    pPos = obj.iMov.pos{i};
                    obj.hROI{i} = InteractObj('rect',obj.hAx,pPos);
                    obj.hROI{i}.setColour(col(indCol));                    
                    obj.hROI{i}.setFields('Tag','hInner','UserData',i);                    

                    % sets the proportional height/width values
                    obj.calcPropRegionDim(pPos,i);                    
                    
                    if obj.isAutoDetect
                        % disables the marker objects/hit-test
                        obj.hROI{i}.disableObj();
                        
                    else
                        % sets the constraint region for the inner regions
                        obj.hROI{i}.setObjMoveCallback(@obj.roiCallback);
                        obj.hROI{i}.setConstraintRegion(xLimS,yLimS);
                    end

                    % creates the individual tube markers
                    colStr = [col(indCol),'--'];                    
                    [xT,yT] = obj.calcTubeCoords(rPosS{i},nTubeNw);
                    plot(obj.hAx,xT,yT,colStr,'tag',...
                              sprintf('hTubeEdge%i',i),'UserData','hTube');     
                end
            end

            % resets the mapping mask
            if obj.isMltTrk
                obj.ImapR = obj.setupRegionMask;
            end

            % resets the plotting objects (so inner objects are on top)
            hObjC = obj.hAx.Children;
            hInner = findall(hObjC,'Tag','hInner');
            [~,iA] = setdiff(hObjC,hInner,'stable');            
            B = setGroup(iA,size(hObjC));
            obj.hAx.Children = [hObjC(~B);hObjC(B)];

            % resets the axes sort method
            obj.hAx.SortMethod = 'childorder';
            
            % turns the axis hold off
            hold(obj.hAx,'off')

        end         
        
        % --- removes the sub-regions
        function deleteRegionConfig(obj,varargin)

            % retrieves the GUI objects
            try
                hGUI = get(obj.objRS,'hGUI');
                if isempty(hGUI); return; end
            catch
            end

            % removes all the division marker objects
            delete(findobj(obj.hAx,'tag','hOuter'));
            delete(findobj(obj.hAx,'tag','hVert'));
            delete(findobj(obj.hAx,'tag','hHorz'));
            delete(findobj(obj.hAx,'tag','hNum'));
            delete(findobj(obj.hAx,'tag','hInner'));

            % deletes all the tube-markers
            delete(findobj(obj.hAx,'UserData','hTube'));

            % removes the sub-region viewing menu object
            if ~isempty(varargin)
                obj.hMenuSR = [];
            end
            
        end
        
        % ------------------------------------- %
        % --- SUB-REGION PLOTTING FUNCTIONS --- %
        % ------------------------------------- %                

        % --- creates the circle outlines
        function createCircleOutlines(obj)

            % adds a hold to the axis
            hold(obj.hAx,'on');

            % sets the X/Y coordinates of the circle centres
            eStr = {'off','on'};
            R = obj.iMov.autoP.R;
            [X,Y] = deal(obj.iMov.autoP.X0,obj.iMov.autoP.Y0);
            [XC0,YC0] = deal(obj.iMov.autoP.XC,obj.iMov.autoP.YC);

            % determines if the circle coordinates need to be scaled
            [nRow,nCol] = size(X);
            sclC = ((nRow*nCol) > 1) && (numel(R) > 1);
            
            % retrieves the group indices
            if isfield(obj.iMov,'pInfo')    
                iGrp = obj.iMov.pInfo.iGrp;
            else
                iGrp = ones(size(X));
            end

            % retrieves the patch colours
            tCol = getAllGroupColours(max(iGrp(:)));

            % loops through all the sub-regions plotting the general objects  
            for iCol = 1:nCol
                % creates the new fill objects for each valid region    
                for k = 1:nRow
                    % sets the plot values
                    if sclC
                        [XC,YC] = deal(R(k,iCol)*XC0,R(k,iCol)*YC0);
                    else
                        [XC,YC] = deal(XC0,YC0);
                    end
                    
                    % calculates the new coordinates and plots the circle
                    pCol = tCol(iGrp(k,iCol)+1,:);
                    isVis = eStr{1+(iGrp(k,iCol)>0)};
                    [xP,yP] = deal(X(k,iCol)+XC,Y(k,iCol)+YC);
                    fill(xP,yP,pCol,'tag','hOuter','UserData',[iCol,k],...
                           'facealpha',0.25,'LineWidth',obj.lWid,...
                           'Parent',obj.hAx,'visible',isVis)
                end
            end  

            % removes the hold
            hold(obj.hAx,'off');

        end

        % --- creates the general object outlines
        function createGeneralOutlines(obj)

            % adds a hold to the axis
            hold(obj.hAx,'on');

            % sets the object location/outline coordinates
            aP = obj.iMov.autoP;
            eStr = {'off','on'};
            [X0,Y0,XC,YC] = deal(aP.X0,aP.Y0,aP.XC,aP.YC);

            % retrieves the group indices
            if isfield(obj.iMov,'pInfo')    
                iGrp = obj.iMov.pInfo.iGrp;
            else
                iGrp = ones(size(X0));
            end

            % retrieves the patch colours
            tCol = getAllGroupColours(max(iGrp(:)));

            % loops through all the sub-regions plotting the general objects  
            [nRow,nCol] = size(X0);
            for iCol = 1:nCol    
                for k = 1:nRow
                    pCol = tCol(iGrp(k,iCol)+1,:);
                    fill(X0(k,iCol)+XC,Y0(k,iCol)+YC,pCol,'tag','hOuter',...
                           'UserData',[iCol,k],'facealpha',0.25,...
                           'LineWidth',1,'Parent',obj.hAx,...
                           'Visible',eStr{1+(iGrp(k,iCol)>0)})
                end
            end 

            % removes the hold
            hold(obj.hAx,'off');

        end        
        
        % ----------------------------------- %
        % --- ROI OBJECT UPDATE FUNCTIONS --- %
        % ----------------------------------- %        
        
        % --- the callback function for moving the vertical seperator
        function vertCallback(obj,varargin)

            % resets the update flag
            obj.isUpdating = true;

            % retrieves the object handle and the index of the line
            switch length(varargin)
                case 1
                    % case is the older version interactive objects
                    lPos = varargin{1};
                    iVL = get(get(gco,'parent'),'UserData');
                    
                case 2
                    % case is the newer version interactive objects
                    lPos = varargin{2}.CurrentPosition;
                    iVL = varargin{1}.UserData;
            end
            
            % updates the attached horizontal line properties
            uD = obj.hVLUD{iVL};
            for i = 1:size(uD,1)
                % updates the position of the attached line
                lPos0 = getIntObjPos(uD{i,1}.hObj);
                lPos0(uD{i,2},1) = lPos(1,1);                
                setIntObjPos(uD{i,1}.hObj,lPos0);

                % sets the position constraint function    
                yLimNw = obj.getHorzYLimNw(uD{i,3},uD{i,4});                
                uD{i,1}.setConstraintRegion(lPos0(:,1),yLimNw);
            end

            % updates the position of the inner regions
            obj.updateInnerRegions(iVL,true)
            setObjEnable(obj.hButU,'on')

            % resets the flag
            obj.isUpdating = false;

        end

        % --- the callback function for moving the horizontal seperator
        function horzCallback(obj,varargin)

            % determines if an object updating is taking place already
            if obj.isUpdating
                % if already updating, then exit the function
                return
            else
                % otherwise, flag that updating is occuring
                obj.isUpdating = true;
            end

            % retrieves the object handle and the index of the line
            switch length(varargin)
                case 1
                    % case is the older version interactive objects
                    iVL = get(get(gco,'parent'),'UserData');
                    
                case 2
                    % case is the newer version interactive objects
                    iVL = varargin{1}.UserData;
            end            

            % updates the position of the inner regions
            obj.updateInnerRegions(iVL,false)
            setObjEnable(obj.hButU,'on')
            
            % resets the flag to false
            obj.isUpdating = false;

        end

        % --- the callback function for moving the 2D inner tube regions
        function roiCallback2D(obj,varargin)
            
            % if updating then exit
            if obj.isUpdating
                return
            end
            
            switch length(varargin)
                case 1
                    % case is the old format objects
                    rPos = varargin{1};
                    hObjR = get(gco,'Parent');
                    
                case 2
                    % case is the new format objects
                    
                    % retrieves the object/event handles
                    [hObjR,evnt] = deal(varargin{1},varargin{2});
                    if isa(hObjR,'images.roi.Ellipse')
                        % case is the object is an ellipse
                        pC = evnt.CurrentCenter;
                        pAx = evnt.CurrentSemiAxes;
                        rPos = [(pC-pAx),2*pAx];                        
                    else
                        % case is the other objects
                        rPos = evnt.CurrentPosition;
                    end
            end

            % retrieves the sub-region data object
            uData = get(hObjR,'UserData');

            % enables the update button
            setObjEnable(obj.hButU,1)

            % add in code here to update region coordinates
            %  - fill out autoP field

            % updates the region markers based on type
            if ~isempty(obj.objRS.objSR) && obj.objRS.objSR.isOpen
                % case is the split region marker is being updated
                obj.updateSplitRegionMarker(uData,rPos)
            else
                % case is a region config marker is being updated
                try
                    [iApp,iTube] = deal(uData(2),uData(1));
                catch
                    return
                end
                
                % updates the positional marker vector
                obj.objRS.iMov.autoP.pPos{iTube,iApp} = rPos;
                if strcmp(obj.iMov.pInfo.mShape,'Circle')
                    % ensures the shape is circular
                    rPos(3:4) = max(rPos(3:4));
                    obj.objRS.iMov.autoP.pPos{iTube,iApp} = rPos;                    
                    
                    % resets the inner region index
                    obj.iAppInner = iApp;
                    
                    % resets the region position
                    obj.manReset = true;
                    setIntObjPos(hObjR,rPos,obj.isOld);
                    obj.manReset = false;
                end
                
                % resets the sub-region limits
                obj.resetRegionLimits2D(iApp,iTube);
                obj.resetMarkerLimits2D(iApp,iTube);
            end

        end
        
        % --- callback function for the multi-tracking
        function roiCallbackMT(obj,hObjR,evnt)
                                    
            % updates the region mask image (if change in selected region)
            if obj.manReset
                % manual reset?
                return
            
            elseif ~isequal(obj.iSelR,hObjR.UserData)
                if ~isempty(obj.iSelR)
                    obj.ImapR(obj.ImapR == obj.indS) = 0;
                    obj.ImapR = obj.ImapR + obj.setupRegionMask(obj.indS);
                end
                
                % resets the region selection flag
                obj.iSelR = hObjR.UserData;
                
                % sets the linear selection index
                nCol = obj.iMov.pInfo.nCol;
                obj.indS = (obj.iSelR(1)-1)*nCol + obj.iSelR(2);
            end
                
            % determines if there is any region overlap            
            switch obj.iMov.mShape
                case 'Rect'
                    % case are rectangular regions                    
                    [ii,jj] = obj.getRectIndices(evnt.CurrentPosition);
                    ImapV = arr2vec(obj.ImapR(ii,jj));
                    
                    % resets the region position (if overlapping)                 
                    if any(nonzeros(ImapV) ~= obj.indS)
                        obj.manReset = true;
                        setIntObjPos(hObjR,evnt.PreviousPosition,obj.isOld);
                        obj.manReset = false;
                    end
                    
                case 'Circ'
                    % case is circular regions
                    p0 = roundP(evnt.CurrentCenter);
                    R = roundP(evnt.CurrentSemiAxes(1));
                    
                    % sets up the circle region mask
                    [ii,jj,Dnw] = obj.getCircIndices(p0,R);                    
                    ImapV = arr2vec(obj.ImapR(ii,jj).*Dnw);
                    
                    % resets the region position (if overlapping)                 
                    if any(nonzeros(ImapV) ~= obj.indS)
                        % sets the previous coordinates
                        pAx = evnt.PreviousSemiAxes*2;
                        pC = evnt.PreviousCenter - pAx/2;
                        
                        % resets the object position
                        obj.manReset = true;                        
                        setIntObjPos(hObjR,[pC,pAx],obj.isOld);
                        obj.manReset = false;
                    end   
                
            end
            
            % enables the update button
            setObjEnable(obj.hButU,'on')
            
        end
        
        % --- resets the 2D horizontal/vertical region marker limits
        function resetMarkerLimits2D(obj,iApp,iRow)
            
            % sets the row/column indices
            pInfo = obj.iMov.pInfo;
            iCol = mod((iApp-1),pInfo.nCol) + 1;
            
            % updates the vertical markers
            if pInfo.nCol > 1
                ii = iCol + [0,1];                
                for i = ii((ii > 1) & (ii <= pInfo.nCol))
                    obj.setVertMarkerConstrainFcn(i)
                end
            end
            
            % resets the horizontal marker constraint region
            if pInfo.nRow > 1
                jj = iRow + [0,1];                            
                for j = jj((jj > 1) & (jj <= pInfo.nRow))
                    hHLnw = obj.hHL{j-1,iCol};
                    obj.setHorzMarkerConstrainFcn(hHLnw,j,iCol);
                end                                
            end            
            
        end
        
        % --- resets the 2D region limits
        function resetRegionLimits2D(obj,iApp,iT)
            
            % sets the row/column indices
            [iRow,iCol] = obj.ind2RC(iApp);                       
            
            % retrieves the x/y limits of the region
            xLT = obj.getRegionXLim(iCol);
            yLT = obj.getRegionYLim(iRow,iCol);
            
            if iT > 1
                % resets the upper region limits
                yL0 = obj.getRegionLimits2D(yLT,iApp,iT-1);
                obj.hROI{iApp}{iT-1}.setConstraintRegion(xLT,yL0);
                                
                % resets the current region limits
                yL1 = obj.getRegionLimits2D(yLT,iApp,iT);
                obj.hROI{iApp}{iT}.setConstraintRegion(xLT,yL1);
            end
               
            if iT < size(obj.iMov.flyok,1)
                % resets the upper region limits
                yL1 = obj.getRegionLimits2D(yLT,iApp,iT);
                obj.hROI{iApp}{iT}.setConstraintRegion(xLT,yL1);
                
                % resets the current region limits
                yL2 = obj.getRegionLimits2D(yLT,iApp,iT+1);
                obj.hROI{iApp}{iT+1}.setConstraintRegion(xLT,yL2);
            end
            
        end        
        
        % --- resets the 2d region limit marker objects
        function yL = getRegionLimits2D(obj,yLT,iApp,iT)
            
            % initialisations
            nRow = obj.iMov.pInfo.nRow;            
            
            % 
            if nRow == 1
                % case is there is only one sub-region
                yL = yLT;
            else                
                % case is there is more than one sub-region
                switch iT
                    case 1
                        % case is sub-region is on first row 
                        pP2 = obj.getRegionPosVec(iApp,iT+1);                        
                        yL = [yLT(1),floor(pP2(2))];

                    case nRow
                        % case is sub-region is on last row
                        pP0 = obj.getRegionPosVec(iApp,iT);
                        yL = pP0(2)+[0,pP0(4)];

                    otherwise
                        % case is sub-region is on other row
                        pP0 = obj.getRegionPosVec(iApp,iT-1);
                        pP2 = obj.getRegionPosVec(iApp,iT+1);
                        yL = [sum(pP0([2,4])),floor(pP2(2))];
                end
            end
            
        end
        
        % --- the split-region region markers
        function updateSplitRegionMarker(obj,uData,rPos)

            % retrieves the marker line objects 
            hMarkR = obj.objRS.objSR.hMarkR{uData(2),uData(1)};

            % initialisation
            obj.objRS.objSR.isUpdating = true;

            % updates the marker object positions
            switch obj.objRS.objSR.mShape
                case 'Rect'
                    % case is rectangular regions

                    % rectangle parameters/limits
                    [p0nw,W,H] = deal(rPos(1:2),rPos(3),rPos(4));  
                    [xLim,yLim] = deal(p0nw(1)+[0,W],p0nw(2)+[0,H]);

                    % resets the vertical marker lines
                    pWidSR = obj.objRS.objSR.pWid;
                    pWid = W*cumsum(pWidSR{uData(2),uData(1)});         
                    for i = find(~cellfun('isempty',hMarkR(:,1)))'
                        % recalculates the new position of the markers
                        pNw = [(p0nw(1)+pWid(i)*[1;1]),(p0nw(2)+H*[0;1])];

                        % resets the object properties
                        hMarkR{i,1}.setPosition(pNw);                        
                        hMarkR{i,1}.setConstraintRegion(xLim,yLim);                        
                    end

                    % resets the horizontal marker lines
                    pHghtSR = obj.objRS.objSR.pHght;
                    pHght = H*cumsum(pHghtSR{uData(2),uData(1)}); 
                    for i = find(~cellfun('isempty',hMarkR(:,2)))'
                        % recalculates the new position of the markers
                        pNw = [(p0nw(1)+W*[0;1]),(p0nw(2)+pHght(i)*[1;1])];

                        % resets the object properties
                        hMarkR{i,2}.setPosition(pNw);                        
                        hMarkR{i,2}.setConstraintRegion(xLim,yLim);                        
                    end

                case 'Circ'
                    % case is circular regions

                    % circle parameters
                    Rnw = rPos(3)/2;
                    p0nw = rPos(1:2)+Rnw;

                    % resets the marker line objects
                    pPhiSR = obj.objRS.objSR.pPhi;                    
                    phiP = pPhiSR{uData(2),uData(1)};
                    for i = 1:length(hMarkR)
                        pNw = [p0nw;(p0nw+Rnw*[cos(phiP(i)),sin(phiP(i))])];
                        hMarkR{i}.setPosition(pNw);
                    end
            end

            % resets the update flag
            obj.objRS.objSR.isUpdating = false;            
            
        end
        
        % --- the callback function for moving the inner tube regions
        function roiCallback(obj,varargin)

            switch length(varargin)
                case 1
                    % case is old version roi callback
                    rPos = varargin{1};
                    
                case 2
                    % case is double input 
                    if isa(varargin{1},'double')
                        [rPos,iApp] = deal(varargin{1},varargin{2});
                    else                        
                        iApp = get(varargin{1},'UserData');
                        if isa(varargin{2},'double')
                            rPos = varargin{2};
                        else
                            rPos = varargin{2}.CurrentPosition();
                        end
                    end
            end
            
            % sets the apparatus index
            if ~exist('iApp','var')
                if obj.manReset
                    iApp = obj.iAppInner;
                else
                    iApp = get(get(gco,'Parent'),'UserData');
                end
            end

            % retrieves the sub-region data struct
            nTube = getSRCount(obj.iMov,iApp);
            [xT,yT] = obj.calcTubeCoords(rPos,nTube);

            % resets the locations of the flies
            hTubeE = findobj(obj.hAx,'tag',sprintf('hTubeEdge%i',iApp));
            set(hTubeE,'xData',xT,'yData',yT);            

            % if not updating, then reset the proportional dimensions
            if ~obj.isUpdating
                % retrieves the sub-region data struct
                obj.resetRegionPropDim(rPos,iApp);   

                % enables the update button
                setObjEnable(obj.hButU,'on')
            end 

        end
        
        % --- resets the region proportional dimensions
        function resetRegionPropDim(obj,rPos,iApp)

            % sets the row/column indices
            iRow = floor((iApp-1)/obj.iMov.pInfo.nCol) + 1;
            iCol = mod((iApp-1),obj.iMov.pInfo.nCol) + 1;

            % retrieves the x/y limits of the region
            xLim = obj.getRegionXLim(iCol);
            yLim = obj.getRegionYLim(iRow,iCol);

            % recalculates the proportional dimensions
            [W,H] = deal(diff(xLim),diff(yLim));
            obj.pX(iApp) = (rPos(1)-xLim(1))/W;
            obj.pY(iApp) = (rPos(2)-yLim(1))/H;
            [obj.pW(iApp),obj.pH(iApp)] = deal(rPos(3)/W,rPos(4)/H);

        end

        % --- updates the position of the inner regions (if the 
        %     vertical/horizontal line objects are being moved)
        function updateInnerRegions(obj,iL,isVert)

            % field retrieval
            [nCol,nRow] = deal(obj.iMov.pInfo.nCol,obj.iMov.pInfo.nRow);
            nReg = nRow*nCol;            
            
            % updates the inner region based on the line being moved
            if isVert
                % case is moving a vertical line    
                for j = 1:2
                    % sets the indices of the inner regions being affected
                    iOfs = iL + (j-2);
                    xLim = obj.getRegionXLim(iL+(j-1));
                    iApp = (1:nCol:nReg) + iOfs;

                    % updates the position of the regions and their 
                    % constraint regions
                    for i = 1:nRow
                        %
                        if obj.use2D
                            uD = [i,iL+(j-1)];
                        else
                            uD = iApp(i);
                        end
                        
                        % retrieves the handle of the inner object
                        obj.iAppInner = iApp(i);                                                
                        hInner = findall(obj.hAx,'Tag','hInner',...
                                                 'UserData',uD);

                        % retrieves the height limits of the 
                        yLim = obj.getRegionYLim(i,iL+(j-1));

                        % retrieves the in
                        if ~isempty(hInner)
                            % sets the new inner region position
                            inPos = getIntObjPos(hInner,obj.isOld);                            
                                
                            if ~obj.use2D
                                inPos(1) = xLim(1) + ...
                                                obj.pX(iApp(i))*diff(xLim);              
                                inPos(3) = obj.pW(iApp(i))*diff(xLim);
                            end
                            
                            % resets the the inner region position
                            obj.manReset = true;
                            setIntObjPos(hInner,inPos,obj.isOld);
                            obj.manReset = false;                            
                            
                            % sets the constraints for the inner regions
                            setConstraintRegion...
                                    (hInner,xLim,yLim,obj.isOld,'rect');                            
                        end
                    end
                end
            else
                % case is moving a horizontal line   
                for j = 1:2
                    % retrieves the height limits of the 
                    iApp = (iL(1)+(j-3))*nCol + iL(2);
                    yLim = obj.getRegionYLim(iL(1)+(j-2),iL(2));
                    xLim = obj.getRegionXLim(iL(2));

                    % retrieves the handle of the inner object
                    obj.iAppInner = iApp;
                    hInner = findall(obj.hAx,'tag','hInner','UserData',iApp);   

                    % retrieves the in
                    if ~isempty(hInner)
                        % sets the new inner region position 
                        inPos = getIntObjPos(hInner,obj.isOld);
                        inPos(2) = yLim(1) + obj.pY(iApp)*diff(yLim);              
                        inPos(4) = obj.pH(iApp)*diff(yLim);

                        % sets the inner region position
                        obj.manReset = true;
                        setIntObjPos(hInner,inPos,obj.isOld);                        
                        obj.manReset = false;
                        
                        % sets the constraint region for the inner regions                        
                        setConstraintRegion...
                                    (hInner,xLim,yLim,obj.isOld,'rect');
                    end
                end
            end

        end
        
        % ------------------------------------- %
        % --- REGION/OBJECT LIMIT FUNCTIONS --- %
        % ------------------------------------- %
        
        % --- retrieves the horizontal seperator line limits (original)
        function yLim = getHorzYLim(obj,iRow,iCol)

            % memory allocation
            yLim = zeros(1,2);
            yGapNw = 3*(nargin == 3)*obj.yGap;

            % sets the limits based on the experiment region type
            if obj.iMov.is2D
                % case is a 2D expt setup            
            
                % retrieves coordinate arrays for the lower columns
                pPLo = obj.getRegionRowPosVec(iRow-1,iCol);
                pPHi = obj.getRegionRowPosVec(iRow,iCol);
                                
                % sets the lower/upper limits
                yLim = [sum(pPLo([2,4])),pPHi(2)];    
                if sign(diff(yLim)) < 0
                    yLim = mean(yLim)*[1,1];
                end
                
            else
                % case is a 1D expt setup
                
                % sets the lower limit
                if iRow == 2
                    yLim(1) = obj.iMov.posG(2) + yGapNw;
                else
                    iL = (iRow-2)*obj.iMov.pInfo.nCol + iCol;    
                    yLim(1) = obj.iMov.pos{iL}(2) + yGapNw;
                end

                % sets the upper limit
                if iRow == obj.iMov.pInfo.nRow
                    yLim(2) = sum(obj.iMov.posG([2 4])) - yGapNw;
                else
                    iU = iRow*obj.iMov.pInfo.nCol + iCol;
                    yLim(2) = obj.iMov.pos{iU}(2) - yGapNw;
                end
            end

        end
        
        % --- retrieves the horizontal seperator line limits (callback)
        function yLim = getHorzYLimNw(obj,iRow,iCol)

            % memory allocation
            [yLim,yGapNw] = deal(zeros(1,2),3*obj.yGap);

            % sets the lower limit
            if iRow == 2
                yLim(1) = obj.iMov.posG(2) + yGapNw;
            else
                % retrieves the line position vector
                uD = [iRow-1,iCol];
                hLineH = findall(obj.hAx,'tag','hHorz','UserData',uD);
                lPos = getIntObjPos(hLineH,obj.isOld); 
                
                % resets the lower limit
                yLim(1) = lPos(1,2) + yGapNw;    
            end

            % sets the upper limit
            if iRow == obj.iMov.pInfo.nRow
                yLim(2) = sum(obj.iMov.posG([2 4])) - yGapNw;
            else
                % retrieves the line position vector
                uD = [iRow+1,iCol];
                hLineH = findall(obj.hAx,'tag','hHorz','UserData',uD);
                lPos = getIntObjPos(hLineH,obj.isOld);             
                
                % resets the upper limit
                yLim(2) = lPos(1,2) - yGapNw;
            end

        end
        
        % --- retrieves the vertical seperator line limits (original)
        function xLim = getVertXLim(obj,iCol)

            % memory allocation and other initialisations
            xLim = zeros(1,2);
            xGapNw = 3*(nargin == 2)*obj.xGap;

            % sets the limits based on the experiment region type
            if obj.iMov.is2D
                % case is a 2D expt setup

                % retrieves coordinate arrays for the lower/upper columns
                pPLo = obj.getRegionPosVec(iCol-1);
                pPHi = obj.getRegionPosVec(iCol);
                
                % sets the lower/upper limits
                xLim = [max(cellfun(@(x)(sum(x([1,3]))),pPLo)),...
                        min(cellfun(@(x)(x(1)),pPHi))];
                if sign(diff(xLim)) == -1
                    xLim = mean(xLim)*[1,1];
                end
                
            else
                % case is a 1D expt setup
                
                % sets the lower limit
                if iCol == 2
                    xLim(1) = obj.iMov.posG(1) + xGapNw;
                else
                    xLim(1) = obj.iMov.posO{iCol-1}(1) + xGapNw;
                end

                % sets the upper limit
                if iCol == obj.iMov.pInfo.nCol
                    xLim(2) = sum(obj.iMov.posG([1 3])) - xGapNw;
                else
                    xLim(2) = obj.iMov.posO{iCol+1}(1) - xGapNw;
                end
            end

        end        
        
        % --- returns the x-limits of the sub-region
        function xLim = getRegionXLim(obj,iCol)

            % memory allocation
            tStr = 'hVert';
            xLim = zeros(1,2);

            % gets the lower limit based on the row count
            if iCol == 1
                % sets the lower limit to be the bottom
                xLim(1) = obj.iMov.posG(1);
%                 xLim(1) = obj.iMov.iC{1}(1);
                
            else
                % retrieves the position of the lower line region
                hLineV = findall(obj.hAx,'Tag',tStr,'UserData',iCol-1);
                lPosL = getIntObjPos(hLineV,obj.isOld);
                xLim(1) = lPosL(1,1);
            end

            % gets the upper limit based on the row count
            if iCol == obj.iMov.pInfo.nCol
                % sets the upper limit to be the top
                xLim(2) = sum(obj.iMov.posG([1 3]));
%                 xLim(2) = obj.iMov.iC{end}(end);
                
            else
                % retrieves the position of the upper line region
                hLineV = findall(obj.hAx,'Tag',tStr,'UserData',iCol);
                lPosR = getIntObjPos(hLineV,obj.isOld);
                xLim(2) = lPosR(1,1);    
            end

        end

        % --- returns the y-limits of the sub-region
        function yLim = getRegionYLim(obj,iRow,iCol)

            % memory allocation
            yLim = zeros(1,2);

            % gets the lower limit based on the row count
            if iRow == 1
                % sets the lower limit to be the bottom
                yLim(1) = obj.iMov.posG(2);
%                 yLim(1) = obj.iMov.iR{1}(1);

            else
                % retrieves the position of the lower line region
                uD = [iRow,iCol];
                hLineH = findall(obj.hAx,'tag','hHorz','UserData',uD);
                lPosLo = getIntObjPos(hLineH);

                % sets the lower limit
                yLim(1) = lPosLo(1,2);
            end

            % gets the upper limit based on the row count
            if iRow == obj.iMov.pInfo.nRow
                % sets the upper limit to be the top
                yLim(2) = sum(obj.iMov.posG([2 4]));
%                 yLim(2) = obj.iMov.iR{end}(end);                

            else
                % retrieves the position of the upper line region
                uD = [iRow+1,iCol];
                hLineH = findall(obj.hAx,'tag','hHorz','UserData',uD);
                lPosHi = getIntObjPos(hLineH);

                % sets the upper limit
                yLim(2) = lPosHi(1,2);    
            end

        end                    
        
        % ------------------------------------------ %
        % --- MAIN GUI OBJECT CALLBACK FUNCTIONS --- %
        % ------------------------------------------ %
                
        % --- sets up the region mask
        function Imap = setupRegionMask(obj,indR)
            
            % memory allocation
            nCol = obj.iMov.pInfo.nCol;
            szImg = [max(get(obj.hAx,'YLim')),max(get(obj.hAx,'XLim'))];
            [Imap,aP] = deal(zeros(szImg),obj.iMov.autoP);
            
            % default input arguments
            if ~exist('indR','var'); indR = 1:numel(aP.pPos); end            
            [hObj,hObjR] = deal(findall(obj.hAx,'Tag','hInner'),[]); 
            
            % sets the outer region
            Binner = ones(szImg);
            [iiI,jjI] = obj.getRectIndices(roundP(obj.iMov.posG));
            Binner(iiI,jjI) = 0;
            Imap(Binner == 1) = 0.1;
            
            % sets the binary regions (based on type)
            for i = indR
                % sets the row columns
                ixR = mod(i-1,nCol) + 1;
                iyR = floor((i-1)/nCol) + 1;
                
                % retrieves the region object (if it exists)
                if ~isempty(hObj)
                    hObjR = findall(hObj,'UserData',[iyR,ixR]);
                end
                
                %
                switch obj.iMov.mShape
                    case 'Rect'
                        % case is rectangle regions

                        % retrieves the default region position
                        if isempty(hObjR)
                            pPosR = obj.iMov.autoP.pPos{iyR,ixR};
                        else
                            pPosR = get(hObjR,'Position');                            
                        end
                           
                        % updates the region indices
                        [ii,jj] = obj.getRectIndices(pPosR);                                                
                        Imap(ii,jj) = i;
                        
                    case 'Circ'
                        % case is circular regions
                        
                        % retrieves the default region position
                        if isempty(hObjR)
                            pPosR = aP.pPos{iyR,ixR};
                            R = ceil(min(pPosR(3:4))/2);
                            p0 = roundP(pPosR(1:2)+min(pPosR(3:4))/2);
                        else
                            R = ceil(hObjR.SemiAxes(1));
                            p0 = roundP(hObjR.Center);                            
                        end                        
                        
                        % sets up the circle region mask
                        [ii,jj,Dnw] = obj.getCircIndices(p0,R);
                        Imap(ii,jj) = Imap(ii,jj) + i*Dnw;
                end
            end
            
        end
        
        % --- sub-region checkbox callback function
        function checkSubRegions(obj)
        
            % sets/removes division figure based on checkbox value
            if get(obj.hChkSR,'Value')            
                % if the sub-regions haven't been set then exit
                obj.iMov = get(obj.hFig,'iMov');
                obj.setupDivisionFigure(true);
                
            else
                % unsetting check box, so remove division figure
                obj.removeDivisionFigure(false)                
            end
            
        end   
        
        % ------------------------------------------ %
        % --- MARKER CONSTRAINT FUNCTION UPDATES --- %
        % ------------------------------------------ %                     
        
        % --- sets the vertical marker constraint function
        function setVertMarkerConstrainFcn(obj,iCol)

            % sets up the constraint function
            yLimVL = obj.getVertXLim(iCol);
            yVL = obj.iMov.posG(2) + [0 obj.iMov.posG(4)];            
            obj.hVL{iCol-1}.setConstraintRegion(yLimVL,yVL);
            
        end        
        
        % --- sets the horizontal marker constraint function
        function setHorzMarkerConstrainFcn(obj,hObj,iRow,iCol)

            % sets the position constraint function
            xHLT = obj.xHL{iCol};
            xLimHL = obj.getHorzYLim(iRow,iCol);    
            hObj.setConstraintRegion(xHLT,xLimHL);
            
        end                
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- sets the marker object visibility flags
        function setMarkerVisibility(obj,isVis)
            
            hInnerM = findall(obj.hAx,'tag','hInner');
            hTubeM = findall(obj.hAx,'UserData','hTube');            
            setObjVisibility([hInnerM(:);hTubeM(:)],isVis);
            
            
        end
        
        % --- sets the limits of the sub-region
        function [xLim,yLim] = setSubImageLimits(obj,xAxL,yAxL,rPos,iApp)

            % sets the row/column iAppices            
            [nRow,nCol] = deal(obj.iMov.pInfo.nRow,obj.iMov.pInfo.nCol);
            [iR,iC] = deal(floor((iApp-1)/nCol)+1,mod(iApp-1,nCol)+1);

            % sets the dimensions of the 
            [L,T,W,H] = deal(rPos(1),rPos(2),rPos(3),rPos(4));
            [dW,dH] = deal(W/nCol,H/nRow);

            % sets the limits based on the type
            if obj.iMov.isOpt
                % case is regions have been optimised
                hV = findobj(obj.hAx,'tag','vLine');
                hH = findobj(obj.hAx,'tag','hLine');

                % sets the details for the vertical lines
                [ivL,xV] = deal(get(hV,'UserData'),get(hV,'xdata'));
                switch length(ivL)
                    case 0
                        % case is there are no vertical lines
                        xGapL = [];
                        
                    case 1
                        % case is there is one vertical line
                        xGapL = xV(1);
                        
                    otherwise
                        % otherwise sets the userdata into numerical arrays
                        [ivL,xV] = deal(cell2mat(ivL),cell2mat(xV)); 
                        xGapL = xV(ivL,1);
                end        

                % sets the details for the horizontal lines
                [ihL,yH] = deal(get(hH,'UserData'),get(hH,'ydata'));    
                switch length(ihL)
                    case 0
                        % case is there are no horizontal lines
                        yGapL = [];
                        
                    case 1
                        % case is there is one horizontal line
                        yGapL = yH(1); 
                        
                    otherwise
                        % otherwise sets the userdata into numerical arrays
                        [ihL,yH] = deal(cell2mat(ihL),cell2mat(yH)); 
                        yGapL = yH(ihL,1);        
                end

                % sets the axis limits
                [XX,YY] = deal([L;xGapL;(L+W)]',[T;yGapL;(T+H)]');
                [xLim,yLim] = deal(XX(iC+(0:1)),YY(iR+(0:1)));
                
            else
                % case is regions have not been optimised
                xLim = L + (iC-1)*dW + [0 dW];
                yLim = T + (iR-1)*dH + [0 dH];    
            end

            % ensures the limits are within the outer region limits
            xLim = [max(xAxL(1),xLim(1)) min(xAxL(2),xLim(2))];
            yLim = [max(yAxL(1),yLim(1)) min(yAxL(2),yLim(2))];    

        end        
        
        % --- retrieves the region position vector
        function pP = getRegionPosVec(obj,iApp,iTube)
            
            % retrieves the data based on the usage type
            if obj.isMain
                % case is accessing from the main GUI
                if exist('iTube','var')
                    pP = obj.iMov.autoP.pPos{iTube,iApp};
                else
                    pP = obj.iMov.autoP.pPos(:,iApp);                    
                end
                
            else
                % case is accessing from the region config GUI
                if exist('iTube','var')
                    pP = obj.objRS.iMov.autoP.pPos{iTube,iApp};
                else
                    pP = obj.objRS.iMov.autoP.pPos(:,iApp);                    
                end
            end
            
        end        
        
        % --- retrieves the region position vector
        function pP = getRegionRowPosVec(obj,iRow,iApp)
            
            % retrieves the data based on the usage type
            if obj.isMain
                % case is accessing from the main GUI
                if exist('iApp','var')
                    pP = obj.iMov.autoP.pPos{iRow,iApp};
                else
                    pP = obj.iMov.autoP.pPos(iRow,:);
                end
                
            else
                % case is accessing from the main GUI
                if exist('iApp','var')
                    pP = obj.objRS.iMov.autoP.pPos{iRow,iApp};
                else
                    pP = obj.objRS.iMov.autoP.pPos(iRow,:);
                end
            end
            
        end   
        
        % --- converts the region index to the row/column indices
        function [iRow,iCol] = ind2RC(obj,iApp)
            
            iRow = floor((iApp-1)/obj.iMov.pInfo.nCol) + 1;
            iCol = mod((iApp-1),obj.iMov.pInfo.nCol) + 1;

        end        
        
        % --- converts the row/column indices to the region index
        function iApp = RC2ind(obj,iRow,iCol)
            
            iApp = (iRow-1)*obj.iMov.pInfo.nCol + iCol;
            
        end
        
        % --- calculates the region proportional dimensions
        function calcPropRegionDim(obj,pPos,iApp)

            % sets the outer/inner region indices                            
            pPosO = obj.iMov.posO{iApp};            

            % calculates the proportional region dimensions
            [wX,wY] = deal(1/pPosO(3),1/pPosO(4));
            obj.pX(iApp) = wX*(pPos(1)-pPosO(1));
            obj.pY(iApp) = wY*(pPos(2)-pPosO(2));
            obj.pW(iApp) = wX*pPos(3);
            obj.pH(iApp) = wY*pPos(4);   

        end   
        
        % --- retrieves the region setup class object
        function getRegionSetupClassObject(obj)

            % determines if the region configuration window is open
            hFigRS = findall(0,'tag','figRegionConfig');            
            if isempty(hFigRS)
                % if not, then use the fly tracking gui handle
                obj.objRS = findall(0,'tag','figFlyTrack');
                
            else
                % otherwise, retrieve the region configuration class object
                obj.objRS = getappdata(hFigRS,'obj');
            end

        end        
        
    end
    
    % static class methods
    methods (Static)
        
        function [ii,jj] = getRectIndices(pPosR)
            
            ii = roundP(pPosR(2) + (0:floor(pPosR(4))));
            jj = roundP(pPosR(1) + (0:floor(pPosR(3))));
            
        end
        
        function [ii,jj,Dnw] = getCircIndices(p0,R)            
            
            % sets the row/column indices
            xiR = -R:R;
            [ii,jj] = deal(p0(2)+xiR,p0(1)+xiR);
            
            % sets the distance mask
            Bnw = setGroup((R+1)*[1,1],(2*R+1)*[1,1]);
            Dnw = bwdist(Bnw) <= R;            
            
        end
        
        function [xT,yT] = calcTubeCoords(rPosS,nTube)
            
            % initialisations
            A = NaN(1,nTube-1);
            xT0 = rPosS(1) + [0;rPosS(3);NaN];
            yT0 = rPosS(2) + linspace(0,rPosS(4),nTube+1);
            
            % sets the final tube coordinates 
            xT = arr2vec(repmat(xT0,1,nTube-1));
            yT = arr2vec([repmat(yT0(2:end-1),2,1);A]);
            
        end
        
    end

end
