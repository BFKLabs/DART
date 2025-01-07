classdef OutputExptFile < handle & dynamicprops
    
    % class properties
    properties
        
        % object class fields
        hProg   
        tDir
        
        % data struct fields
        fNameOut        
        iParaOut    
        oParaOut
        snTotOut        
        
        % boolean class fields
        isCSV
        
        % fixed scalar class fields
        nField = 5;        
        
        % cell array class fields
        wStr0 = {'File Batch Progress','Waiting For Process',...
                 'Current Experiment Progress'};        
        
    end
    
    % private class properties
    properties (Access = private)
        
        objB
        
    end    
    
    % class methods
    methods
        
        % --- class constructor
        function obj = OutputExptFile(objB)
            
            % sets the input arguments
            obj.objB = objB;
            
            % initialises the class fields/objects
            obj.linkParentProps();
            obj.initClassFields();
            
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %        
        
        % --- initialises the class object fields with that parent object
        function linkParentProps(obj)
            
            % parent fields strings
            fldStr = {'sInfo','oPara','useExp','iProg',...
                      'fName','fExtn','gName','fDir','fDirFix',...
                      'hRadioO','hChkP','hEditP'};
            
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
            
            obj.tDir = obj.iProg.TempFile;
            
        end
        
        % -------------------------------------- %
        % --- SOLUTION FILE OUTPUT FUNCTIONS --- %
        % -------------------------------------- %        
    
        % --- outputs the selected solution files
        function outputSolnFiles(obj)
            
            % creates the progress bar
            obj.hProg = ProgBar(obj.wStr0,'Solution File Loading');
                                    
            % sets the output directory files
            if obj.hRadioO{1}.Value
                % case is using a fixed output directory
                fDirO = repmat({obj.fDirFix},sum(obj.useExp),1);
                
            else
                % case is using a custom output directory structure
                fDirO = obj.fDir(obj.useExp);
            end
            
            % reshapes the arrays to only include those for output
            nExpO = sum(obj.useExp);      
            fNameO = obj.fName(obj.useExp);
            fExtnO = obj.fExtn(obj.useExp);
            sInfoO = obj.sInfo(obj.useExp);
            oParaO = obj.oPara(obj.useExp);
            gNameO = obj.gName(obj.useExp);
            
            % if the first file output is .mat, then collase the progress bar
            if strcmp(fExtnO{1},'.mat')
                obj.hProg.collapseProgBar(2)
            end
            
            % loops through each of the valid experiments outputting data to file
            for i = 1:nExpO
                % updates the progress bar
                wStrNw = sprintf('%s (Expt %i of %i)',obj.wStr0{1},i,nExpO);
                if obj.hProg.Update(1,wStrNw,i/(1+nExpO))
                    % if the user cancelled, then exit
                    return
                    
                elseif i > 1
                    % resets the progress waitbar
                    for j = 2:length(obj.wStr0)
                        obj.hProg.Update(j,obj.wStr0{j},0);
                    end
                end
                
                % updates the experiment with the new groups names/fields
                obj.snTotOut = sInfoO{i}.snTot;
                obj.snTotOut.iMov.pInfo.gName = gNameO{i};
                
                % sets the full output file/directory name
                obj.fNameOut = fullfile(fDirO{i},fNameO{i});
                obj.iParaOut = sInfoO{i}.iPara;
                obj.oParaOut = oParaO(i);
                
                % outputs the solution file (based on the users selection)
                switch fExtnO{i}
                    case '.ssol'
                        % case is the DART Solution File
                        obj.outputDARTSoln();
                        
                    case '.mat'
                        % case is the Matlab Mat File
                        obj.outputMATSoln();
                        
                    case {'.csv','.txt'}
                        % case is an ascii type file (csv or txt)
                        obj.isCSV = strcmp(fExtnO{i},'.csv');
                        obj.outputASCIIFile();
                end
                
                if i < nExpO
                    % determines which of the current/next files are .mat files
                    isMat = cellfun(@(x)(strcmp(x,'.mat')),fExtnO(i+[0,1]));
                    if isMat(1)
                        % if the current file is a mat file, but the next 
                        % is not, then expand the progressbar
                        if ~isMat(2)
                            obj.hProg.expandProgBar(2);
                        end
                        
                    elseif isMat(2)
                        % if next file is a .mat then collapse progressbar
                        obj.hProg.collapseProgBar(2);
                    end
                end
                
            end            
            
            % closes the progress bar
            obj.hProg.closeProgBar()            
            
        end
        
        % --- outputs the DART single experiment solution file --- %
        function outputDARTSoln(obj)
            
            % resets the progress bar strings
            obj.hProg.wStr(2:end) = ...
                {'Overall Progress','Output Data Field'};
            
            % resets the progreebar
            for i = 2:length(obj.hProg.wStr)
                obj.hProg.Update(i,obj.hProg.wStr{i},0);
            end
            
            % updates the region data struct
            obj.snTotOut = obj.updateRegionInfo(obj.snTotOut);
            obj.snTotOut = reshapeExptSolnFile(obj.snTotOut);
            
            % removes the y-position data (if not required);
            if ~obj.oParaOut.outY; obj.snTotOut.Py = []; end
            
            % outputs the solution file
            fFileFull = [obj.fNameOut,'.ssol'];
            saveExptSolnFile(obj.tDir,fFileFull,obj.snTotOut,obj.hProg,1);
            
        end
        
        % --- outputs a Matlab mat solution file --- %
        function outputMATSoln(obj)
            
            % converts the cell arrays to numerical arrays
            obj.snTotOut.T = cell2mat(obj.snTotOut.T);
            obj.snTotOut.isDay = cell2mat(obj.snTotOut.isDay');
            
            % removes the y-coordinate data (if not required)
            if ~obj.snTotOut.iMov.is2D && ~obj.oParaOut.outY
                obj.snTotOut = rmfield(obj.snTotOut,'Py');
            end
            
            % removes any other extraneous fields
            snTot = rmfield(obj.snTotOut,{'iExpt'});
            
            % saves the file
            obj.hProg.Update(2,'Outputting Matlab Solution File...',0.5);
            save([obj.fNameOut,'.mat'],'snTot')
            
            % closes the waitbar
            obj.hProg.Update(2,'Matlab Solution File Output Complete',1);
            pause(0.05);
            
        end
        
        % --- outputs the CSV combined solution file --- %
        function outputASCIIFile(obj)
            
            % retrieves the apparatus data and solution file struct
            oParaO = obj.oParaOut;
                        
            % sets the waitbar strings
            obj.hProg.wStr = {'Setting Positional Data',...
                              'Outputting Data To File',...
                              'Current File Progress'};
            
            % resets the fields
            for i = 2:length(obj.hProg.wStr)
                obj.hProg.Update(2,obj.hProg.wStr{i},0);
            end
            
            % -------------------------------- %
            % --- SOLUTION FILE DATA SETUP --- %
            % -------------------------------- %
            
            % retrieves the positional data
            [T,Pos,fNameSuf,Hstr,ok] = obj.setupPosData('csv');
            if ~ok
                return
            else
                % sets the number of files to output (for each apparatus)
                [nFile,nApp] = deal(length(T),length(Pos));
                
                % loops through each of the apparatus
                for i = 1:nApp
                    % updates the waitbar figure
                    wStrNw = sprintf('Overall Progress (Region %i of %i)',i,nApp);
                    obj.hProg.Update(2,wStrNw,i/nApp);
                    
                    % outputs the data for each split file
                    for j = 1:nFile
                        % updates the waitbar figure
                        obj.hProg.Update(3,sprintf('%s (%i of %i)',...
                            obj.hProg.wStr{3},j,nFile),j/nFile);
                        
                        % opens a new data file
                        DataNw = [Hstr{i};num2cell([T{j} Pos{i}{j}])];
                        if obj.isCSV
                            fNameNw = sprintf('%s (%s).csv',...
                                obj.fNameOut,fNameSuf{i}{j});
                        else
                            fNameNw = sprintf('%s (%s).txt',...
                                obj.fNameOut,fNameSuf{i}{j});
                        end
                        
                        % opens the file
                        fid = fopen(fNameNw,'w');
                        
                        % updates the waitbar figure
                        [nRow,nCol] = size(DataNw);
                        wStrNw = sprintf(...
                            '%s (Row 0 of %i)',obj.hProg.wStr{3},nRow);
                        obj.hProg.Update(3,wStrNw,0);
                        
                        % writes to the new data file
                        for iRow = 1:nRow
                            % updates the waitbar figure
                            if mod(iRow,min(500,nRow)) == 0
                                if obj.hProg.Update(3,sprintf(...
                                    '%s (Row %i of %i)',obj.hProg.wStr{3},...
                                    iRow,nRow),iRow/nRow)
                                    % if the user cancelled, then exit the function
                                    try fclose(fid); catch; end
                                    return
                                end
                            end
                            
                            % prints the first column of data
                            if iRow == 1
                                fprintf(fid,'%s',DataNw{iRow,1});
                            else
                                fprintf(fid,'%.2f',DataNw{iRow,1});
                            end
                            
                            % prints the other columns of data
                            for iCol = 2:nCol
                                if obj.isCSV || oParaO.useComma
                                    if iRow == 1
                                        fprintf(fid,',%s',...
                                            DataNw{iRow,iCol});
                                    else
                                        fprintf(fid,',%.2f',...
                                            DataNw{iRow,iCol});
                                    end
                                else
                                    if iCol == 2
                                        if iRow == 1
                                            fprintf(fid,'\t\t%s',...
                                                DataNw{iRow,iCol});
                                        else
                                            fprintf(fid,'\t\t%.2f',...
                                                DataNw{iRow,iCol});
                                        end
                                    else
                                        if iRow == 1
                                            fprintf(fid,'\t%s',...
                                                DataNw{iRow,iCol});
                                        else
                                            fprintf(fid,'\t%.2f',...
                                                DataNw{iRow,iCol});
                                        end
                                    end
                                end
                            end
                            
                            % prints the end of line-statement
                            if obj.isCSV
                                fprintf(fid,'\n');
                            else
                                fprintf(fid,'\r\n');
                            end
                        end
                        
                        % updates the waitbar figure and closes the file
                        wStrNw = sprintf('%s (Row %i of %i)',...
                            obj.hProg.wStr{3},size(DataNw,1),size(DataNw,1));
                        obj.hProg.Update(3,wStrNw,1);
                        fclose(fid);
                    end
                end
            end
            
            % retrieves the experimental data (if selected)
            if oParaO.outStim
                % sets the stimuli data
                stimData = obj.setupStimData();
                if obj.isCSV
                    fNameStim = [obj.fNameOut,' (Stim Data).csv'];
                else
                    fNameStim = [obj.fNameOut,' (Stim Data).txt'];
                end
                
                % writes the stimuli data to file
                writeCSVFile(fNameStim,stimData);
            end
            
            % retrieves the experimental data (if selected)
            if oParaO.outExpt
                % retrieves the experiment info and the file name
                exptData = obj.setupExptData();
                if obj.isCSV
                    fNameExpt = [obj.fNameOut,' (Expt Data).csv'];
                else
                    fNameExpt = [obj.fNameOut,' (Expt Data).txt'];
                end
                
                % writes the stimuli data to file
                writeCSVFile(fNameExpt,exptData);
            end
            
        end
        
        % ----------------------------------- %
        % --- OUTPUT DATA SETUP FUNCTIONS --- %
        % ----------------------------------- %

        % --- sets up the positional data array for output to file 
        function [T,Pos,fNameSuf,Hstr,ok] = setupPosData(obj,fType)
            
            % retrieves the apparatus data and solution file struct
            iParaO = obj.iParaOut;
            oParaO = obj.oParaOut;
            snTotO = obj.snTotOut;
                        
            % field retrieval
            isSplit = obj.hChkP{5}.Value;            
            flyok = snTotO.iMov.flyok;
            indOut = find(snTotO.iMov.ok);
            gName = snTotO.iMov.pInfo.gName;
            
            % determines the data groups
            if detMltTrkStatus(snTotO.iMov)
                % FINISH ME!
                a = 1;
                
            elseif snTotO.iMov.is2D
                % FINISH ME!
                a = 1;
                
            else
                % case is 1D expt
                
                % initialisations
                cIDT = cell2mat(snTotO.cID);
                szR = [snTotO.iMov.nCol,snTotO.iMov.nRow];
                iApp = sub2ind(szR,cIDT(:,2),cIDT(:,1));
                A = [iApp,cIDT(:,3)];
                
                % determines the unique grouping names
                [gName,~,iC] = unique(snTotO.iMov.pInfo.gName(indOut));
                indC = arrayfun(@(x)(indOut(iC==x)),1:length(gName),'un',0);
                
                % sets the final group indices
                fokR = flyok(sub2ind(size(flyok),cIDT(:,3),iApp));
                indG0 = cellfun(@(x)(find(ismember(iApp,x))),indC,'un',0);
                indG = cellfun(@(x)(x(fokR(x))),indG0,'un',0);
                
                % sets the final x-position group data
                PxG = cellfun(@(x)(cell2mat(arrayfun(@(y,z)...
                    (snTotO.Px{y}(:,z)),A(x,1),A(x,2),'un',0)')),indG,'un',0);
                if oParaO.outY 
                    % sets the final y-position group data (if required)
                    PyG = cellfun(@(x)(cell2mat(arrayfun(@(y,z)...
                        (snTotO.Py{y}(:,z)),A(x,1),A(x,2),'un',0)')),indG,'un',0);
                end
            end
            
            % memory allocation
            [nApp,ok] = deal(length(gName),true);
            [Pos,fNameSuf,Hstr] = deal(cell(1,nApp));
            
            % ------------------------- %
            % --- TIME VECTOR SETUP --- %
            % ------------------------- %
            
            % sets the time vector based on the file type/
            switch fType
                case {'txt','csv'} % case is text/csv file output
                    % sets the time vector
                    T = cell2mat(snTotO.T);
            end
            
            % ------------------------------ %
            % --- POSITIONAL ARRAY SETUP --- %
            % ------------------------------ %
            
            % sets the indices of the frames that are to be kept
            sOfs = [0;cumsum(cellfun('length',snTotO.T))];
            i0 = sOfs(iParaO.indS(1)) + iParaO.indS(2);
            i1 = sOfs(iParaO.indF(1)) + iParaO.indF(2);
            indNw = i0:i1;
            
            % resets the time
            T = T(indNw);
            if ~iscell(T); T = T - T(1); end
            
            % sets the solution file group indices
            if isSplit
                % if splitting up the movies, then set the split time
                tSplitH = str2double(obj.objB.hEditP.String);
                tSplit = tSplitH*3600;
                
                % determines the point in the movie where the split occurs
                Tmod = mod(T-T(1),tSplit);
                ii = find(Tmod(2:end)<Tmod(1:end-1)) + 1;
                
                % sets the group indices based on the number of file splits
                if isempty(ii)
                    % only one group, so set from start to end
                    indGrp = [];
                else
                    % sets the indices of each solution file group
                    jj = [[1;ii],[(ii-1);length(T)]];
                    indGrp = cellfun(@(x)(x(1):x(2)),num2cell(jj,2),'un',0);
                end
                
            else
                % only one group, so set from start to end
                indGrp = [];
            end
            
            % loops through all the
            for i = 1:nApp
                if obj.hProg.Update(2,sprintf('%s (Region %i of %i)',...
                        obj.hProg.wStr{2},i,nApp),i/nApp)
                    % if the user cancelled, then exit the function
                    [T,Pos,Hstr,ok] = deal([],[],[],false);
                    return
                end
                
                % retrieves the fly x-coordinates
                Px = PxG{i}(indNw,:);
                
                % sets the apparatus index and ok flags
                Hstr{i} = cell(1,1+(1+double(oParaO.outY))*size(Px,2));
                
                % sets the position array based on whether outputting the y-coords
                if oParaO.outY
                    % output y-location as well
                    Py = PyG{i}(indNw,:);
                    [PxC,PyC] = deal(num2cell(Px,1),num2cell(Py,1));
                    Pos{i} = cell2mat(cellfun(@(x,y)([x y]),PxC,PyC,'un',0));
                    
                    % clears extraneous variables
                    clear Py; pause(0.01);
                else
                    % only outputting x-locations
                    Pos{i} = Px;
                end
                
                % clears extraneous variables
                clear Px; pause(0.01);
                
                % sets the file name suffix strings
                if ~isempty(indGrp)
                    % if more than one file, then set the file-names based on the
                    % file period
                    Pos{i} = cellfun(@(x)(Pos{i}(x,:)),indGrp,'un',0);
                    fNameSuf{i} = cellfun(@(x)(sprintf('%s - H%i-%i',gName{i},...
                        (x-1)*tSplitH,x*tSplitH)),...
                        num2cell(1:size(indGrp,1))','un',0);
                    
                    % splits up the time strings into groups
                    if (i == 1)
                        T = cellfun(@(x)(T(x,:)),indGrp,'un',0);
                    end
                else
                    % otherwise, set the suffix name to be the apparatus name
                    [Pos{i},fNameSuf{i}] = deal(Pos(i),gName(i));
                    if (i == 1)
                        T = {T};
                    end
                end
                
                % sets the header string for each apparatus
                switch fType
                    case {'csv','txt'}
                        % sets the header string based on whether outputting y-data
                        Hstr{i}{1} = 'Time';
                        xiH = 1:size(Pos{i}{1},2);
                        H1 = arrayfun(@(x)(sprintf('X%i',x)),xiH,'un',0);
                        if oParaO.outY
                            % case is outputting both x and y data
                            H2 = [H1 arrayfun(@(x)(sprintf('Y%i',x)),xiH,'un',0)];
                            Hstr{i}(2:end) = reshape(H2',[1 numel(H2)]);
                        else
                            % case is outputting both x data
                            Hstr{i}(2:end) = H1;
                        end
                end
            end
            
        end
        
        % --- sets up the stimulus data array for output to file
        function stimData = setupStimData(obj)
            
            % initialisations
            snTotO = obj.snTotOut;
            [stimP,sTrainEx] = deal(snTotO.stimP,snTotO.sTrainEx);            
            [nTrain,sTrain] = deal(length(sTrainEx.sName),sTrainEx.sTrain);
            
            % loops through each block within the train retrieving the info
            for i = 1:nTrain
                stimDataNw = obj.setStimTrainInfo(sTrain(i).blkInfo,stimP,i);
                if i == 1
                    stimData = stimDataNw;
                else
                    stimData = combineCellArrays(stimData,stimDataNw,1,'');
                end
            end
            
            % removes the last column from the final data array
            stimData = stimData(:,1:end-1);
            
        end        
        
        % --- sets up the experimental data array for output to file --- %
        function exptData = setupExptData(obj)
            
            % memory allocation
            exptData = cell(obj.nField,2);            
            [snTotO,iParaO] = deal(obj.snTotOut,obj.iParaOut);
            
            % sets the experiment data fields based on the field type
            for i = 1:obj.nField
                switch i
                    case 1 
                        % case is the start time
                        exptData{i,1} = 'Solution Start Time';
                        T0 = snTotO.iExpt.Timing.T0;
                        dT = roundP(snTotO.T{...
                            iParaO.indS(1)}(iParaO.indS(2))/(24*3600));
                        exptData{i,2} = datestr(datenum(T0) + datenum(dT));
                        
                    case 2 
                        % case is the duration
                        Tst = snTotO.T{iParaO.indS(1)}(iParaO.indS(2),:);
                        Tfn = snTotO.T{iParaO.indF(1)}(iParaO.indF(2),:);
                        [~,~,Ts] = calcTimeDifference(Tfn-Tst);                        
                        exptData{i,1} = 'Solution File(s) Duration';
                        exptData{i,2} = sprintf('%s:%s:%s:%s',Ts{1},Ts{2},Ts{3},Ts{4});
                        
                    case (3) 
                        % case is the experiment type
                        exptData{i,1} = 'Experiment Type';
                        
                        % sets the recording field type
                        switch snTotO.iExpt.Info.Type
                            case ('RecordOnly')
                                % case is recording only
                                exptData{i,2} = 'Recording Only';
                            
                            otherwise
                                % case is recording + stimuli
                                exptData{i,2} = 'Recording + Stimuli';
                        end
                        
                    case (4) 
                        % case is the video count
                        exptData{i,1} = 'Video Count';
                        exptData{i,2} = num2str(length(snTotO.T));
                        
                    case (5) 
                        % case is the recording frame rate
                        exptData{i,1} = 'Recording Rate (fps)';
                        exptData{i,2} = num2str(snTotO.iExpt.Video.FPS);
                end
            end
            
        end
        
    end
    
    % static class methods
    methods (Static)
                
        % --- updates the region information data struct
        function snTot = updateRegionInfo(snTot)
            
            % retrieves the region data struct fields
            iMov = snTot.iMov;
            
            % updates the setup dependent fields
            if detMltTrkStatus(iMov)
                % field retrieval
                iGrp = iMov.pInfo.iGrp;
                iGrp(:) = 0;
                
                % recalculates the group indices
                [iA,~,iC] = unique(iMov.pInfo.gName,'Stable');
                for i = 1:max(iC)
                    iGrp(iC == i) = i;
                end
                
                % resets the group counter
                iMov.pInfo.iGrp = iGrp';
                iMov.pInfo.nGrp = length(iA);
                
            elseif iMov.is2D
                % resets the group index array/count
                iGrp0 = iMov.pInfo.iGrp;
                iMov.pInfo.iGrp(:) = 0;
                
                % sets the grouping indices
                indG = 1;
                for i = 1:max(iGrp0(:))
                    % determine the feasible groups that below to the 
                    % current group index (indG)
                    ii = (iGrp0 == i) & iMov.flyok;
                    
                    % updates the group index (if valid)
                    if iMov.ok(i) && any(ii(:))
                        iMov.pInfo.iGrp(ii) = indG;
                        indG = indG + 1;
                    else
                        iMov.pInfo.iGrp(ii) = 0;
                    end
                end
                
                % resets the group counter
                iMov.pInfo.nGrp = indG - 1;
                
            else
                % sets the group numbers and group indices
                [NameU,~,iC] = unique(iMov.pInfo.gName,'Stable');
                iMov.pInfo.nGrp = length(NameU);
                
                % sets the grouping numbers for each region
                for i = 1:iMov.pInfo.nRow
                    for j = 1:iMov.pInfo.nCol
                        k = (i-1)*iMov.pInfo.nCol + j;
                        if iMov.ok(k)
                            % region is accepted, so set grouping index 
                            iMov.pInfo.iGrp(i,j) = iC(k);
                            iMov.pInfo.nFly(i,j) = sum(iMov.flyok(:,k));
                        else
                            % region is rejected, so set the index to zero
                            iMov.pInfo.iGrp(i,j) = 0;
                            iMov.pInfo.nFly(i,j) = NaN;
                            [iMov.flyok(:,k),iMov.ok(k)] = deal(false);
                        end
                    end
                end
            end
            
            % retrieves the region data struct fields
            snTot.iMov = iMov;
            
        end        

        % --- retrieves the stimuli block information
        function sBlk = setStimTrainInfo(bInfo,stimP,iTrain)
            
            % retrieves the block channel names
            chNameBlk = cellfun(@(x)(regexprep(...
                x,'[ #]','')),field2cell(bInfo,'chName'),'un',0);
            devTypeBlk = cellfun(@(x)(regexprep(...
                x,'[ #]','')),field2cell(bInfo,'devType'),'un',0);
            
            % retrieves the unique device names from the list. from this 
            % determine if any motor devices where used (with matching 
            % protocols). if so, then remove them from the list of output
            isOK = false(length(devTypeBlk),1);
            devTypeU = unique(devTypeBlk);
            for i = 1:length(devTypeU)
                % determines all devices that belong to the current type
                ii = find(strcmp(devTypeBlk,devTypeU{i}));
                if strContains(devTypeU{i},'Motor')
                    % if the device is a motor, and the fields have already 
                    % been reduced, then ignore the other channels (as they 
                    % are identical)
                    if isfield(getStructField(stimP,devTypeU{i}),'Ch')
                        [ii,chNameBlk{ii(1)}] = deal(ii(1),'Ch');
                    end
                end
                
                % updates the acceptance flags
                isOK(ii) = isOK(ii) || true;
            end
            
            % removes any of the
            bInfo = bInfo(isOK);
            chNameBlk = chNameBlk(isOK);
            devTypeBlk = devTypeBlk(isOK);
            
            % determines the number of blocks
            nBlk = length(bInfo);
            sBlkT = cell(1,nBlk);
            
            % sets the column header string arrays
            cStr1 = repmat({'Time','Units'},1,nBlk);
            cStr2 = [{'Stim #'},repmat({'tStart','tFinish'},1,nBlk)];
            
            % sets the row header string arrays
            rStr1 = {'Train #','Device Type','Channel','Signal Type',''}';
            rStr2 = {'Cycle Count','Amplitude',''}';
            rStr3 = {'','Initial Offset','Cycle Duration',...
                     'Total Duration',''}';
            
            % combines bottom row header with the stimuli info header row
            rStr4 = combineCellArrays(...
                combineCellArrays(rStr3,cStr1,1),cStr2,0);
            
            % combines all the data into the header array
            sBlkH = combineCellArrays(rStr1,combineCellArrays(rStr2,rStr4,0),0);
            sBlkH(cellfun(@isnumeric,sBlkH)) = {''};
            sBlkH{1,2} = num2str(iTrain);
            
            % sets stimuli information for each block within entire train
            for i = 1:nBlk
                % iteration initialisations
                [iC,sP] = deal(2*i,bInfo(i).sPara);
                
                % sets the output channel name (based on type)
                if strcmp(chNameBlk{i},'Ch')
                    chNameNw = 'All Channels';
                else
                    chNameNw = chNameBlk{i};
                end
                
                % sets the main stimuli info fields
                sBlkH{2,iC} = bInfo(i).devType;
                sBlkH{3,iC} = chNameNw;
                sBlkH{4,iC} = bInfo(i).sType;
                
                % sets the train count field
                iR = length(rStr1);
                sBlkH{iR+1,iC} = num2str(sP.nCount);
                
                % sets the duration info fields
                iR2 = iR + length(rStr2);
                sBlkH{iR2+2,iC} = num2str(sP.tOfs);
                sBlkH{iR2+2,iC+1} = sP.tOfsU;
                sBlkH{iR2+4,iC} = num2str(sP.tDur);
                sBlkH{iR2+4,iC+1} = sP.tDurU;
                
                % sets the signal type specific fields
                switch bInfo(i).sType
                    case 'Square' % case is the square wave stimuli
                        
                        % sets the amplitude field
                        sBlkH{iR+2,iC} = sprintf('0/%s',num2str(sP.sAmp));
                        
                        % sets the cycle duration fields
                        sBlkH{iR2+3,iC} = sprintf('%s/%s',...
                            num2str(sP.tDurOn),num2str(sP.tDurOff));
                        sBlkH{iR2+3,iC+1} = sprintf('%s/%s',...
                            num2str(sP.tDurOnU),num2str(sP.tDurOffU));
                        
                    otherwise % case is the other stimuli types
                        
                        % sets the amplitude field
                        sBlkH{iR+2,iC} = sprintf('%s/%s',...
                            num2str(sP.sAmp1),num2str(sP.sAmp1));
                        
                        % sets the cycle duration fields
                        sBlkH{iR2+3,iC} = num2str(sP.tCycle);
                        sBlkH{iR2+3,iC+1} = sP.tCycleU;
                end
                
                % sets the stimuli block start times
                stP = eval(sprintf(...
                    'stimP.%s.%s',devTypeBlk{i},chNameBlk{i}));
                ii = stP.iStim(:) == iTrain;
                sBlkT{i} = num2cell(roundP([stP.Ts(ii),stP.Tf(ii)],0.001));
            end
            
            % sets the full stimuli start/finish time arrays
            sBlkT = [num2cell(1:size(sBlkT{1},1))',cell2cell(sBlkT,0)];
            
            % combines the header/time stamp informations into a single 
            % array (converts all numerical values to strings)
            sBlk = combineCellArrays(...
                combineCellArrays(sBlkH,sBlkT,0),{''},1,'');
            isNum = cellfun(@isnumeric,sBlk);
            sBlk(isNum) = cellfun(@num2str,sBlk(isNum),'un',0);
            
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