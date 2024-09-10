classdef MarkerClass < handle
    
    % class properties
    properties
        
        % main class objects
        hFig
        hAx
        
        % main gui object handles
        hChkT
        hChkM
        hChkD
        hChkLV
        hChkBGM
        hEditC
        hEditM
        hMenuCT
        hMenuRT
        
        % plot object handles
        objM
        hTube
        hDir    
        xTube
        yTube
        xOfs
        yOfs
        
        % other class fields
        iMov
        Type
        mPara
        pltLocT
        pltAngT                
        isCG        
        pColF
        isVis
        
        % other scalar fields
        szDel
        lWid = 1.5;    
        yDelG = 0.35;
        ix = [1,2,2,1];
        iy = [1,1,2,2];
        isSet = false;
        isMltTrk
        
        % static string fields
        hTStr = 'hTube';        
        
    end
    
    % class methods
    methods 
        
        % --- class constructor
        function obj = MarkerClass(hFig)
            
            % sets the input arguments
            obj.hFig = hFig;
            
            % initialises the class fields
            obj.initClassFields();
            
        end

        % -------------------------------------- %        
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % field retrieval
            obj.szDel = obj.hFig.szDel;
            
            % sets the input arguments
            obj.hAx = findall(obj.hFig,'type','axes');
            
            % parameter/tag string mapping array
            tStr = {'hChkT','checkShowTube';...
                    'hChkM','checkShowMark';...
                    'hChkD','checkShowAngle';...
                    'hChkLV','checkLocalView';...
                    'hEditC','frmCountEdit';...
                    'hEditM','movCountEdit';...
                    'hMenuCT','menuCorrectTrans';...
                    'hMenuRT','menuRTTrack'};
                
            % retrieves the handles from the tag-string array
            for i = 1:size(tStr,1)
                obj.(tStr{i,1}) = findall(obj.hFig,'tag',tStr{i,2});
            end
            
            % makes the marker visibility menu item invisible
            hMenuP = findall(obj.hFig,'tag','menuAnalysis');
            hMenuV = findall(hMenuP,'tag','menuMarkerVis');            
            if isempty(hMenuV); setObjEnable(hMenuV,'off'); end
            
            % determines if the tracking parameters have been set
            A = load(getParaFileName('ProgPara.mat'));
            if ispc
                % track parameters have not been set, so initialise
                obj.mPara = A.trkP.PC;
            else
                % track parameters have been set
                obj.mPara = A.trkP.PC;
            end                        
            
        end
        
        % --- allocates memory for the object arrays
        function allocateObjectMemory(obj)

            if obj.isMltTrk
                % case is multi-tracking
                A = cell(obj.iMov.pInfo.nRow,obj.iMov.pInfo.nCol);
            
            else
                % case is single fly tracking
                if obj.isCG
                    xyT = obj.iMov.xTube;
                else
                    xyT = obj.iMov.yTube;
                end
                
                % temporary array 
                A = cellfun(@(x)(cell(size(x,1),1)),xyT,'un',0);
            end

            % memory allocation
            [obj.hTube,obj.hDir] = deal(A); 
            [obj.xTube,obj.yTube] = deal(A);

            % creates the marker object
            obj.objM = TrackMarkerObj(obj);            
            
        end        
        
        % ----------------------------- %
        % --- PLOT MARKER FUNCTIONS --- %
        % ----------------------------- %
        
%         % --- marker plot initialisation function
%         function initTrackMarkers(obj,isOn)
%             
%             if isprop(obj.hFig,'iMov')
%                 % if the sub-regions haven't been set then exit
%                 obj.iMov = get(obj.hFig,'iMov');
%                 if isempty(obj.iMov.yTube); return; end
%             else
%                 % case is the sub-region data struct isn't set
%                 return
%             end
%             
%             % sets the default input arguments
%             if ~exist('isOn','var'); isOn = true; end
%             
%             % initialises the class fields
%             obj.Type = getDetectionType(obj.iMov);
%             obj.isCG = isColGroup(obj.iMov);
%             
%             % resets the current axes and removes existing tracking markers
%             set(obj.hFig,'CurrentAxes',obj.hAx)
%             obj.deleteTrackMarkers();
%             
%             % if the sub-region data struct isn't set then exit
%             if ~obj.iMov.isSet; return; end
%             
%             % -------------------------------- %
%             % --- OBJECT MEMORY ALLOCATION --- %
%             % -------------------------------- %
%             
%             % axes initialisations
%             hold(obj.hAx,'on')
%             
%             % array creation
%             obj.allocateObjectMemory();
%             
%         end
        
        % --- deletes all the tracking markers
        function deleteTrackMarkers(obj)
            
            % resets the set flag
            obj.isSet = false;           
            
            % deletes the tube/marker objects (based on tracking type)
            if obj.isMltTrk
                % case is multi-tracking 
                tStr = {'hTube'};
                for i = 1:length(tStr)
                    hObj = findall(obj.hAx,'tag',tStr{i});
                    if ~isempty(hObj); delete(hObj); end
                end
                
            else
                % case is single tracking                
                for i = 1:length(obj.hTube)
                    cellfun(@delete,obj.hTube{i});
                    cellfun(@delete,obj.hDir{i});
                end                                            
            end      
            
            % deletes any existing marker objects
            if ~isempty(obj.objM)
                obj.objM.delete();
            end
            
            % resets the tube/marker handle arrays            
            [obj.hDir,obj.hTube] = deal([]);
            
        end     
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %                        
        
        % --- determines if the plot marker objects are valid
        function isValid = isMarkerValid(obj)
            
            % determines if the region marker exists
            isValid = ~(isempty(obj.hTube) || isempty(obj.hTube{1}));
            if isValid && ~obj.isMltTrk
                % additional check for single-tracking
                isValid = ~isempty(obj.hTube{1}{1});
            end
            
            % if the region marker exists, determine if it is valid
            if isValid
                if obj.isMltTrk
                    isValid = ishandle(obj.hTube{1});                    
                else
                    isValid = ishandle(obj.hTube{1}{1});
                end
            end
            
        end           
        
    end    
    
end