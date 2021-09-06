classdef GitRebaseClass < handle
    % class properties
    properties
        % main object properties
        hFig
        hGUI
        hFigM
        vObj
        gfObj
        
        % other class fields
        cIDB
        cIDP
        cMsg0
        rbInfo        
        todoFile
        todoInfo
        todoInfo0
        
        % table colours        
        RED = [1.0,0.5,0.5];
        GREEN = [0.5,1.0,0.5];
        YELLOW = [1.0,1.0,0.5];    
        
        % other fields
        actFld = {'pick','drop','fixup'};
        cFld = {'Accept','Delete','Squash'};        
        
    end
    
    % class methods
    methods
        function obj = GitRebaseClass(hFig)
            
            % retrieves the 
            obj.hFig = hFig;
            obj.hGUI = guidata(hFig);
            obj.hFigM = getappdata(hFig,'hFigM');
             
            % creates a loadbar
            h = ProgressLoadbar('Setting Up Rebase Information...');
            
            % initialises the class fields and object properties
            obj.initClassFields();
            obj.initObjCallbacks();
            obj.initObjProps();
            
            % deletes the loadbar
            delete(h);
            
        end
        
        % --------------------------------------------- %
        % --- CLASS OBJECT INITIALISATION FUNCTIONS --- %
        % --------------------------------------------- %          
        
        % --- initialises all the object class fields
        function initClassFields(obj)
            
            % name/script strings
            gType = 'sequence.editor';
            rbStr0 = '"sed -i -re ''s/^pick /e /I p''"'; 
            
            % sets the version/git function class object fields
            obj.vObj = getappdata(obj.hFigM,'verObj');
            obj.gfObj = obj.vObj.gfObj;
            
            % aborts any previous rebases
            obj.gfObj.gitCmd('rebase-abort')
            
            % determines the currently selected commit and its parent
            [~,obj.cIDB] = obj.vObj.getSelectedCommitInfo();
            A = obj.gfObj.gitCmd('get-commit-parent',obj.cIDB);
            obj.cIDP = getArrayVal(strsplit(A),2);
            
            % performs the interactive rebase
            obj.gfObj.gitCmd('set-global-config',gType,rbStr0)
            pause(0.1);
            obj.gfObj.gitCmd('rebase-interactive',obj.cIDP)
            
            % reads in the data from the todo file and aborts the rebase
            obj.getTodoFileData();
            obj.gfObj.gitCmd('rebase-abort')
            
        end
        
        % --- retrieves the to-do file data
        function getTodoFileData(obj)
        
            % field initialisations
            fName = 'git-rebase-todo';  
            gRepoDir = obj.vObj.gRepoDir;
            
            % sets the name of the rebase todo file
            obj.todoFile = fullfile(gRepoDir,'rebase-merge',fName);
            
            % opens the file, reads it and closes it again
            fid = fopen(obj.todoFile,'r'); 
            fInfo = fread(fid,'*char')'; 
            fclose(fid);
            
            % splits up the file information into components        
            fInfoL = cellfun(@(x)(strsplit(x)),...
                            strsplit(fInfo(1:end-1),'\n')','un',0);
                        
            % sets the todo information table data
            obj.todoInfo = cell((length(fInfoL)+1)/2,4);
            obj.todoInfo(:,[1,2,4]) = cell2cell...
                            (cellfun(@(x)([x(1:2),...
                            {strjoin(x(3:end))}]),fInfoL(1:2:end),'un',0));                     
            obj.todoInfo(:,1) = obj.cFld(1);
            
            % retrieves the branch names of each of the commits
            pCID = arrayfun(@(x)(x.brInfo.CID),obj.vObj.rObj.gHist,'un',0);
            iBr = cellfun(@(x)(find(cellfun(@(y)(any...
                            (startsWith(x,y))),pCID))),obj.todoInfo(:,2));
            obj.todoInfo(:,3) = obj.vObj.rObj.brData(iBr,1);
            
            % creates a copy of the commit messaages
            obj.cMsg0 = obj.todoInfo(:,4);
                        
        end
        % --- initialises all the object callback functions
        function initObjCallbacks(obj)
            
            % objects with cell selection callback functions
            scObj = {'tableRebaseInfo'};
            for i = 1:length(scObj)
                hObj = getStructField(obj.hGUI,scObj{i});
                cbFcn = eval(sprintf('@obj.%sCE',scObj{i}));
                set(hObj,'CellEditCallback',cbFcn)
            end                   
            
        end
        
        % --- initialises the GUI objects
        function initObjProps(obj)
            
            % sets the table information
            cForm = {obj.cFld,'char','char'};
            tInfo = obj.todoInfo;
            tInfo(:,2) = cellfun(@(x)(x(1:7)),tInfo(:,2),'un',0);
            
            % sets the table properties
            set(obj.hGUI.tableRebaseInfo,'Data',tInfo,...
                                         'ColumnFormat',cForm);
            
            % automatically resizes the table columns
            autoResizeTableColumns(obj.hGUI.tableRebaseInfo);
            obj.resetTableColours();
                                     
        end
        
        % ------------------------------------ %
        % --- CELL EDIT CALLBACK FUNCTIONS --- %
        % ------------------------------------ %
        
        % --- case is the tableRebaseInfo cell edit function
        function tableRebaseInfoCE(obj,~,event)
            
            % updates the rebase information array
            [iRow,iCol] = deal(event.Indices(1),event.Indices(2));            
            obj.todoInfo{iRow,iCol} = event.NewData;
            
            % updates the continue rebase control button enabled props
            isOK = strcmp(obj.todoInfo{1,1},'Accept');
            setObjEnable(obj.hGUI.buttonContRebase,isOK);
            
            % updates the table based on the selection
            if iCol == 1
                % case is updating the action
                obj.resetTableColours();
            end
        end
        
        % --- resets the table background colours
        function resetTableColours(obj)
                        
            % updates the background colours
            bgCol0 = {obj.GREEN,obj.RED,obj.YELLOW};
            bgCol = cell2mat(cellfun(@(x)(bgCol0...
                        {strcmp(obj.cFld,x)}),obj.todoInfo(:,1),'un',0));
            set(obj.hGUI.tableRebaseInfo,'BackgroundColor',bgCol);
            
        end
        
        % --- writes the final todo file
        function sStrF = getScriptString(obj)
            
            % initial string            
            cMsg = obj.cMsg0;
            tInfo = obj.todoInfo;
            [sStr0,sStr] = deal('sed -i','');
            
            % creates the script string
            for i = 1:size(tInfo,1)
%                 if i == 1
%                     str0 = sprintf('^pick %s',tInfo{i,2}(1:7));
%                     strNw = sprintf('e %s',tInfo{i,2}(1:7));
%                     sStr = sprintf('%s -re ''s/%s/%s/''',sStr,str0,strNw); 
% 
%                 else
                if ~strcmp(tInfo{i,1},obj.cFld{1})
                    % determines the new action and the new/original
                    % information strings for the regexp search
                    nwAct = obj.actFld{strcmp(obj.cFld,tInfo{i,1})};
%                     str0 = sprintf('^pick %s %s',tInfo{i,2},cMsg{i});
%                     strNw = sprintf('%s %s %s',nwAct,tInfo{i,2},tInfo{i,4});
                    
                    %
                    str0 = sprintf('^pick %s',tInfo{i,2}(1:7));
                    strNw = sprintf('%s %s',nwAct,tInfo{i,2}(1:7));                       
                    
                    % appends the new regexp string to the overall string
                    sStr = sprintf('%s -re ''s/%s/%s/''',sStr,str0,strNw);
                end
                
%                 if ~strcmp(cMsg{i},tInfo{i,4})
%                     sStr = sprintf('%s -re ''s/^%s/%s/''',...
%                                                 sStr,cMsg{i},tInfo{i,4});
%                 end
            end
            
            % sets the final script string
            if isempty(sStr)
                % the script string is empty, so return an empty value
                sStrF = [];
            else
                % otherwise, combine the header/search string for the final
                % script string
                sStrF = sprintf('%s %s',sStr0,sStr);
            end
        end
        
    end
    
    % static class methods
    methods (Static)
        
    end
    
end