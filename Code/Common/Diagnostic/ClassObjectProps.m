classdef ClassObjectProps < handle
    
    % class properties
    properties
        
        % main class fields
        cObj
        
        % figure object handle fields
        hFig
        hMenu
        hPanelO        
        hTabGrp
        hTabC
        hPanelC
        hPanelF
        hTreeF        
        hListF
        
        % variable object dimensions
        widPanelO
        hghtPanelO        
        widPanelC
        hghtPanelC
        widPanelF
        hghtPanelF
        widListF
        hghtListF  
        pTabGrp
        
        % fixed object dimensions
        dX = 10;
        widFig = 700;
        hghtFig = 450;        
        
        % boolean fields
        ok = true;
        tSz = 13;
        ltSz = 11;
        nClass = 0;
        iClass = 0;        
        
    end
            
    % class methods
    methods
        
        % --- class constructor
        function obj = ClassObjectProps()

            % initialises the class fields
            obj.initClassFields();
            obj.initObjProps();

        end

        % --- initialises the class fields
        function initClassFields(obj)            
            
            % variable object dimension calculations
            obj.widPanelO = obj.widFig - 2*obj.dX;           
            obj.hghtPanelO = obj.hghtFig - 2*obj.dX;
            
        end        
        
        % --- initialises the class object properties
        function initObjProps(obj)
           
            % initialisations       
            dtGrp = 5*[1,1,-2,-1];
            tagStr = 'figClassObj';
            tStr = 'Class Object Functions';
            
            % deletes any previous class objects
            hFigPr = findall(0,'tag',tagStr);
            if ~isempty(hFigPr); delete(hFigPr); end
            
            % creates the progress loadbar
            hProg = ProgressLoadbar('Initialising GUI Objects');            
            
            % ---------------------------- %
            % --- MAIN FIGURE CREATION --- %
            % ---------------------------- %
            
            % creates the figure object
            fPos = [100,100,obj.widFig,obj.hghtFig];
            
            % creates the figure object
            obj.hFig = figure('Position',fPos,'tag',tagStr,...
                              'MenuBar','None','Toolbar','None',...
                              'Name',tStr,'NumberTitle','off',...
                              'Visible','off','Resize','off',...
                              'CloseRequestFcn',{@obj.closeGUI});                         
            
            % creates the outer panel object
            pPosO = [obj.dX*[1,1],obj.widPanelO,obj.hghtPanelO];            
            obj.hPanelO = uipanel(obj.hFig,'Title','','Units','Pixels',...
                                           'Position',pPosO);                                                                                    

            % ------------------------- %
            % --- MENU ITEM OBJECTS --- %
            % ------------------------- %
            
            % initialisations
            accStr = {'A','R','X'};
            lblStr = {'Add Class','Remove Class','Exit'};
            cbFcn = {@obj.addClass,@obj.rmvClass,@obj.closeGUI};
            
            % creates the main menu items
            hMenuP = uimenu(obj.hFig,'Label','File');            

            % creates the menu items
            obj.hMenu = cell(length(cbFcn),1);
            for i = 1:length(obj.hMenu)
                obj.hMenu{i} = uimenu(hMenuP,'Label',lblStr{i},...
                        'Callback',cbFcn{i},'Accelerator',accStr{i});
            end
            
            % creates the menu items
            set(obj.hMenu{2},'Enable','off');
            set(obj.hMenu{3},'Separator','on');                                       
                                       
            % ------------------------ %
            % --- TAB GROUP OBJECT --- %
            % ------------------------ %                                       
                                       
            % creates the tab group             
            obj.pTabGrp = getTabPosVector(obj.hPanelO,dtGrp);
            obj.calcDependentObjectDim();
            
            % creates a tab panel group            
            obj.hTabGrp = createTabPanelGroup(obj.hPanelO,1);
            set(obj.hTabGrp,'position',obj.pTabGrp,'Visible','off')                                  
            
            % ------------------------------- %
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %
            
            % deletes the progressbar
            delete(hProg);
            
            % makes the GUI visible
            setObjVisibility(obj.hFig,1)
                          
        end

        % ---------------------------------- %
        % --- NEW CLASS OBJECT FUNCTIONS --- %
        % ---------------------------------- %
        
        % --- adds in a new class object 
        function addNewClassObj(obj,fFileNw)
            
            % creates the progress loadbar
            hProg = ProgressLoadbar('Adding New Class Object');
            
            % attempts to split the class object code
            cObjNw = ClassObjectCode(fFileNw,hProg);
            if ~cObjNw.ok
                % if there was an error, then exit the function
                delete(hProg)
                return
            end
            
            % creates the class object tab
            obj.addClassObjTab(cObjNw);
            setObjEnable(obj.hMenu{2},1);
            
            % deletes the progress loadbar
            delete(hProg);
            
        end
        
        % --- adds in the class object tab
        function addClassObjTab(obj,cObjNw)
            
            % initialisations            
            tabStr = cObjNw.clName;            
            [obj.iClass,obj.nClass,nC] = deal(obj.nClass + 1);
            pStr = {'FUNCTION TREE STRUCTURE','FUNCTION DEPENDENCIES'};            
            
            % expands the data array fields
            obj.cObj = obj.expandDataArray(obj.cObj,1);
            obj.hTabC = obj.expandDataArray(obj.hTabC,1);
            obj.hPanelC = obj.expandDataArray(obj.hPanelC,1);
            obj.hPanelF = obj.expandDataArray(obj.hPanelF,2);
            obj.hListF = obj.expandDataArray(obj.hListF,1);
            obj.hTreeF = obj.expandDataArray(obj.hTreeF,1);
            
            % sets the class code object
            obj.cObj{nC} = cObjNw;
            
            % sets up the tabs within the tab group
            obj.hTabC{nC} = createNewTab(obj.hTabGrp,...
                                'Title',tabStr,'UserData',nC);
            set(obj.hTabC{nC},'ButtonDownFcn',@obj.tabSelected)
            set(obj.hTabGrp,'SelectedTab',obj.hTabC{nC},'Visible','on')
            
            % creates the class object panel
            pPosC = [(obj.dX/2)*[1,1],obj.pTabGrp(3:4)-obj.dX*[1.5,4]];
            obj.hPanelC{nC} = uipanel(obj.hTabC{nC},...
                        'Title','','Units','Pixels','Position',pPosC);                        
                    
            % creates the function dependency panels
            for i = 1:2
                % sets the panel positional vector
                lPosF = obj.dX/2 + (i-1)*obj.widPanelF;
                pPosF = [lPosF,obj.dX/2,obj.widPanelF,obj.hghtPanelF];
                
                % creates the sub-panels
                obj.hPanelF{nC,i} = uipanel(obj.hPanelC{nC},'Title',...
                        pStr{i},'Units','Pixels','Position',pPosF,...
                        'FontUnits','Pixels','FontWeight','Bold',...
                        'FontSize',obj.tSz);
            end
            
            % creates the tree-explorer object
            obj.createExplorerTree();

            % creates the listbox object
            lPosF = [obj.dX*[1,1],obj.widListF,obj.hghtListF];
            obj.hListF{nC} = uicontrol(obj.hPanelF{nC,2},'Style',...
                    'ListBox','Position',lPosF,'FontUnits','Pixels',...
                    'FontSize',obj.ltSz,'Enable','Inactive',...
                    'String',[],'Max',2,'Value',[]);
            
        end        

        % ---------------------------------- %
        % --- NEW CLASS OBJECT FUNCTIONS --- %
        % ---------------------------------- %        
        
        % --- creates a new explorer tree
        function createExplorerTree(obj)
            
            % initialisations
            rStr = 'Class Functions';
            
            % initialisations
            nC = obj.nClass;
            cObjT = obj.cObj{nC};
            lPosF = [obj.dX*[1,1],obj.widListF,obj.hghtListF];
            
            % Root node creation
            hRootL = createUITreeNode(rStr, rStr, [], false);
            set(0,'CurrentFigure',obj.hFig);
            
            % creates the parent function nodes
            iFcnP = find(cObjT.isFcnR);
            for i = 1:length(iFcnP)
                % function properties
                j = iFcnP(i);
                hNodeP = obj.createNewTreeNode(hRootL,cObjT,j);
                
                % creates the tree leaf node objects
                for k = 1:length(cObjT.iDep{j})
                    obj.createTreeLeafNodes(hNodeP,cObjT,[j,k]);
                end
            end
            
            % creates the tree object
            wState = warning('off','all');
            [obj.hTreeF{nC},hC] = uitree('v0','Root',hRootL,...
                        'SelectionChangeFcn',@obj.treeSelectChng,...    
                        'position',lPosF);
            set(hC,'Visible','off')
            set(hC,'Parent',obj.hPanelF{nC,1},'visible','on')
            warning(wState)
            
            % retrieves the selected node
            obj.hTreeF{nC}.expand(hRootL);            
            
        end
        
        % --- creates the tree leaf nodes
        function createTreeLeafNodes(obj,hNodeP,cObjT,indP)
            
            % determines the path node string names
            iDepP = cObjT.iDep{indP(1)}(indP(2));
            pStr = arrayfun(@(x)(char(x.getName())),hNodeP.getPath,'un',0);
            if any(strcmp(pStr,cObjT.Fcn{iDepP}))
                % if there is recursion, then exit
                return
            end
            
            % creates the new tree node
            hNode = obj.createNewTreeNode(hNodeP,cObjT,iDepP);
            
            % creates any leaf nodes
            for i = 1:length(cObjT.iDep{iDepP})
                obj.createTreeLeafNodes(hNode,cObjT,[iDepP,i])
            end
            
        end
        
        % ------------------------------------ %
        % --- MENU ITEM CALLBACK FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- add class menu item callback
        function addClass(obj,~,~)
            
            % initialisations
            tStr = 'Select The Class Object File';
            fMode = {'*.m','Matlab M-File (*.m)'};            
            
            % prompt the user for the class object file 
            [fName,fDir,fIndex] = uigetfile(fMode,tStr,pwd);
            if fIndex == 0
                % if the user cancelled, then exit
                return
            else
                % otherwise, set the full file path
                fFileNw = fullfile(fDir,fName);                
            end
            
            % determines if the selected class is already loaded
            if obj.nClass > 0
                fFileC = cellfun(@(x)(x.fFile),obj.cObj,'un',0);
                if any(strcmp(fFileC,fFileNw))
                    % if so, then output an error to screen
                    tStr = 'Class Object Already Exists';
                    [~,fNameC,~] = fileparts(fName);
                    eStr = sprintf(['The following class object ',...
                            'already exist:\n\n %s %s\n\nRetry with ',...
                            'an unloaded object class file.'],...
                            char(8594),fNameC);
                    waitfor(errordlg(eStr,tStr,'modal'))
                    
                    % exits the function
                    return
                end
            end
            
            % creates the new class object
            obj.addNewClassObj(fFileNw);
            
        end
        
        % --- remove class menu item callback
        function rmvClass(obj,hMenu,~)
            
            % initialisations
            tStr = 'Confirm Class Removal';
            qStr = 'Are you sure you want to remove the current class?';
            
            % prompts the user if they wish to remove the current class
            uChoice = questdlg(qStr,tStr,'Yes','No','Yes');            
            if ~strcmp(uChoice,'Yes'); return; end
            
            % initialisations
            nClass0 = obj.nClass;
            obj.nClass = obj.nClass - 1;            
            
            % deletes the class object tab
            delete(obj.hTabC{obj.iClass});
            
            % reduces down the data arrays
            xi = ~setGroup(obj.iClass,[nClass0,1]);
            obj.cObj = obj.cObj(xi);
            obj.hTabC = obj.hTabC(xi);
            obj.hPanelC = obj.hPanelC(xi);
            obj.hPanelF = obj.hPanelF(xi,:);
            obj.hTreeF = obj.hTreeF(xi);
            obj.hListF = obj.hListF(xi);
            
            % resets the selected tab index
            if obj.iClass == nClass0
                obj.iClass = obj.iClass - 1;                
            end
            
            % updates the selected tab            
            if obj.nClass > 0
                xiN = num2cell(1:obj.nClass)';
                cellfun(@(x,y)(set(x,'UserData',y)),obj.hTabC,xiN);                
                set(obj.hTabGrp,'SelectedTab',obj.hTabC{obj.iClass})
            end
            
            % updates the other object properties
            setObjEnable(hMenu,obj.nClass>0);
            setObjVisibility(obj.hTabGrp,obj.nClass>0);
            
        end        
        
        % --------------------------------- %
        % --- OBJECT CALLBACK FUNCTIONS --- %
        % --------------------------------- %
        
        % --- explorer tree selection change update function
        function treeSelectChng(obj, ~, ~)
            
            % initialisations
            lStr = [];
            cObjT = obj.cObj{obj.iClass};
            
            % retrieves the handle of the currently selected node
            hNode = obj.hTreeF{obj.iClass}.getSelectedNodes;            
            if ~isempty(hNode)                
                if hNode(1).isRoot
                    % case is the root node is selected
                    lStr = cObjT.Fcn(cObjT.isFcnR);

                else
                    % retrieves the indices of the function strings
                    iFcn = hNode(1).getUserObject;
                    if ~isempty(iFcn)
                        % if depdendencies exist, then return the functions
                        lStr = cObjT.Fcn(cObjT.iDep{iFcn});
                    end
                end
            end
            
            % updates thee list strings
            set(obj.hListF{obj.iClass},'String',lStr);
            
        end

        % --- tab selection callback function
        function tabSelected(obj,hObj,~)
            
            obj.iClass = get(hObj,'UserData');
            
        end
        
        % --- function for closing the GUI
        function closeGUI(obj,~,~)
            
            % deletes the figure object
            delete(obj.hFig);
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- calculates the dependent object dimensions
        function calcDependentObjectDim(obj)
            
            % class object panel object dimensions
            obj.widPanelC = obj.pTabGrp(3) - 1.5*obj.dX;
            obj.hghtPanelC = obj.pTabGrp(4) - 4*obj.dX;            
            
            % calculates the function list/tree object dimensions
            obj.widPanelF = (obj.widPanelC - obj.dX)/2;
            obj.hghtPanelF = obj.hghtPanelC - obj.dX;
            obj.widListF = obj.widPanelF - 2*obj.dX;
            obj.hghtListF = obj.hghtPanelF - 3.5*obj.dX;             
            
        end
        
    end
    
    % static class methods
    methods (Static)        
        
        % --- expands the data array
        function Y = expandDataArray(Y,nCol)
            
            Y = [Y;cell(1,nCol)];
            
        end        
        
        % --- creates the new tree node
        function hNode = createNewTreeNode(hNodeP,cObjT,iFcn)

            % retrieves node properties
            nwStr = cObjT.Fcn{iFcn};
            isLeaf = isempty(cObjT.iDep{iFcn});

            % creates the new child node
            hNode = createUITreeNode(nwStr,nwStr,[],isLeaf);
            hNode.setUserObject(iFcn);
            hNodeP.add(hNode);

        end        
        
    end
    
    
end