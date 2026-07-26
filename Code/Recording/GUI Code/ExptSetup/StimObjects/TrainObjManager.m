classdef TrainObjManager < StimObjManager
    
    % class properties
    properties
        
        
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = TrainObjManager(objB)
            
            % input arguments
            obj@StimObjManager(objB,false);
            
            % initialises the class fields/objects
            obj.initTrainClassFields();
            obj.initTrainClassObjects();
            
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
                
        % --- initialises the class fields
        function initTrainClassFields(obj)
            

            
        end
        
        % --- initialises the class objects
        function initTrainClassObjects(obj)
            
            % creates the stimuli channel objects
            for iCh = 1:obj.nChTot
                obj.objS{iCh} = TrainObjChannel(obj,iCh);
            end
            
        end
        
        % ---------------------------------- %
        % --- EXPERIMENT TRAIN FUNCTIONS --- %
        % ---------------------------------- %
        
        % --- experiment block placement mouse move function
        function exptTrainPlace(obj,hHover)
            
            % determines which hover objects are fill objects
            isChP = obj.detFillHoverObj(hHover);
            
            % determines if the mouse is hovering over a channel
            if any(isChP)
                % resets the mouse status flags
                [obj.mpStrDef,obj.isHLOn] = deal('hand',true);
                
                % ensures the correct channel is being highlighted
                obj.resetChannelHighlight(hHover(isChP));
                
                % checks if the stimuli train is highlighted correctly                
                obj.checkStimTrainHighlight(hHover);
                obj.updateTempStimObj();
                
            else
                % otherwise, remove the channel highlight
                obj.removeChannelHighlight()
            end
            
        end        
        
        % --- experiment block movement mouse move function
        function exptTrainMove(obj,hHover)
            
            % resets the mouse/highlight flags
            [obj.mpStrDef,obj.isHLOn] = deal('hand',true);

            % checks the current stimuli block highlight
            obj.checkStimTrainHighlight(hHover)
            
        end                
        
        % --- updates the stimuli train object highlight
        function checkStimTrainHighlight(obj,hHover)
            
            % determines if a signal block is being hovered over
            if any(isnan(obj.iSigS))
                hSB = findobj(hHover,'tag','hSigBlk');
                if isempty(hSB)
                    % if not, then turn off all signal block highlights
                    obj.setSignalBlockHighlight(hSB,'off')

                else
                    % otherwise, turn on the stim train block highlight
                    obj.setSignalBlockHighlight(hSB,'on')                    

                    %
                    if obj.mType == 2
                        % hides the temporary stimuli block/distance lines
                        obj.sBlkT.setObjVisibility('off');
                        obj.objDL.setLineVisible('off');

                        % resets the mouse movement type
                        obj.mType = 1;
                    end
                end
            end
            
        end     
        
        % --- set the signal block highlight
        function setSignalBlockHighlight(obj,hBlk,vState)
                                    
            switch vState
                case {'on'}
                    % case is showing signal block highlight
                    
                    % retrieves the rectangle object handle (if TrainObj)
                    if isa(hBlk,'TrainObj')
                        hBlk = hBlk.hRectS.hObj;
                    end                    
                    
                    % updates the selected object index     
                    iSigNw = hBlk.UserData;
                    if obj.iSigH > 0
                        % clears the signal block highlight if changed
                        if (iSigNw ~= obj.iSigH)
                            % resets the signal index
                            obj.setSignalBlockHighlight([],'off');
                            obj.iSigH = iSigNw;
                            
                            % updates the stimuli train properties
                            sBlkH = obj.getHoverTrain(iSigNw);
                            if ~isempty(sBlkH)
                                sBlkH.alterStimObjProps([],[],'rPos')
                            end                            
                        end                        
                    else
                        % resets the signal index
                        obj.iSigH = iSigNw;                        
                    end                    
                    
                    % resets the stimuli object linewidth
                    set(hBlk,'LineWidth',obj.lWid,'Color','k',...
                             'EdgeColor','k','EdgeAlpha',1)
                    
                case {'off'}
                    % case is hiding signal block highlight                    
                    
                    % removes the signal block highlight                    
                    if obj.iSigH > 0
                        sBlkH = obj.getHoverTrain(); 
                        if ~isempty(sBlkH)
                            sBlkH.setTrainObjHighlight('off');
                        end                            
                    end
                    
                    % resets the signal block index
                    obj.iSigH = -1;                                        
            end
            
        end
        
        % --- resets the entire stimuli train, sTrainNw
        function resetStimuliTrain(obj,sTrainNw)
            
            % field retrieval
            bInfo = sTrainNw.blkInfo;
            chN = field2cell(bInfo,'chName');
            
            % removes any channel mis-matches
            [isM,iChG] = ismember(chN,flip(sTrainNw.chName));            
            [bInfo,iChG] = deal(bInfo(isM),iChG(isM));
            
            % loop through all channels resetting the stimuli train objects
            for iCh = 1:length(obj.objS)
                % determines the matching channel indices
                obj.iChH = iCh;
                
                % resets the channel train objects
                isCh = iChG == iCh;
                obj.objS{iCh}.resetChannelStimObj(bInfo(isCh));
            end
            
        end
        
        % --- creates the train object
        function createTrainObj(obj,iChT)
            
            % default input arguments
            if ~exist('iChT','var')
                iChT = obj.iChH;
            end
            
            % creates a new train object for the current channel
            obj.objS{iChT}.createTrainObj();
            
            % resets the channel highlight
            obj.removeChannelHighlight(1,1);            
            
        end
        
        % --- deletes all stimuli objects
        function deleteAllTrainObj(obj)
            
            % deletes all stimuli objects (over all channels)
            for i = 1:length(obj.objS)
                obj.objS{i}.deleteChannelStimObj();
            end
            
            % clears the signal/channel index values
            obj.iSigS(:) = NaN;
            [obj.iChH,obj.iSigH] = deal(-1);
            
        end                
        
        % --- determines the overall stimuli duration (which is the end
        %     time point of the last stimuli over all channels)
        function [tLimMx,tLimS] = getOverallStimDur(obj)
            
            tLimS = cellfun(@(x)(x.getChannelStimDur()),obj.objS);
            tLimMx = round(max(tLimS,[],'omitnan'),2);
            
        end
        
        % --- resets the end stimuli train limits
        function resetEndTrainObjLimits(obj)
            
            for i = 1:length(obj.objS)
                if obj.objS{i}.nObj > 0
                    obj.objS{i}.resetTrainObjLimits(obj.objS{i}.nObj);
                end
            end
            
        end
        
        % --- resets the selected object time limits
        function resetSelectedObjLimits(obj)
            
            if ~any(isnan(obj.iSigS))
                obj.objS{obj.iSigS(1)}.resetTrainObjLimits(obj.iSigS(2));
            end
            
        end        
        
        % ------------------------------ %
        % --- CLASS GETTER FUNCTIONS --- %
        % ------------------------------ %
        
        % --- stores the current full stimuli train data struct
        function sTrain = getStimTrainInfo(obj)
            
            % field retrieval
            nBlk = obj.getTotalStimCount();            
            chName = flip(obj.chInfo(:,2));
            devType = flip(obj.chInfo(:,3));
            
            % memory allocation
            sTrain = obj.setupTrainInfoStruct();             
            sTrain.sName = obj.sName;
            sTrain.chName = obj.chInfo(:,2);
            sTrain.devType = obj.chInfo(:,3);
            sTrain.tDur = obj.tDurTot;
            sTrain.tDurU = obj.tDurTotU;
            sTrain.blkInfo = repmat(obj.setupBlockInfoStruct(),nBlk,1);
            
            %
            iBlkT = 1;
            for iCh = 1:length(obj.objS)
                for iBlkCh = 1:obj.objS{iCh}.nObj
                    % block object retrieval
                    sBlkT = obj.objS{iCh}.sBlk{iBlkCh};
                    
                    % stimuli train field setting
                    sTrain.blkInfo(iBlkT).chName = chName{iCh};
                    sTrain.blkInfo(iBlkT).devType = devType{iCh};                    
                    sTrain.blkInfo(iBlkT).sPara = sBlkT.sPara;
                    sTrain.blkInfo(iBlkT).sType = sBlkT.sType;
                    
                    % increments the total block counter
                    iBlkT = iBlkT + 1;
                end
            end
            
        end

        % --- retrieves the currently selected train handle
        function sBlkS = getSelectedTrain(obj)
            
            if ~any(isnan(obj.iSigS))
                % case is the stimuli train block flag is set
                objSS = obj.objS{obj.iSigS(1)};
                if obj.iSigS(2) > objSS.nObj
                    % case is an invalid train index
                    [sBlkS,obj.iSigS(:)] = deal([],NaN);
                else
                    % otherwise, return the stimuli object
                    sBlkS = objSS.sBlk{obj.iSigS(2)};
                end
            else
                % otherwise, return an empty block 
                sBlkS = [];
            end
            
        end
        
        % --- retrieves the currently selected train handle
        function sBlkH = getHoverTrain(obj,iSigNw)
            
            % default input arguments
            if ~exist('iSigNw','var'); iSigNw = obj.iSigH; end
            
            if (iSigNw > 0) && (obj.iChH > 0)
                % case is the stimuli train block flag is set
                if iSigNw > obj.objS{obj.iChH}.nObj
                    % case is an invalid train index
                    [sBlkH,obj.iSigH] = deal([],-1);
                else
                    % otherwise, return the stimuli object
                    sBlkH = obj.objS{obj.iChH}.sBlk{iSigNw};
                end
            else
                % otherwise, return an empty block 
                sBlkH = [];
            end
            
        end        
        
        % --- calculates the stimuli train duration
        function tDurMin = getMinTrainDuration(obj,sTrainNw)
            
            % field retrieval
            sPara = field2cell(sTrainNw.blkInfo,'sPara',1);
            [tDur,tOfs] = field2cell(sPara,{'tDur','tOfs'},1);            
            
            % temporal time multipliers
            tMltDur = arrayfun(@(x)(...
                getTimeMultiplier(x.tDurU,obj.tDurTotU)),sPara);
            tMltOfs = arrayfun(@(x)(...
                getTimeMultiplier(x.tDurU,obj.tDurTotU)),sPara);            
            
            % calculates the overall minimum train duration
            tDurMin = max(tDur.*tMltDur + tOfs.*tMltOfs);
            
        end
        
        % ------------------------------ %
        % --- CLASS SETTER FUNCTIONS --- %
        % ------------------------------ %
        
        % --- gets the simuli train 
        function sLim = getStimTrainLimits(obj,sParaS,mPosX)
                        
            % determines if there are any stimuli objects
            if obj.objS{obj.iChH}.nObj == 0
                % if not, then use the full range
                sLim = [0,sParaS.tDurTot];

            else
                % otherwise, retrieve the positions of the stimuli blocks
                sLim = obj.objS{obj.iChH}.getFeasRegionLimits(mPosX);                
            end
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- updates the custim stimuli objects
        function updateCustomStimObj(obj,sObjNw)
                        
            % signal train update
            for i = 1:obj.nCh
                % if the channel is empty, then continue
                if isempty(obj.objS{i})
                    continue
                end
                
                % loops through each train in the block determining if they
                % need to be updated
                for j = 1:obj.objS{i}.nObj
                    sBlkS = obj.objS{i}.sBlk{j};
                    if strcmp(sBlkS.sType,sObjNw.sName)
                        % if there is a match, then reset
                        sBlkS.sPara.sObj = sObjNw;
                        sBlkS.iChH = i;
                        
                        % recalculate the block stimuli signal
                        sBlkS.calcInitialStimuliSignal();
                        sBlkS.updatePlotObject();
                    end
                end
            end
            
            % retrieves the experiment protocol stimuli train names
            sTypeEx = [];            
            if ~isempty(obj.sTrainP.Ex)
                sTypeEx = cellfun(@(x)(x.sName),obj.sTrainP.Ex,'un',0);
            end            
            
            % saves signal train update
            for i = 1:length(obj.sStr)
                % field retrieval
                sTrain = obj.sTrainP.(obj.sStr(i));
                
                % loops through each info block (in each stimuli train)
                % determining if the parameters need updating
                for j = 1:length(sTrain)
                    for k = 1:length(sTrain{j}.blkInfo)
                        % determines if there is a match
                        if strcmp(sTrain{j}.blkInfo(k).sType,sObjNw.sName)
                            % if so, then update the custom block info
                            sTrain{j}.blkInfo(k).sPara.sObj = sObjNw;                            
                        end
                    end
                    
                    % determines if the current stimuli block is within the
                    % experimental block stimuli block
                    ii = strcmp(sTypeEx,sTrain{j}.sName);
                    if any(ii)
                        % if so, update the parameters and flag an update
                        obj.sTrainP.Ex{ii}.sTrain = sTrain{j};
                        
                        % resets the experiment protocol block signal
                        sBlkT = obj.objT{4}.objSM.sBlk{ii};
                        sBlkT.sTrain = sTrain{j};
                        sBlkT.calcStimBlockSignals();
                        sBlkT.updatePlotObject();
                    end                    
                end
                
                % field reset
                obj.sTrainP.(obj.sStr(i)) = sTrain;
            end
            
        end        
        
        % --- determines if the stimuli object placement is feasible
        function isFeas = isStimObjFeas(obj)
            
            isFeas = obj.objS{obj.iChH}.isStimObjFeas();
            
        end        
        
        % --- creates the temporary stimuli object
        function updateTempStimObj(obj)
            
            if isempty(obj.sBlkT)
                return
            end
                
            % field retrieval
            sType = obj.objP.tTabSel;
            sParaS = obj.objP.(sType);
            mPos = get(obj.hAx,'CurrentPoint');
            
            % calculates the stimuli object
            sLim = obj.getStimTrainLimits(sParaS,mPos(1,1));
            if isempty(sLim)
                obj.sBlkT.setObjVisibility('off')
                obj.objDL.setLineVisible('off');
                obj.mType = 1;
                return
            else
                obj.sBlkT.setObjVisibility('on')
            end
            
            % calculates the stimli object position vector
            y0 = (obj.iChH-1) + obj.yGap;
            x0 = obj.calcStimObjOffset(mPos(1,1),sParaS.tDur,obj.tDurTot);            
            tMltDur = getTimeMultiplier(obj.tDurTotU,sParaS.tDurU);
            rPos = [x0,y0,sParaS.tDur*tMltDur,1-obj.yGap];
            
            % creates the temporary stimuli object
            obj.sBlkT.updateTrainObjProps(rPos,sLim,sParaS,sType);
            obj.sBlkT.moveTrainObj();
            
        end
       
        % --- resets the stimuli object time limits
        function resetStimObjTimeLimits(obj)
            
            obj.objS{obj.iChH}.resetTrainObjLimits(obj.iSigH);
            
        end        
        
        % --- sets the signal object hit-test flags
        function setSignalObjHitTest(obj,htState)

            % field retrieval
            htFlag = obj.htStr{1+strcmp(htState,'on')};
            
            % updates the hit-test flags on the other stimuli blocks
            for i = 1:length(obj.objS)
                for j = 1:obj.objS{i}.nObj
                    sBlkH = obj.objS{i}.sBlk{j};
                    if ~isequal([i,j],[obj.iChH,obj.iSigH])
                        % updates the plot flag
                        set(sBlkH.hPlotS,'HitTest',htState);
                        sBlkH.setStimObjProps('InteractionAllowed',htFlag)
                    end
                end
            end

        end    
        
        % --- resets the channel highlight
        function resetChannelHighlight(obj,hHoverCh)
            
            % field retrieval
            iChHnw = hHoverCh.UserData;
            
            % updates the channel object visibility (if there is a change)
            if iChHnw ~= obj.iChH
                % removes channel highlight
                if obj.iChH > 0
                    setObjVisibility(obj.hFillCh{obj.iChH},'off');
                end
                
                % resets the channel fill object visibility
                setObjVisibility(obj.hFillCh{iChHnw},'on');
                
                % updates the hover channel index
                obj.iChH = iChHnw;
            end
            
        end          
        
        % --- removes the channel highlight
        function removeChannelHighlight(obj,resetCursor,forceUpdate)
            
            % default input arguments
            if ~exist('forceUpdate','var')
                forceUpdate = false;
            end
            
            % resets the mouse point string
            if resetCursor
                if obj.mType == 1
                    obj.resetCustomMousePointer();
                else
                    obj.mpStrDef = 'arrow';
                end
            end
            
            % if no highlight/force updating then exit
            if ~(obj.isHLOn || forceUpdate)
                return
            end
            
            % updates the temporary stimuli object properties (if showing)
            if obj.sBlkT.isShow
                % hides the temporary stimuli object
                obj.sBlkT.setObjVisibility(0)
                
                % resets the status flag
                if ~forceUpdate
                    obj.mType = 1;
                end
            end            
            
            % resets the channel flags
            if obj.iChH > 0
                % hides the distance line markers
                obj.objDL.setLineVisible('off');
                obj.setFillVisibility('off');
                obj.isHLOn = false;
                
                % removes the signal block highlight
                obj.setSignalBlockHighlight([],'off');
            end
            
        end         
        
        % --- sets the channel highlight visibility
        function setFillVisibility(obj,eStr)
            
            if obj.iChH > 0
                setObjVisibility(obj.hFillCh{obj.iChH},eStr);
            end
            
        end
        
        % --- removes the channel highlights
        function removeAllChannelHighlights(obj)
           
            for i = 1:length(obj.objS)
                for j = 1:obj.objS{i}.nObj
                    obj.objS{i}.sBlk{j}.setTrainObjHighlight('off');
                end
            end
            
        end        
        
    end
    
    % static class methods
    methods (Static)        

        % --- initialises the stimuli train information data struct
        function sTrain = setupTrainInfoStruct()
            
            sTrain = struct('sName',[],'chName',[],'tDur',[],'tDurU',[],...
                            'blkInfo',[]);
            
        end
        
        % --- initialises the stimuli object block information data struct
        function blkInfo = setupBlockInfoStruct()
            
            blkInfo = struct('chName',[],'devType',[],...
                             'sPara',[],'sType',[]);
            
        end
        
    end
    
end