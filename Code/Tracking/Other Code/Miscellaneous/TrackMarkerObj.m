classdef TrackMarkerObj < dynamicprops & handle
    
    % class properties
    properties
        
        % main class fields
        hMark
        
        % data array fields
        xP
        yP
        cP
        pOfs
        pOfsL
        vcData
        
        % scalar class fields
        cFrm
        nApp        
        
        % boolean class fields
        isLV
        isManReseg
        
        % character class fields        
        tagStrM = 'figManualReseg';
        fStr = {'pNC';'pMov';'pStat';'pRej'};
        
    end
    
    % private class properties
    properties (Access = private)
        
        objB
        
    end    
    
    % class methods
    methods
        
        % --- class constructor
        function obj = TrackMarkerObj(objB)
            
            % setsthe input arguments
            obj.objB = objB;
            
            % initialises the parent object links and class objects
            obj.linkParentProps();
            obj.initClassFields();
            obj.initClassObjects();
            
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %        
        
        % --- initialises the class object fields with that parent object
        function linkParentProps(obj)
            
            % parent fields strings
            fldStr = {'hFig','hAx','mPara','iMov',...
                      'hEditC','hEditM','hChkLV','hMenuCT',...
                      'isCG','isMltTrk'};
            
            % connects the base/child objects
            for propname = fldStr
                metaprop = addprop(obj, propname{1});
                metaprop.SetMethod = @(obj, varargin) ...
                    SetDispatch(obj, propname{1}, varargin{:});
                metaprop.GetMethod = @(obj)GetDispatch(obj, propname{1});
            end
            
        end                
        
        % --- initialises the class objects
        function initClassFields(obj)        
            
            % region offsets
            obj.pOfs = cellfun(@(x,y)...
                ([x(1),y(1)]-1),obj.iMov.iC,obj.iMov.iR,'un',0);
            
            % initialises the manual segmentation flag
            if obj.hFig.isCalib
                obj.isManReseg = false;
            else
                obj.isManReseg = ~isempty(findall(0,'tag',obj.tagStrM));
            end
            
            % tracking type specific initialisations
            if obj.isMltTrk
                % case is for multi-tracking
    
                % field retrieval
                obj.nApp = numel(obj.iMov.flyok);            
                
                % sets up the face vertex array
                if obj.iMov.sepCol
                    % case is colours are separated
                    nFlyMx = max(obj.iMov.pInfo.nFly(:));
                    obj.vcData = distinguishable_colors(nFlyMx,'k');
                    
                else
                    % case is the colours are not separated
                    obj.vcData = cell2mat(cellfun(@(x)...
                        (obj.mPara.(x).pCol),obj.fStr,'un',0));
                end
                
            else
                % case is for single tracking
              
                % sets up the face vertex array
                obj.nApp = length(obj.iMov.iR);                            
                obj.vcData = cell2mat(cellfun(@(x)...
                    (obj.mPara.(x).pCol),obj.fStr,'un',0));
                
                % calculates local offsets                
                if obj.isCG
                    % case is for column grouped regions
                    obj.pOfsL = cellfun(@(y)(cellfun(...
                        @(x)([x(1)-1,0]),y,'un',0)'),obj.iMov.iCT,'un',0);
                else
                    % case is for row grouped regions
                    obj.pOfsL = cellfun(@(y)(cellfun(...
                        @(x)([0,x(1)-1]),y,'un',0)'),obj.iMov.iRT,'un',0);                    
                end
            end
            
            % memory allocation
            [obj.xP,obj.yP,obj.cP] = deal(cell(obj.nApp,1));            
            
        end
            
        % --- initialises the class objects
        function initClassObjects(obj)
        
            % deletes any previous objects
            hMarkPr = findall(obj.hAx,'tag','hMark');
            if ~isempty(hMarkPr); delete(hMarkPr); end
            
            % retrieves the marker properties
            [~,~,~,mShape,mSize] = obj.objB.getMarkerProps();
            
            % creates the marker object
            obj.hMark = patch(obj.hAx,NaN,NaN,NaN,'EdgeColor','interp',...
                'Marker',mShape,'MarkerSize',mSize,'tag','hMark');
            
        end

        % ----------------------------------------- %        
        % --- MARKER DATA ARRAY SETUP FUNCTIONS --- %
        % ----------------------------------------- %
        
        % --- sets up the marker data vector fields
        function updateMarkerData(obj)
            
            % retrieves the current frame index and other flag values
            obj.getCurrentFrameIndex();            
            
            % sets the region marker data to update
            if obj.isLV
                xiR = str2double(get(obj.hEditM,'string'));
            elseif obj.isMltTrk
                xiR = find(arr2vec(obj.iMov.flyok')');                
            else
                xiR = find(obj.iMov.ok);
            end
            
            % sets up marker data vectors for the specified regions
            arrayfun(@(x)(obj.setupRegionMarkerData(x)),xiR);
            
            % updates the marker object
            obj.hMark.XData = cell2mat(obj.xP(xiR));
            obj.hMark.YData = cell2mat(obj.yP(xiR));
            
            % updates the marker colours
            cPT = cell2mat(obj.cP(xiR));
            obj.hMark.FaceVertexCData = obj.vcData(cPT,:);                 
            
        end
        
        % --- sets up the marker data point/colour vectors
        function setupRegionMarkerData(obj,iApp)
            
            % field retrieval
            fPos0 = obj.getPositionData(iApp);            
            if isempty(fPos0)
                return
            else
                dpOfs = obj.getFrameOffset(iApp);
            end
            
            % ------------------------------- %
            % --- POSITIONAL VECTOR SETUP --- %
            % ------------------------------- %
            
            if obj.isLV                                
                % case is for local tracking view
                dP = [obj.hFig.szDelX,obj.hFig.szDelY];                
                if obj.hFig.isCalib
                    % case is calibration
                    fPos = fPos0 - (dpOfs + obj.pOfs{iApp});
                    
                elseif obj.isMltTrk
                    % case is multi-tracking
                    fPos = cellfun(@(x)(x(obj.cFrm,:)-dP),fPos0,'un',0);
                    
                else
                    % case is single tracking
                    dpOfsT = dpOfs*obj.iMov.is2D - dP;                    
                    fPos = cellfun(@(x,p)(x(obj.cFrm,:) + ...
                            p + dpOfsT),fPos0,obj.pOfsL{iApp},'un',0);
                end
                
            else
                % case is for global tracking view
                if obj.hFig.isCalib
                    % case is calibration
                    fPos = num2cell(fPos0,2);
                    
                elseif obj.isMltTrk
                    % case is multi-tracking 
                    fPos = cellfun(@(x)(x(obj.cFrm,:)+dpOfs),fPos0,'un',0);
                    
                else
                    % sets the regional offset
                    if obj.isCG
                        pOfsR = [obj.pOfs{iApp}(1),0];
                    else
                        pOfsR = [0,obj.pOfs{iApp}(2)];                        
                    end
                    
                    % case is single tracking
                    fPos = cellfun(@(x)(x(obj.cFrm,:) + ...
                            dpOfs + pOfsR),fPos0,'un',0);
                end
                
            end
            
            % stores the x/y coordinates for all flies
            fPosT = cell2mat(cellfun(@(x)([x;NaN(1,2)]),fPos(:),'un',0));
            [obj.xP{iApp},obj.yP{iApp}] = deal(fPosT(:,1),fPosT(:,2));

            % --------------------------- %            
            % --- COLOUR VECTOR SETUP --- %
            % --------------------------- %
            
            if obj.hFig.isCalib
                % case is calibration
                fStatus = ones(size(fPosT,1),1);
                 
            elseif obj.isMltTrk
                % case is multi-tracking
                if obj.iMov.sepCol
                    fStatus = (1:length(fPos))';
                else
                    fStatus = 2*ones(length(fPos),1);
                end
                
            else
                % case is single tracking
                fStatus = 1 + obj.iMov.Status{iApp};
            end
            
            % sets the colour data vector
            xiP = 1:length(fPos);
            obj.cP{iApp} = cell2mat(cellfun(@(x,y)(x*ones(...
                size(y,1)+1,1)),num2cell(fStatus(xiP)),fPos(:),'un',0));
            
        end
        
        % ---------------------------------------- %
        % --- FIELD RETRIEVAL/UPDATE FUNCTIONS --- %
        % ---------------------------------------- %
        
        % --- calculates the frame offset (for the frame, cFrm)
        function dpOfs = getFrameOffset(obj,iApp)
            
            if strcmp(get(obj.hMenuCT,'Checked'),'on')
                % image translation has already been corrected
                dpOfs = [0,0];
                
            elseif obj.isMltTrk
                % case is multi-tracking
                [~,iApp] = ind2sub(size(obj.iMov.flyok),iApp);
                dpOfs = getFrameOffset(obj.iMov,obj.cFrm,iApp);
                
            else
                % case is for single tracking
                dpOfs = getFrameOffset(obj.iMov,obj.cFrm,iApp);
            end                
                        
            % removes the region offset (if using local view)
            if get(obj.hChkLV,'value')
                dpOfs = dpOfs - obj.pOfs{iApp};
            end            
            
        end        
        
        % --- retrieves the positional data struct
        function pData = getPositionData(obj,iApp)
                        
            % retrieves the position data struct
            if obj.hFig.isCalib
                % case is for calibration
                pData = obj.hFig.fPosNew{iApp};
                
            else
                if isempty(obj.hFig.pData)
                    % if there is no data, then return an empty array
                    pData = [];
                
                elseif obj.isLV
                    % case is for the local tracking view 
                    if obj.isMltTrk
                        [j,i] = ind2sub(size(obj.iMov.flyok),iApp);
                        pData = obj.hFig.pData.fPosL{i,j};                        
                    else
                        pData = obj.hFig.pData.fPosL{iApp};
                    end

                else
                    % case is for the global tracking
                    pData = obj.hFig.pData.fPos{iApp};
                end            
            end
            
        end
        
        % --- retrieves the current frame index, cFrm
        function getCurrentFrameIndex(obj)
        
            % retrieves the current local view flag value
            obj.isLV = get(obj.hChkLV,'value');
            
            % sets the manual calibration flag             
            if obj.hFig.isCalib
                % case is calibration
                obj.cFrm = 1;
                
            else
                % case is video tracking                
                cFrm0 = str2double(get(obj.hEditC,'string'));
                obj.cFrm = max(1,cFrm0-(obj.iMov.nPath-1)):cFrm0;
            end         
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- sets the marker object visibility
        function setVisibility(obj,vState)
            
            setObjVisibility(obj.hMark,vState);
            
        end        
        
        % --- marker deletion function
        function delete(obj)
            
            delete(obj.hMark)
            obj.hMark = [];
            
        end        
        
    end
    
    % private class methods
    methods (Access = private)
        
        % --- sets a class object field
        function SetDispatch(obj, propname, varargin)
            obj.objB.(propname) = varargin{:};
        end
        
        % --- gets a class object field
        function varargout = GetDispatch(obj, propname)
            varargout{:} = obj.objB.(propname);
        end
        
    end        
    
end
