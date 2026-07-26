classdef BlockObjManager < StimObjManager
    
    % class properties
    properties
                
        % stimuli object class fields
        nObj = 0;
        sBlk = {};
        idBlk = 0;
        idBlkList = [];
        
        % function handle fields
        updateMinDurFcn        
        
        % static cell array fields
        sType = {'S','L'};
        tagStrB = 'hBlkPrompt';
        
    end    
        
    % class methods
    methods
        
        % --- class constructor
        function obj = BlockObjManager(objB)
            
            % input arguments
            obj@StimObjManager(objB,true);
            
            % initialises the class fields/objects
            obj.initBlockClassFields();
            obj.initBlockClassObjects();
            
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %        
                
        % --- initialises the class fields
        function initBlockClassFields(obj)
            
            
            
        end
        
        % --- initialises the class objects
        function initBlockClassObjects(obj)
            
            
            
        end                
        
        % ---------------------------------- %
        % --- EXPERIMENT BLOCK FUNCTIONS --- %
        % ---------------------------------- %
        
        % --- determines if the mouse is within the temporary stimuli block
        function isWithin = isWithinBlock(obj,sBlkB)
            
            % default input arguments
            if ~exist('sBlkB','var')
                sBlkB = obj.sBlk{obj.iSigS};
            end
            
            % field retrieval
            isWithin = false;            
            rPos = sBlkB.rPos;            
            mP = get(obj.hAx,'CurrentPoint');            
            
            % determines if the point is within the block x-limits
            isInX = (mP(1,1)>rPos(1)) && (mP(1,1)<sum(rPos([1,3])));
            if isInX           
                % if so, check the block y-limits
                isInY = (mP(1,2)>rPos(2)) && (mP(1,2)<sum(rPos([2,4])));
                isWithin = isInX && isInY;
            end
            
        end
        
        % --- experiment block placement mouse move function
        function exptBlockPlace(obj,hHover)
                        
            % determines which hover objects are fill objects
            isChP = obj.detFillHoverObj(hHover);            
            
            % determines if the mouse is within block vertically
            if obj.isWithinBlock(obj.sBlkT)
                % resets the mouse status flags and channel highlight
                [obj.mpStrDef,obj.isHLOn] = deal('hand',true);
                obj.resetChannelHighlight(hHover(isChP));
                
                % checks if the stimuli train is highlighted correctly
                obj.checkStimBlockHighlight(hHover);
                
            else
                % otherwise, remove the channel highlight
                obj.removeChannelHighlight(1,1)
                [obj.mpStrDef,obj.isHLOn] = deal('arrow',false);
            end
            
        end
        
        % --- experiment block movement mouse move function
        function exptBlockMove(obj,hHover)
            
            % determines if the mouse is within block vertically
            if obj.isWithinBlock()                
                % checks if the stimuli train is highlighted correctly
                [obj.mpStrDef,obj.isHLOn] = deal('hand',true);                
                obj.checkStimBlockHighlight(hHover);
                
            else
                % otherwise, remove the channel highlight
