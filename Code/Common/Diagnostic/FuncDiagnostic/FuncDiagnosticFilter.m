classdef FuncDiagnosticFilter < matlab.mixin.SetGet
    
    % class properties
    properties
        
        % main object fields
        hFig
        hPanel
        hButton        
        
        % function filter objects
        hTree
        jTree        
        jRoot
        jTable
        hNodeLS

        % function handles
        treeUpdateExtn
        
        % parameter struct fields        
        rGrp
        Imap
        snTot
        pDataT
        fcnInfo
        fcnData
        cmpData
        cFiltTot
         
        % other scalar parameters
        dX = 5;  
        fSz = 9;
        nCol = 6;        
        isUpdating = false;
        rType = {'Scope','Dur','Shape','Stim','Spec'}; 
        
    end
    
    % class methods
    methods
        
        % --- class constructors
        function obj = FuncDiagnosticFilter(hFig,snTot,pDataT)
            
            % ensures the solution file data is stored in a cell array
            if ~iscell(snTot); snTot = num2cell(snTot); end            
            
            % object setting/retrieval
            obj.hFig = hFig;
            obj.hPanel = findall(obj.hFig,'tag','panelFuncFilter');
            obj.hButton = findall(obj.hFig,'tag','toggleFuncFilter');  
            
            % retrieves the solution file information
            obj.snTot = snTot;
            obj.pDataT = pDataT;                        
            
            % initialises the tree object
            obj.initExptInfo();
            obj.initReqdFunc();                        
            
            % resets the experiment compatibility flags
            obj.detExptCompatibility();
            obj.initTreeObj(false); 
            
        end

        % --- resets the function filter
        function resetFuncFilter(obj,snTot,pDataT,fScope)
            
            % sets the default input arguments
            if ~exist('fScope','var'); fScope = []; end
            
            % ensures the solution file data is stored in a cell array
            if ~iscell(snTot); snTot = num2cell(snTot); end
            
            % updates the fields
            obj.snTot = snTot;
            
            % updates the plotting data field
            if exist('pDataT','var'); obj.pDataT = pDataT; end           
            
            % initialises the tree object
            obj.initExptInfo();
            obj.initReqdFunc();                
            
            % resets the experiment compatibility flags
            obj.detExptCompatibility(fScope);
            obj.initTreeObj(true);
            
        end
        
        % --------------------------------------- %        
        % --- OBJECT INITIALISATION FUNCTIONS --- %
        % --------------------------------------- %
        
        % --- initialises the experiment information
        function initExptInfo(obj)

            % exits if no data is loaded
            if isempty(obj.snTot); return; end
            
            % parameters
            nReq = 4;
            tLong = 12;            
 
            % memory allocation
            nExp = length(obj.snTot);
            obj.fcnInfo = cell(nExp,nReq);

            % other initialisations
            expStr = {'1D','2D'};
            durStr = {'Short','Long'};
            iMov = cellfun(@(x)(x.iMov),obj.snTot,'un',0);
            stimP = cellfun(@(x)(x.stimP),obj.snTot,'un',0);
            isMT = cellfun(@(x)(detMltTrkStatus(x)),iMov);
            
            % calculates the experiment duration in terms of hours
            Ts = cellfun(@(x)(x.T{1}(1)),obj.snTot);
            Tf = cellfun(@(x)(x.T{end}(length(x.T{end}))),obj.snTot);
            Texp = convertTime(Tf-Ts,'s','h');

            % sets the duration string
            obj.fcnInfo(:,1) = arrayfun(@(x)...
                                    (durStr{1+(x>tLong)}),Texp,'un',0);

            % for each of the experiments, strip out the important 
            % information fields from the solution file data
            for iExp = 1:nExp
                % experiment shape string
                obj.fcnInfo{iExp,2} = expStr{1+iMov{iExp}.is2D};
                if isfield(iMov{iExp},'autoP') && ...
                        ~isempty(iMov{iExp}.autoP)
                    obj.fcnInfo{iExp,2} = sprintf('%s (%s)',...
                        obj.fcnInfo{iExp,2},iMov{iExp}.autoP.Type);
                end

                % stimuli type string
                if isempty(stimP{iExp})
                    obj.fcnInfo{iExp,3} = 'None';
                else
                    stimStr = fieldnames(stimP{iExp});
                    obj.fcnInfo{iExp,3} = strjoin(stimStr,'/');
                end

                % special type string 
                if isMT(iExp)
                    obj.fcnInfo{iExp,4} = 'MT';
                else
                    obj.fcnInfo{iExp,4} = 'None';
                end
            end          
            
        end
        
        % --- initialises the requirement grouping information
        function initReqdFunc(obj)
            
            % initialisations
            obj.rGrp = struct();
            obj.fcnData = obj.setupFuncReqInfo();

            % retrieves the requirement information for each type
            for i = 1:length(obj.rType)
                switch obj.rType{i}
                    case 'Scope'
                        rGrpNw = {'Individual','Single Expt','Multi Expt'}';

                    otherwise
                        reqDataU = unique(obj.fcnData(:,i+1));
                        ii = strcmp(reqDataU,'None');    
                        rGrpNw = [reqDataU(ii);reqDataU(~ii)];
                end

                % appends the field to the data struct
                obj.rGrp = setStructField(obj.rGrp,obj.rType{i},rGrpNw);
            end

        end        
        
        % --- creates the explorer tree object
        function initTreeObj(obj,isReset)
        
            % parameters      
            rFld = fieldnames(obj.rGrp);
            fldStr = {'Analysis Scope','Duration Requirements',...
                      'Region Shape Requirements','Stimuli Requirements',...
                      'Special Requirements'};                  

            % deletes any existing explorer trees
            if isReset
                hTree0 = findall(obj.hPanel,'Type','hgjavacomponent');
                if ~isempty(hTree0); delete(hTree0); end
            end   
            
            % sets up the compatibility table
            cmpFcn = obj.fcnData(obj.cmpData(:,1),3:end);
            T = unique(cell2table(cmpFcn,'VariableNames',rFld(2:end)));
               
            % retrieves the object position
            objP = get(obj.hPanel,'position');
            tPos = [obj.dX-[1 0],objP(3:4)-2*obj.dX];
            obj.hTree = uitree(obj.hPanel,'CheckBox','Position',tPos,...
                'FontWeight','Bold','FontSize',obj.fSz);            
            
            % creates all the requirement categories and their sub-nodes
            for i = 1:length(rFld)
                % retrieves the requirement filter fields
                if i > 1
                    rVal = unique(getStructField(T,rFld{i}));
                else
                    rVal = [];
                end                
                
                % retrieves the sub              
                if length(rVal) > 1                 
                    % sets the requirement type node
                    hNodeP = uitreenode(obj.hTree,'Text',fldStr{i});
                    for j = 1:length(rVal)
                        uitreenode(hNodeP,'Text',rVal{j});
                    end
                end
            end
            
            % sets all the selected nodes
            hChildN = findall(obj.hTree,'type','uitreenode');
            if ~isempty(hChildN)
                obj.hTree.CheckedNodes = hChildN;
            end

            % sets the callback function for the mouse clicking of the tree structure
            set(obj.hTree,'CheckedNodesChangedFcn',@obj.treeUpdateClick,...
                          'NodeCollapsedFcn',@obj.treeCollapseClick,...
                          'NodeExpandedFcn',@obj.treeExpandClick) 
                    
