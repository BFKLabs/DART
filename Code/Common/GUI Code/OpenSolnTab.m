classdef OpenSolnTab < handle
    
    % class properties
    properties
        % main class fields        
        hGUI
        hFig
        hFigM
        sInfo
        iProg   
        pDataT
        hasInfo
        
        % other class fields
        hTabGrpF
        jTabGrpF
        
        % group/experiment names
        expDir
        expName     
        gName
        gName0
        gNameU        
        
        % java colours
        white = java.awt.Color.white;
        black = java.awt.Color.black;
        gray = getJavaColour(0.81*ones(1,3));
        grayLight = getJavaColour(0.90*ones(1,3));
        redFaded = getJavaColour([1.0,0.5,0.5]);
        blueFaded = getJavaColour([0.5,0.5,1.0]);
        greenFaded = getJavaColour([0.5,1.0,0.5]);
        
        % sub-class objects
        cObj            % experiment comparison class object
        fObj            % file loading class object
        fcnObj          % function compatibility object
        mltObj          % multi-experiment class object
        
        % scalar fields
        sType
        nExp
        isChange = false;
    end
    
    % class methods
    methods
        % --- class constructor
        function obj = OpenSolnTab(hFig,sType)
           
            % sets the class fields
            obj.hFig = hFig;
            obj.sType = sType;
            obj.hGUI = guidata(hFig);
            
            % retrieves the other fields      
            obj.hFigM = getappdata(hFig,'hFigM');
            obj.sInfo = getappdata(obj.hFigM,'sInfo');
            obj.iProg = getappdata(obj.hFigM,'iProg');
            
            % sets up the gui based on 
            switch sType
                case 1
                    % case is the data combining file open gui
                    obj.fObj = OpenSolnFileTab(obj);
                    
                case 2
                    % case is the data combining save multi-expt gui
                    obj.mltObj = OpenSolnMultiTab(obj,1);
                    
                case 3
                    % expands the gui to incorporate the panels
                    obj.expandGUI();                    
                    
                    % case is the analysis file open gui
                    obj.fObj = OpenSolnFileTab(obj);
                    obj.mltObj = OpenSolnMultiTab(obj,0);
                    
                    % sets up the solution function tab (if required)
                    if any(cellfun(@(x)(any(x)),obj.hasInfo))
                        obj.fcnObj = OpenSolnFuncTab(obj);
                    end
            end
            
        end     
        
        % --- expands the gui so the panels are part of a tab panel object
        function expandGUI(obj)
            
            % parameters
            dX = 10;
            dY = 30;
            
            % tab strings
            tabStr = {'Load Solution Files',...
                      'Experiment Compatibility & Groups',...
                      'Function Compatibility'};
                
            % field retrieval
            obj.pDataT = getappdata(obj.hFigM,'pDataT'); 
            
            % determines if any functions has the reqd information fields
            pName = fieldnames(obj.pDataT);
            obj.hasInfo = cellfun(@(x)(arrayfun(@(x)(~isempty(x.rI)),...
                            getStructField(obj.pDataT,x))),pName,'un',0);
            if ~any(cellfun(@(x)(any(x)),obj.hasInfo))
                tabStr = tabStr(1:2);
            end
                        
            % resets the figure size
            resetObjPos(obj.hFig,'Width',3*dX/2,1)
            resetObjPos(obj.hFig,'Height',dY,1)
                  
            % sets the object positions
            tabPosI = getTabPosVector(obj.hFig,dX*[0,0,0,-0.5]);
            obj.hTabGrpF = createTabPanelGroup(obj.hFig,1);
            obj.jTabGrpF = getTabGroupJavaObj(obj.hTabGrpF);
            set(obj.hTabGrpF,'position',tabPosI,'tag','hTabGrpL');
            pause(0.05);
            
            % creates the tabs for each of the panels
            for i = 1:length(tabStr)
                % creates the new tab
                hTabNw = createNewTabPanel...
                          (obj.hTabGrpF,1,'title',tabStr{i},'UserData',i); 
                set(hTabNw,'ButtonDownFcn',{@obj.tabSelectedFull}) 
                
                % sets the panel parent object
                hPanel = findall(obj.hFig,'type','uipanel','userdata',i);
                set(hPanel,'Parent',hTabNw);
                
                % resets the location of the panels within the tab
                resetObjPos(hPanel,'Left',dX/2)
                resetObjPos(hPanel,'Bottom',dX/2)
                
                % sets the experiment/function comparison tab properties
                isOn = (i == 1) || ~isempty(obj.sInfo);
                obj.jTabGrpF.setEnabledAt(i-1,isOn);
            end            
            
            % resets the selected tab to the solution explorer
            hTab0 = findall(obj.hTabGrpF,'UserData',1);
            set(obj.hTabGrpF,'SelectedTab',hTab0)
            
        end
        
        % --- updates the experiment information in the full gui
        function updateFullGUIExpt(obj)
            
            % gui update only applicable for analysis gui file loading
            if obj.sType ~= 3
                return
            end
            
            % pauses for any updates
            pause(0.05);
                                                                
            % updates the experiment comparison class object
            obj.cObj.updateExptCompData(obj.sInfo);
            
            % updates the function compatibility tab
            if ~isempty(obj.fcnObj)
                obj.fcnObj.updateFuncDepTable();
            end
            
            % updates the experiment comparison tab
            obj.mltObj.updateExptInfoTable();
            
        end    
        
        % --- updates the experiment names on the other tabs (when altering
        %     an experiment name in 
        function updateExptNames(obj,iExp,iType)
            
            % retrieves the new experiment name
            expFileNw = obj.sInfo{iExp}.expFile;
            expFileCell = java.lang.String(expFileNw);
        
            % updates the experiment names
            switch iType
                case 1
                    % case is updating from the file open panel 
                    
                    % updates the experiment name within the table
                    obj.mltObj.tableUpdate = true;
                    obj.mltObj.jTable.setValueAt(expFileCell,iExp-1,1);
                    obj.mltObj.jTable.repaint()
                    
                    % resets the group lists
                    obj.mltObj.updateGroupLists()                       
                    
                    % resets the flag (after pausing for update)
                    pause(0.05)
                    obj.mltObj.tableUpdate = false;                                     
                    
                case 2
                    % case is updating from the expt comparison panel

                    % updates the experiment name within the table
                    obj.fObj.tableUpdate = true;
                    obj.fObj.jTable.setValueAt(expFileCell,iExp-1,0);
                    obj.fObj.jTable.repaint()
                    
                    %
                    obj.fObj.resetExptTableBGColour(0);
%                     obj.fObj.updateGroupTableProps();   
                    
                    % resets the flag (after pausing for update)
                    pause(0.05)
                    obj.fObj.tableUpdate = false;                    
            end
        
        end
        
        % --- retrieves the currently selected tab group index
        function iTabG = getTabGroupIndex(obj)
            
            hTabGrpL = obj.mltObj.hTabGrpL;
            iTabG = obj.mltObj.getTabGroupIndex(hTabGrpL);
            
        end
        
        % --- tab selection callback function
        function tabSelectedFull(obj, hObject, eventdata)
            
            
        end        
    end
    
    % state class methods
    methods (Static)
        
    end    
    
end