%                 obj.removeChannelHighlight(1,1)
                [obj.mpStrDef,obj.isHLOn] = deal('arrow',false);                
            end
                            
        end
        
        % --- updates the stimuli train object highlight
        function checkStimBlockHighlight(obj,hHover)
            
            % determines if a signal block is being hovered over
            if isnan(obj.iSigS)
                hSB = findobj(hHover,'tag','hSigBlk');
                if isempty(hSB)
                    % if not, then turn off all signal block highlights
                    obj.setSignalBlockHighlight(hSB,'off')

                else
                    % otherwise, turn on the stim train block highlight
                    obj.setSignalBlockHighlight(hSB,'on')                    

                    % case is the experimental protocol tab
                    if obj.mType == 4
                        % hides the temporary stimuli block/distance lines
                        obj.sBlkT.setObjVisibility('off');
                        obj.objDL.setLineVisible('off');

                        % resets the mouse movement type
                        obj.mType = 1;
                    end
                end
            end
            
        end             

        % --- deletes all the block object within index, iBlkS
        function deleteBlockObj(obj,iBlkS,resetLimits)
            
            % default input arguments
            if ~exist('resetLimits','var')
                resetLimits = false;
            end
            
            % deletes all train objects in the channel
            obj.sBlk{iBlkS}.deleteStimObj();           
            
            % resets the class fields
            isOK = (1:obj.nObj) ~= iBlkS;
            obj.sBlk = obj.sBlk(isOK);  
            obj.idBlkList = obj.idBlkList(isOK);
            
            % resets the block limits (if any objects remain)
            obj.nObj = obj.nObj - 1;            
            if resetLimits && (obj.nObj > 0)
                obj.resetBlockObjLimits();
                
                % updates the feasibility flags
                obj.objT{1}.setFeasFlag('AllStimProto',obj.nObj>0);
            end            
            
        end
        
        % --- deletes all the block objects 
        function deleteAllBlockObj(obj)
           
            % deletes all block objects
            for i = flip(1:obj.nObj)
                obj.deleteBlockObj(i,false);
            end

            % updates the feasibility flags
            obj.objT{1}.setFeasFlag('AllStimProto',false);            
            
            % clears the signal/channel index values
            [obj.iChH,obj.iSigH] = deal(-1);            
            [obj.iSigS(:),obj.idBlk] = deal(NaN,0);
            
        end
        
        % ------------------------------ %
        % --- CLASS GETTER FUNCTIONS --- %
        % ------------------------------ %
        
%         % --- determines the limits the experimental block has (given
%         %     the stimuli block duration and other existing blocks)
%         function sLimChB = getExptBlockLimits(obj,mX,tDurEx,iChS)
%             
%             % converts a time vector to a single value
%             if length(tDurEx) == 4
%                 tDurEx = vec2time(tDurEx);    
%             end            
%             
%             % memory allocation
%             if obj.nObj == 0
%                 sLimChB = [0,tDurEx];
%                 return
%             end
%             
%             %
%             for i = 1:obj.nObj
%                 a = 1;
%             end
%             
%             %
%             
%             
%         end         
        
        % --- retrieves the stimuli train information
        function sTrainS = getStimTrainInfo(obj)
            
            % field retrieval
            iSelS = obj.objR.getListTrainIndex();
