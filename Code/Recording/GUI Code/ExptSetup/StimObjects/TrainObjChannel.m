classdef TrainObjChannel < handle & dynamicprops
    
    % class properties
    properties
        
        % channel properties
        iCh
        sCol
        
        % stimuli object class fields
        nObj = 0;
        sBlk = {};
        
    end
    
    % private class properties
    properties (Access = private)
        
        objB
        
    end    
        
    % class methods
    methods
        
        % --- class constructor
        function obj = TrainObjChannel(objB,iCh)
            
            % input arguments
            obj.objB = objB;
            obj.iCh = iCh;
            
            % initialises the class fields/objects
            obj.linkParentProps();
            obj.initClassFields();
            obj.initClassObjects();
                        
        end
        
        % --- initialises the class object fields with that parent object
        function linkParentProps(obj)
            
            % parent fields strings
            fldStr = {'hFig','hAx','iExpt','objDL',...
                      'yGap','objP','tDurTot','tDurTotU',...
                      'sBlkT','iChH','chCol','mType','lWid'};
            
            % connects the base/child objects
            for propname = fldStr
                metaprop = addprop(obj, propname{1});
                metaprop.SetMethod = @(obj, varargin) ...
                    SetDispatch(obj, propname{1}, varargin{:});
                metaprop.GetMethod = @(obj)GetDispatch(obj, propname{1});
            end
            
        end        
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %        
        
        % --- initialises the class fields
        function initClassFields(obj)
           
            obj.sCol = obj.chCol{obj.iCh};
            
        end
        
        % --- initialises the class objects
        function initClassObjects(obj)
            

                        
        end        
        
        % --- creates a new train object
        function createTrainObj(obj,sParaT,isReset)
            
            % default input arguments
            if ~exist('sParaT','var') || isempty(sParaT)
                sParaT = obj.sBlkT.sParaS.copyParaValue();
            end
            
            % sets the default reset limits flag
            if ~exist('isReset','var')
                isReset = true;
            end
                        
            % creates a new train block object
            sBlkNw = TrainObj(obj,sParaT);
            
            % appends the training object to the 
            obj.sBlk{end+1} = sBlkNw;
            obj.nObj = obj.nObj + 1;
            
            % reorders the blocks temporaly (if more than one)
            if obj.nObj > 1
                % reorders 
                tLimS = obj.getTrainObjLimits();
                [~,iSort] = sort(tLimS(:,1));
                obj.sBlk = obj.sBlk(iSort);
                
                % resets the userdata fields
                xiN = num2cell(1:obj.nObj);
                cellfun(@(h,i)(...
                    h.setStimObjProps('UserData',i)),obj.sBlk,xiN)
            end            
            
            % resets the train stimuli object limits
            if isReset
                obj.resetTrainObjLimits()
            end
            
        end
        
        % --- resets the channel stimuli objects
        function resetChannelStimObj(obj,bInfoCh)
            
            % field retrieval
            nObjNw = length(bInfoCh);            
            obj.sBlkT.sLim = [0,obj.tDurTot];
            
            % creates any missing stimuli objects
            for i = flip((obj.nObj+1):nObjNw)
                % ensures the block parameters are setup correctly
                if ~isfield(bInfoCh(i).sPara,'dType')
                    bInfoCh(i).sPara.dType = bInfoCh(i).sType;
                end
                
                % creates the train stimuli object                
                obj.createTrainObj(bInfoCh(i).sPara,false);
            end

            % deletes any extraneous stimuli objects
            for i = flip((nObjNw+1):obj.nObj)
                obj.deleteStimObj(i,false);
            end
            
            % updates the existing stimuli object parameters
            for i = 1:nObjNw
                obj.sBlk{i}.alterTrainPara(bInfoCh(i).sPara);
            end
            
            % resets the train object limits
            obj.resetTrainObjLimits();
            
        end                
        
        % --- deletes all the stimuli objects within the channel
        function deleteChannelStimObj(obj)
                        
            % deletes all train objects in the channel
            for i = flip(1:obj.nObj)
                obj.deleteStimObj(i);
            end
            
            % resets the class fields
            obj.nObj = 0;
            obj.sBlk = {};
            
        end
        
        % --- deletes all the stimuli objects within the channel
        function deleteStimObj(obj,iBlkS,resetLimits)
            
            % default input arguments
            if ~exist('resetLimits','var')
                resetLimits = false;
            end
            
            % deletes all train objects in the channel
            obj.sBlk{iBlkS}.deleteStimObj();
            
            % decrements the block user data flag
            for i = (iBlkS+1):obj.nObj
                iBlk = obj.sBlk{i}.hRectS.getFieldVal('UserData');
                obj.sBlk{i}.setStimObjProps('UserData',iBlk-1)
            end
            
            % resets the class fields
            obj.sBlk = obj.sBlk((1:obj.nObj) ~= iBlkS);            
            obj.nObj = obj.nObj - 1;
            
            % resets the block limits
            if resetLimits && (obj.nObj > 0)
                obj.resetTrainObjLimits();
            end
            
        end
        
        % --- resets the train object limits
        function resetTrainObjLimits(obj,iBlkT)
            
            % exit if no stimuli objects have been created
            if (obj.nObj == 0)
                return
            elseif exist('iBlkT','var')
                iBlkT = max(1,iBlkT-1):min(obj.nObj,iBlkT+1);
            else
                iBlkT = 1:obj.nObj;
            end
            
            % retrieves the train object limits
            tLimS = obj.getTrainObjLimits();
            
            % updates the limits for the specified stimuli objects
            for i = iBlkT(:)'
                % sets the limits based on location
                if length(iBlkT) == 1
                    % case is only one signal object
                    sLimNw = [0,obj.tDurTot];
                else
                    % case is multiple signal objects
                    switch i
                        case 1
                            sLimNw = [0,tLimS(i+1,1)];
                        case obj.nObj
                            sLimNw = [tLimS(i-1,2),obj.tDurTot];
                        otherwise
                            sLimNw = [tLimS(i-1,2),tLimS(i+1,1)];
                    end
                end
                
                % resets the block limits
                obj.sBlk{i}.sLim = sLimNw;
            end
            
        end
        
        % --- calculates the overall stimuli duration
        function tDurCh = getChannelStimDur(obj)
            
            if obj.nObj == 0
                tDurCh = NaN;
            else
                tDurCh = obj.sBlk{end}.xS(end);
            end
            
        end
        
        % --- determines if the stimuli object placement is feasible
        function isFeas = isStimObjFeas(obj)
            
            if obj.nObj == 0
                % if there are no existing objects then flag true
                isFeas = true;
                
            else
                % determines if the mouse is within an existing object
                mPos = get(obj.hAx,'CurrentPoint');
                tLimS = obj.getTrainObjLimits();
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
        
        % --- retrieves the channel's train object limits
        function tLimS = getTrainObjLimits(obj)
            
            if obj.nObj == 0
                % case is there are no train object created
                tLimS = [];
                
            else
                % case is there is at least one train object
                rPos = cell2mat(cellfun(@(x)(x.rPos),obj.sBlk(:),'un',0));
                tLimS = rPos(:,1) + [zeros(obj.nObj,1),rPos(:,3)];
            end
            
        end
        
        % --- retrieves the feasible (non-signal object) regions
        function tLimB = getFeasRegionLimits(obj,mPX)
            
            if obj.nObj == 0
                tLimB = [0,obj.tDurTot];
                
            else
                % sets up the feasible block limits
                tLimS = obj.getTrainObjLimits();
                tLimB = [[0;tLimS(:,2)],[tLimS(:,1);obj.tDurTot]];
                
                % returns the band which contains the mouse pointer
                tLimB = tLimB(prod(sign(tLimB - mPX),2) == -1,:);
            end
            
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