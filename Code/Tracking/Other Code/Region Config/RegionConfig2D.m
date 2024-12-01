classdef RegionConfig2D < dynamicprops & handle
    
    % class properties
    properties
        
        % main class objects
        hTab
        hPanel   
        
        % configuration information panel objects
        hPanelC
        hEditC
        hPopupC
        
        % region information panel class objects
        hPanelR
        hPanelRI
        hRadioR
        hEditR
        hPopupR
        
        % group name panel class objects
        hPanelN
        hTableN        
        
        % fixed object dimension fields
        widTxtL = 165;
        widChk = 225;
        widTxtR = 150;
        hghtPanelC = 130;
        hghtPanelR = 175;
        hghtPanelN = 130;
        hghtPanelI = 35;                
        
        % calculated object dimension fields  
        widPanel
        widTable
        hghtPanel 
        hghtPanelRI
        hghtTableN        
        widPanelRI
        widRadioRI
        
        % static numeric class fields
        nRowN = 4;
        
        % static string class fields
        tStr = '2D Setup';
        
    end
    
    % private class properties
    properties (Access = private)
        
        objB
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = RegionConfig2D(objB)
            
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
            fldStr = {'hFig','hAx','hTabGrp',...
                  'iMov','iData','dX','fSzH','fSzL','fSz','isMTrk',...
                  'isChange','isUpdating','isMenuOpen','isMouseDown',...
                  'widPanelI','hghtRow','hghtRadio','H0T','HWT','ppStr'};
            
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
            
            % inner region grouping panel dimensions
            obj.widPanelRI = obj.widPanel - obj.dX;
            obj.hghtPanelRI = obj.dX + [1,2]*obj.hghtRow;
            obj.widRadioRI = obj.widPanel - 2*obj.dX;
            
            % other object dimension calculations
            obj.widTable = obj.widPanel - 2*obj.dX;
            obj.hghtTableN = obj.H0T + obj.nRowN*obj.HWT;                        
            
        end
        
        % --- initialises the class fields
        function initClassObjects(obj)
            
            % object callback function handles
            cbFcnCE = obj.objB.editParaFcn;
            cbFcnCP = obj.objB.popupParaFcn;
            cbFcnRS = obj.objB.radioRegionChangeFcn;
            cbFcnNE = obj.objB.tableGroupEditFcn;
            cbFcnNS = obj.objB.tableGroupSelectFcn;
            
            % ------------------------ %            
            % --- MAIN TAB OBJECTS --- %
            % ------------------------ %            
            
            % creates the tab object
            obj.hTab = createNewTabPanel(...
                obj.hTabGrp,1,'Title',obj.tStr,'UserData',2);            
            set(obj.hTab,'ButtonDownFcn',obj.objB.tabSelFcn);
                   
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
            tDataN = obj.iData.D2.gName;            
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
                'CellSelectionCallback',cbFcnNS,'UserData',2);
            
            % --------------------------------- %
            % --- REGION INFO PANEL OBJECTS --- %
            % --------------------------------- %
            
            % initialisations
            tHdrR = 'REGION GROUPING';
            pStrR = {'nRowG','nColG'};
            tStrR = {'Row Group Count','Column Group Count'};
            rStrR = {'Evenly Spaced Grid-Based Grouping',...
                     'Customised Region Grouping'};
                 
            % creates the panel object
            yPosR = sum(pPosN([2,4])) + obj.dX/2;
            pPosR = [obj.dX/2,yPosR,obj.widPanel,obj.hghtPanelR];
            obj.hPanelR = obj.objB.createPanel(obj.hPanel,pPosR,tHdrR,1);
            
            % creates the inner panel/radio buttons
            [obj.hPanelRI,obj.hRadioR] = deal(cell(2,1));
            for i = 1:length(obj.hghtPanelRI)
                % sets the global index
                j = length(obj.hghtPanelRI) - (i-1);
                
                % sets up the panel dimension vector
                hOfs = sum(obj.hghtPanelRI(1:(i-1)));
                yOfs = obj.dX/2 + (i-1)*(obj.hghtRow + obj.dX/2) + hOfs;
                pPosRI = [obj.dX/2,yOfs,obj.widPanelRI,obj.hghtPanelRI(i)];

                % creates the panel object
                obj.hPanelRI{j} = createUIObj(...
                    'panel',obj.hPanelR,'Position',pPosRI,'Title','');
                
                % creates the radio object
                yOfsRR = sum(pPosRI([2,4])) + 3;
                pPosRR = [obj.dX,yOfsRR,obj.widRadioRI,obj.hghtRadio];
                obj.hRadioR{j} = createUIObj('radiobutton',obj.hPanelR,...
                    'String',rStrR{j},'Position',pPosRR,...
                    'FontWeight','Bold','FontSize',obj.fSzL,...
                    'UserData',j);
            end
            
            % creates the evenly spaced editbox combo groups
            obj.hEditR = cell(length(tStrR),1);
            for i = 1:length(tStrR)
                % pre-calculations
                j = length(tStrR) - (i-1);
                yOfsRE = obj.dX/2 + (j-1)*obj.hghtRow;
                
                % creates the editbox combo group
                obj.hEditR{i} = obj.objB.createEditGroup(...
                    obj.hPanelRI{1},130,tStrR{i},yOfsRE);
                set(obj.hEditR{i},'UserData',pStrR{i},'Callback',cbFcnCE);
            end
            
            % creates the custom region panel popup menu
            pStrPR = [{'None'};tDataN(:)];
            obj.hPopupR = obj.objB.createPopupGroup(...
                obj.hPanelRI{2},100,'Current Group',obj.dX/2);
            set(obj.hPopupR,'String',pStrPR,'Value',2)
            
            % sets the other panel properties
            set(obj.hPanelR,'SelectionChangedFcn',cbFcnRS);
            
            % ----------------------------------- %
            % --- CONFIGURATION PANEL OBJECTS --- %
            % ----------------------------------- %
            
            % initialisations
            tHdrC = 'CONFIGURATION INFO';
            pStr = {'nRow','nCol','nGrp','mShape'};                        
            tStrC = {'Grid Row Count','Grid Column Count',...
                     'Genotype Group Count','Sub-Region Shape'};                 
                 
            % creates the panel object
            yPosC = sum(pPosR([2,4])) + obj.dX/2;
            pPosC = [obj.dX/2,yPosC,obj.widPanel,obj.hghtPanelC];
            obj.hPanelC = obj.objB.createPanel(obj.hPanel,pPosC,tHdrC);            
            
            % creates the parameter objects
            obj.hEditC = cell(length(tStrC)-1,1);
            for i = 1:length(tStrC)
                % pre-calculations
                j = length(tStrC) - (i-1);
                yOfs = obj.dX + (j-1)*obj.hghtRow;
                
                % creates the label/object parameter group
                if strcmp(pStr{i},'mShape')
                    % case is popupmenu combo group
                    obj.hPopupC = obj.objB.createPopupGroup(...
                        obj.hPanelC,obj.widTxtL,tStrC{i},yOfs);
                    set(obj.hPopupC,'String',obj.ppStr,...
                        'UserData',pStr{i},'Callback',cbFcnCP)
                    
                else
                    % case is editbox combo group
                    obj.hEditC{i} = obj.objB.createEditGroup(...
                        obj.hPanelC,obj.widTxtL,tStrC{i},yOfs);
                    set(obj.hEditC{i},...
                        'UserData',pStr{i},'Callback',cbFcnCE)
                end            
            end
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % auto-resizes the tables
            autoResizeTableColumns(obj.hTableN);                                    
            
        end
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %        
        
        % --- region grouping radio button selection callback function
        function radioRegionChange(obj, hObj, evnt)
            
            % pre-calculations
            nReg = obj.iData.D2.nRow*obj.iData.D2.nCol;
            
            % determines the button that is selected
            hRadioS = hObj.SelectedObject;
            iSelR = hRadioS.UserData;
            
            % updates the panel properties
            setPanelProps(obj.hPanelRI{1},(nReg > 1) && (iSelR == 1));
            setPanelProps(obj.hPanelRI{2},(iSelR == 2));
            
            % if initialising then exit the function
            if isempty(evnt); return; end
            
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