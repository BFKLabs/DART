classdef TrackMarkerClass < MarkerClass    
    
    % --- class properties
    properties
                
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = TrackMarkerClass(hFig)
           
            % creates the super-class object
            obj@MarkerClass(hFig);
            
            % other field initialisations
            obj.isMltTrk = false;            
            
        end
        
        % ----------------------------- %
        % --- PLOT MARKER FUNCTIONS --- %
        % ----------------------------- %
        
        % --- marker plot initialisation function
        function initTrackMarkers(obj,varargin)
            
            if isprop(obj.hFig,'iMov')
                % if the sub-regions haven't been set then exit
                obj.iMov = get(obj.hFig,'iMov');
                if isempty(obj.iMov.yTube); return; end
            else
                % case is the sub-region data struct isn't set
                return
            end
            
            % initialises the class fields
            obj.Type = getDetectionType(obj.iMov);            
            obj.isCG = isColGroup(obj.iMov);
            
            % resets the current axes and removes existing tracking markers
            set(obj.hFig,'CurrentAxes',obj.hAx)            
            obj.deleteTrackMarkers();       
            
            % if the sub-region data struct isn't set then exit
            if ~obj.iMov.isSet; return; end
            
            % -------------------------------- %
            % --- OBJECT MEMORY ALLOCATION --- %
            % -------------------------------- %            
            
            % axes initialisations
            hold(obj.hAx,'on')
            
            % array creation 
            obj.allocateObjectMemory();
                        
            % sets the visibilty flag
            if nargin == 1
                isOn = true;
            else
                isOn = varargin{1}; 
            end

            % retrieves the checkbox markers
            isOnT = get(obj.hChkT,'Value') && isOn;
            isOnD = get(obj.hChkD,'Value') && isOn;                
            
            % resets the markers
            for i = find(obj.iMov.ok(:)')
                % sets the x/y offset
                obj.xOfs = obj.iMov.iC{i}(1) - 1;
                obj.yOfs = obj.iMov.iR{i}(1) - 1;  

                switch obj.Type
                    case {'GeneralR','Circle','Rectangle'}
                        % sets the row/column indices
                        [iCol,iFlyR,~] = getRegionIndices(obj.iMov,i);  

                    otherwise
                        [iFlyR,iCol] = deal(1:getSRCount(obj.iMov,i),NaN);
                end

                for j = iFlyR(:)'
                    % sets the tag strings and the offsets
                    hDStr = sprintf('hDir%i',i);

                    % sets the plot colour for the tubes
                    [pCol,fAlpha,eCol,~,~] = obj.getMarkerProps(i,j);        

                    % sets the x/y coordinates of the tube regions (either 
                    % for single tracking, or multi-tracking for the first 
                    % iteration)
                    if (j == 1) || ~obj.isMltTrk
                        % sets up the sub-region coordinates
                        obj.setSubRegionCoords(i,j,iCol);

                        % creates the tube region patch
                        obj.hTube{i}{j} = fill(obj.xTube{i}{j},...
                            obj.yTube{i}{j},pCol,'tag',obj.hTStr,...
                            'FaceAlpha',fAlpha,'EdgeColor',...
                            eCol,'EdgeAlpha',1,'Visible','off',...
                            'Parent',obj.hAx,'UserData',[i,j]); 
                    end                    

                    % creates the fly positional/orientation markers
                    obj.hDir{i}{j} = patch(NaN,NaN,'r','tag',hDStr,...
                            'Parent',obj.hAx,'UserData',[10,0.33],...
                            'Visible','off','LineWidth',2,'EdgeColor','r');
                end
            end

            % sets the object marker visibility flags
            cellfun(@(x)(cellfun(@(y)...
                        (setObjVisibility(y,isOnT)),x)),obj.hTube)
            cellfun(@(x)(cellfun(@(y)...
                        (setObjVisibility(y,isOnD)),x)),obj.hDir)

            % turns the hold on the axis off
            hold(obj.hAx,'off')            
        
            % updates the set flags
            obj.isSet = true;
            
        end
        
        % --- updates the object location marker coordinates
        function updateTrackMarkers(obj,hasImg)

            % retrieves the important data arrays/structs
            % cType = get(hFig,'cType');

            % determines if the marker objects are created/valid
            if isempty(obj.objM)
                % if there are no markers, then exit
                return                
                
            elseif ~obj.isMarkerValid()
                % otherwise if the markers are not valid then recreate them
                if get(obj.hChkM,'value')
                    obj.initTrackMarkers();
                else
                    obj.initTrackMarkers(1);
                end                
                
            end
            
            % retrieves the marker boolean flag
            if obj.hFig.isCalib
                pltLocT0 = get(obj.hChkBGM,'value') && hasImg;
            else
                pltLocT0 = get(obj.hChkM,'value') && hasImg;
            end
            
            % retrieves the angle marker boolean flag
            if ishandle(obj.hChkD)
                pltAngT0 = get(obj.hChkD,'value') && hasImg;
            else
                pltAngT0 = false;
            end

            % array indexing & parameters
            if obj.hFig.isCalib
                if isfield(obj.hFig,'rtObj')
                    if isempty(obj.hFig.fPosNew); return; end     
                end
            end

            % sets the markers for all flies
            if ~isempty(obj.objM)
                % if the markers have been deleted then re-initialise
                if isempty(obj.objM.hMark) || ~ishandle(obj.objM.hMark)
                    obj.objM = TrackMarkerObj(obj);
                end                
                
                % updates the region markers
                obj.objM.updateMarkerData();                
                
                for i = find(obj.iMov.ok(:)')                    
                    % updates the plot tracking/angle marker objects                    
                    obj.pltLocT = pltLocT0 && obj.iMov.ok(i);                    
                    obj.pltAngT = pltAngT0 && obj.iMov.ok(i);
                    
                    % sets the plot location marker flag for the 
                    % current apparatus
                    if obj.hFig.isCalib       
                        % case is updating the calibration points
                        if isprop(obj.hFig,'fPosNew')
                            obj.updateRegionMarkers(i) 
                        end
                    else
                        % case is updating for a video
                        obj.updateRegionMarkers(i) 
                    end
                end
            end           

        end                
        
        % --- updates a signal marker
        function updateRegionMarkers(obj,ind)
                        
            % retrieves the position data struct
            if obj.hFig.isCalib
                pData = obj.hFig.fPosNew;
            else
                pData = obj.hFig.pData;
            end
            
            % retrieves the marker handles
            hDirS = obj.hDir{ind};
            if isempty(pData)
                % if there is no data, then set the markers to be invisible
                obj.objM.setVisibility('off');
                setObjVisibility(hDirS,'off');
                return
                
            elseif ~obj.iMov.isSet
                % if the regions are not set, then exit
                return
            end
            
            % other initialisations
            vStr = {'off','on'};
            pltLV = obj.objM.isLV;      
            cMov = obj.hFig.iData.cMov;               
            cFrm0 = obj.hFig.iData.cFrm;         
            hasPhi = ~obj.hFig.isCalib && isfield(pData,'PhiF');            
            
            % --------------------------------- %
            % --- SUB-REGION OUTLINE UPDATE --- %
            % --------------------------------- %  
            
            % retrieves the tube region coordinates
            if strcmp(get(obj.hMenuCT,'Checked'),'off')
                dpOfs = obj.objM.getFrameOffset(ind);
                obj.updateRegionOutline(ind,dpOfs);
            end
                        
            % ------------------------------------- %
            % --- MARKER OBJECT LOCATION UPDATE --- %
            % ------------------------------------- %            
            
            % updates the marker visibility flags
            obj.objM.setVisibility(obj.pltLocT);
            
            % updates the directional markers (if available)
            if hasPhi
                % retrieves the show direction marker flags
                showDir = obj.pltAngT;
                if pltLV
                    showDir = showDir && (ind == cMov);
                end
                
                % updates the marker visibility
                obj.updateMarkerVisibility(hDirS,showDir)  
            end
            
            for i = 1:getSRCount(obj.iMov,ind)
%                 % determines if the local view is being plotted
%                 if pltLV  
%                     % sets the local fly coordinates'    
%                     fPosT = fPosL{i};
%                     xFly = fPosT(:,1) - obj.hFig.szDelX;
%                     yFly = fPosT(:,2) - obj.hFig.szDelY;
% 
% %                     % sets the marker visibility string
% %                     if cMov == ind(1)
% %                         vStrNwM = vStr{(fok && obj.pltLocT) + 1};
% %                         vStrNwA = vStr{(fok && obj.pltAngT) + 1};
% %                     else
% %                         [vStrNwM,vStrNwA] = deal('off');
% %                     end
%                 else
%                     % sets the global fly coordinates
%                     fPosT = fPos{i};
%                     [xFly,yFly] = deal(fPosT(:,1),fPosT(:,2));                        
% 
% %                     % sets the marker visibility string
% %                     vStrNwM = vStr{(fok && obj.pltLocT) + 1};
% %                     vStrNwA = vStr{(fok && obj.pltAngT) + 1};
%                 end

                % otherwise, update the marker locations/visibility
                if obj.objM.isManReseg
%                     % retrieves the manual segmentation data struct
%                     hMR = findobj(0,'tag','figManualReseg');
%                     mData = getappdata(hMR,'mData');
%                     pCol = obj.getMarkerProps(handles,obj.iMov,ind,i);    
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
%                         pCol = obj.getMarkerProps(handles,iMov,ind,i);
%                     end            
                else

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
                            obj.updateArrowHeadCoords(hDirS{i},...
                                                [xFly,yFly],PhiNw,1,isF); 
%                             setObjVisibility(hDirS{i},vStrNwA)
                            
                        else
                            % otherwise, make the marker invisible
                            setObjVisibility(hDirS{i},'off')
                        end                        
                    end
                end        
            end            
            
        end                                       

        % --- updates the region outlines
        function updateRegionOutline(obj,ind,dpOfs)
            
            % retrieves the plot object handles and region coordinates
            hTubeS = obj.hTube{ind};
            [xTubeS,yTubeS] = deal(obj.xTube{ind},obj.yTube{ind});
            
            % updates the coordinates of the sub-region outlines
            if exist('dpOfs','var')
                cellfun(@(h,x,y)(set(h,'xdata',x+dpOfs(1),'ydata',...
                                y+dpOfs(2))),hTubeS,xTubeS,yTubeS);
            else
                cellfun(@(h,x,y)(set(h,'xdata',x,'ydata',y)),...
                                hTubeS,xTubeS,yTubeS);                
            end
            
        end        
        
        % --- resets the region outline object coordinates
        function resetRegionOutlines(obj)
            
            xiR = 1:length(obj.iMov.iR);
            arrayfun(@(x)(obj.updateRegionOutline(x)),xiR)
            
        end
        
        % ------------------------------------------ %
        % --- MAIN GUI OBJECT CALLBACK FUNCTIONS --- %
        % ------------------------------------------ %
        
        % --- show tube region checkbox callback function
        function checkShowTube(obj,iMov,showUpdate,event)
           
            % sets the input arguments
            obj.iMov = iMov;
            
            % retrieves the tube struct arrays
            mlt = 1;
            iData = get(obj.hFig,'iData');
            isLV = get(obj.hChkLV,'value');   
            
            % resets the tube regions (if they are invalid)
            if ~obj.isMarkerValid()  
                obj.initTrackMarkers(get(obj.hChkT,'Value'))
            end
            
            % retrieves the indices of the sub-regions to be shown
            if isLV
                % local view, so get the current sub-region
                iApp = iData.cMov;
                
                % makes the other region objects invisible
                isOther = ~setGroup(iApp,size(obj.hTube));                
                cellfun(@(x)(setObjVisibility(x,0)),obj.hTube(isOther))

            else
                % global view, so show all sub-regions
                iApp = find(iMov.ok);
            end            
            
            % sets the tube visibility strings
            for i = iApp(:)'
                if ~showUpdate
                    % calculates the frame offset
                    %  => FINISH ME!
                    
                    % sets the marker offsets and other properties
                    switch obj.Type
                        case {'GeneralR','Circle','Rectangle','Polygon'} 
                            % case is automatic detection

                            % sets the positional offset
                            if isLV
                                % case is for local view
                                xOfs0 = (iMov.iC{i}(1)-1) - obj.szDel;
                                yOfs0 = (iMov.iR{i}(1)-1) - obj.szDel;
                            else
                                % case is for global view
                                [xOfs0,yOfs0] = deal(0);    
                            end

                            % retrieves the global row/column indices
                            if obj.isMltTrk
                                [iCol,iFlyR] = deal(i,1);
                            else
                                [iCol,iFlyR,~] = getRegionIndices(iMov,i);
                            end

                        otherwise
                            % case is other region types

                            % sets the positional offset                
                            if isLV
                                % case is for local view
                                if iMov.ok(i)
                                    % sets the x/y tube region offset
                                    if size(iMov.xTube{i}([1 end]),1) == 1
                                        yOfs0 = iMov.iR{i}(1)-1;
                                        yOfs0 = min(max(0,yOfs0),obj.szDel);
                                        xOfs0 = obj.szDel;
                                    else
                                        xOfs0 = iMov.iC{i}(1)-1;
                                        xOfs0 = min(max(0,xOfs0),obj.szDel);
                                        yOfs0 = obj.szDel;
                                    end            
                                end
                            else
                                % case is for global view
                                xOfs0 = iMov.pos{i}(1);
                                yOfs0 = iMov.pos{i}(2);
                            end       

                            % sets the x/y-coordinates of the sub-region
                            if isempty(iMov.xTube{i})
                                % case is the region has never been set
                                iFlyR = [];                    
                            else
                                % otherwise, set the x/y offsets
                                if size(iMov.xTube{i},1) == 1
                                    x = (iMov.xTube{i}([1 end]) + xOfs0);
                                else
                                    y = (iMov.yTube{i}([1 end]) + yOfs0);
                                end

                                % sets the fly indices
                                iFlyR = 1:length(obj.hTube{i});
                            end
                    end        

                    for j = iFlyR(:)'
                        % retrieves the marker properties 
                        [pCol,fAlpha,eCol] = obj.getMarkerProps(i,j);              

                        % sets the tube region patch based on the detection type 
                        switch obj.Type
                            case 'GeneralR'
                                % case is the repeating general patterns
                                
                                % sets up the sub-region x-coordinates
                                dxTube = iMov.autoP.XC - xOfs0;
                                xT = iMov.autoP.X0(j,iCol) + dxTube;
                                
                                % sets up the sub-region y-coordinates
                                dyTube = iMov.autoP.YC - yOfs0;
                                yT = iMov.autoP.Y0(j,iCol) + dyTube;     

                            case 'Circle'
                                % calculates the circle coordinates
                                [XC,YC] = calcCircleCoords(iMov.autoP,j,iCol);

                                % sets up the sub-region x-coordinates
                                dxTube = XC - xOfs0;
                                xT = iMov.autoP.X0(j,iCol) + dxTube;
                                
                                % sets up the sub-region y-coordinates
                                dyTube = YC - yOfs0;
                                yT = iMov.autoP.Y0(j,iCol) + dyTube;                       

                            case 'Rectangle'
                                % sets up the sub-region x-coordinates
                                xC = [0,iMov.autoP.W(j,iCol)] - xOfs0;
                                xT = iMov.autoP.X0(j,iCol) + xC(obj.ix);
                                
                                % sets up the sub-region x-coordinates
                                yC = [0,iMov.autoP.H(j,iCol)] - yOfs0;
                                yT = iMov.autoP.Y0(j,iCol) + yC(obj.iy);                                
                                
                            otherwise
                                % case is for the other detection types
                                if obj.isCG
                                    x = iMov.xTube{i}(j,:) + xOfs0; 
                                else            
                                    y = iMov.yTube{i}(j,:) + yOfs0; 
                                end

                                % sets the final tube outline x/y coordinates
                                [xT,yT] = deal(x(obj.ix),y(obj.iy));
                        end

                        % creates the fly/tube markers
                        try
                            set(obj.hTube{i}{j},'xdata',xT,'ydata',...
                                    yT,'FaceAlpha',fAlpha*mlt,...
                                    'EdgeColor',eCol,'FaceColor',pCol);
                        catch
                            % if there was an error, reinitalise
                            obj.initTrackMarkers(1)

                            % updates the tube location
                            set(obj.hTube{i}{j},'xdata',xT,'ydata',...
                                    yT,'FaceAlpha',fAlpha*mlt,...
                                    'EdgeColor',eCol,'FaceColor',pCol);            
                        end
                    end    
                end

                % sets the tube visibility strings
                if isa(event,'char')
                    isShow = str2double(event);
                else
                    isShow = get(obj.hChkT,'value') && any(i == iApp);        
                end    

                % sets the visibility fields
                cellfun(@(x)(setObjVisibility(x,isShow)),obj.hTube{i})
            end
            
        end
        
        % --- show marker checkbox callback function
        function checkShowMark(obj)
            
            % updates the image axes
            if obj.hFig.isCalib
                % updates the plot markers
                obj.updateTrackMarkers(true)
                
%                 if isfield(handles,'menuRTTrack')
%                     if ~strcmp(get(obj.hMenuRT,'checked'),'on')
%                         objIMAQ = obj.hFig.infoObj.objIMAQ;
%                         updateVideoFeedImage(obj.hFig,objIMAQ)  
%                     end
%                 else
% 
%                 end
            else
                % initialisations
                isOn = get(obj.hChkM,'Value');                
                
%                 % updates the plot markers
%                 if obj.hFig.isBatch
%                     obj.updateTrackMarkers(true)
%                 end

                try
                    % attempts to update the marker visibility
                    if isOn; obj.updateTrackMarkers(1); end
                    obj.objM.setVisibility(isOn);
                    
                catch
                    % if there was an error, recreate the markers and 
                    % reset their visibility
                    obj.initTrackMarkers(1);
                    obj.objM.setVisibility(isOn);
                end
            end            
            
        end        
        
        % --- show angle checkbox callback function
        function checkShowAngle(obj)
            
            % initialisations
            isOn = get(obj.hChkD,'Value');
            isLV = get(obj.hChkLV,'Value');
            
            if isLV
                cMov = str2double(get(obj.hEditM,'string'));
                lvReg = setGroup(cMov,size(obj.iMov.ok));
            end
            
            try
                % attempts to update the marker visibility
                if isLV
                    cellfun(@(x)(cellfun(@(y)...
                        (setObjVisibility(y,isOn)),x)),obj.hDir(lvReg))
                    cellfun(@(x)(cellfun(@(y)...
                        (setObjVisibility(y,0)),x)),obj.hDir(~lvReg))                    
                else
                    cellfun(@(x)(cellfun(@(y)...
                        (setObjVisibility(y,isOn)),x)),obj.hDir)
                end
            catch
                % if there was an error, recreate the markers and set their
                % visibility
                obj.initTrackMarkers();
                
                if isLV
                    cellfun(@(x)(cellfun(@(y)...
                        (setObjVisibility(y,isOn)),x)),obj.hDir(lvReg))
                    cellfun(@(x)(cellfun(@(y)...
                        (setObjVisibility(y,0)),x)),obj.hDir(~lvReg))                     
                else
                    cellfun(@(x)(cellfun(@(y)...
                            (setObjVisibility(y,isOn)),x)),obj.hDir)
                end
            end            
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %                
        
        % --- updates the marker visibility
        function updateMarkerVisibility(obj,hObj,isOn)        
            
            % ensures the objects are stored in a cell array
            if ~iscell(hObj); hObj = {hObj}; end
            
            if isOn            
                if isempty(obj.isVis)
                    % case is the visibility flags are not provided
                    cellfun(@(x)(cellfun(@(y)...
                                (setObjVisibility(y,isOn)),x)),hObj)
                else
                    % case is the visibility flags are set
                    cellfun(@(x,y)(cellfun(@(yy,zz)...
                                (setObjVisibility(yy,zz)),x,...
                                num2cell(y))),hObj,obj.isVis)
                end            
            else
                % case is the visibility flags are not provided
                cellfun(@(x)(cellfun(@(y)...
                    (setObjVisibility(y,0)),x)),hObj)
            end
                
        end     
        
        % --- retrieves the tube/fly marker properties (based on the 
        %     analysis type and the status of the fly/tube region)
        function [pCol,fAlpha,eCol,pMark,mSz] = ...
                                        getMarkerProps(obj,i,j)

            % initialisations
            eCol = 'y';
            cStr = {'pNC','pMov','pStat','pRej'};

            % sets the plot colour for the tubes
            if obj.hFig.isCalib
                % determines if the fly has been accepted/rejected
                if obj.iMov.flyok(j,i) && obj.iMov.ok(i)
                    % case is fly is accepted
                    fAlpha = 0.1;
                    mSz = obj.mPara.pMov.mSz;
                    pCol = obj.mPara.pMov.pCol;
                    pMark = obj.mPara.pMov.pMark;
                else
                    % case is fly is rejected
                    [eCol,fAlpha] = deal('k',0.50);
                    mSz = obj.mPara.pRej.mSz;
                    pCol = obj.mPara.pRej.pCol;
                    pMark = obj.mPara.pRej.pMark;
                end
            else
                % case is single fly tracking
                if ~exist('i','var') || ~exist('j','var')
                    % case is initialising (after grid setting)
                    Status = 0;
                
                elseif ~(obj.iMov.flyok(j,i) && obj.iMov.ok(i))
                    % case is the fly has been rejected
                    [Status,obj.iMov.Status{i}(j)] = deal(3);

                elseif isnan(obj.iMov.Status{i}(j))
                    % case is the status flag has not been set
                    [Status,obj.iMov.Status{i}(j)] = deal(0);

                else
                    % otherwise, set the status flag
                    Status = obj.iMov.Status{i}(j);
                end

                % sets the facecolour and marker colour, type and size
                fAlpha = 0.1*(1 + (Status~=1));   
                mPF = getStructField(obj.mPara,cStr{1+Status});                
                [pMark,mSz,pCol] = deal(mPF.pMark,mPF.mSz,mPF.pCol);
            end

        end
        
        % --- sets up the x/y coordinates for a specific sub-region
        function setSubRegionCoords(obj,iApp,iFly,iCol)
            
            switch obj.Type
                case 'Circle'
                    % case is circular shape regions
                    if numel(obj.iMov.autoP.R) == 1
                        RC = obj.iMov.autoP.R;
                    else
                        RC = obj.iMov.autoP.R(iFly,iCol);
                    end
                    
                    % case is an automatic shape region
                    obj.xTube{iApp}{iFly} = RC*obj.iMov.autoP.XC + ...
                        obj.iMov.autoP.X0(iFly,iCol);
                    obj.yTube{iApp}{iFly} = RC*obj.iMov.autoP.YC + ...
                        obj.iMov.autoP.Y0(iFly,iCol);
                    
                case 'GeneralR'
                    % case is an automatic shape region
                    obj.xTube{iApp}{iFly} = obj.iMov.autoP.XC + ...
                        obj.iMov.autoP.X0(iFly,iCol);
                    obj.yTube{iApp}{iFly} = obj.iMov.autoP.YC + ...
                        obj.iMov.autoP.Y0(iFly,iCol);
                    
                case 'Rectangle'
                    % case is a rectangular region
                    xTube0 = [0,obj.iMov.autoP.W(iFly,iApp)] + ...
                        obj.iMov.autoP.X0(iFly,iApp);
                    obj.xTube{iApp}{iFly} = xTube0(obj.ix);
                    
                    yTube0 = [0,obj.iMov.autoP.H(iFly,iApp)] + ...
                        obj.iMov.autoP.Y0(iFly,iApp);
                    obj.yTube{iApp}{iFly} = yTube0(obj.iy);
                    
                otherwise
                    % otherwise, case is another region type
                    if obj.isCG
                        x = obj.iMov.xTube{iApp}(iFly,:) + obj.xOfs;
                        y = obj.iMov.yTube{iApp} + obj.yOfs + ...
                            obj.yDelG*[1,-1];
                    else
                        x = obj.iMov.xTube{iApp} + obj.xOfs;
                        y = obj.iMov.yTube{iApp}(iFly,:) + obj.yOfs + ...
                            obj.yDelG*[1,-1];
                    end
                    
                    % sets the final tube outline coordinates
                    obj.xTube{iApp}{iFly} = x(obj.ix);
                    obj.yTube{iApp}{iFly} = y(obj.iy);
            end
            
        end        
        
    end
    
    % class static methods
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
