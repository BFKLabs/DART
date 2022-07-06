classdef TrackRegionClass < handle

    % class properties
    properties
        
        % main class objects
        hFig
        hAx 
        hFigRS
        
        % main gui object handles
        hChkSR
        hButU
        hMenuSR        
        
        % plot object fields
        hMark
        hTube
        hDir
        hROI
        
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
        hVL
        xHL
        
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
            obj.hFigRS = findall(0,'tag','figRegionSetup');
            
            % sets the other sub-region flags
            if ~isfield(obj.iMov,'isOpt'); obj.iMov.isOpt = false; end

            % sets the apparatus dimensions and show number flag 
            obj.showNum = nargin == 3;
            [nRow,nCol] = deal(obj.iMov.nRow,obj.iMov.nCol);

            % sets the movement flag
            if obj.isMain
                % for the main GUI viewing, so don't allow box movement 
                obj.isMove = false;
            else
                % otherwise, allow movement of the imrect boxes
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
            tStr = {'hInner','hOuter','hLine','vLine','hNum','hFillROI'};            
            
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

            % ------------------------------------ %
            % --- OUTER RECTANGLE OBJECT SETUP --- %
            % ------------------------------------ %

            % retrieves the outer region handle
            hOuter = findall(obj.hAx,'Tag','hOuter');

            % updates the position of the outside rectangle
            if isempty(hOuter)
                if obj.isSet
                    hROI = imrect(obj.hAx,obj.iMov.posG);
                else    
                    hROI = imrect(obj.hAx);    
                end

                % disables the bottom line of the imrect object
                set(hROI,'tag','hOuter')
                setObjVisibility(findobj(hROI,'tag','bottom line'),'off');

                % if moveable, then set the position callback function
                api = iptgetapi(hROI);
                api.setColor('r');
                rPos = api.getPosition();
                
                % updates for the region configuration setup
                if ~obj.isMain
                    % determines if the outer region is feasible                   
                    [dszF,rPos0] = deal(getCurrentImageDim - 1,rPos);
                    xL = min(max(1,[rPos0(1),sum(rPos0([1,3]))]),dszF(2));
                    yL = min(max(1,[rPos0(2),sum(rPos0([2,4]))]),dszF(1));
                    rPos = [xL(1),yL(1),[(xL(2)-xL(1)),(yL(2)-yL(1))]+1];

                    % resets the region if there is a change in size
                    if ~isequal(rPos,rPos0)
                        api.setPosition(rPos);
                    end                                        
                end

                % force the imrect object to be fixed
                setResizable(hROI,false);
                set(findobj(hROI),'hittest','off')

                % sets the constraint function for the rectangle object
                fcn = makeConstrainToRectFcn('imrect',...
                                rPos(1)+[0 rPos(3)],rPos(2)+[0 rPos(4)]);
                api.setPositionConstraintFcn(fcn); 
                
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

            % sets the region dimension vectors
            pPos = obj.iMov.pos;
            useOuter = cellfun(@isempty,pPos);
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
                [dW,dH] = deal(W/obj.iMov.nCol,H/obj.iMov.nRow); 
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

            % sets the window index text (if set)
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
            nApp = obj.iMov.nRow*obj.iMov.nCol;
            PosNw = zeros(1,4);            

            % sets the colours for the inner rectangles
            if obj.isMove
                % case is for movable inner objects (different colours)
                if mod(obj.iMov.nCol,2) == 1
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
                [L,T,W,H] = deal(rPos(1),rPos(2),rPos(3),rPos(4));
                [dW,dH] = deal((W/obj.iMov.nCol),(H/obj.iMov.nRow));    

                % if there are any negative dimensions, then exit the function
                if any([dW,dH] < 0)
                    return
                end

                % calculates the new locations for all apparatus
                for i = 1:obj.iMov.nRow
                    for j = 1:obj.iMov.nCol
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
                        rPosS{(i-1)*obj.iMov.nCol+j} = PosNw;
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
                xLimS = [max(rPos(1),xLimS(1)) min(rPos(1)+rPos(3),xLimS(2))];
                yLimS = [max(rPos(2),yLimS(1)) min(rPos(2)+rPos(4),yLimS(2))];   

                % adds the ROI fill objects
                if obj.isSet
                    hold(obj.hAx,'on')
                    hFill = fill(xLimS(obj.ix),yLimS(obj.iy),'r',...
                                'facealpha',0,'tag','hFillROI',...
                                'linestyle','none','parent',obj.hAx);
                    if ~obj.iMov.ok(i)
                        set(hFill,'facealpha',obj.fAlpha); 
                    end
                    hold(obj.hAx,'off')
                end        

                % creates the new rectangle object (region config only)
                if ~obj.iMov.isSet
                    hROIF = imrect(obj.hAx,rPosS{i});
                    indCol = mod(i-1,length(col))+1;

                    % disables the bottom line of the imrect object
                    set(hROIF,'tag','hInner');
                    setObjVisibility(findobj(hROIF,'tag','bottom line'),0);

                    % if moveable, then set the position callback function
                    api = iptgetapi(hROIF);
                    api.setColor(col(indCol));
                    api.addNewPositionCallback(@obj.roiCallback);         
                end

                if obj.isMove                      
                    % sets the position callback function 
                    set(hROIF,'UserData',i)                

                    % sets the constraint region for the 
                    fcn = makeConstrainToRectFcn('imrect',xLimS,yLimS);
                    api.setPositionConstraintFcn(fcn);                 

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
                        case {'GeneralR','Circle','Rectangle'}
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
                            % force the imrect object to be fixed
                            if exist('hROIF','var')
                                setResizable(hROIF,false);                
                                fcn = makeConstrainToRectFcn('imrect',...
                                  rPos(1)+[0,rPos(3)],rPos(2)+[0,rPos(4)]);
                                api.setPositionConstraintFcn(fcn); 
                                set(findobj(hROIF),'hittest','off')
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
            obj.hFigRS = findall(0,'tag','figRegionSetup');
            obj.isMltTrk = detMltTrkStatus(obj.iMov);
            
            % removes any previous sub-regions
            obj.deleteRegionConfig()
            
            % determines if the regions have been set
            if obj.isSet
                % otherwise, setup the outer frame from the previous values
                obj.setupMainFrameRect();

            else
                % if not, then prompt the user to set them up
                hGUI = guidata(obj.hFigRS);
                obj.iMov.posG = obj.setupMainFrameRect();
                obj.iMov = obj.hFigRS.initSubPlotStruct(hGUI,obj.iMov);
                
                if ~obj.isMain
                    obj.hFigRS.iMov = obj.iMov;
                end
            end        
            
            % resets the tube count/use flags (multi-fly tracking only)
            if obj.isMltTrk
                if isempty(obj.iMov.nFlyR)
                    obj.iMov.nFlyR = obj.iMov.pInfo.nFly;        
                    obj.iMov.nTubeR = ones(obj.iMov.nRow,obj.iMov.nCol);
                end    
            end
            
            % sets the output region data struct
            iMov = obj.iMov;

            % removes any previous markers and updates
            obj.createRegionConfig();            
            
        end
        
        % --- creates the subplot regions and line objects
        function createRegionConfig(obj)

            % initialisations
            A = zeros(obj.iMov.nCol*obj.iMov.nRow,1);
            [obj.pX,obj.pY,obj.pH,obj.pW] = deal(A);

            % retrieves the GUI objects            
            hold(obj.hAx,'on')

            % sets the region position vectors
            rPosS = obj.iMov.pos;

            % ------------------------------ %
            % --- VERTICAL LINE CREATION --- %
            % ------------------------------ %

            % tag strings
            tStr = {'end point 1','end point 2'};
            
            % memory allocation
            xVL = cell(obj.iMov.nCol-1,1);
            obj.hVL = cell(1,obj.iMov.nCol-1);  
            yVL = obj.iMov.posG(2) + [0 obj.iMov.posG(4)];

            % sets the position vector
            if ~isempty(obj.iMov.pos)
                pPos = obj.iMov.pos;
                pPos(~obj.iMov.ok) = obj.iMov.posO(~obj.iMov.ok);
            end

            % only set up vertical lines if there is more than one column
            for i = 2:obj.iMov.nCol
                % sets the x-location of the lines
                if ~isempty(obj.iMov.pos)
                    % sets indices of the groups to the left of the line
                    iLf = obj.iMov.nCol*(0:(obj.iMov.nRow-1)) + (i-1);

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
                obj.hVL{i-1} = imline(obj.hAx,xVL{i-1},yVL);
                set(obj.hVL{i-1},'tag','hVert');
                set(findobj(obj.hVL{i-1},'tag',tStr{1}),'hittest','off');
                set(findobj(obj.hVL{i-1},'tag',tStr{2}),'hittest','off');

                % sets the bottom line invisible
                hLineBL = findobj(obj.hVL{i-1},'tag','bottom line');
                set(hLineBL,'visible','off','UserData',i-1);
                
                % updates the marker properties/callback function
                api = iptgetapi(obj.hVL{i-1});
                api.setColor('r')
                api.addNewPositionCallback(@obj.vertCallback); 

                % sets the position constraint function
                obj.setVertMarkerConstrainFcn(i);                
            end

            % -------------------------------- %
            % --- HORIZONTAL LINE CREATION --- %
            % -------------------------------- % 
            
            % memory allocation
            obj.xHL = cell(obj.iMov.nCol,1);

            % only set up the horizontal lines if more than one column
            for j = 1:obj.iMov.nCol
                % sets the x-location of the lines
                if obj.iMov.nCol == 1
                    % case is there is only one column group
                    obj.xHL{j} = obj.iMov.posO{j};
                else
                    % case is there are multiple column groups
                    switch j
                        case 1
                            obj.xHL{j} = [obj.iMov.posO{j}(1),xVL{j}(1)];

                        case obj.iMov.nCol
                            obj.xHL{j} = [xVL{j-1}(1),sum(obj.iMov.posO{j}([1,3]))];

                        otherwise
                            obj.xHL{j} = [xVL{j-1}(1),xVL{j}(1)];

                    end        
                end

                % creates the line objects
                for i = 2:obj.iMov.nRow
                    % sets the y-location of the line
                    if ~isempty(obj.iMov.pos)
                        iLo = (i-2)*obj.iMov.nCol + j;
                        iHi = (i-1)*obj.iMov.nCol + j;
                        yHL = 0.5*(sum(pPos{iLo}([2 4])) + ...
                                   sum(pPos{iHi}(2)))*[1 1];
                    else
                        k = (i-1)*obj.iMov.nCol + j;
                        yHL = obj.iMov.posO{k}(2)*[1 1];
                    end

                    % creates the line object and sets the properties
                    hHL = imline(obj.hAx,obj.xHL{j},yHL);
                    set(hHL,'tag','hHorz','UserData',[i,j]);                     
                    set(findobj(hHL,'tag','end point 1'),'hittest','off');
                    set(findobj(hHL,'tag','end point 2'),'hittest','off');        
                    
                    % makes the bottom line object invisible
                    hLineBL = findobj(hHL,'tag','bottom line');
                    setObjVisibility(hLineBL,'off');
                    
                    % updates the 
                    api = iptgetapi(hHL);
                    api.setColor('r')
                    api.addNewPositionCallback(@obj.horzCallback);
                    
                    % sets the horizontal marker constraint function
                    obj.setHorzMarkerConstrainFcn(hHL,i,j);
                    
                    % sets the left-coordinate for the vertical line
                    if j > 1
                        uD = [get(obj.hVL{j-1},'UserData');{api,1,i,j}];
                        set(obj.hVL{j-1},'UserData',uD);
                    end

                    % sets the right-coordinate for the vertical line
                    if j < obj.iMov.nCol
                        uD = [get(obj.hVL{j},'UserData');{api,2,i,j}];
                        set(obj.hVL{j},'UserData',uD);            
                    end
                end
            end

            % ----------------------------------- %
            % --- TUBE REGION OBJECT CREATION --- %
            % ----------------------------------- %
            
            % memory allocation
            obj.hROI = cell(size(obj.iMov.ok));

            % case is for movable inner objects (different colours)
            if mod(obj.iMov.nCol,2) == 1
                col = 'gmyc';    
            else
                col = 'gmy';    
            end

            % sets the inner rectangle objects for all apparatus
            for i = find(obj.iMov.ok(:)')
                % sets the row/column indices
                iCol = mod(i-1,obj.iMov.nCol) + 1;
                iRow = floor((i-1)/obj.iMov.nCol) + 1;

                % sets the sub-region limits
                xLimS = obj.getRegionXLim(iCol);
                yLimS = obj.getRegionYLim(iRow,iCol);

                % adds the ROI fill objects (if already set)
                if obj.iMov.isSet
                    % creates the fill object
                    hFill = fill(xLimS(obj.ix),yLimS(obj.iy),'r',...
                         'facealpha',0,'tag','hFillROI','linestyle',...
                         'none','parent',obj.hAx,'UserData',i);

                    % if the region is rejected, then reset the facecolour 
                    if ~obj.iMov.ok(i)
                        set(hFill,'facealpha',obj.fAlpha)
                    end
                end       

                % retrieves the new fly count index
                nTubeNw = getSRCount(obj.iMov,i);
                indCol = mod(i-1,length(col))+1;  
                xTubeS0 = rPosS{i}(1)+[0 rPosS{i}(3)];
                xTubeS = repmat(xTubeS0,nTubeNw-1,1)';

                % sets the proportional height/width values
                [wX,wY] = deal(1/obj.iMov.posO{i}(3),1/obj.iMov.posO{i}(4));
                obj.pX(i) = wX*(obj.iMov.pos{i}(1)-obj.iMov.posO{i}(1));
                obj.pY(i) = wY*(obj.iMov.pos{i}(2)-obj.iMov.posO{i}(2));
                obj.pW(i) = wX*obj.iMov.pos{i}(3);
                obj.pH(i) = wY*obj.iMov.pos{i}(4);   

                % creates the new rectangle object
                if obj.iMov.is2D || obj.isMltTrk
                    % calculates the vertical tube region coordinates
                    xiN = num2cell(1:nTubeNw)';
                    widPos = sum(rPosS{i}([2,4]));
                    yTube0 = linspace(rPosS{i}(2),widPos,nTubeNw+1)';
                    yTubeS = num2cell([yTube0(1:end-1),yTube0(2:end)],2);

                    % calculates the sub-region outline coordinates
                    pPos{i} = obj.getRegionPosVec(i);

                    % case is 2D setup expt
                    switch obj.iMov.mShape
                        case 'Rect'
                            % case is using rectangular shapes
                            cFcnType = 'imrect';
                            obj.hROI{i} = cellfun(@(x)...
                                    (imrect(obj.hAx,x)),pPos{i},'un',0);

                        case 'Circ'
                            % case is using circular shapes
                            cFcnType = 'imellipse';

                            % creates the circle objects
                            obj.hROI{i} = cell(length(pPos{i}),1);
                            for j = 1:length(pPos{i})
                                % retrieves the original dimensions
                                p0 = pPos{i}{j}(1:2);
                                szObj = pPos{i}{j}(3:4);                    
                                
                                % resets the position vector
                                pPos{i}{j}(1) = ...
                                        p0(1) + (szObj(1)-pPos{i}{j}(3))/2;
                                pPos{i}{j}(2) = ...
                                        p0(2) + (szObj(2)-pPos{i}{j}(4))/2;
                                pPos{i}{j}(3:4) = min(szObj); 
                                    
                                % creates the circle object
                                obj.hROI{i}{j} = ...
                                            imellipse(obj.hAx,pPos{i}{j});
                                setFixedAspectRatioMode(obj.hROI{i}{j},1);
                            end
                    end        

                    % updates the ROI object properties
                    cellfun(@(h,x)(set(h,'tag','hInner',...
                                    'UserData',[i,x])),obj.hROI{i},xiN);

                    % if moveable, then set the position callback function
                    for j = 1:length(obj.hROI{i})
                        api = iptgetapi(obj.hROI{i}{j});
                        api.setColor(col(indCol));
                        api.addNewPositionCallback(@obj.roiCallback2D); 
                        
                        % retrieves the children objects and their tags
                        hChild = get(obj.hROI{i}{j},'Children');
                        tStr = get(hChild,'tag');

                        % removes the bottom line
                        isBL = strcmp(tStr,'bottom line');
                        setObjVisibility(hChild(isBL),0)
                        
                        % removes the marker objects
                        mSz = ceil(mean(pPos{i}{j}(3:4))/100);
                        hMarkC = hChild(strContains(tStr,'marker'));
                        arrayfun(@(x)(set(x,'MarkerSize',mSz)),hMarkC)
                        
                        % sets the constraint region for the inner regions
                        fcn = makeConstrainToRectFcn...
                                                (cFcnType,xLimS,yTubeS{j});
                        api.setPositionConstraintFcn(fcn);             
                    end

                    % resets the axes properties
                    set(obj.hAx,'Layer','Bottom','SortMethod','childorder')

                else
                    % case is 1D setup expt
                    obj.hROI{i} = imrect(obj.hAx,obj.iMov.pos{i});          
                    hLineBL = findobj(obj.hROI{i},'tag','bottom line');
                    
                    % disables the bottom line of the imrect object
                    setObjVisibility(hLineBL,'off');
                    set(obj.hROI{i},'tag','hInner','UserData',i);                    

                    % if moveable, then set the position callback function
                    api = iptgetapi(obj.hROI{i});
                    api.setColor(col(indCol));

                    if obj.isAutoDetect
                        % retrieves the marker object handles
                        hObj = findall(obj.hROI{i});            
                        isM = strContains(get(hObj,'Tag'),'marker');

                        % turns off the object visibility/hit-test
                        set(hObj,'hittest','off')
                        setObjVisibility(hObj(isM),0)
                    else
                        % sets the constraint region for the inner regions
                        api.addNewPositionCallback(@obj.roiCallback);   
                        fcn = makeConstrainToRectFcn('imrect',xLimS,yLimS);
                        api.setPositionConstraintFcn(fcn); 
                    end

                    % creates the individual tube markers        
                    colStr = [col(indCol),'--'];
                    yTubeS = rPosS{i}(2) + ...
                              (rPosS{i}(4)/nTubeNw)*(1:(nTubeNw-1));            
                    plot(obj.hAx,xTubeS,repmat(yTubeS,2,1),colStr,'tag',...
                              sprintf('hTubeEdge%i',i),'UserData','hTube');     
                end
            end

            % turns the axis hold off
            hold(obj.hAx,'off')

        end
        
        % --- removes the sub-regions
        function deleteRegionConfig(obj,varargin)

            % retrieves the GUI objects
            try
                hGUI = get(obj.hFigRS,'hGUI');
                if isempty(hGUI); return; end
            end

            % removes all the division marker objects
            delete(findobj(obj.hAx,'tag','hOuter'));
            delete(findobj(obj.hAx,'tag','hVert'));
            delete(findobj(obj.hAx,'tag','hHorz'));
            delete(findobj(obj.hAx,'tag','hNum'));
            delete(findobj(obj.hAx,'tag','hInner'));
            delete(findobj(obj.hAx,'tag','hFillROI'));

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
        function vertCallback(obj,lPos)

            % global variables
            obj.isUpdating = true;

            % retrieves the object handle and the index of the line
            hVL0 = get(gco,'parent');
            iVL = get(findall(hVL0,'tag','bottom line'),'UserData');

            % updates the attached horizontal line properties
            uD = get(hVL0,'UserData');
            for i = 1:size(uD)
                % updates the position of the attached line
                lPos0 = uD{i,1}.getPosition;
                lPos0(uD{i,2},1) = lPos(1,1);
                uD{i,1}.setPosition(lPos0);

                % sets the position constraint function    
                yLimNw = obj.getHorzYLimNw(uD{i,3},uD{i,4});
                fcn = makeConstrainToRectFcn('imline',lPos0(:,1),yLimNw);
                uD{i,1}.setPositionConstraintFcn(fcn);      
            end

            % updates the position of the inner regions
            obj.updateInnerRegions(iVL,true)
            setObjEnable(obj.hButU,'on')

            % resets the flag
            obj.isUpdating = false;

        end

        % --- the callback function for moving the horizontal seperator
        function horzCallback(obj,~)

            % determines if an object updating is taking place already
            if obj.isUpdating
                % if already updating, then exit the function
                return
            else
                % otherwise, flag that updating is occuring
                obj.isUpdating = true;
            end

            % retrieves the horizontal line marker index
            iVL = get(get(gco,'parent'),'UserData');

            % updates the position of the inner regions
            obj.updateInnerRegions(iVL,false)
            setObjEnable(obj.hButU,'on')
            
            % resets the flag to false
            obj.isUpdating = false;

        end

        % --- the callback function for moving the 2D inner tube regions
        function roiCallback2D(obj,rPos)
            
            % if updating then exit
            if obj.isUpdating
                return
            end

            % retrieves the sub-region data object
            srObj = get(obj.hFigRS,'srObj');
            hROInw = get(gco,'Parent');
            uData = get(hROInw,'UserData');

            % enables the update button
            setObjEnable(obj.hButU,1)

            % add in code here to update region coordinates
            %  - fill out autoP field

            % updates the region markers based on type
            if ~isempty(srObj) && srObj.isOpen
                % case is the split region marker is being updated
                obj.updateSplitRegionMarker(uData,rPos)
            else
                % case is a region config marker is being updated
                try
                    [iApp,iTube] = deal(uData(1),uData(2));
                catch
                    return
                end
                
                % updates the positional marker vector
                obj.hFigRS.iMov.autoP.pPos{iTube,iApp} = rPos;
                if strcmp(obj.iMov.pInfo.mShape,'Circle')
                    % ensures the shape is circular
                    rPos(3:4) = max(rPos(3:4));
                    obj.hFigRS.iMov.autoP.pPos{iTube,iApp} = rPos;                    
                    
                    % resets the region position
                    obj.isUpdating = true;
                    api = iptgetapi(hROInw);
                    api.setPosition(rPos);
                    obj.isUpdating = false;
                end
                
                % resets the sub-region limits
                obj.resetRegionLimits2D(iApp,iTube);
                obj.resetMarkerLimits2D(iApp);
            end

        end
        
        % --- resets the 2D horizontal/vertical region marker limits
        function resetMarkerLimits2D(obj,iApp)
            
            % sets the row/column indices
            iRow = floor((iApp-1)/obj.iMov.nCol) + 1;
            iCol = mod((iApp-1),obj.iMov.nCol) + 1;
            
            % updates the vertical markers
            if obj.iMov.nCol > 1
                ii = iCol + [0,1];                
                for i = ii((ii > 1) & (ii <= obj.iMov.nCol))
                    obj.setVertMarkerConstrainFcn(i)
                end
            end
            
            %
            if obj.iMov.nRow > 1
%                 % FINISH ME!
%                 set(hHL,'tag','hHorz','UserData',[i,j]); 
%                 obj.setHorzMarkerConstrainFcn(hHL,i,j);
            end            
            
        end
        
        % --- resets the 2D region limits
        function resetRegionLimits2D(obj,iApp,iT)
            
            % sets the row/column indices
            iRow = floor((iApp-1)/obj.iMov.nCol) + 1;
            iCol = mod((iApp-1),obj.iMov.nCol) + 1;

            % retrieves the x/y limits of the region
            xLT = obj.getRegionXLim(iCol);
            yLT = obj.getRegionYLim(iRow,iCol);
            
            if iT > 1
                % resets the upper region limits
                yL0 = obj.getRegionLimits2D(yLT,iApp,iT-1);
                obj.setRegionConstrainFcn(obj.hROI{iApp}{iT-1},xLT,yL0);
                
                % resets the current region limits
                yL1 = obj.getRegionLimits2D(yLT,iApp,iT);
                obj.setRegionConstrainFcn(obj.hROI{iApp}{iT},xLT,yL1);                
            end
               
            if iT < size(obj.iMov.flyok,1)
                % resets the upper region limits
                yL1 = obj.getRegionLimits2D(yLT,iApp,iT);
                obj.setRegionConstrainFcn(obj.hROI{iApp}{iT},xLT,yL1);
                
                % resets the current region limits
                yL2 = obj.getRegionLimits2D(yLT,iApp,iT+1);
                obj.setRegionConstrainFcn(obj.hROI{iApp}{iT+1},xLT,yL2);
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
                        pP0 = obj.getRegionPosVec(iApp,iT-1);
                        yL = [sum(pP0([2,4])),yLT(2)];

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

            % updates the region marker
            srObj = get(obj.hFigRS,'srObj');
%             obj.updateSubRegionMarker(uData,rPos)

            % retrieves the marker line objects 
            hMarkR = srObj.hMarkR{uData(2),uData(1)};

            % initialisation
            srObj.isUpdating = true;

            % updates the marker object positions
            switch srObj.mShape
                case 'Rect'
                    % case is rectangular regions

                    % rectangle parameters
                    [p0nw,W,H] = deal(rPos(1:2),rPos(3),rPos(4));  

                    % sets up the constraint function
                    [xLim,yLim] = deal(p0nw(1)+[0,W],p0nw(2)+[0,H]);
                    fcn = makeConstrainToRectFcn('imline',xLim,yLim);

                    % resets the vertical marker lines
                    pWid = W*cumsum(srObj.pWid{uData(2),uData(1)});         
                    for i = find(~cellfun(@isempty,hMarkR(:,1)))'
                        % recalculates the new position of the markers
                        pNw = [(p0nw(1)+pWid(i)*[1;1]),(p0nw(2)+H*[0;1])];

                        % resets the object properties
                        hAPI = iptgetapi(hMarkR{i,1});              
                        hAPI.setPosition(pNw);  
                        hAPI.setPositionConstraintFcn(fcn);   
                    end

                    % resets the horizontal marker lines
                    pHght = H*cumsum(srObj.pHght{uData(2),uData(1)}); 
                    for i = find(~cellfun(@isempty,hMarkR(:,2)))'
                        % recalculates the new position of the markers
                        pNw = [(p0nw(1)+W*[0;1]),(p0nw(2)+pHght(i)*[1;1])];

                        % resets the object properties
                        hAPI = iptgetapi(hMarkR{i,2});
                        hAPI.setPosition(pNw);            
                        hAPI.setPositionConstraintFcn(fcn);            
                    end

                case 'Circ'
                    % case is circular regions

                    % circle parameters
                    Rnw = rPos(3)/2;
                    p0nw = rPos(1:2)+Rnw;

                    % resets the marker line objects
                    phiP = srObj.pPhi{uData(2),uData(1)};
                    for i = 1:length(hMarkR)
                        hAPIR = iptgetapi(hMarkR{i});  
                        pNw = [p0nw;(p0nw+Rnw*[cos(phiP(i)),sin(phiP(i))])];
                        hAPIR.setPosition(pNw);            
                    end
            end

            % resets the update flag
            srObj.isUpdating = false;            
            
        end
        
        % --- the callback function for moving the inner tube regions
        function roiCallback(obj,rPos,iApp)

            % global variables
            global isUpdating

            % sets the apparatus index
            if ~exist('iApp','var')
                iApp = get(get(gco,'Parent'),'UserData');
                if (iscell(iApp)) || (length(iApp) ~= 1)
                    iApp = obj.iAppInner; 
                end
            end

            % retrieves the sub-region data struct
            nTube = getSRCount(obj.iMov,iApp);

            % resets the locations of the flies
            hTubeE = findobj(obj.hAx,'tag',sprintf('hTubeEdge%i',iApp));
            dY = diff(rPos(2)+[0 rPos(4)])/nTube;

            % sets the x/y locations of the tube sub-regions
            xTubeS = repmat(rPos(1)+[0 rPos(3)],nTube-1,1)';
            yTubeS = repmat(rPos(2)+(1:(nTube-1))*dY,2,1);

            % sets the x/y locations of the inner regions
            for i = 1:length(hTubeE)
                set(hTubeE(i),'xData',xTubeS(:,i),'yData',yTubeS(:,i));
            end

            % if not updating, then reset the proportional dimensions
            if ~isUpdating
                % retrieves the sub-region data struct
                obj.resetRegionPropDim(rPos,iApp);   

                % enables the update button
                setObjEnable(obj.hButU,'on')
            end 

        end
        
        % --- resets the region proportional dimensions
        function resetRegionPropDim(obj,rPos,iApp)

            % sets the row/column indices
            iRow = floor((iApp-1)/obj.iMov.nCol) + 1;
            iCol = mod((iApp-1),obj.iMov.nCol) + 1;

            % retrieves the x/y limits of the region
            xLim = obj.getRegionXLim(iCol);
            yLim = obj.getRegionYLim(iRow,iCol);

            % recalculates the proportional dimensions
            [W,H] = deal(diff(xLim),diff(yLim));
            obj.pX(iApp) = (rPos(1)-xLim(1))/W;
            obj.pY(iApp) = (rPos(2)-yLim(1))/H;
            [obj.pW(iApp),obj.pH(iApp)] = deal(rPos(3)/W,rPos(4)/H);

        end

        % --- updates the position of the inner regions (if the vertical/horizontal
        %     line objects are being moved)
        function updateInnerRegions(obj,iL,isVert)

            % updates the inner region based on the line being moved
            if isVert
                % case is moving a vertical line    
                for j = 1:2
                    % sets the indices of the inner regions being affected
                    iOfs = iL + (j-2);
                    xLim = obj.getRegionXLim(iL+(j-1));
                    iApp = (1:obj.iMov.nCol:length(obj.iMov.pos)) + iOfs;

                    % updates the position of the regions and their 
                    % constraint regions
                    for i = 1:obj.iMov.nRow
                        % retrieves the handle of the inner object
                        obj.iAppInner = iApp(i);
                        hInner = findall(obj.hAx,'tag','hInner',...
                                                 'UserData',iApp(i));

                        % retrieves the height limits of the 
                        yLim = obj.getRegionYLim(i,iL+(j-1));

                        % retrieves the in
                        if ~isempty(hInner)
                            api = iptgetapi(hInner);
                            inPos = api.getPosition();

                            % sets the new inner region position            
                            inPos(1) = xLim(1) + obj.pX(iApp(i))*diff(xLim);              
                            inPos(3) = obj.pW(iApp(i))*diff(xLim);

                            % sets the constraints for the inner regions
                            api.setPosition(inPos);
                            fcn = makeConstrainToRectFcn('imrect',xLim,yLim);
                            api.setPositionConstraintFcn(fcn);
                        end
                    end
                end
            else
                % case is moving a horizontal line   
                for j = 1:2
                    % retrieves the height limits of the 
                    iApp = (iL(1)+(j-3))*obj.iMov.nCol + iL(2);
                    yLim = obj.getRegionYLim(iL(1)+(j-2),iL(2));
                    xLim = obj.getRegionXLim(iL(2));

                    % retrieves the handle of the inner object
                    obj.iAppInner = iApp;
                    hInner = findall(obj.hAx,'tag','hInner','UserData',iApp);   

                    % retrieves the in
                    if ~isempty(hInner)
                        api = iptgetapi(hInner);
                        inPos = api.getPosition();

                        % sets the new inner region position            
                        inPos(2) = yLim(1) + obj.pY(iApp)*diff(yLim);              
                        inPos(4) = obj.pH(iApp)*diff(yLim);

                        % sets the constraint region for the inner regions
                        api.setPosition(inPos);
                        fcn = makeConstrainToRectFcn('imrect',xLim,yLim);
                        api.setPositionConstraintFcn(fcn);
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
                pPLo = obj.getRegionPosVec(iCol-1);
                pPHi = obj.getRegionPosVec(iCol);
                                
                % sets the lower/upper limits
                yLim = [max(cellfun(@(x)(sum(x([2,4]))),pPLo)),...
                        min(cellfun(@(x)(x(2)),pPHi))];                
                
            else
                % case is a 1D expt setup
                
                % sets the lower limit
                if iRow == 2
                    yLim(1) = obj.iMov.posG(2) + yGapNw;
                else
                    iL = (iRow-2)*obj.iMov.nCol + iCol;    
                    yLim(1) = obj.iMov.pos{iL}(2) + yGapNw;
                end

                % sets the upper limit
                if iRow == obj.iMov.nRow
                    yLim(2) = sum(obj.iMov.posG([2 4])) - yGapNw;
                else
                    iU = iRow*obj.iMov.nCol + iCol;
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
                % retrieves the lower line api object
                uD = [iRow-1,iCol];
                hLineH = findall(obj.hAx,'tag','hHorz','UserData',uD);
                apiLo = iptgetapi(hLineH);

                % resets the lower limit
                lPos = apiLo.getPosition();
                yLim(1) = lPos(1,2) + yGapNw;    
            end

            % sets the upper limit
            if iRow == obj.iMov.nRow
                yLim(2) = sum(obj.iMov.posG([2 4])) - yGapNw;
            else
                % retrieves the upper line api object
                uD = [iRow+1,iCol];
                hLineH = findall(obj.hAx,'tag','hHorz','UserData',uD);
                apiHi = iptgetapi(hLineH);
                
                % resets the upper limit
                lPos = apiHi.getPosition();
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
                
            else
                % case is a 1D expt setup
                
                % sets the lower limit
                if iCol == 2
                    xLim(1) = obj.iMov.posG(1) + xGapNw;
                else
                    xLim(1) = obj.iMov.posO{iCol-1}(1) + xGapNw;
                end

                % sets the upper limit
                if iCol == obj.iMov.nCol
                    xLim(2) = sum(obj.iMov.posG([1 3])) - xGapNw;
                else
                    xLim(2) = obj.iMov.posO{iCol+1}(1) - xGapNw;
                end
            end

        end        
        
        % --- returns the x-limits of the sub-region
        function xLim = getRegionXLim(obj,iCol)

            % memory allocation
            xLim = zeros(1,2);
            tStr = 'bottom line';

            % gets the lower limit based on the row count
            if iCol == 1
                % sets the lower limit to be the bottom
                xLim(1) = obj.iMov.posG(1);
            else
                % retrieves the position of the lower line region
                hLineV = findall(obj.hAx,'tag',tStr,'UserData',iCol-1);
                api = iptgetapi(get(hLineV,'parent'));                

                % sets the lower limit
                lPosL = api.getPosition();
                xLim(1) = lPosL(1,1);
            end

            % gets the upper limit based on the row count
            if iCol == obj.iMov.nCol
                % sets the upper limit to be the top
                xLim(2) = sum(obj.iMov.posG([1 3]));
            else
                % retrieves the position of the upper line region
                hLineV = findall(obj.hAx,'tag',tStr,'UserData',iCol);
                api = iptgetapi(get(hLineV,'parent'));                

                % sets the upper limit
                lPosR = api.getPosition();
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
            else
                % retrieves the position of the lower line region
                uD = [iRow,iCol];
                hLineH = findall(obj.hAx,'tag','hHorz','UserData',uD);
                api = iptgetapi(hLineH);                

                % sets the lower limit
                lPosLo = api.getPosition();
                yLim(1) = lPosLo(1,2);
            end

            % gets the upper limit based on the row count
            if iRow == obj.iMov.nRow
                % sets the upper limit to be the top
                yLim(2) = sum(obj.iMov.posG([2 4]));
            else
                % retrieves the position of the upper line region
                uD = [iRow+1,iCol];
                hLineH = findall(obj.hAx,'tag','hHorz','UserData',uD);
                api = iptgetapi(hLineH);                

                % sets the upper limit
                lPosHi = api.getPosition();
                yLim(2) = lPosHi(1,2);    
            end

        end
        
        % ------------------------------------------ %
        % --- MAIN GUI OBJECT CALLBACK FUNCTIONS --- %
        % ------------------------------------------ %
                
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
        
        % --- sets the region constraint function
        function setRegionConstrainFcn(obj,hObj,xLim,yLim)

            % retrieves the constraint shape type
            switch obj.iMov.pInfo.mShape
                case 'Circle'
                    % case is a circular region
                    cType = 'imellipse';
                    
                case 'Rectangle'
                    % case is a rectangular region
                    cType = 'imrect';
                    
                otherwise
                    % case is a general polygon region
                    cType = 'impoly';
                    
            end
            
            % sets up the constraint function
            fcn = makeConstrainToRectFcn(cType,xLim,yLim);

            % resets the position constraint function
            api = iptgetapi(hObj);
            api.setPositionConstraintFcn(fcn);                 

        end                
        
        % --- sets the vertical marker constraint function
        function setVertMarkerConstrainFcn(obj,iCol)

            % sets up the constraint function
            yLimVL = obj.getVertXLim(iCol);
            yVL = obj.iMov.posG(2) + [0 obj.iMov.posG(4)];
            fcn = makeConstrainToRectFcn('imline',yLimVL,yVL);
            
            % updates the constraint function            
            api = iptgetapi(obj.hVL{iCol-1});
            api.setPositionConstraintFcn(fcn);          

        end        
        
        % --- sets the horizontal marker constraint function
        function setHorzMarkerConstrainFcn(obj,hObj,iRow,iCol)

            % sets the position constraint function
            xHLT = obj.xHL{iCol};
            xLimHL = obj.getHorzYLim(iRow,iCol);            
            fcn = makeConstrainToRectFcn('imline',xHLT,xLimHL);

            % updates the constraint function
            api = iptgetapi(hObj);
            api.setPositionConstraintFcn(fcn);             

        end                
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- sets the marker object visibility flags
        function setMarkerVisibility(obj,isVis)
            
            %
            hInner = findall(obj.hAx,'tag','hInner');
            setObjVisibility(hInner,isVis);
            
        end
        
        % --- sets the limits of the sub-region
        function [xLim,yLim] = setSubImageLimits(obj,xAxL,yAxL,rPos,iApp)

            % sets the row/column iAppices
            [nRow,nCol] = deal(obj.iMov.nRow,obj.iMov.nCol);
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
                    pP = obj.hFigRS.iMov.autoP.pPos{iTube,iApp};
                else
                    pP = obj.hFigRS.iMov.autoP.pPos(:,iApp);                    
                end
            end
            
        end        
        
    end

    % static class methods
    methods (Static)
        
        
    end

end