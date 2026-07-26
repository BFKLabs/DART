classdef ExptParaTabGroup < handle & dynamicprops
    
    % class properties
    properties
        
        % main object handles
        hTabGrp
        
        % other class fields
        tTabSel
        
        % static character arrays
        tStr = {'Square','Ramp','Triangle','SineWave','Random'};
        
    end
    
    % private class properties
    properties (Access = public)
        
        objB
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = ExptParaTabGroup(objB)
            
            % input arguments
            obj.objB = objB;
            
            % initialises the class fields/objects
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
            fldStr = {'hFig','objP','objSM','objCS','hButP',...
                'dX','hghtGrp','hghtLbl','hghtRow',...
                'hghtTxt','hghtPopup','hghtEdit','hPanelP',...
                'fSz','fSzL','isShort','tDurTot','tDurTotU',...
                'mType','mpStrDef'};
            
            % connects the base/child objects
            for propname = fldStr
                metaprop = addprop(obj, propname{1});
                metaprop.SetMethod = @(obj, varargin) ...
                    SetDispatch(obj, propname{1}, varargin{:});
                metaprop.GetMethod = @(obj)GetDispatch(obj, propname{1});
            end
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % finish me!
            
        end
        
        % --- initialises the class objects
        function initClassObjects(obj)
            
            % initialisations
            cbFcnTG = @obj.tabChangedPara;
            
            % sets up the tab group position
            pPos = obj.hPanelP.Position;
            yPos = sum(obj.hButP{2}.Position([2,4])) + obj.dX/2;
            hPos = obj.hButP{1}.Position(2) - (yPos + obj.dX/2);
            tgPos = [pPos(1),yPos,pPos(3)-obj.dX,hPos];
            
            % creates a tab panel group
            obj.hTabGrp = createTabPanelGroup(obj.hPanelP,1);
            set(obj.hTabGrp,'Position',tgPos,'SelectionChangedFcn',cbFcnTG)
            
            % creates the stimuli parameter tab groups
            for i = 1:length(obj.tStr)
                obj.addParaTab(obj.tStr{i});                
            end
            
            % sets the selected tab stirng
            obj.tTabSel = obj.tStr{1};
            
        end
        
        % --- adds the new parameter tab
        function addParaTab(obj,tStrNw,sObj)
            
            % default input arguments
            if ~exist('sObj','var')
                sObj = [];
            end
            
            % adds the tab string
            if ~any(strcmp(obj.tStr,tStrNw))
                obj.tStr{end+1} = tStrNw;
            end
            
            % adds/creates the new parameter property field
            addprop(obj,tStrNw);            
            obj.(tStrNw) = ExptParaTab(obj,tStrNw,sObj);
            
        end
        
        % --- deletes the parameter tab
        function deleteParaTabs(obj,tStrD)
            
            % ensures the tab deletion names are stored in a cell array
            if ~iscell(tStrD)
                tStrD = {tStrD};
            end
            
            % deletes the parameter tab
            for i = 1:length(tStrD)
                delete(obj.(tStrD{i}).hTab);
                rmprops(obj,tStrD{i});
            end
            
            % removes the parameters from the list
            obj.tStr = setdiff(obj.tStr,tStrD);
                        
        end
        
        % --- adds/removes any missing/extraneous custom signal tabs
        function resetCustomTabs(obj,sTypeEx,sTrainEx)
            
            % field retrieval
            hTab = obj.hTabGrp.Children;
            isRmvT = arrayfun(@(x)(x.UserData),hTab);
            tStrT = arrayfun(@(x)(x.Title),hTab,'un',0);
            
            % adds in any missing tabs
            sTypeAdd = setdiff(sTypeEx,tStrT);
            if ~isempty(sTypeAdd)
                % stimuli block information field retrieval
                bInfo = cell2cell(cellfun(...
                    @(x)(x.sTrain.blkInfo),sTrainEx,'un',0));                
                sType = arrayfun(@(x)(x.sType),bInfo,'un',0);
                sObj = arrayfun(@(x)(x.sPara.sObj),bInfo,'un',0);
            
                % adds the missing custom parameter tab                
                for i = 1:length(sTypeAdd)
                    ii = find(strcmp(sType,sTypeAdd{i}),1,'first');                    
                    obj.addParaTab(sTypeAdd{i},sObj{ii});
                end
            end
                
            % clears any required tabs from the removal index array
            [~,iB] = intersect(tStrT,sTypeEx,'stable');
            isRmvT(iB) = false;
            
            % deletes any extraneous custom signal tabs
            if any(isRmvT)
                obj.deleteParaTabs(tStrT(isRmvT));
            end
            
        end
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- parameter tab group selection changed callback function
        function tabChangedPara(obj,varargin)
                    
