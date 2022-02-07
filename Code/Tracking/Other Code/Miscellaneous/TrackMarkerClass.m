classdef TrackMarkerClass < handle
    
    % class properties
    properties
        
        % main class objects
        hFig
        hAx
        hChkM
        hChkT
        hChkD
        hChkLV
        hEditC
        hEditM
        hMenuCT
        propFcn        
        
        % object array fields
        hMark
        hTube
        hDir        
        
        % other class fields
        iMov
        Type
        pltLocT
        pltAngT        
        isMltTrk
        isCG        
        
        % other scalar fields
        lWid = 1.5;    
        yDelG = 0.35;
        ix = [1,2,2,1];
        iy = [1,1,2,2];
        
    end
    
    % class methods
    methods
        % --- class constructor
        function obj = TrackMarkerClass(hFig,hAx)
           
            % sets the input arguments
            obj.hFig = hFig;
            obj.hAx = hAx;   
            
            % retrieves the other main GUI object handles
            obj.hChkT = findall(hFig,'tag','checkShowTube');
            obj.hChkM = findall(hFig,'tag','checkShowMark');
            obj.hChkD = findall(hFig,'tag','checkShowAngle'); 
            obj.hChkLV = findall(hFig,'tag','checkLocalView');                        
            obj.hEditC = findall(hFig,'tag','frmCountEdit');
            obj.hEditM = findall(hFig,'tag','movCountEdit');
            obj.hMenuCT = findall(hFig,'tag','menuCorrectTrans');
            
            % retrieves the marker properties
            obj.propFcn = get(obj.hFig,'getMarkerProps');
            
        end
        
        % ----------------------------- %
        % --- PLOT MARKER FUNCTIONS --- %
        % ----------------------------- %
        
        % --- marker plot initialisation function
        function initTrackMarkers(obj,varargin)
            
            % if the sub-regions haven't been set then exit
            obj.iMov = get(obj.hFig,'iMov');
            if isempty(obj.iMov.yTube); return; end
            
            % initialises the class fields
            obj.Type = getDetectionType(obj.iMov);
            obj.isMltTrk = detMltTrkStatus(obj.iMov);
            obj.isCG = isColGroup(obj.iMov);
            
            % -------------------------------- %
            % --- OBJECT MEMORY ALLOCATION --- %
            % -------------------------------- %
            
            % array creation 
            if obj.isMltTrk
                % case is multi-fly tracking
                nFlyR = arr2vec(obj.iMov.nFlyR');
                
                % case is single fly tracking
                if obj.isCG
                    xyT = obj.iMov.xTube;
                else
                    xyT = obj.iMov.yTube;
                end    

                % memory allocation
                A = arrayfun(@(x)(cell(x,1)),nFlyR,'un',0);
                B = cellfun(@(x)(cell(size(x,1),1)),xyT,'un',0);
                [obj.hMark,obj.hTube,obj.hDir] = deal(A,B,A);    

            else
                % case is single fly tracking
                if obj.isCG
                    xyT = obj.iMov.xTube;
                else
                    xyT = obj.iMov.yTube;
                end

                % memory allocation
                A = cellfun(@(x)(cell(size(x,1),1)),xyT,'un',0);
                [obj.hMark,obj.hTube,obj.hDir] = deal(A);    
            end            
            
            % axes initialisations
            set(obj.hFig,'CurrentAxes',obj.hAx)            
            obj.deleteAllMarkers();
            hold(obj.hAx,'on')
            
            % sets the visibilty flag
            if nargin == 2
                isOn = true;
            else
                isOn = varargin{1}; 
            end

            % retrieves the checkbox markers
            isOnT = get(obj.hChkT,'Value') && isOn;
            isOnM = get(obj.hChkM,'Value') && isOn;
            isOnD = get(obj.hChkD,'Value') && isOn;            
            
            % resets the markers
            for i = find(obj.iMov.ok(:)')
                % sets the x/y offset
                xOfs = obj.iMov.iC{i}(1) - 1;
                yOfs = obj.iMov.iR{i}(1) - 1;  

                switch obj.Type
                    case {'GeneralR','Circle'}
                        % sets the row/column indices
                        [iCol,iFlyR,~] = getRegionIndices(obj.iMov,i);  

                    otherwise
                        iFlyR = 1:length(obj.hMark{i});

                end

                for j = iFlyR(:)'
                    % sets the tag strings and the offsets                
                    [hTStr,hMStr] = deal('hTube','hMark');
                    hDStr = sprintf('hDir%i',i);

                    % sets the plot colour for the tubes
                    [pCol,fAlpha,edgeCol,pMark,mSz] = ...
                                        getMarkerProps(obj.iMov,i,j);        

                    % sets the x/y coordinates of the tube regions (either 
                    % for single tracking, or multi-tracking for the first 
                    % iteration)
                    if (j == 1) || ~obj.isMltTrk
                        switch obj.Type
                            case {'GeneralR','Circle'}
                                % sets the outline coordinates
                                xTube = obj.iMov.autoP.X0(j,iCol) + ...
                                        obj.iMov.autoP.XC;
                                yTube = obj.iMov.autoP.Y0(j,iCol) + ...
                                        obj.iMov.autoP.YC;

                            otherwise
                                % otherwise set the region based on storage type
                                if obj.isCG
                                    x = obj.iMov.xTube{i}(j,:) + xOfs;
                                    y = obj.iMov.yTube{i} + yOfs + ...
                                            obj.yDelG*[1,-1];             
                                else
                                    x = obj.iMov.xTube{i} + xOfs;
                                    y = obj.iMov.yTube{i}(j,:) + yOfs + ...
                                            obj.yDelG*[1,-1];                              
                                end

                                % sets the final tube outline coordinates
                                [xTube,yTube] = deal(x(ii),y(jj));
                        end

                        % creates the tube region patch
                        obj.hTube{i}{j} = fill(xTube,yTube,pCol,...
                            'tag',hTStr,'FaceAlpha',fAlpha,'EdgeColor',...
                            edgeCol,'EdgeAlpha',1,'Visible','off',...
                            'Parent',obj.hAx,'UserData',[i,j]); 
                    end

                    % determines if separate colours are being used
                    if obj.iMov.sepCol
                        % if so, retrieve the stored colours
                        pColF = get(handles.output,'pColF');
                        if j > length(pColF)
                            % if there is sufficient colours, then reset the array
                            nMark = length(obj.hMark{i});
                            pColF = num2cell(distinguishable_colors(nMark,'w'),2);
                            set(handles.output,'pColF',pColF)
                        end        

                        % retrieves the colour
                        pCol = pColF{j};
                    end

                    % creates the fly positional/orientation markers
                    obj.hMark{i}{j} = plot(NaN,NaN,'Color',pCol,...
                            'Marker',pMark,'MarkerSize',mSz,'Parent',...
                            obj.hAx,'Visible','off','LineWidth',obj.lWid,...
                            'UserData',[i,j],'tag',hMStr);
                    obj.hDir{i}{j} = patch(NaN,NaN,pCol,'tag',hDStr,...
                            'Parent',obj.hAx,'UserData',[10,0.33],...
                            'Visible','off');
                end
            end

            % sets the object marker visibility flags
            cellfun(@(x)(cellfun(@(y)...
                        (setObjVisibility(y,isOnT)),x)),obj.hTube)
            cellfun(@(x)(cellfun(@(y)...
                        (setObjVisibility(y,isOnM)),x)),obj.hMark)
            cellfun(@(x)(cellfun(@(y)...
                        (setObjVisibility(y,isOnD)),x)),obj.hDir)

            % turns the hold on the axis off
            hold(obj.hAx,'off')            
            
        end
        
        % --- updates the object location marker coordinates
        function updateTrackMarkers(obj,hasImg)

            % global variables
            global isCalib

            % retrieves the important data arrays/structs
            % cType = get(hFig,'cType');

            % retrieves the marker boolean flags
            obj.pltLocT = get(obj.hChkM,'value') && hasImg;
            if ishandle(obj.hChkD)
                obj.pltAngT = get(obj.hChkD,'value') && hasImg;
            else
                obj.pltAngT = false;
            end

            % array indexing & parameters
            if isCalib
                if isfield(obj.hFig,'rtObj')
                    if isempty(obj.hFig.fPosTmp); return; end     
                end
            end

            % retrieves the updates the region markers (if there is translation)
            if ~isempty(obj.iMov.phInfo) && any(obj.iMov.phInfo.hasT)

            end

            % sets the markers for all flies
            if ~isempty(obj.hFig.hMark)    
                for i = find(obj.iMov.ok(:)')
                    % if the markers have been deleted then re-initialise
                    initReqd = isempty(obj.hMark{i}{1}) || ...
                                            ~ishandle(obj.hMark{i}{1});
                    if (i == 1) && initReqd
                        obj.initTrackMarkers(1)
                    end

                    % sets the plot location marker flag for the current apparatus
                    if isCalib       
                        if isfield(obj.hFig,'fPosTmp')
                            obj.updateSingleMarker(i) 
                        end
                    else
                        obj.updateSingleMarker(i) 
                    end
                end
            end

        end
        
        % --- updates a signal marker
        function updateSingleMarker(obj,ind)
            
            % global variables
            global isCalb
            
            % retrieves the position data struct
            if isCalb
                pData = obj.hFig.fPosTmp;
            else
                pData = obj.hFig.pData;
            end
            
            % retrieves the marker handles
            [hMarkS,hDirS] = deal(obj.hMark{ind},obj.hDir{ind});
            if isempty(pData)
                % if there is no data, then set the markers to be invisible
                setObjVisibility(hMarkS,'off');
                setObjVisibility(hDirS,'off');
                return
            elseif ~obj.iMov.isSet
                % if the regions are not set, then exit
                return
            end
            
            % other initialisations
            vStr = {'off','on'};
            pltLV = get(obj.hChkLV,'value');
            hasPhi = isfield(pData,'PhiF') && ~isCalib;                        
            
            % retrieves the sub-region count
            nFly = length(obj.hMark);
            cMov = str2double(get(obj.hEditM,'string'));            
            
            % sets the manual calibration flag             
            if isCalib
                % case is calibration
                manReseg = false;
            else
                % case is video tracking
                manReseg = ~isempty(findall(0,'tag','figManualReseg'));
                cFrm0 = str2double(get(obj.hEditC,'string'));  

                % sets the history path frame indices
                cFrm = max(1,cFrm0-(obj.iMov.nPath-1)):cFrm0;
            end                 
            
            % ----------------------------------- %
            % --- MARKER LOCATION ARRAY SETUP --- %
            % ----------------------------------- %
            
            % calculates the frame offset
            if strcmp(get(obj.hMenuCT,'Checked'),'on')
                dpOfs = zeros(nFly,2);
            else
                dpOfs = repmat(getFrameOffset(obj.iMov,cFrm),nFly,1);
            end                
            
            % sets the global/local coordinates and the y-offset 
            if pltLV
                % sets the global/local fly locations
                if isCalib
                    % case is calibration 
                    pOfs = [(obj.iMov.iC{ind(1)}(1)-1),...
                            (obj.iMov.iR{ind(1)}(1)-1)];            
                    fPosL = pData{ind(1)} - repmat(pOfs,nFly,1) + dpOfs;

                else           
                    % case is full video tracking
                    fPosL = cellfun(@(x)(x(cFrm,:)),pData.fPosL{ind(1)},'un',0);               
                    if obj.isCG        
                        pOfs = cellfun(@(x)(repmat([x(1)-1,0],...
                            length(cFrm),1)),obj.iMov.iCT{ind},'un',0);                                 
                    else
                        pOfs = cellfun(@(x)(repmat([0,x(1)-1],...
                            length(cFrm),1)),obj.iMov.iRT{ind},'un',0);                                
                    end

                    % sets the final local coordinates
                    dpOfs = num2cell(dpOfs,2);
                    fPosL = cellfun(@(x,p,dp)(x+p+dp),fPosL,pOfs',dpOfs','un',0);
                end
                
            else
                % sets the global fly locations
                if isCalib
                    % case is calibration 
                    fPos = pData{ind(1)} + dpOfs;
                else
                    % case is full video tracking
                    fPos = cellfun(@(x)(x(cFrm,:)),pData.fPos{ind(1)},'un',0);               
                    if obj.isCG
                        pOfs0 = [obj.iMov.iC{ind(1)}(1)-1,0];
                        pOfs = repmat(pOfs0,length(cFrm),1);            
                    else
                        pOfs0 = [0,obj.iMov.iR{ind(1)}(1)-1];
                        pOfs = repmat(pOfs0,length(cFrm),1);
                    end

                    % adds on the positional offset
                    fPos = cellfun(@(x)(x+pOfs+dpOfs(1,:)),fPos,'un',0);
                end
            end   
            
            % ------------------------------------- %
            % --- MARKER OBJECT LOCATION UPDATE --- %
            % ------------------------------------- %            
            
            for i = 1:nFly
                % determines if the local view is being plotted
                if pltLV  
                    % sets the local fly coordinates'    
                    fPosT = fPosL{i};
                    [xFly,yFly] = deal(fPosT(:,1)-szDelX,fPosT(:,2)-szDelY);

                    % sets the marker visibility string
                    if cMov == ind(1)
                        [vStrNwM,vStrNwA] = deal(vStr{(pltLoc)+1},vStr{(pltAng)+1});
                    else
                        [vStrNwM,vStrNwA] = deal('off');
                    end
                else
                    % sets the global fly coordinates
                    fPosT = fPos{i};
                    [xFly,yFly] = deal(fPosT(:,1),fPosT(:,2));                        

                    % sets the marker visibility string
                    [vStrNwM,vStrNwA] = deal(vStr{(pltLoc)+1},vStr{(pltAng)+1});
                end

                % otherwise, update the marker locations/visibility
                if manReseg
%                     % retrieves the manual segmentation data struct
%                     hMR = findobj(0,'tag','figManualReseg');
%                     mData = getappdata(hMR,'mData');
%                     pCol = getMarkerProps(handles,obj.iMov,ind,i);    
% 
%                     % determines if any points have been added
%                     if ~isempty(mData)
%                         % if so, then determine if this point has been resegmented for
%                         % this given frame
%                         [iFrm,iApp,iFly,fPosM,fPosLM] = field2cell(...
%                                         mData,{'iFrm','iApp','iFly','fPos','fPosL'},1);
%                         ii = (iFrm == cFrm) & (iApp == ind) & (iFly == i);                        
%                         if any(ii)
%                             % marker has been resegmented so reset colour and location
%                             pCol = 'm';
%                             if pltLV
%                                 % use local coordinates
%                                 yOfs = (iMov.iRT{ind}{i}(1)-1)+szDel;  
%                                 xFly = fPosLM(ii,1)+szDel;
%                                 yFly = fPosLM(ii,2)+yOfs;
%                             else
%                                 % use global coordinates
%                                 yOfs = (iMov.iR{ind}(1)-1);
%                                 [xFly,yFly] = deal(fPosM(ii,1),fPosM(ii,2)+yOfs);                    
%                             end
%                         end
%                     else
%                         % no segmentation data, so use default colour
%                         pCol = getMarkerProps(handles,iMov,ind,i);
%                     end            
% 
%                     % updates the marker
%                     cellfun(@(x)(set(x,'visible',vStrNwM,'xData',xFly,...
%                                        'yData',yFly)),hMark(i));
%                     if strcmp(pCol,'m')
%                         if ~checkManSegTable(mData,hMark(i),hMR,ind,i,cFrm)
%                             cellfun(@(x)(set(x,'Color',pCol)),hMark(i))
%                         end
%                     else
%                         cellfun(@(x)(set(x,'Color',pCol)),hMark(i))
%                     end
                else

                    % updates the location markers
                    set(obj.hMark{i},'Visible',vStrNwM,'xData',xFly,...
                                     'yData',yFly);

                    % updates the orientation angle markers
                    if hasPhi                        
                        % retrieves the final angle
                        isF = true;
                        PhiNw = pData.PhiF{ind}{i}(cFrm0)*pi/180;                        
                        if isnan(PhiNw)
                            % if the final angle isn't set, then retrieve 
                            % initial angle
                            isF = false;
                            PhiNw = pData.Phi{ind}{i}(cFrm0)*pi/180;                
                        end

                        % determines if there is a non-NaN orientation angle
                        if ~isnan(PhiNw)
                            % if so, update the arrow head coordinates
                            obj.updateArrowHeadCoords(obj.hDir{i},...
                                                [xFly,yFly],PhiNw,1,isF); 
                            setObjVisibility(obj.hDir{i},vStrNwA)
                            
                        else
                            % otherwise, make the marker invisible
                            setObjVisibility(obj.hDir{i},'off')
                        end                        
                    end
                end        
            end            
            
        end
        
        % --- deletes all the tracking markers
        function deleteTrackMarkers(obj)
            
            % if there are no markers, then exit the function
            if isempty(obj.hMark); return; end
            
            % deletes the tube/marker objects
            for i = 1:length(obj.hTube)
                cellfun(@delete,obj.hTube{i});
                cellfun(@delete,obj.hMark{i});
                cellfun(@delete,obj.hDir{i});
            end
            
            % resets the tube/marker handle arrays
            [obj.hMark,obj.hTube,obj.hDir] = deal([]);
            
        end        
        
    end
    
    methods (Static)
        
        % --- updates the coordinate for an arrow head with the coordinates p0 and 
        %     bearing angle, Bear
        function updateArrowHeadCoords(hArr,p0,Phi,yDir,isF)

            % sets the default input arguments
            if ~exist('yDir','var'); yDir = 1; end
            if ~exist('isF','var'); isF = 1; end

            % retrieves the arrow user data
            %  1 - arrow height
            %  2 - arrow base width
            uData = get(hArr,'UserData');

            % converts the bearing angle to radians
            pB = uData(1)*uData(2)*isF;

            % memory allocation
            [xArr,yArr] = deal(zeros(3,1));
            [xDel,yDel] = deal(uData(1)*cos(Phi),uData(1)*sin(yDir*Phi));
            [xDelB,yDelB] = deal(pB*cos(Phi+pi/2),pB*sin(yDir*(Phi+pi/2)));

            % sets the coordinates of the arrow vertices
            [xB,yB] = deal(p0(1)-xDel,p0(2)-yDel);
            [xArr(1),yArr(1)] = deal(p0(1)+xDel,p0(2)+yDel);
            [xArr(2:3),yArr(2:3)] = deal(xB+xDelB*[-1 1],yB+yDelB*[-1 1]);

            % updates the arrow vertex coordinates
            set(hArr,'xdata',xArr,'ydata',yArr);

        end        
        
    end
    
end