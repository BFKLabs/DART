classdef InstallInfo < handle
    
    % properties
    properties
        
        % information fields
        vInfo
        pInfo
        tDataT
        tDataP
        
        % object handle fields
        hFig
        hPanelT
        hPanelP
        hTableT
        hTableP
        hTxtD
        
        % fixed class fields
        hRowTR
        hRowT0
        dX = 10;  
        dTH = 25;
        hghtTxt = 16;
        widTable = 480;
        
        % calculates class fields
        widFig
        hghtFig        
        hghtPanelT
        hghtPanelP
        hghtTableT
        hghtTableP
        widPanel
        widTxtP        
        
        % string array fields
        cHdrT
        cHdrP
        toolStr
        toolStrS
        affStr
        
        % fixed character fields
        tStr = ' Toolbox';
        pStr = ' Support Package for ';
        tagStr = 'figInstallInfo';
        figName = 'Program Installation Information';
        
        % other scalar fields
        nRowT
        nRowP
        nColT
        nColP
        fSzH = 13;
        fSzL = 12;
        fSz = 10 + 2/3;
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = InstallInfo()
       
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();
            
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %        
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % global variables
            global H0T HWT
            
            % field retrieval
            [obj.hRowT0,obj.hRowTR] = deal(H0T,HWT);
            
            % toolbox/package table header strings
            obj.cHdrT = {'Toolbox Name','Affects','Installed?','Version'};
            obj.cHdrP = {'Package Name','Base Toolbox','Version'};
            
            % sets the toolbox name/affected component strings
            obj.toolStr = {'Curve Fitting';...
                           'Data Acquisition';...
                           'Image Acquisition';...
                           'Image Processing';...
                           'Instrument Control';...
                           'Optimization';...
                           'Signal Processing';...
                           'Statistics and Machine Learning';...
                           'Deep Learning'};
            obj.toolStrS = [obj.toolStr;{'MATLAB'}];
            obj.affStr = {{'Tracking','Analysis'};...
                          {'Recording'};...
                          {'Recording','Tracking'};...
                          {'Tracking','Analysis'};...
                          {'Recording'};...
                          {'Tracking','Analysis'};...
                          {'Tracking','Analysis'};...
                          {'Tracking','Analysis'};...
                          {'Tracking'}};
                    
            % retrieves the version and support package info
            obj.vInfo = ver;
            obj.pInfo = matlabshared.supportpkg.getInstalled;                      
                      
            % sets the data for the tables
            obj.initToolboxTableData();
            obj.detInstalledPackages();
            
            % array dimensions
            obj.nColT = length(obj.cHdrT);
            obj.nColP = length(obj.cHdrP);
            obj.nRowT = length(obj.toolStr);

            % ------------------------------------- %                      
            % --- OBJECT DIMENSION CALCULATIONS --- %
            % ------------------------------------- %
            
            % table heights
            obj.hghtTableT = obj.nRowT*obj.hRowTR + obj.hRowT0;
            
            % table panel heights
            obj.hghtPanelT = (obj.dX + obj.dTH) + obj.hghtTableT;
            obj.hghtPanelP = (obj.dX + obj.dTH) + obj.hghtTableP;

            % other object dimensions
            obj.widTxtP = obj.widTable - 2*obj.dX;
            obj.widPanel = obj.widTable + 2*obj.dX;

            % figure dimensions
            obj.widFig = 2*obj.dX + obj.widPanel;
            obj.hghtFig = 3*obj.dX + (obj.hghtPanelT + obj.hghtPanelP);
                      
        end
        
        % --- initialises the class objects
        function initClassObjects(obj)
            
            % removes any previous GUIs
            hFigPr = findall(0,'tag',obj.tagStr);
            if ~isempty(hFigPr); delete(hFigPr); end
                        
            % -------------------------- %
            % --- MAIN CLASS OBJECTS --- %
            % -------------------------- %
            
            % creates the figure object
            fPos = [100*[1,1],obj.widFig,obj.hghtFig];
            obj.hFig = figure('Position',fPos,'tag',obj.tagStr,...
                'MenuBar','None','Toolbar','None','Name',obj.figName,...
                'NumberTitle','off','Visible','off','Resize','off',...
                'CloseReq',@obj.closeWindow,'WindowStyle','modal');
            
            % ------------------------------------- %
            % --- SUPPORT PACKAGE PANEL OBJECTS --- %
            % ------------------------------------- %
            
            % initialisations
            tStrP = 'INSTALLED SUPPORT PACKAGES';
            cWidP = {300,113,65};
            cFormP = {'char','char','char'};
            
            % creates the panel object
            pPosP = [obj.dX*[1,1],obj.widPanel,obj.hghtPanelP];
            obj.hPanelP = createUIObj('panel',obj.hFig,...
                'FontSize',obj.fSzH,'Title',tStrP,'FontWeight','Bold',...
                'Units','Pixels','Position',pPosP);            
            
            % creates the table object
            pPosPT = [obj.dX*[1,1],obj.widTable,obj.hghtTableP];
            obj.hTableP = createUIObj('table',obj.hPanelP,...
                'Data',obj.tDataP,'ColumnEditable',false(1,obj.nColP),...
                'ColumnName',obj.cHdrP,'Position',pPosPT,...
                'ColumnFormat',cFormP,'RowName',[],'ColumnWidth',cWidP,...
                'Data',obj.tDataP,'BackgroundColor',ones(1,3));        
            autoResizeTableColumns(obj.hTableP);            
            
            % -------------------------------------- %
            % --- REQUIRED TOOLBOX PANEL OBJECTS --- %
            % -------------------------------------- %
            
            % initialisations
            tStrT = 'REQUIRED TOOLBOXES';
            cWidT = {175,175,65,65};
            cFormT = {'char','char','logical','char'};
            
            % creates the panel object
            yPosT = sum(pPosP([2,4])) + obj.dX;
            pPosT = [obj.dX,yPosT,obj.widPanel,obj.hghtPanelT];
            obj.hPanelT = createUIObj('panel',obj.hFig,...
                'FontSize',obj.fSzH,'Title',tStrT,'FontWeight','Bold',...
                'Units','Pixels','Position',pPosT);            
            
            % creates the table object
            pPosTT = [obj.dX*[1,1],obj.widTable,obj.hghtTableT];
            obj.hTableT = createUIObj('table',obj.hPanelT,...
                'Data',obj.tDataT,'ColumnEditable',false(1,obj.nColT),...
                'ColumnName',obj.cHdrT,'Position',pPosTT,...
                'ColumnFormat',cFormT,'RowName',[],'ColumnWidth',cWidT,...
                'BackgroundColor',ones(1,3));
            autoResizeTableColumns(obj.hTableT);            
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % centers and refreshes the figure
            centerfig(obj.hFig);
            refresh(obj.hFig);
            
            % makes the window visible
            setObjVisibility(obj.hFig,1);
            drawnow            
            
        end
        
        % --- initialises the toolbox table data
        function initToolboxTableData(obj)
            
            % determines required toolboxes that are currently available
            [vName,vVer0] = field2cell(obj.vInfo(:),{'Name','Version'});
            iInst = cellfun(@(x)(...
                find(startsWith(vName,x))),obj.toolStr,'un',0);
            isInst = ~cellfun('isempty',iInst);

            % sets up the required toolbox table data
            tData = cell(length(obj.toolStr),obj.nColT);
            tData(:,1) = obj.toolStr;
            tData(:,2) = cellfun(@(x)(strjoin(x,', ')),obj.affStr,'un',0);
            tData(:,3) = num2cell(isInst);
            tData(isInst,4) = vVer0(cell2mat(iInst(isInst)));            
            obj.tDataT = tData;
            
        end

        % --- determines the installed packages
        function detInstalledPackages(obj)
            
            % splits the table fields
            [pName0,pVer,pTool0] = field2cell(...
                obj.pInfo(:),{'Name','InstalledVersion','BaseProduct'});      
            hasP = cellfun(@(x)(...
                any(strContains(x,obj.toolStrS))),pTool0);            
            
            % sets the table data based on the installed packages
            if any(hasP)
                % sets the toolbox/package names
                pTool = cellfun(@(x)(getArrayVal...
                        (regexp(x,obj.tStr,'split'),1)),pTool0,'un',0);
                pName = cellfun(@(x)(getArrayVal...
                        (regexp(x,obj.pStr,'split'))),pName0,'un',0);

                % sets up the installed package table data fields
                pData0 = [pName(hasP),pTool(hasP),pVer(hasP)];
                [~,iSort] = sort(pData0(:,2));
                obj.tDataP = pData0(iSort,:);
                
                % sets the table dimenions fields
                obj.nRowP = size(obj.tDataP,1);
                obj.hghtTableP = obj.nRowP*obj.hRowTR + obj.hRowT0;                
                
            else
                % flag that there are no packages installed
                obj.nRowP = NaN;
                obj.hghtTableP = 3*obj.dX + obj.dTH;
            end
            
        end
        
        % -------------------------- %        
        % --- CALLBACK FUNCTIONS --- %
        % -------------------------- %
        
        % --- close window callback functions
        function closeWindow(obj, ~, ~)
            
            delete(obj.hFig);
            
        end
        
    
    end        
    
end