%             % pause for button down callback function to complete
%             pause(0.01);
            
            % resets the stimuli selection state
            mType0 = obj.mType;
            sParaS0 = obj.(obj.tTabSel).copyParaValue();
            [obj.mType,obj.mpStrDef] = deal(0,'arrow');
            set(obj.hFig,'Pointer',obj.mpStrDef);
            
            % updates the currently selected tab
            hTabSel = obj.hTabGrp.SelectedTab;
            obj.tTabSel = hTabSel.Title;
            
            % sets the custom signal menu items (if available)
            if ~isempty(obj.objCS)
                setObjEnable(obj.objCS.hMenuA,hTabSel.UserData);
            end
            
            % updates the stimuli parameter block
            sBlkS = obj.objSM.getSelectedTrain();
            if ~isempty(sBlkS)
                % retrieves the tab parameters
                objTS = obj.(obj.tTabSel);
                sParaS = objTS.copyParaValue();
                
                % resets the stimuli parameter time offset
                [objTS.tOfs,sParaS.tOfs] = deal(sParaS0.tOfs);
                [objTS.tOfsU,sParaS.tOfsU] = deal(sParaS0.tOfsU);                                
                
                % resets the time offset object properties
                objTS.hEditOfs.String = num2str(sParaS.tOfs);                
                if ~obj.isShort
                    ii = strcmp(objTS.hPopupOfs.String,sParaS.tOfsU);
                    objTS.hPopupOfs.Value = find(ii);
                end                 
                
                % updates the train parameters
                sBlkS.alterTrainPara(sParaS);                               
            end
            
            pause(0.05);
            obj.mType = mType0;
            
        end

        % ------------------------------ %
        % --- CLASS GETTER FUNCTIONS --- %
        % ------------------------------ %
        
        % --- retrieves the default parameter struct
        function sParaDef = getDefParaStruct(obj,tTabS)
            
            if exist('tTabS','var')
                sParaDef = obj.(tTabS).sPara0;
            else
                sParaDef = obj.(obj.tTabSel).sPara0;
            end
            
        end
        
        % --- retrieves the tab parameter struct
        function sPara = getTabPara(obj,tTabStr)
            
            if exist('tTabStr','var')
                sPara = obj.(tTabStr);
            else
                sPara = obj.(obj.tTabSel);
            end
            
        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- updates the current parameter group field
        function updateParaField(obj,pFld,pVal)
            
            obj.(obj.tTabSel).(pFld) = pVal;
            
        end
        
        % --- resets the default parameters
        function resetDefPara(obj,tType)
            
            % default input arguments
            if ~exist('tType','var')
                tType = obj.tTabSel;
            end
            
            % field retrieval
            objT = obj.(tType);
            
            % resets the stimuli parameters
            objT.isUpdating = true;
            objT.setupStimParaFields();
            objT.isUpdating = false;
            
        end
        
        % --- resets all stimuli types to default parameter values
        function resetAllDefPara(obj)
            
            for i = 1:length(obj.tStr)
                obj.resetDefPara(obj.tStr{i});
            end
            
        end                
        
        % --- resets the selected stimuli parameter fields
        function resetSelectedTrainPara(obj,sParaH)
            
            % resets the selected parameter tab
            obj.resetSelectedParaTab(sParaH.dType);
            obj.(obj.tTabSel).setupStimParaFields(sParaH);
            
        end
        
        % --- resets the selected tab
        function resetSelectedParaTab(obj,dType)
            
            obj.tTabSel = dType;
            obj.hTabGrp.SelectedTab = obj.(dType).hTab;
            
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