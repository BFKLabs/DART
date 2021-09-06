classdef GitMergeClass < handle
    % class properties
    properties
        % main class fields
        hFig
        hGUI        
        vObj
        dData
        mBr
        cBr     
        
        % colour arrays
        Red = [1,0.5,0.5];
        Green = [0.5,1,0.5];        
        
        % other class fields
        fStr
        isOK
        iAct
        cDir0
        hasRes
        isUpdating = false;
        tDir = 'External Files/TempDiff';        
        
    end
    
    % class methods
    methods
        % --- class constructor
        function obj = GitMergeClass(hFig,vObj,dData,mBr,cBr)
            
            % sets the input class fields
            obj.hFig = hFig;
            obj.hGUI = guidata(hFig);
            obj.vObj = vObj;
            obj.dData = dData;
            
            % sets the other fields
            if exist('mBr','var'); obj.mBr = mBr; end
            if exist('cBr','var'); obj.cBr = cBr; end     
            
            % initialises the GUI objects/callbacks
            obj.initObjCallbacks();
            obj.initGUIObjects();
            
        end
        
        % --- initialises all the object callback functions
        function initObjCallbacks(obj)
            
            % initialisations
            rType = {'Conflict','Diff'};
            
            % sets the table and control button callbacks
            for i = 1:length(rType)
                % object handle retrieval
                hTable = eval(sprintf('obj.hGUI.table%s',rType{i}));
                hButV = eval(sprintf('obj.hGUI.buttonRevert%s',rType{i}));
                hButR = eval(sprintf('obj.hGUI.buttonResolve%s',rType{i}));
                
                % sets the object callback functions
                set(hButV,'Callback',{@obj.buttonRevert,rType{i}});
                set(hButR,'Callback',{@obj.buttonResolve,rType{i}});
                set(hTable,'CellEditCallback',{@obj.tableEdit,rType{i}},...
                           'CellSelectionCallback',@obj.tableSelect)
            end
            
        end
        
        % --- initialises all the object callback functions
        function initGUIObjects(obj)
            
            % initialisations
            obj.cDir0 = pwd;
            obj.fStr = fieldnames(obj.dData);
            [dX,hasEmpty] = deal(10,false);
            [obj.isOK,obj.iAct] = deal(cell(1,2));
            
            % sets the master/child branch names
            if isempty(obj.mBr)
                [mBrC,cBrC] = deal('Initial','Final');
            else
                [mBrC,cBrC] = deal(obj.mBr,obj.cBr);
            end
            
            % initialises the GUI objects
            cd(obj.vObj.gfObj.gDirP)

            % sets the table column format strings
            rTypeC = {'Custom Resolve',...
                     sprintf('Use "%s"',mBrC),...
                     sprintf('Use "%s"',cBrC)};                                  
            rTypeD = {'Custom Resolve','Accept Differences'};
            cForm = {{'char',rTypeC,'logical'},{'char',rTypeD,'logical'}};            

            % reverts all difference files back to original
            for i = 1:length(obj.dData.Diff)
                fFile = obj.getFullFileName(obj.dData.Diff(i));
                obj.vObj.gfObj.gitCmd('checkout-branch-file',obj.mBr,fFile);
            end            
            
            % if there are difference files, then copy to a tmp directory
            if ~isempty(obj.dData.Diff)
                % creates the temporary directory
                obj.tmpDirFunc('add')

                % checkouts the difference file from the merging branch
                for i = 1:length(obj.dData.Diff)
                    % sets the difference and temporary output file names
                    dFile = obj.getFullFileName(obj.dData.Diff(i));
                    dFileOut = obj.getTempDiffFileName(obj.dData.Diff(i));

                    % outputs file from merging branch to the tmp directory
                    obj.vObj.gfObj.gitCmd...
                           ('checkout-to-location',obj.cBr,dFile,dFileOut);
                end
            end

            % initialises table data for merge conflict/difference files
            for i = 1:length(obj.fStr)
                % retrieves the corresponding data struct field
                dcStr = getStructField(obj.dData,obj.fStr{i});

                % retrieves the corresponding panel/table object handles
                hPanel = eval(sprintf('obj.hGUI.panel%s',obj.fStr{i}));
                hTable = eval(sprintf('obj.hGUI.table%s',obj.fStr{i}));   

                % sets the table (if any exists)
                nFld = length(dcStr);
                if nFld > 0
                    % if there are valid fields, then update the table
                    obj.isOK{i} = false(nFld,1);
                    [ii,obj.iAct{i}] = deal(ones(nFld,1));
                    fName = field2cell(dcStr,'Name');
                    bgCol = repmat(obj.Red,nFld,1);
                    
                    % sets the table data
                    tData = [fName,cForm{i}{2}(ii),num2cell(obj.isOK{i})];
                    set(hTable,'Data',tData,'ColumnFormat',cForm{i},...
                               'BackgroundColor',bgCol)
                    autoResizeTableColumns(hTable)

                    % if the other panel is empty then reset the gui size 
                    if hasEmpty
                        resetObjPos(hPanel,'left',dX)
                    end
                else
                    % make the panel invisible and sets an empty table         
                    setObjVisibility(hPanel,0)  
                    set(hTable,'Data',{'',true});             

                    % resets the button's panel position and figure width
                    [pPos,hasEmpty] = deal(get(hPanel,'position'),true);
                    resetObjPos(obj.hGUI.panelContButtons,'left',dX)     
                    resetObjPos(obj.hFig,'width',-(pPos(3)+dX),1);  
                end
            end

            % disables all push-buttons (except the cancel button)
            hBut = findall(obj.hFig,'style','pushbutton');
            setObjEnable(hBut,0)
            setObjEnable(obj.hGUI.buttonCancel,1)            
            
        end        

        % -------------------------- %        
        % --- CALLBACK FUNCTIONS --- %
        % -------------------------- %   
        
        % --- case is resolving the merge/differences
        function buttonResolve(obj,hObject,eventdata,rType)

            % runs the mergetool on the file
            setObjVisibility(obj.hFig,0)
            
            % retrieves the important objects from the GUI
            gfObj = obj.vObj.gfObj;
            isDiff = strcmp(rType,'Diff');            

            % creates the loadbar
            if isDiff
                h = ProgressLoadbar('Initiating Difftool...');
            else
                h = ProgressLoadbar('Initiating Mergetool...');
            end

            % object handle retrieval
            hTable = eval(sprintf('obj.hGUI.table%s',rType));
            hBut = eval(sprintf('obj.hGUI.buttonRevert%s',rType));                       
            
            % sets/determines the currently selected row index
            if isnumeric(eventdata)
                iRow = eventdata;
            else
                iRow = getTableCellSelection(hTable);
                dDataR0 = getStructField(obj.dData,rType);
            end
            
            % sets the temporary file name
            fFile = obj.getFullFileName(dDataR0(iRow));

            % runs the diff/merge tool depending on table type
            if isDiff
                % case is running a merge difference resolution
                fFileTmp = obj.getTempDiffFileName(dDataR0(iRow));    
                gfObj.gitCmd('run-difftool',fFile,fFileTmp);    
            else
                % case is running a merge conflict resolution
                gfObj.gitCmd('run-mergetool',fFile);
            end

            % deletes the loadbar
            delete(h)

            % updates the table/control button properties (type dependent)
            if isDiff
                % determines if difference has been resolved
                dStr = gfObj.gitCmd('diff-no-index',fFile,fFileTmp);
                if ~isempty(dStr)
                    dStr = strsplit(dStr,'\n');
                    if (length(dStr) == 2) && startsWith(dStr{1},'warning:') 
                        dStr = [];
                    end
                end 
                
                % disables/enables the resolve/revert buttons
                obj.isOK{2}(iRow) = isempty(dStr);
                obj.updateTableFlag(hTable,iRow,obj.isOK{2}(iRow))
                if obj.isOK{2}(iRow)
                    obj.resetButtonProps(hObject,hBut)
                    obj.setContButtonProps()
                end                
            else
                % determines if the merge conflict was successful
                fFileF = fullfile(gfObj.gDirP,fFile);
                if strContains(fileread(fFileF),'<<<<<<<')
                    % if the merge conflict was not resolved correctly,  
                    % thenoutput an error message to screen
                    etStr = 'Conflict Not Resolved!';
                    eStr = ['Merge conflict was not resolved correctly. ',...
                            'You will need to resolve all conflicts ',...
                            'within this file before continuing.'];
                    waitfor(errordlg(eStr,etStr,'modal'))

                    % un-resolves the merge and exits the function                    
                    obj.vObj.gfObj.gitCmd('unresolve-merge',fFile)
                    obj.isOK{1}(iRow) = false;
                    return
                end

                % updates the table indicating difference has been resolved
                obj.isOK{1}(iRow) = true;
                obj.updateTableFlag(hTable,iRow,true)

                % disables/enables the resolve/revert buttons
                obj.resetButtonProps(hObject,hBut)
                obj.setContButtonProps()                
                
            end         

            % makes the gui visible again
            setObjVisibility(obj.hFig,1)            
            
        end

        % --- case is reverting back to a previous version
        function buttonRevert(obj,hObject,eventdata,rType)
            
            if ~isnumeric(eventdata)
                % prompt the user if they want to revert to original
                qtStr = 'Undo Resolution?';
                qStr = 'Are you sure you want to revert back to original?';
                uChoice = questdlg(qStr,qtStr,'Yes','No','Yes');
                if ~strcmp(uChoice,'Yes')
                    % if the user cancelled, then exit the function
                    return
                end
            end              
            
            % object retrieves
            hTable = eval(sprintf('obj.hGUI.table%s',rType));
            hBut = eval(sprintf('obj.hGUI.buttonResolve%s',rType));              
            
            % other initialisations
            gfObj = obj.vObj.gfObj;
            isDiff = strcmp(rType,'Diff');
            
            % sets the selected row index
            if isnumeric(eventdata)
                % case is the value is provided externally
                iRow = eventdata;
            else
                % case is reading the value from the table
                iRow = getTableCellSelection(hTable);                         
            end                
            
            % sets the currently selected file name
            dDataR0 = getStructField(obj.dData,rType); 
            fFile = obj.getFullFileName(dDataR0(iRow));
            
            % reverts the merge difference file back to original
            if isDiff
                gfObj.gitCmd('checkout-branch-file',obj.mBr,fFile);
            else
                gfObj.gitCmd('unresolve-merge',fFile)                                
            end

            % updates the table indicating the difference has been resolved
            obj.isOK{1+isDiff}(iRow) = false;
            obj.updateTableFlag(hTable,iRow,false)

            % disables/enables the resolve/revert buttons
            obj.resetButtonProps(hObject,hBut)
            setObjEnable(obj.hGUI.buttonCont,0)            
            
        end      
        
        % --- case is selecting a table cell
        function tableSelect(obj,hObject,eventdata)
            
            % sets the update flag depending on the value
            if obj.isUpdating
                % if in the process of updating, then exit
                return
            else
                % otherwise, flag that an updating is occuring
                obj.isUpdating = true;
            end

            % updates the row selection properties
            if ~isempty(eventdata.Indices)    
                iRow = eventdata.Indices(1);
                obj.updateSelectionProperties(hObject,iRow)
            end

            % flag that updating is complete
            obj.isUpdating = false;            
            
        end   
        
        % --- case is editting a table cell
        function tableEdit(obj,hObject,event,rType)
            
            % sets the update flag depending on the value
            if obj.isUpdating
                % if in the process of updating, then exit
                return
            else
                % if not the correct column then exit
                [iRow,iCol] = deal(event.Indices(1),event.Indices(2));
                if iCol == 3; return; end
                
                % otherwise, flag that an updating is occuring
                obj.isUpdating = true;
            end                        
            
            % intialisations            
            iType = 1 + strcmp(rType,'Diff');            
            hButV = eval(sprintf('obj.hGUI.buttonRevert%s',rType));
            hButR = eval(sprintf('obj.hGUI.buttonResolve%s',rType));
            
            % retrieves the selected row index
            cForm = get(hObject,'ColumnFormat');
            iSel = find(strcmp(cForm{2},event.NewData));            
            
            % updates action flag index
            obj.iAct{iType}(iRow) = iSel;
            
            % updates the table flag
            if iSel == 1
                ok = obj.isOK{iType}(iRow);
                obj.updateTableFlag(hObject,iRow,ok)
                setObjEnable(hButV,ok)
                setObjEnable(hButR,~ok)
            else
                obj.updateTableFlag(hObject,iRow,true)
                setObjEnable(hButV,0)
                setObjEnable(hButR,0)                
            end
            
            % sets the continue control button properties
            obj.setContButtonProps()            
            
            % flag that updating is complete
            obj.isUpdating = false;              
            
        end         
        
        % ----------------------- %        
        % --- OTHER FUNCTIONS --- %
        % ----------------------- % 
        
        % --- updates the properties when selecting a table row
        function updateSelectionProperties(obj,hTable,iRowSel)

            % parameters
            tStr = get(hTable,'tag');
            bStr = tStr(6:end);

            % retrieves the control button object handles
            h = obj.hGUI;
            hButV = getStructField(h,sprintf('buttonRevert%s',bStr));
            hButR = getStructField(h,sprintf('buttonResolve%s',bStr));

            % sets the enabled properties of the control buttons depending 
            % on whether the conflict/difference has been resolved or not
            Data = get(hTable,'Data');
            setObjEnable(hButV,Data{iRowSel,3})
            setObjEnable(hButR,~Data{iRowSel,3})

        end
        
        % --- determines if the user can continue (only when all
        %     conflicts/differences have been resolved)
        function setContButtonProps(obj)

            % retrieves the data from both tables
            tDataD = get(obj.hGUI.tableDiff,'Data');
            tDataM = get(obj.hGUI.tableConflict,'Data');            

            % if all differences have been resolved then continue
            if isempty(tDataM)
                % case is there are only merge conflict files
                canCont = all(cell2mat(tDataM(:,end)));
            elseif isempty(tDataD)
                % case is there are only merge difference files
                canCont = all(cell2mat(tDataD(:,end)));
            else
                % case is there are both merge difference/conflict files
                canCont = all(cell2mat(tDataM(:,end))) && ...
                          all(cell2mat(tDataD(:,end)));
            end

            % updates the enabled properties of the continue button
            setObjEnable(obj.hGUI.buttonCont,canCont)

        end
        
        % --- retrieves the temporary difference file name
        function dFileOut = getTempDiffFileName(obj,dStr)

            [~,fName,fExtn] = fileparts(dStr.Name);
            dFileOut = sprintf('%s/%s_REMOTE%s',obj.tDir,fName,fExtn);

        end        
        
        % --- performs the temporary directory function type
        function tmpDirFunc(obj,type)

            % global variables
            global mainProgDir

            % retrieves the full temporary directory name            
            tmpDirF = strrep(fullfile(mainProgDir,obj.tDir),'/',filesep);

            switch (type)
                case 'add'
                    % case is adding the directory
                    if ~exist(tmpDirF,'dir')
                        mkdir(tmpDirF); 
                    end

                case 'remove'
                    % case is removing the directory
                    if exist(tmpDirF,'dir')
                        rmdir(tmpDirF, 's'); 
                    end
            end

        end                        
        
        % --- updates the ok flag on a specific row, iRow
        function updateTableFlag(obj,hTable,iRow,tVal)

            % if it doesn't exist, then retrieve and set it
            jScrollPane = findjobj(hTable);
            jTable = jScrollPane.getViewport.getView;
            
            % resets the table flag values
            obj.isUpdating = true;
            jTable.setValueAt(tVal,iRow-1,2)  
            pause(0.05)
        
            % sets the table background colours
            bgCol = obj.getTableBGColour(hTable);
            set(hTable,'BackgroundColor',bgCol)
            pause(0.05)
            
            % updates the table value            
            obj.isUpdating = false;            
            
        end             
        
        % --- retrieves the table background colour array
        function bgCol = getTableBGColour(obj,hTable)
           
            % initialisations
            col0 = {obj.Red,obj.Green};            
            
            % sets the colours for each row
            Data = get(hTable,'Data');
            bgCol = cell2mat(cellfun(@(x)(col0{1+x}),Data(:,end),'un',0));
            
        end        
        
    end
    
    % static class methods
    methods (Static)
        
        % --- retrieves the full file name from the file data struct
        function ffName = getFullFileName(fFile)

            if isempty(fFile.Path)
                ffName = fFile.Name;
            else
                ffName = sprintf('%s/%s',fFile.Path,fFile.Name);
            end

        end           
        
        % --- disables/enables the corresponding control buttons
        function resetButtonProps(hOff,hOn)

            % disables/enables the corresponding buttons
            setObjEnable(hOn,1)
            setObjEnable(hOff,0)

        end

    end

end