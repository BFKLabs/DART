classdef RegionConfig1D < dynamicprops & handle
    
    % class properties
    properties
        
        % main class objects
        hTab        
        hPanel
        
        % configuration information panel objects
        hPanelC
        hEditC
        hChkC
        hPopupC
        
        % region information panel class objects
        hPanelR
        hTableR
        hChkR
        hPopupR
        hTxtR
        
        % group name panel class objects
        hPanelN
        hTableN
        
        % fixed object dimension fields
        widTxtL = 165;
        widTxtR = 95;
        widChk = 225;
        hghtPanelC = 130;
        hghtPanelR = 175;
        hghtPanelN = 130;        
        
        % calculated object dimension fields  
        widPanel
        widTable
        hghtPanel
        hghtTableN
        hghtTableR
        
        % static numeric class fields
        nRowN = 4;
        nRowR = 4;
        
        % static string class fields
        tStr = '1D Setup';
        
    end
    
    % private class properties
    properties (Access = private)
        
        objB
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = RegionConfig1D(objB)
            
            % sets the input arguments
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
            fldStr = {'hFig','hAx','hTabGrp','isMTrk',...
                  'iMov','iData','dX','fSzH','fSzL','fSz',...                  
                  'isChange','isUpdating','isMenuOpen','isMouseDown',...
                  'hghtChk','widPanelI','hghtRow','H0T','HWT','ppStr'};
            
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
            
            % ------------------------------ %
            % --- DIMENSION CALCULATIONS --- %
            % ------------------------------ %            
        
            % panel dimension calculations
            obj.widPanel = obj.widPanelI - obj.dX;
            obj.hghtPanel = 2.5*obj.dX + ...
                obj.hghtPanelC + obj.hghtPanelR + obj.hghtPanelN;
            
            % other object dimension calculations
            obj.widTable = obj.widPanel - 2*obj.dX;
            obj.hghtTableN = obj.H0T + obj.nRowN*obj.HWT;
            obj.hghtTableR = obj.H0T + obj.nRowR*obj.HWT;

            % updates the properties for multi-tracking
            if obj.isMTrk
                % resets the tab title
                obj.tStr = 'Region Setup';                
                
                % resets the panel heights
                obj.hghtPanelC = obj.hghtPanelC + obj.hghtRow;
                obj.hghtPanelR = obj.hghtPanelR - obj.hghtRow;
            end
            
        end
        
        % --- initialises the class fields
        function initClassObjects(obj)
            
            % object callback function handles
            cbFcnCE = obj.objB.editParaFcn;
            cbFcnCP = obj.objB.popupParaFcn;
            cbFcnRC = obj.objB.checkSubGroupFcn;            
            cbFcnRE = obj.objB.tableRegionEditFcn;
            cbFcnNE = obj.objB.tableGroupEditFcn;
            cbFcnNS = obj.objB.tableGroupSelectFcn;            
            
            % ------------------------ %            
            % --- MAIN TAB OBJECTS --- %
            % ------------------------ %            
            
            % creates the tab object
            obj.hTab = createNewTabPanel(...
                obj.hTabGrp,1,'Title',obj.tStr,'UserData',1);
            set(obj.hTab,'ButtonDownFcn',obj.objB.tabSelFcn)            

            % creates the panel object
            pPos = [obj.dX/2*[1,1],obj.widPanelI,obj.hghtPanel];
            obj.hPanel = createUIObj(...
                'panel',obj.hTab,'Position',pPos,'Title','');
            
            % --------------------------------- %
            % --- GROUP NAMES PANEL OBJECTS --- %
            % --------------------------------- %
            
            % initialisations
            tHdrN = 'GROUP NAMES';
            
            % table properties
            cFormN = {'char'};
            cHdrN = {'Group Name'};
            tDataN = obj.iData.D1.gName;
            tCol = getAllGroupColours(length(tDataN),1);            
                        
            % creates the panel object
            pPosN = [obj.dX/2*[1,1],obj.widPanel,obj.hghtPanelN];
            obj.hPanelN = obj.objB.createPanel(obj.hPanel,pPosN,tHdrN);
            
            % creates the table object
            pPosTN = [obj.dX*[1,1],obj.widTable,obj.hghtTableN];
            obj.hTableN = createUIObj('table',obj.hPanelN,...
                'Data',tDataN,'Position',pPosTN,'ColumnName',cHdrN,...
                'ColumnEditable',true,'ColumnFormat',cFormN,...                
                'CellEditCallback',cbFcnNE,'BackgroundColor',tCol,...
                'CellSelectionCallback',cbFcnNS,'UserData',1);
            
            % --------------------------------- %
            % --- REGION INFO PANEL OBJECTS --- %
            % --------------------------------- %
            
            % initialisations
            tHdrR = 'REGION INFORMATION';
            cFormG = [{' '};tDataN(:)];
            chkStrR = 'Allow Sub-Grouping Within Regions';
            
            % table properties
            cWidR = {45, 45, 45, 91};
            cHdrR = {'Row #','Col #','Count','Group'};
            cFormR = {'numeric','numeric','numeric',cFormG'};
            cEditR = [false,false,true,true];            
            
            % creates the panel object
            yPosR = sum(pPosN([2,4])) + obj.dX/2;
            pPosR = [obj.dX/2,yPosR,obj.widPanel,obj.hghtPanelR];
            obj.hPanelR = obj.objB.createPanel(obj.hPanel,pPosR,tHdrR);            
            
            % sets the tracking specific objects/properties
            if obj.isMTrk
                % case is multi-tracking
                yOfsPR = obj.dX/2;
                yPosTR = obj.dX/2 + obj.hghtRow + 2;
                
            else
                % case is single tracking
                
                % creates the checkbox object
                cPosR = [obj.dX*[2,0.5],obj.widChk,obj.hghtChk];
                obj.hChkR = createUIObj('checkbox',obj.hPanelR,...
                    'Position',cPosR,'FontSize',obj.fSzL,...
                    'FontWeight','Bold','String',chkStrR,...
                    'Callback',cbFcnRC,'UserData','isFixed');                
                
                % calculates the table vertical offset
                yOfsPR = obj.dX/2 + obj.hghtRow;                
                yPosTR = obj.dX/2 + 2*obj.hghtRow;
            end
            
            % creates the popup menu
            pStrPR = [{'None'};tDataN(:)];
            yPosPR = yOfsPR;
            [obj.hPopupR,obj.hTxtR] = obj.objB.createPopupGroup(...
                obj.hPanelR,obj.widTxtR,'Current Group',yPosPR);
            set(obj.hPopupR,'String',pStrPR,'Value',2);            
                
            % creates the table object
            tPosR = [obj.dX,yPosTR,obj.widTable,obj.hghtTableR];
            obj.hTableR = createUIObj('table',obj.hPanelR,...
                'Position',tPosR,'FontSize',obj.fSz,'ColumnName',cHdrR,...
                'ColumnFormat',cFormR,'ColumnWidth',cWidR,'RowName',[],...
                'ColumnEditable',cEditR,'CellEditCallback',cbFcnRE,...
                'FontSize',obj.fSz);            
            
            % ----------------------------------- %
            % --- CONFIGURATION PANEL OBJECTS --- %
            % ----------------------------------- %
            
            % initialisations
            yOfs0 = 0;            
            tHdrC = 'CONFIGURATION INFO';
            pStr = {'nRow','nCol','nGrp','nFlyMx'};
            tStrC = {'Region Row Groupings','Region Column Groupings',...
                     'Genotype Group Count','Max Sub-Region Count'};                  
                 
            % creates the panel object
            yPosC = sum(pPosR([2,4])) + obj.dX/2;
            pPosC = [obj.dX/2,yPosC,obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = obj.objB.createPanel(obj.hPanel,pPosC,tHdrC);
            
            % sets up the multi-tracking specific objects
            if obj.isMTrk
                % creates the region shape popupmenu
                tStrCP = 'Experiment Region Shape';
                obj.hPopupC = obj.objB.createPopupGroup(...
                    obj.hPanelC,obj.widTxtL,tStrCP,obj.dX);                
                
                % sets the popup menu properties
                set(obj.hPopupC,'String',obj.ppStr,...
                    'UserData','mShape','Callback',cbFcnCP);
                
                % resets the text label string
                isFlyMx = strcmp(pStr,'nFlyMx');
                tStrC{isFlyMx} = 'Max Fly Count Per Region';
                
                % sets the parameter vertical offset
                yOfs0 = obj.hghtRow;
            end
            
            % creates the parameter objects
            obj.hEditC = cell(length(tStrC),1);
            for i = 1:length(tStrC)
                % pre-calculations
                j = length(tStrC) - (i-1);
                yOfs = obj.dX + (j-1)*obj.hghtRow + yOfs0;
                
                % creates the parameter editbox/label combo
                obj.hEditC{i} = obj.objB.createEditGroup(...
                    obj.hPanelC,obj.widTxtL,tStrC{i},yOfs);
                set(obj.hEditC{i},'UserData',pStr{i},'Callback',cbFcnCE);
            end

            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % auto-resizes the tables
            autoResizeTableColumns(obj.hTableR);
            autoResizeTableColumns(obj.hTableN);
            
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