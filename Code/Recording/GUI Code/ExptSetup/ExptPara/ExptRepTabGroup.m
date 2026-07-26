classdef ExptRepTabGroup < handle & dynamicprops
    
    % class properties
    properties
        
        % main object handles
        hTabGrp
        jTabGrp
        hTab
        objT
        
        % calculated object dimensions
        tgPos
        
        % boolean class fields
        isOn
        
        % numerical class fields
        iTab = 1;
        nTab = 2;
        
        % static character arrays
        tStr = {'Short-Term Stimuli','Long-Term Stimuli'};
        
    end
    
    % private class properties
    properties (Access = public)
        
        objB
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = ExptRepTabGroup(objB)
            
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
            fldStr = {'hFig','objSM','hghtGrp','hghtLbl','hghtRow',...
                'hghtTxt','hghtPopup','hghtEdit','hPanelR','iExpt',...
                'dX','fSz','fSzL','yGap','isShort','sTrainP',...
                'calcExptStimDurFcn','hButD'};
            
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
            
            % memory allocation
            obj.objT = cell(obj.nTab,1);
            obj.isOn = false(obj.nTab,1);
            
            % sets up the tab group position
            pPos = obj.hPanelR.Position;
            obj.tgPos = [obj.dX*[1,1]/2,pPos(3:4)-obj.dX];
            
        end
        
        % --- initialises the class objects
        function initClassObjects(obj)
            
            % creates a tab panel group
            obj.hTabGrp = createTabPanelGroup(obj.hPanelR,1);
            set(obj.hTabGrp,'position',...
                obj.tgPos,'SelectionChangedFcn',@obj.tabChangedPara)
            
            % creates the stimuli parameter tab groups
            for i = 1:obj.nTab
                % creates the tab panel object
                obj.objT{i} = ExptRepTab(obj,i==1);
            end
            
        end
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- parameter tab group selection changed callback function
        function tabChangedPara(obj,varargin)
            
            % updates the selected tab index
            obj.iTab = obj.hTabGrp.SelectedTab.UserData;
            
        end
        
        % ------------------------------ %
        % --- CLASS GETTER FUNCTIONS --- %
        % ------------------------------ %
        
        % --- retrieves the currently selected train listbox index
        function iSelS = getListTrainIndex(obj)
            
            iSelS = obj.objT{obj.iTab}.hListS.Value;
            
        end        
        
        % ------------------------------ %
        % --- CLASS SETTER FUNCTIONS --- %
        % ------------------------------ %
        
        % --- manually resets the current parameter tab
        function setParaTab(obj,iTabNw)
            
            obj.iTab = iTabNw;
            obj.hTabGrp.SelectedTab = obj.objT{iTabNw}.hTab;
            
        end
        
        % --- resets the tab enabled properties
        function setTabEnable(obj,eState,iTabNw)
            
            % field initialisations
            if isempty(obj.jTabGrp)
                obj.jTabGrp = getTabGroupJavaObj(obj.hTabGrp);
            end
            
            % default input arguments
            if ~exist('iTabNw','var')
                iTabNw = 1:obj.nTab;
            end
            
            % sets the tab enabled properties
            obj.isOn(iTabNw) = eState;
            arrayfun(@(x)(obj.jTabGrp.setEnabledAt(x-1,eState)),iTabNw);
            cellfun(@(x)(x.setRepParaProps(eState)),obj.objT(iTabNw));
            
            % resets the selected tab
            if any(obj.isOn) && ~obj.isOn(obj.iTab)
                obj.setParaTab(find(obj.isOn,1,'first'));
            end
            
        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- copies the currently selected repetition parameter values
        function sParaC = copyRepParaValue(obj)
            
            sParaC = obj.objT{obj.iTab}.copyRepParaValue();
            
        end    
        
        % --- updates the current parameter group field
        function updateParaField(obj,pFld,pVal)
            
            obj.objT{obj.iTab}.(pFld) = pVal;
            
        end
        
        % --- updates the tab/listbox properties
        function updateRepParaProps(obj,sNameNw,iTabEx)
        
            % updates the listbox properties
            if isempty(sNameNw)
                set(obj.objT{iTabEx}.hListS,'String',[],...
                    'Max',2,'Value',[],'Enable','off');
            else
                set(obj.objT{iTabEx}.hListS,'String',sNameNw,...
                    'Max',1,'Value',length(sNameNw),'Enable','on');                
            end
            
            % sets the tab properties
            obj.setTabEnable(~isempty(sNameNw),iTabEx);
            obj.objT{iTabEx}.calcStimBlockDur();
            
        end        
        
        % --- resets the selected stimuli parameter fields
        function resetSelectedBlockPara(obj,sTrainEx)
            
            % resets the selected parameter tab
            obj.resetSelectedRepTab(sTrainEx.sType);
            obj.objT{obj.iTab}.setupRepParaFields(sTrainEx.sParaEx);
            
        end        
        
        % --- resets the selected tab
        function resetSelectedRepTab(obj,sTypeNw)
            
            obj.iTab = find(strcmp(obj.tStr,sTypeNw));
            obj.hTabGrp.SelectedTab = obj.objT{obj.iTab}.hTab;
            
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