%             iSelS = obj.mapBlkIndex(obj.objR.getListTrainIndex());
            
            % returns the stimuli train information
            sTrainS = obj.sTrainP.(obj.sType{obj.objR.iTab}){iSelS};
            
        end
        
        % --- retrieves the channel's train object limits 
        function tLimS = getBlockObjLimits(obj,iChB)
            
            if obj.nObj == 0
                % case is there are no train object created
                tLimS = [];
                
            else
                % case is there is at least one train object
                rPos = cell2mat(cellfun(@(x)(x.rPos),obj.sBlk(:),'un',0));
                tLimS = rPos(:,1) + [zeros(obj.nObj,1),rPos(:,3)]; 
                
                if exist('iChB','var')
                    a = 1;
                end
            end
            
        end    
        
        % --- gets the block channel limits (over all channels)
        function tLimB = getFeasBlockRegions(obj,iChB)
            
            % memory allocation
            sLimCh = cell(obj.nCh,1);
            
            % field retrieval
            tLimB = [0,obj.getExptDur()];
            tLimS = obj.getBlockObjLimits();
            
            % sets the block limits for each channel (over all blocks)
            for i = 1:obj.nObj
                % retrieves the current stimuli block channel indices
                sTrainB = obj.sTrainP.Ex{i}.sTrain;
                iChBNw = obj.getBlockChannelIndices(sTrainB);
                
                % appends the stimuli limits for each channel in the block
                sLimCh(iChBNw) = cellfun(@(x)(...
                    [x;tLimS(i,:)]),sLimCh(iChBNw),'un',0);                
            end            
            
            % sets the feasible regions (i.e., regions without blocks)
            sLimCh = unique(cell2mat(sLimCh(iChB)),'rows');
                        
            % determines the overall feasible regions (ie, without blocks)
            for i = 1:size(sLimCh,1)
                % determines the lower/upper limit row indices
                iLo = find(sLimCh(i,1) >= tLimB(:,1),1,'last');
                iHi = find(sLimCh(i,2) <= tLimB(:,2),1,'first');
                
                % updates the information based on the relative row indices
                if iLo == iHi
                    % append a new line if both row indices are equal                    
                    tLimB = [[tLimB(1:iLo,1),...
                              [tLimB(1:(iLo-1),2);sLimCh(i,1)]];...
                             [[sLimCh(i,2);tLimB((iLo+1):end,1)],...
                               tLimB(iLo:end,2)]];
                else
                    % stimuli block lower limit check
                    if sLimCh(i,1) < tLimB(iLo,2)
                        tLimB(iLo,2) = sLimCh(i,1);
                    end
                    
                    % stimuli block upper limit check
                    if sLimCh(i,2) > tLimB(iHi,1)
                        tLimB(iHi,1) = sLimCh(i,2);
                    end                    
                end
            end
            
        end
        
        % --- retrieves the feasible (non-signal object) regions
        function tLimB = getFeasRegionLimits(obj,mPX)
            
            if obj.nObj == 0
                tLimB = [0,obj.getExptDur()];
                
            else
                % sets up the feasible block limits
                iChB = obj.getBlockChannelIndices();
                tLimB = obj.getFeasBlockRegions(iChB);
                                
                % returns the band which contains the mouse pointer
                tLimB = tLimB(prod(sign(tLimB - mPX),2) == -1,:);
            end
            
        end        

        % --- determines the block/complimnetary channels indices from
        %     the stimuli block parameter struct, sTrainS
        function [iChB,iChC] = getBlockChannelIndices(obj,sTrainS)
            
            % default input arguments
            if ~exist('sTrainS','var')
                sTrainS = obj.getStimTrainInfo();
            end
            
            % field retrieval
            chNameS = sTrainS.chName;
            chName = field2cell(sTrainS.blkInfo,'chName');
            
            % determines block/complimentary channel indices
            iChB = unique(cellfun(@(x)(find(strcmp(chNameS,x))),chName));
            iChC = (obj.nCh + 1) - iChB;
            
        end

        % --- calculates the total experiment duration
        function tDurEx = getExptDur(obj)
            
            Timing = obj.iExpt.Timing;
            tDurEx = vec2time(Timing.Texp,Timing.TexpU);
            
        end                
        
        % ------------------------------ %
        % --- CLASS SETTER FUNCTIONS --- %
        % ------------------------------ %
        
        % --- set the signal block highlight
        function setSignalBlockHighlight(obj,hBlk,vState)
            
            switch vState
                case {'on'}
                    % case is showing signal block highlight
                    
                    % retrieves the rectangle object handle (if TrainObj)
                    if isa(hBlk,'BlockObj')
                        hBlk = hBlk.hRectS.hObj;
                    end
                    
                    % updates the selected object index
                    iSigNw = obj.mapBlkIndex(hBlk.UserData);
                    if ~isnan(obj.iSigS)
                        % clears the signal block highlight if changed
                        if (iSigNw ~= obj.iSigS)
                            % resets the signal index
                            obj.setSignalBlockHighlight([],'off');
                            obj.iSigS = iSigNw;
                            obj.resetHoverChannelIndex();
                            
                            % updates the stimuli train properties                                                        
                            sBlkH = obj.sBlk{iSigNw};
                            if ~isempty(sBlkH)
                                sBlkH.alterStimObjProps([],[],'rPos')
                            end
                        end
                    else
                        % resets the signal index
                        obj.iSigS = iSigNw;
                        obj.resetHoverChannelIndex();
                    end
                    
                    % resets the stimuli object linewidth
                    obj.objT{4}.hListB.Value = obj.iSigS;
                    set(hBlk,'LineWidth',obj.lWid,'Color','k',...
                        'EdgeColor','k','EdgeAlpha',1)
                    
                case {'off'}
                    % case is hiding signal block highlight
                    
                    % removes the signal block highlight
                    if ~isnan(obj.iSigS)
                        sBlkS = obj.sBlk{obj.iSigS};
                        if ~isempty(sBlkS)
                            sBlkS.setBlockObjHighlight('off');
                        end
                        
                        % resets the experiment parameter struct
                        sParaEx = obj.objR.copyRepParaValue();
                        obj.objT{4}.sTrain{obj.iSigS}.sParaEx = sParaEx;
                    end
                    
                    % resets the signal block index
                    [obj.iSigS,obj.iSigH,obj.iChH] = deal(NaN,-1,-1);
                    set(obj.objT{4}.hListB,'Max',2,'Value',[])
            end
            
        end        
        
        % --- sets the signal object hit-test flags
        function setSignalObjHitTest(obj,htState)

            % field retrieval
            htFlag = obj.htStr{1+strcmp(htState,'on')};
            
            % updates the hit-test flags on the other stimuli blocks
            for i = 1:obj.nObj
                if i ~= obj.iSigS
                    % updates the plot flag
                    sBlkH = obj.sBlk{i};
                    cellfun(@(h)(set(h,'HitTest',htState)),sBlkH.hPlotS);
                    sBlkH.setStimObjProps('InteractionAllowed',htFlag)
                end
            end

        end             

        % ---------------------------------------- %
        % --- BLOCK REGION SELECTION FUNCTIONS --- %
        % ---------------------------------------- %
        
        % --- prompts the user for the region for block placement
        function iBlkS = promptExptBlockRegion(obj,tLim)
            
            % precalculations
            lWidB = 2;
            fColB = 0.8*[1,1,1];
            hPos = obj.nCh - obj.yGap;            
            
            % prompt for the user to select desired region
            tStr = 'Select Block Region';
            mStr = ['Select the region where you would like to ',...
                    'add the experiment block'];
            waitfor(msgbox(mStr,tStr,'modal'))
            
            % removes the figure event callback functions
            cbFcnU = obj.hFig.WindowButtonUpFcn;
            cbFcnD = obj.hFig.WindowButtonDownFcn;
            cbFcnM = obj.hFig.WindowButtonMotionFcn;            
            obj.setFigCallbackFunc([],[],[]);
            
            % turns the axis hold on
            hold(obj.hAx,'on');                        
            
            % creates the 
            hRect = cell(size(tLim,1),1);
            for i = 1:size(tLim,1)
                rPos = [tLim(i,1),obj.yGap,diff(tLim(i,:)),hPos];
                hRect{i} = InteractObj('rect',obj.hAx,rPos);
                hRect{i}.setFields('UserData',i,'Tag',obj.tagStrB,...
                                   'EdgeColor','m','FaceColor',fColB,...
                                   'LineWidth',lWidB,'UiContextMenu',[],...
                                   'InteractionsAllowed','None',...
                                   'FaceAlpha',0.5);
            end
            
            % turns the axis hold off
            hold(obj.hAx,'off');  
            
            
            % wait for the next user key press
            while 1
                w = waitforbuttonpress;
                if w == 0
                    iBlkS = obj.getUserClickRegion();
                    if isempty(iBlkS)
                        break
                    elseif iBlkS > 0
                        break
                    end
                end
            end
            
            % deletes any prompt block objects
            cellfun(@(x)(x.deleteObj),hRect);
            obj.setFigCallbackFunc(cbFcnU,cbFcnD,cbFcnM); 
            pause(0.05);
            
        end
        
        % --- determines the user selected region index
        function iBlkS = getUserClickRegion(obj)
            
            % field retrieval
            mPos = get(obj.hFig,'CurrentPoint');
            
            if strcmp(get(obj.hFig,'SelectionType'),'alt')
                % if right-click, then flag the user wants to cancel
                iBlkS = [];
                
            elseif obj.isOverAxesFcn(mPos)
                % determines if the user is over a block object
                hHover = findAxesHoverObjects(obj.hFig);
                hBlkP = findobj(hHover,'tag',obj.tagStrB);
                if isempty(hBlkP)
                    % if not, then return an error index flag
                    iBlkS = -1;
                else
                    % otherwise, return the index of the selected block
                    iBlkS = get(hBlkP,'UserData');
                end
                
            else
                % flag that the user didn't click over the plot axes
                iBlkS = -1;
            end                
            
        end                

        % --- sets the figure event callback functions
        function setFigCallbackFunc(obj,cbFcnU,cbFcnD,cbFcnM)
            
            set(obj.hFig,'WindowButtonUp',cbFcnU,...
                         'WindowButtonDownFcn',cbFcnD,...
                         'WindowButtonMotionFcn',cbFcnM);
            
        end
                
        % ---------------------------------- %
        % --- EXPERIMENT BLOCK FUNCTIONS --- %
        % ---------------------------------- %
                
        % --- new stimuli block check
        function tLimF = newBlockObjCheck(obj,tDurBlk)
                        
            % default input arguments            
            tDurEx = obj.getExptDur();            
            sTrainS = obj.getStimTrainInfo();
            sParaEx = obj.objR.copyRepParaValue();
            iChB = obj.getBlockChannelIndices(sTrainS); 
            
            % sets the stimuli block duration flags
            if exist('tDurBlk','var')
                isUserIA = false;                
            else
                isUserIA = true;                
                tDurBlk = obj.calcExptStimDurFcn(sTrainS,sParaEx);
            end
            
            % retrieves the feasible block regions
            if obj.nObj == 0
                % case is there are no blocks created
                tLimF = [0,tDurEx];
            else
                % case is at least one block has been created
                tLimF = obj.getFeasBlockRegions(iChB);
            end
            
            % determines time regions that can fit the stimuli block
            isOK = diff(tLimF,[],2) >= tDurBlk;
            tLimF = tLimF(isOK,:);
            
            %
            if isempty(tLimF)
                % if there are no feasible regions, then output error
                if isUserIA
                    tStr = 'Infeasible Block Placement';
                    eStr = sprintf(['There are no feasible locations ',...
                        'to place the new experiment block (%.2fh). ',...
                        'Either remove existing experiment blocks or ',...
                        'alter the new experiment block parameters.'],...
                        tDurBlk);
                    waitfor(msgbox(eStr,tStr,'modal'))
                end
                
            elseif isUserIA && (size(tLimF,1) > 1)
                % prompts the user for experiment block placement region
                iBlkS = obj.promptExptBlockRegion(tLimF);
                if isempty(iBlkS)
                    tLimF = [];
                else
                    tLimF = tLimF(iBlkS,:);
                end
            end
            
        end
        
        % --- creates the block object
        function createBlockObj(obj,tLimF,isReset)
            
            % sets the default reset limits flag
            if ~exist('isReset','var')
                isReset = true;
            end            
            
            % default input arguments 
            obj.idBlk = obj.idBlk + 1;            
            sTrainS = obj.getStimTrainInfo();            
            sParaEx = obj.objR.copyRepParaValue();                       

            % determines the stimuli block channel indices
            iChB = obj.getBlockChannelIndices(sTrainS); 
            sParaEx.tOfs = tLimF(1)*obj.objR.objT{obj.objR.iTab}.tMltO;
            
            % creates the block object  
            sBlkNw = BlockObj(obj,sParaEx,sTrainS,iChB,tLimF(1));
            obj.objT{4}.appendExptBlockInfo(sParaEx,sTrainS);
            sBlkNw.updateMinDurFcn = obj.updateMinDurFcn;
            
            % parameter field update
            sTypeB = obj.objR.tStr{obj.objR.iTab};
            sTrainB = struct('sType',sTypeB,'sParaEx',sParaEx);
            obj.objR.resetSelectedBlockPara(sTrainB)
            
            % appends the training object to the 
            obj.sBlk{end+1} = sBlkNw;
            
            % update the other object class fields
            obj.nObj = obj.nObj + 1;            
            obj.idBlkList(end+1) = obj.idBlk;
            obj.iSigS = obj.nObj;
            
            % resets the channel index
            obj.resetHoverChannelIndex();
            obj.sBlk{obj.iSigS}.moveBlockObj();
            
            % updates the block selection hightlight
            obj.updateExptBlockSelection(sBlkNw);
            
            % resets the train stimuli object limits
            if isReset
                obj.objT{4}.hListB.Value = obj.iSigS;                
                obj.resetBlockObjLimits()
            end
            
            % appends the experimental block information
            obj.objT{1}.setFeasFlag('AllStimProto',true);            
            
        end         
        
        % --- determines if the stimuli object placement is feasible
        function isFeas = isStimObjFeas(obj)
            
            if obj.nObj == 0
                % if there are no existing objects then flag true
                isFeas = true;
                
            else
                % determines if the mouse is within an existing object
                mPos = get(obj.hAx,'CurrentPoint');
                tLimS = obj.getBlockObjLimits();
                if any(prod(sign(tLimS - mPos(1)),2) == -1)
                    % if so, then flag that it is not feasible to add
                    isFeas = false;
                    obj.mType = 1;
                    return
                end
                
                % determines if the stimuli block fits in the gap
                tmpPos = obj.sBlkT.hObj.Position;
                tLimB = obj.getFeasRegionLimits(mPos(1));        
                if isempty(tLimB)
                    isFeas = false;
                else
                    isFeas = tmpPos(3) < diff(tLimB);
                end
            end
            
        end       
        
        % --- resets the end stimuli block limits
        function resetEndBlockObjLimits(obj)
            
            obj.resetBlockObjLimits(obj.nObj);
            
        end
                
        % --- resets all block object limits
        function resetBlockObjLimits(obj,iBlkT)
            
            if (obj.nObj == 0)
                % exit if no stimuli objects have been created
                return
            elseif exist('iBlkT','var')
                % if specified, then get surrounding block indices
                iBlkT = max(1,iBlkT-1):min(obj.nObj,iBlkT+1);
            else
                % it not specified, update all stimuli blocks
                iBlkT = 1:obj.nObj;
            end      
            
            % updates the limits for the specified stimuli objects
            for i = iBlkT(:)'
                % sets the limits based on location
                sBlkT = obj.sBlk{i};
                
                % determines the limits of the block (on 
                tLimR = obj.getFeasBlockRegions(sBlkT.iChB);
                if size(tLimR,1) == 1
                    % resets the block limits
                    sBlkT.sLim = tLimR;                    
                else
                    % otherwise, determine 
                    rPosM = sum(sBlkT.rPos([1,3]).*[1,0.5]);
                    i0 = find(rPosM > tLimR(:,2),1,'last');
                    
                    % resets the block limits
                    sBlkT.sLim = [tLimR(i0,1),tLimR(i0+1,2)];
                end
            end
            
        end        
        
        % --- maps the block ID to the actual list order
        function iBlkS = mapBlkIndex(obj,idBlkS)
            
            iBlkS = find(obj.idBlkList == idBlkS);
            
        end
        
        % --- resets the channel highlight
        function resetChannelHighlight(obj,hHoverCh)
            
            % field retrieval
            iSigHnw = obj.mapBlkIndex(hHoverCh.UserData);
            
            % updates the channel object visibility (if there is a change)
            if iSigHnw ~= obj.iSigH
                % removes channel highlight
                if obj.iSigH > 0
                    obj.sBlk{obj.iSigH}.setBlockObjHighlight('off')
                end
                
                % resets the channel fill object visibility
                obj.sBlk{iSigHnw}.setBlockObjHighlight('on')
                
                % updates the hover channel index
                obj.iSigH = iSigHnw;
                obj.resetHoverChannelIndex(obj.iSigH);
            end
            
        end     
        
        % --- resets the block hover channel index
        function resetHoverChannelIndex(obj,iSig)
            
            if ~exist('iSig','var')
                iSig = obj.iSigS;
            end
            
            obj.iChH = min((obj.nCh + 1) - obj.sBlk{iSig}.iChB);
            
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
            
            % resets the channel flags
            if obj.iSigH > 0
                % hides the distance line markers
                obj.objDL.setLineVisible('off');
                obj.sBlk{obj.iSigH}.setBlockObjHighlight('off');
                [obj.isHLOn,obj.iSigH] = deal(false,-1);
                
                % removes the signal block highlight                
                    obj.setSignalBlockHighlight([],'off');
            end            
            
        end                
        
        % --- removes the channel highlights
        function removeAllChannelHighlights(obj)
           
            for i = 1:obj.nObj
                obj.sBlk{i}.setBlockObjHighlight('off');
            end
            
        end        
        
        % --- updates the selection experimental block object proeprties
        function updateExptBlockSelection(obj,sBlkNw)
            
            % updates the selection flag
            obj.mType = 5;
            
            % stimuli block object propety update
            sBlkNw.setStimObjProps('EdgeColor','r');
            sBlkNw.setBlockObjHighlight('on');
            
            % resets the repetition parameter fields
            feval(obj.hFig.WindowButtonMotionFcn)
            
        end
        
%         % --- creates the temporary stimuli object
%         function updateTempStimObj(obj)
%             
%             if isempty(obj.sBlkT)
%                 return
%             end            
%           
%             % field retrieval
%             mPos = get(obj.hAx,'CurrentPoint');
%             sTrainS = obj.getStimTrainInfo();
%             
%             % determines the stimuli block channel indices
%             [iChB,iChS] = obj.getBlockChannelIndices(sTrainS);
%             
%             % if not within the channel range then exit
%             iChHnw = ceil(mPos(1,2));
%             if (iChHnw < min(iChS)) || (iChHnw > max(iChS))
%                 obj.mType = 1;
%                 return
%             end
%             
%             % calculates the repeated stimui block/full expt durations
%             sPara = obj.objR.copyRepParaValue();
%             tDurS = obj.calcExptStimDurFcn(sTrainS,sPara);
%             tDurEx = obj.getExptDur();
%             
%             % determines the temporary experiment block limits
%             sLim = obj.getExptBlockLimits(mPos(1,1),tDurEx,iChS);
%             
%             % calculates the temporary block position vector
%             obj.iChH = min(iChS);
%             y0 = (obj.iChH-1) + obj.yGap;
%             x0 = obj.calcStimObjOffset(mPos(1,1),tDurS,tDurEx);
%             rPos = [x0,y0,tDurS,(rangewr(iChS)+1)-obj.yGap];
%             
%             % updates the object properties
%             obj.sBlkT.updateObjProps(rPos,sLim,sTrainS,sPara,iChB);
%             obj.sBlkT.moveBlockObj();
%             
%         end             

        % -- clears the class fields
        function resetClassFields(obj)
            
            % clears the fields
            [obj.idBlkList,obj.nObj] = deal([],0);
            [obj.iSigS,obj.iSigH,obj.iChH] = deal(NaN,-1,-1);
            
        end
        
    end    
        
end