%             % resets the tree panel position
%             nwHeight = jTreeCB.getMaximumSize.getHeight;
%             obj.resetTreePanelPos(nwHeight)            

        end
        
        % ------------------------------- %        
        % --- EXPLORER TREE FUNCTIONS --- %
        % ------------------------------- %        
        
        % --- callback for updating selection of the function filter tree
        function treeUpdateClick(obj,~,evnt)
            
            % if updating elsewhere, then exit
            if obj.isUpdating
                return
            end

            % runs the external update function
            obj.hNodeLS = evnt.LeafCheckedNodes;
            feval(obj.treeUpdateExtn)
            
        end
        
        % --- callback for expanding a tree node
        function treeCollapseClick(obj,hObject,~)

            % flags that the tree is updating
            obj.isUpdating = true;

            % resets the tree panel dimensions
%             obj.resetTreePanelPos(hObject.getMaximumSize.getHeight)
            pause(0.05);

            % flags that the tree is updating
            obj.isUpdating = false;            
            
        end
        
        % --- callback for expanding a tree node
        function treeExpandClick(obj,hObject,~)

            % flags that the tree is updating
            obj.isUpdating = true;

            % resets the tree panel dimensions
%             obj.resetTreePanelPos(hObject.getMaximumSize.getHeight)
            pause(0.05);

            % flags that the tree is updating
            obj.isUpdating = false;            
            
        end
        
        % ----------------------- %
        % --- OTHER FUNCTIONS --- %
        % ----------------------- %
        
        % --- retrieves the selected nodes
        function sNode = getSelectedNodes(obj)
            
            % initialisations
            sNode = struct();
            
            % sets the checked/grouping nodes
            if isempty(obj.hNodeLS)                                
                hNodeC = obj.hTree.CheckedNodes;
                hNodeG = intersect(hNodeC,obj.hTree.Children);
            else
                hNodeC = obj.hNodeLS;
                hNodeG = unique(arrayfun(@(x)(get(x,'Parent')),hNodeC));
            end
            
            % retrieves the 
            for i = 1:length(hNodeG)
                % sets the struct fields string
                switch get(hNodeG(i),'Text')
                    case 'Duration Requirements'
                        % case is the duration requirements
                        fStr = 'Dur';
                        
                    case 'Region Shape Requirements'
                        % case is the region shape requirements
                        fStr = 'Shape';
                        
                    case 'Stimuli Requirements'
                        % case is the stimuli requirements
                        fStr = 'Stim';
                        
                    case 'Special Requirements'
                        % case is the special requirements
                        fStr = 'Spec';
                        
                end                
                
                % retrieves the children nodes of the sub-node
                hNC = hNodeG(i).Children;
                fSel = arrayfun(@(x)(get(x,'Text')),hNC,'un',0);
                isSel = arrayfun(@(x)(~isempty(intersect(hNodeC,x))),hNC);
                
                % updates the node struct field
                sNode = setStructField(sNode,fStr,fSel(isSel));                
            end
            
        end
        
        % --- determines the experiment compatibilities for each function
        function detExptCompatibility(obj,fScope)

            % if there is no loaded data, then exit
            if isempty(obj.snTot); return; end
            
            % memory allocation
            nFunc = size(obj.fcnData,1);
            [nExp,nReq] = size(obj.fcnInfo);
            obj.cmpData = true(nFunc,nExp);

            % calculates the compatibility flags for each experiment
            for iFunc = 1:nFunc
                % retrieves the requirement data for the current function
                fcnDataF = obj.fcnData(iFunc,3:end);

                % determines if the requirements match for each expt
                isMatch = true(nReq,nExp);
                for iReq = 1:nReq
                    if ~strcmp(fcnDataF{iReq},'None')
                        isMatch(iReq,:) = cellfun(@(x)(strContains(...
                             x,fcnDataF{iReq})),obj.fcnInfo(:,iReq));
                    end
                end                

                % calculates the overall compatibility
                obj.cmpData(iFunc,:) = all(isMatch,1);                           
            end
            
            % accounts for the function scope (if provided)
            if exist('fScope','var')
                B = repmat(strContains(obj.fcnData(:,2),fScope),1,nExp);
                obj.cmpData = obj.cmpData & B;
            end                 

        end        
        
        % --- resets the filter tree panel position
        function resetTreePanelPos(obj,hghtTree0)
            
            % tree height offset (manual hack...)
            hghtTree = hghtTree0 + 2;

            % object retrieval
            hTree = findall(obj.hPanel,'type','hgjavacomponent');

            % other initialisations
            hghtPanel = hghtTree + 2*obj.dX;
            bPos = getObjGlobalCoord(obj.hButton);
            
            % sets the panel offset
            dY = 4 + 3*obj.dX;                               
            
            % ressets the tree/panel dimensions
            resetObjPos(obj.hPanel,'Height',hghtPanel);
            resetObjPos(obj.hPanel,'Bottom',bPos(2)-(hghtPanel+dY))
            resetObjPos(hTree,'Height',hghtTree)
            resetObjPos(hTree,'Bottom',obj.dX)  
            
        end

        % --- sets up the function requirement information
        function reqData = setupFuncReqInfo(obj)
            
            % returns an empty array (if no data)
            if isempty(obj.pDataT)
                reqData = [];
                return
            end

            % retrieves the plotting function data struct
            pFldT = fieldnames(obj.pDataT);
            pData = cell2cell(cellfun(@(x)(num2cell...
                        (getStructField(obj.pDataT,x))),pFldT,'un',0));

            % other initialisations            
            pFld = fieldnames(pData{1}.rI); 
            reqData = cell(length(pData),obj.nCol); 

            % sets the 
            for i = 1:length(pData)
                % sets the experiment name
                reqData{i,1} = pData{i}.Name; 

                % sets the other requirement fields
                for j = 1:(length(pFld)-1)
                    reqData{i,j+1} = getStructField(pData{i}.rI,pFld{j}); 
                end 
            end

            % determines the unique analysis functions
            [~,iB,~] = unique(reqData(:,1));
            reqData = reqData(iB,:);
            
            % maps the functions (for each scope level) to the functions in
            % the array
            obj.Imap = NaN(size(reqData,1),length(pFldT));
            for i = 1:length(pFldT)
                % retrieves the analysis scope functions
                pDataS = getStructField(obj.pDataT,pFldT{i});
                Name = field2cell(pDataS,'Name');
                
                % calculates the mapping indices
                iM = cellfun(@(x)(find(strcmp(reqData(:,1),x))),Name(:));
                obj.Imap(iM,i) = 1:length(iM); 
                
            end

        end            
                        
        % --- retrieves the matching function index
        function fcnIndex = getFuncIndex(obj,fcnName,pInd)
            
            iSelF = strcmp(obj.fcnData(:,1),fcnName);
            fcnIndex = obj.Imap(iSelF,pInd);           
            
        end
        
    end
    
    % static class methods
    methods (Static)

        % --- retrieves the node selection states
        function sState = getSelectState(hNode)
        
            % retrieves the selection state of the nodes
            sState = cellfun(@(x)(char(x.getSelectionState)),hNode,'un',0);        
        
        end
            
    end
    
end
