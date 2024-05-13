classdef DetGridRegion < handle

    % class properties
    properties
        
        % main class fields
        hFig
        iMov
        iData
        phObj
        trkObj
        
        % other class fields
        hProg
        frmSz
        pOfsG
        
        % boolean fields
        calcOK
        updateObj
    
    end

    % class methods
    methods
        % class constructor
        function obj = DetGridRegion(hFig)
           
            % sets the input arguments
            obj.hFig = hFig;
            
            % initialsises the class fields
            obj.initClassFields();
            obj.getVideoPhaseInfo();
            
            % runs the initial detection estimate
            obj.detectInitEst();
            if obj.calcOK
                obj.setRegionInfo();
            end
            
        end
    
        % --- initialises the object class fields
        function initClassFields(obj)            

            % progressbar setup
            wStr = {'Phase Detection','Region Segmentation',...
                    'Sub-Region Segmentation'};
            obj.hProg = ProgBar(wStr,'1D Automatic Detection'); 
            
            % field retrieval            
            obj.phObj = get(obj.hFig,'phObj');
            obj.iMov = get(obj.hFig,'iMov');
            obj.iData = get(obj.hFig.hGUI.output,'iData');
            
            % other initialisations             
            obj.frmSz = getCurrentImageDim();
            [obj.updateObj,obj.calcOK] = deal(false,true);
            
        end
        
        % --- retrieves the video phase information
        function getVideoPhaseInfo(obj)
            
            % global variables
            global isCalib            
            
            % runs the phase detection solver    
            if isCalib
                % updates the data struct with the phase information
                obj.phObj = struct('iPhase',[1,1],'vPhase',1);
            else
                % creates the video phase object
                obj.hProg.Update(1,'Determining Video Phases...',0.25);
                if isempty(obj.phObj)
                    obj.updateObj = true;
                    obj.phObj = ...
                            VideoPhase(obj.iData,obj.iMov,obj.hProg,1,true);
                    obj.phObj.runPhaseDetect();  
                end

                % updates the progressbar
                if obj.hProg.Update(2,'Phase Detection Complete!',1)
                    % if the user cancelled, then exit
                    [obj.iMov,obj.trkObj] = deal([]);
                    return
                end

                % updates the sub-image data struct with the phase information
                obj.iMov.phInfo = getPhaseObjInfo(obj.phObj);
            end              
            
            % sets the phase indices/classification flags
            obj.iMov.iPhase = obj.phObj.iPhase;
            obj.iMov.vPhase = obj.phObj.vPhase;            
            
        end
        
        % --- runs the initial detection estimate
        function detectInitEst(obj)
            
            % runs the phase detection solver            
            obj.hProg.Update(1,'Estimating Grid Setup...',0.50);

            % determines the longest low-variance phase
            indPh = [obj.phObj.vPhase,diff(obj.phObj.iPhase,[],2)];
            [~,iSort] = sortrows(indPh,[1,2],{'ascend' 'descend'});
            iMx = iSort(1);  
            
            % updates the sub-image data struct with the phase information
            iMovT = obj.iMov;
            iMovT.iPhase = iMovT.iPhase(iMx,:);
            iMovT.vPhase = iMovT.vPhase(iMx);   
            
            % creates the tracking object
            obj.trkObj = SingleTrackInitAuto(obj.iData);

            % runs the initial estimate
            obj.trkObj.calcInitEstimateAuto(iMovT,obj.hProg)
            if obj.trkObj.calcOK
                % calculates the global offset
                obj.pOfsG = cellfun(@(x,y)([x(1),y(1)]-1),...
                                    obj.trkObj.iCG,obj.trkObj.iRG,'un',0);                
                
            else
                % if the user cancelled, then exit
                obj.calcOK = false;
            end            
            
        end
        
        % --- sets the final sub-region information fields
        function setRegionInfo(obj)            

            % sets the parameters for each of the sub-regions
            for i = 1:length(obj.iMov.pos)
                % sets the region position coordinates
                if ~isempty(obj.trkObj.yTube{i})
                    % calculates the dimensions/offsets for the tube regions
                    [xT,yT] = obj.calcTubeRegionOffset(i);
                    [W,H] = deal(diff(xT)+1,diff(yT([1,end]))+1);
                    dxT = xT - xT(1);
                    dyT = yT - yT(1);
                    
                    % sets the region outlne coordinate vector                    
                    obj.iMov.pos{i} = [obj.pOfsG{i}+[xT(1),yT(1)],W,H];

                    % tube-region x/y coordinate arrays
                    obj.iMov.xTube{i} = dxT;
                    obj.iMov.yTube{i} = [dyT(1:end-1),dyT(2:end)];

                    % sets the region row/column indices   
                    [x0,y0] = deal(obj.iMov.pos{i}(1)+1,obj.iMov.pos{i}(2)+1);
                    iRnw = (ceil(y0+dyT(1)):floor(y0+dyT(end)));
                    iCnw = (ceil(x0+dxT(1)):floor(x0+dxT(end))); 

                    % sets the feasible row/column indices
                    isFR = (iRnw>0)&(iRnw<=obj.frmSz(1));
                    isFC = (iCnw>0)&(iCnw<=obj.frmSz(2));

                    % resets the feasible row/column indices
                    obj.iMov.iR{i} = iRnw(isFR);
                    obj.iMov.iC{i} = iCnw(isFC);

                    % sets the sub-region row/column indices
                    obj.iMov.iCT{i} = 1:length(obj.iMov.iC{i});        
                    obj.iMov.iRT{i} = cellfun(@(x)((1+ceil(x(1))):...
                        min(length(obj.iMov.iR{i}),floor(x(2)))),...
                                num2cell(obj.iMov.yTube{i},2),'un',0);

                    % reduces downs the filter/reference images (if they exist)
                    if ~isempty(obj.iMov.phInfo.Iref{i})
                        obj.iMov = reducePhaseInfoImages(obj.iMov,i);
                    end
                end
            end

            % sets the outer region dimension vectors
            pPos = obj.iMov.pos;
            pPos(~obj.iMov.ok) = obj.iMov.posO(~obj.iMov.ok);

            % resets the outer region coordinates
            for i = 2:obj.iMov.pInfo.nRow    
                for j = 1:obj.iMov.pInfo.nCol
                    % sets the lower/upper region indices
                    iLo = (i-2)*obj.iMov.pInfo.nCol + j;
                    iHi = (i-1)*obj.iMov.pInfo.nCol + j;

                    % calculates the vertical location separating the regions
                    yHL = 0.5*(sum(pPos{iLo}([2 4])) + sum(pPos{iHi}(2)));
                    yB = sum(obj.iMov.posO{iHi}([2,4]));

                    % resets the outer region coordinates        
                    obj.iMov.posO{iHi}(2) = yHL;
                    obj.iMov.posO{iHi}(4) = yB - yHL;
                    obj.iMov.posO{iLo}(4) = yHL - obj.iMov.posO{iLo}(2);
                end
            end

            % re-initialises the status flags
            nT = arr2vec(getSRCountVec(obj.iMov)');
            obj.iMov.Status = arrayfun(@(x)(NaN(x,1)),nT,'un',0);            
            
            % ------------------------------------------ %            
            % --- GLOBAL OUTLINE BOUNDING BOX UPDATE --- %
            % ------------------------------------------ %
            
            % resizes the global coordinates (if necessary)
            pPosG = obj.iMov.posG;
            pPosT = cell2mat(obj.iMov.pos(:));
            
            % determines the min/max bounding box extents
            dMin = min(pPosT(:,1:2),[],1);
            dMax = max(pPosT(:,1:2)+pPosT(:,3:4),[],1);
            
            % resets the base bounding-box coordinates
            pPosG(1:2) = max(1,min(pPosG(1:2),dMin));            
            for i = 1:2
                pPosG(i+2) = max(pPosG(i+2),dMax(i)-pPosG(i));
            end
           
            % updates the data struct
            obj.iMov.posG = pPosG;
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %            
            
            % updates the phase detection object if required
            if obj.updateObj
                % clears the phase object fields
                [obj.phObj.Img0,obj.phObj.ILF] = deal([]);

                % updates the phase object field
                set(obj.hFig,'phObj',obj.phObj)
            end

            % closes the progressbar
            obj.hProg.closeProgBar();            
            
        end
        
        % --- calcualtes the 
        function [xTL,yTL] = calcTubeRegionOffset(obj,iApp)

            % calculates the regions with respect to the global image frame
            pO = obj.pOfsG{iApp};
            [xTL,yTL] = deal(obj.trkObj.xTube{iApp},obj.trkObj.yTube{iApp});
            [xTG0,yTG0] = deal(xTL+pO(1),yTL+pO(2));

            % ensures the horizontal locations are within frame
            xTG = max(min(xTG0,obj.frmSz(2)),0);
            yTG = max(min(yTG0,obj.frmSz(1)),0);

            % resets the x-location global offsets (if required)
            [dxTG0,dxTGF] = deal(xTG(1) - xTG0(1),xTG0(2) - xTG(2));
            [dyTG0,dyTGF] = deal(yTG(1) - yTG0(1),yTG0(end) - yTG(end));                      
                        
            % resets the top/bottom
            yTL(1) = yTL(1) + dyTG0;
            yTL(end) = yTL(end) - dyTGF;
            xTL(1) = xTL(1) + dxTG0;
            xTL(end) = xTL(end) - dxTGF;
            
%             % calculates the tube-region offsets
%             [xTL,yTL] = deal(xTL-xTL(1),yTL-yTL(1));

        end
        
    end
    
    % static class methods
    methods (Static)
    
    end    

end