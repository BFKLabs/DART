% --- sets the combined solution file data struct --- %
function [snTot,iMov,eStr] = combineSolnFiles(sFile,isReduce)

% global variables
global hh hDay

% sets the default input arguments
if ~exist('isReduce','var'); isReduce = false; end

% parameters and initialisations
tOfs = 0;
eStr = [];
calcPhi = false;
updateSumm = false;
wState = warning('off','all');
sName = cellfun(@(x)(getFileName(x,1)),sFile,'un',0);

% sets the summary file name from the solution file data
A = load(sFile{1},'-mat');
smFile = getSummaryFilePath(A.fData);
if isempty(smFile)
    smFile = getSummaryFilePath(struct('movStr',sFile{1}));
end

% sets the video/stimuli arrays
if exist(smFile,'file')
    % creates the load bar
    smData = load(smFile);
    
    % determines the solution files which contain the base file name
    baseName = smData.iExpt.Info.BaseName;
    if isempty(baseName)
        hasBN = cellfun(@(x)(startsWith(x,' -')),sName);
    else
        hasBN = cellfun(@(x)(strContains(x,baseName)),sName);
    end
    
    % retrieves the index of the first file
    if any(hasBN)
        % if the files do have the base file name, then use the first
        % feasible solution file to determine the file index 
        xi = cellfun(@(x)(getVideoFileIndex(x)),sName(hasBN));
        xi = xi(~isnan(xi));
        
    elseif length(sFile) == 1
        % if there is only one video, then only use this video
        xi = 1;
        
    else
        % case is there are no validly name video solution files
        xi = [];  
    end
    
    if isempty(xi)
        % case is there are no validly name video solution files
        eStr = sprintf(['The selected video solution files are ',...
                      'not named correctly. Ensure that the video ',...
                      'solution files have the following name ',...
                      'convention\n * "%s ####.soln'],baseName);

        % if there is an issue, then exit
        [snTot,iMov] = deal([]);
        return      
    end    
        
    % retrieves the stimuli protocol/experiment information
    [stimP,sTrainEx] = getExptStimInfo(smFile);     
    
    % if the summary file exists, then load it and set the time fields 
    [iExpt,nFile] = deal(smData.iExpt,length(sFile));
    [Tp,T0] = deal(smData.iExpt.Timing.Tp,NaN(nFile,1));
    
    % determines if any of the videos are all NaNs
    allNaN = cellfun(@(x)(all(isnan(x))),smData.tStampV(xi));
    if any(allNaN)       
        % sets the initial time of the video based on the other videos
        for i = reshape(find(allNaN),1,sum(allNaN))
            if i == 1
                % case is the first video is all NaNs
                T0(i) = 0;
                
            elseif allNaN(i-1)
                % case is the previous video is also all NaNs
                T0(i) = T0(i-1) + ...
                        length(smData.tStampV{i-1})/iExpt.Video.FPS + Tp;
                    
            else
                % case is the previous video is not all NaNs
                T0(i) = smData.tStampV{i-1}(end) + Tp;
            end
        end
    end
    
    % removes any NaN values from the time vectors
    FPS = 1/calcWeightedMean(diff(smData.tStampV{xi(1)}));
    tStampV = cellfun(@(x,y)(removeTimeNaNs(x,FPS,y)),...
                        smData.tStampV(xi),num2cell(T0),'un',0);    
                    
    % determines if the solution file data is valid
    okF = [isfield(smData,'sData'),isfield(smData,'iMov')];
    if any(~okF)
        % retrieves the soluton file direction
        slnDir = fileparts(smFile);
                
        % determines if the batch processing file exists in the solution
        % file directory
        bpFile = fullfile(slnDir,'BP.mat');
        if exist(bpFile,'file')
            % if it does, then determine if the original solution file
            % exists on the original path
            A = load(bpFile);
            if exist(A.bData.sName,'file')
                % if so, then copy the file over to the solution directory
                % and reload the summary file
                delete(smFile)
                copyfile(A.bData.sName,slnDir,'f');
                
                smData = load(A.bData.sName);
                [iExpt,tStampV] = deal(smData.iExpt,smData.tStampV);
            else
                % otherwise, set empty fields for the missing data
                if ~okF(1); smData.sData = 0; end
                if ~okF(2); smData.iMov = []; end
            end
        else
            % otherwise, set empty fields for the missing data
            if ~okF(1); smData.sData = 0; end
            if ~okF(2); smData.iMov = []; end
        end
    end
    
    % determines if there was any stimuli information from a real-time
    % tracking experiment
    if iscell(smData.sData)
        % experiment was real-time, so set data array
        [sData,iExpt.Info.Type] = deal(smData.sData,'RTTrack');
    else
        % no data, so set empty array
        sData = [];
    end

    % sets the video start/end times
    tStampVF = tStampV(1:min(length(sFile),length(tStampV)));
    T0 = cellfun(@(x)(x(1)),tStampVF);
    Tf = cellfun(@(x)(x(end)),tStampVF);
    dT = T0(2:end) - Tf(1:(end-1)); 
    
    % checks to see if the time difference between videos is not too large
    ii = (dT > 6*iExpt.Timing.Tp) & (dT < 60*iExpt.Timing.Tp);
    if any(ii)
        % if there are such videos, then reset their time-stamps
        jj = find(ii) + 1;
        for i = 1:length(jj)
            j = jj(i);
            T = tStampV{j}-tStampV{j}(1)+iExpt.Timing.Tp+tStampV{j-1}(end);
            tStampV{j} = T;
        end
    end
    
    % sets the stimulus time-stamp array
    if ~isempty(smData.tStampS)            
        if iscell(smData.tStampS)
            % if a cell array, then set the first cell as the time stamps
            tStampS = smData.tStampS{1};
        else
            % if not a cell, then set the array
            tStampS = smData.tStampS;
        end
        
        % removes all the stimuli time stamps past the last video end
        tStampS = tStampS(tStampS <= tStampV{end}(end));
    else
        % otherwise, set an empty time-stamp array
        tStampS = [];
    end    
            
    % determines the start-time of the experiment
    T0 = datevec(addtodate(datenum...
                        (iExpt.Timing.T0),floor(tStampV{1}(1)),'second'));
    if xi(1) ~= 0
        [iExpt.Timing.T0,tOfs] = deal(T0,tStampV{1}(1));
        tStampV = cellfun(@(x)(x-tOfs),tStampV,'un',0);
    end  
    
    % sets the experiment flag (if not set)
    if ~isfield(iExpt.Info,'Type')
        if ~isempty(smData.tStampS{1})
            iExpt.Info.Type = 'RecordStim'; 
        else
            iExpt.Info.Type = 'RecordOnly';         
        end
        
    elseif strcmp(iExpt.Info.Type,'RecordOnly') && ~isempty(tStampS)
        % case is the experiment originally set as a record experiment, but 
        % has had the stimuli time stamps added in through SyncSummary
        iExpt.Info.Type = 'RecordStim';
    end    
    
    % determines the overall file count
    nFile = min(length(sFile),length(tStampV));    
    
else    
    % otherwise, set an empty time-stamp array    
    [tStampS,tStampV,T0,stimP,sTrainEx] = deal([]);
        
    %
    nFile = length(sFile);    
    [xi,tNow] = deal(1:nFile,clock());
    
    % sets up the experiment data struct
    Info = struct('Type','RecordOnly');
    Timing = struct('T0',[tNow(1:2),[0,12,0,0]]);    
    iExpt = struct('Timing',Timing,'Info',Info);
end
    
% memory allocation
isOK = true(nFile,1);
sgP = struct('sRate',[],'fRate',[],'sFac',[]);
snTot = orderfields(struct('T',[],'Px',[],'Py',[],'Phi',[],'AxR',[],...
                           'stimP',stimP,'sTrainEx',sTrainEx,...
                           'isDay',[],'sgP',sgP,'iExpt',iExpt,...
                           'exD',[],'iMov',[],'Type',1));           
           
% sub-struct memory allocation    
initData = true;
[snTot.T,Px,Py] = deal(cell(nFile,1)); 
if exist('sData','var'); snTot.sData = sData; end
   
% retrieves the waitbar figure properties
if ~isempty(hh)
    [h,wOfs] = deal(hh,1);
    if isa(h,'ProgBar') && ishandle(h.hFig)
        % if the waitbar is valid, then retrieve the level strings
        wStr = h.wStr;
    else
        % if the waitbar has been deleted, but the flag not reset, then
        % create a new waitbar figure and reset the handle variable
        [wStr,hh] = deal({'Loading Video Solution Files'},[]);
        [h,wOfs] = deal(ProgBar(wStr,'Combining Solution Files'),0); 
    end
else
    % creates a new waitbar figure
    wStr = {'Loading Video Solution Files'};
    [h,wOfs] = deal(ProgBar(wStr,'Combining Solution Files'),0);
end
    
% loops through all the data files setting the values
for i = 1:nFile
    % ------------------------------------------- %    
    % --- SOLUTION FILE LOADING & TIME ARRAYS --- %
    % ------------------------------------------- %
    
    % updates the waitbar figure
    wStrNw = sprintf('%s (%i of %i)',wStr{1+wOfs},i,nFile);
    if h.Update(1+wOfs,wStrNw,0.5*(i/nFile))
        % the user cancelled, then exit the function
        [snTot,iMov] = deal([]);
        return        
    end        
            
    % loads the positional data from the solution file
    A = load(sFile{i},'-mat','pData');
    if isempty(A.pData)          
        % if it is empty, then flag that the movie is not suitable
        isOK(i) = false;
        
    else                        
        % otherwise, load the solution file
        a = load(sFile{i},'-mat');            
        fPos = a.pData.fPos;
        [nFrm,sRate] = deal(size(fPos{1}{1},1),a.iMov.sRate); 
        
        % retrieves the index of the file to be analysed
        vFile = getFileName(a.fData.name);
        D0 = cellfun(@(x)(fzsearch(x,vFile)),sFile(:),'un',0);
        D = cell2mat(cellfun(@(x)(x(1:2)),D0,'un',0));
        ii = argMin(D(:,1));
        
        % sets the region count
        if isfield(a.pData,'nApp')
            nApp = a.pData.nApp;
        else
            nApp = numel(fPos);
        end                
        
        % sets the essential parameters (for the first frame)
        if initData
            % sets the experimental recording/segmentation parameters  
            initData = false;
            sgP = struct('sRate',a.iMov.sRate,'fRate',a.exP.FPS,...
                         'sFac',a.exP.sFac);
            [snTot.Px,snTot.Py] = deal(cell(nApp,1));            
            [snTot.sgP,iMov,snTot.iMov] = deal(sgP,a.iMov,a.iMov);  
            
            if (xi(1) ~= 0) && isempty(tStampS)
                tStampS = tStampS - tOfs; 
            end                   
            
            % retrieves the orientation flag
            if isfield(A.pData,'calcPhi')
                calcPhi = A.pData.calcPhi;
            else
                % old solution file (does not exist)
                calcPhi = false;
            end
            
            % determines if the orientation angles have been calculated            
            if calcPhi
                % allocates memory for the orientation angles
                [PhiF,AxRF] = deal(cell(nFile,1));
                [snTot.Phi,snTot.AxR] = deal(cell(nApp,1));                
            else
                % if the orientation angles are not calculated, then remove
                % the field from the data struct
                rFld = {'Phi','pMapPhi','AxR','pMapAxR'};
                for j = 1:length(rFld)
                    if isfield(snTot,rFld{j})
                        snTot = rmfield(snTot,rFld{j});
                    end
                end
            end
        end    
        
        % sets the orientation angles (if they were calculated)
        if calcPhi; [Phi,AxR] = deal(a.pData.PhiF,a.pData.axR); end

        % ensures the 2D flag is set
        if ~isfield(a.iMov,'is2D')
            a.iMov.is2D = is2DCheck(a.iMov); 
        end         
        
        % ---------------------------- %    
        % --- FLY LOCATION SETTING --- %
        % ---------------------------- %    

        % allocates memory for the fly location data and binned
        % distance/range calculations
        [Px{i},Py{i}] = deal(cell(1,nApp));      
        if calcPhi
            [PhiF{i},AxRF{i}] = deal(cell(1,nApp)); 
        end

        % loops through all the apparatus setting the x/y locations of the
        % flies, and calculates binned x/y location and summed displacement
        % of the flies
        for j = find(a.iMov.ok(:)')
            % fills any missing data values with NaN's
            kk = cellfun('isempty',fPos{j});
            if any(kk)
                [i0,jj] = deal(find(~kk,1,'first'),find(kk));
                for k = 1:length(jj)
                    fPos{j}{jj(k)} = NaN(size(fPos{j}{i0}));
                    if calcPhi
                        Phi{j}{jj(k)} = NaN(size(Phi{j}{i0}));
                        AxR{j}{jj(k)} = NaN(size(AxR{j}{i0}));
                    end
                end
            end
            
            % sets the x/y locations of the flies         
            dyOfs = a.iMov.is2D*(a.iMov.iR{j}(1)-1);            
            Px{i}{j} = cell2mat(cellfun(@(x)(x(:,1)*sgP.sFac),...
                                fPos{j},'un',0));
            Py{i}{j} = cell2mat(cellfun(@(x)((x(:,2)+dyOfs)*sgP.sFac),...
                                fPos{j},'un',0));                             
                            
            % sets the orientation angles (if they were calculated)
            if calcPhi
                PhiF{i}{j} = cell2mat(Phi{j}); 
                AxRF{i}{j} = cell2mat(AxR{j}); 
            end
        end        
        
        % --------------------------------- %            
        % --- VIDEO/STIMULI TIME STAMPS --- %
        % --------------------------------- %            
        
        % sets the frame time stamp vector
        if isempty(tStampV)
            Tnw = a.pData.T(1:sRate:end);
            
        elseif all(isnan(tStampV{ii}))
            % sets the time offset            
            if ii == 1
                Tnw0 = 0;
            else            
                Tnw0 = tStampV{ii}(end) + iExpt.Timing.Tp;
            end

            % sets the new time-array
            if all(isnan(a.pData.T))
                dT = 1/iExpt.Video.FPS;
                tStampV{ii} = (0:dT:(length(a.pData.T)-1)*dT)' + Tnw0;
            else
                tStampV{ii} = a.pData.T + Tnw0;
            end

            % flag that the summary file needs to be updated
            [Tnw,updateSumm] = deal(tStampV{ii}(1:sRate:end),true);
            
        else
            % otherwise, read the time values from the time-stamp array
            Tnw = tStampV{ii}(1:sRate:end);
        end

        % interpolates any missing time points
        snTot.T{i} = Tnw(1:min(length(Tnw),nFrm));        
        iiNaN = isnan(snTot.T{i});
        if any(iiNaN)
            snTot.T{i}(iiNaN) = interp1(find(~iiNaN),snTot.T{i}(~iiNaN),...
                                find(iiNaN),'linear','extrap');
        end
    end
end

% sets the time vectors (if the experiment start time is provided) 
if ~isempty(T0)
    for i = 1:nFile
        % updates the waitbar figure
        wStrNw = sprintf('%s (%i of %i)','Setting Time Vectors',i,nFile);
        if h.Update(1+wOfs,wStrNw,0.5*(1+(i/nFile)))
            % the user cancelled, so exit the function
            [snTot,iMov] = deal([]);
            return        
        end
        
        % sets the day/night boolean flags (if ok)        
        if isOK(i)
            TT = cellfun(@(x)(addtodate(datenum(T0),...
                            roundP(x,1),'second')),num2cell(snTot.T{i}));
            TTv = datevec(TT);
            snTot.isDay{i} = (TTv(:,4) >= hDay) & (TTv(:,4) < (hDay + 12));                        
        end
    end
end

% checks to see which of the solution files were feasible
if all(~isOK)
    % closes the progressbar (if created within function)
    if wOfs == 0
        h.closeProgBar();
    end
    
    % case is none of the video solution files are feasible    
    eStr = sprintf(['All selected video solution files are either ',...
                    'corrupt, or have not been fully tracked. Check ',...
                    'that these videos have been tracked properly ',...
                    'before attempting to combine this experiment.']);
    
    % exits the function with empty data structs
    [snTot,iMov] = deal([]); 
    return
    
elseif any(~isOK)
    % some were infeasible    
    [Px,Py,sFile] = deal(Px(isOK),Py(isOK),sFile(isOK)); 
    [snTot.T,snTot.isDay] = deal(snTot.T(isOK),snTot.isDay(isOK));
    if calcPhi; [PhiF,AxRF] = deal(PhiF(isOK),AxRF(isOK)); end
end

% back-formats the region data struct
iMov = backFormatRegionDataStruct(iMov);

% resets the multi-tracking status to 2D
if detMltTrkStatus(iMov)
    iMov.is2D = true;
end

% sets the apparatus/individual fly boolean flags
snTot.sName = sFile;

% resets the x/y locations into a cell array
for i = 1:nApp
    % sets the x/y locations for the current sub-region
    snTot.Px{i} = cell2mat(cellfun(@(x)(x{i}),Px,'un',0));
    snTot.Py{i} = cell2mat(cellfun(@(x)(x{i}),Py,'un',0));       
    
    % sets the orientation angles (if calculated)
    if calcPhi
        snTot.Phi{i} = cell2mat(cellfun(@(x)(x{i}),PhiF,'un',0));
        snTot.AxR{i} = cell2mat(cellfun(@(x)(x{i}),AxRF,'un',0));
    end
end

% determines if the total number of frames exceeds the total frame count
nFrmTotal = sum(cellfun('length',snTot.T));
if size(snTot.Px{1},1) > nFrmTotal
    % if so, then reduce the x/y-coordinates
    snTot.Px = cellfun(@(x)(x(1:nFrmTotal,:)),snTot.Px,'un',0);
    snTot.Py = cellfun(@(x)(x(1:nFrmTotal,:)),snTot.Py,'un',0);
    
    % reduces the orientation angles (if calculated)
    if calcPhi
        snTot.Phi = cellfun(@(x)(x(1:nFrmTotal,:)),snTot.Phi,'un',0);
        snTot.AxR = cellfun(@(x)(x(1:nFrmTotal,:)),snTot.AxR,'un',0);
    end    
end

% removes the rejected apparatus from the analysis fields
if ~isempty(iMov) && isReduce
    if isfield(iMov,'ok')        
        % retrieves the acceptance/rejection flags
        ok0 = iMov.ok;
        
        % resets the solution data struct
        snTot.Px = snTot.Px(ok0);
        snTot.Py = snTot.Py(ok0);         
        
        % resets the orientation angles (if calculated)
        if calcPhi
            snTot.Phi = snTot.Phi(ok0); 
            snTot.AxR = snTot.AxR(ok0); 
        end
        
        % if there are any 
        if any(~ok0)
            for i = find(~ok0(:)')
                [iCol,~,iRow] = getRegionIndices(iMov,i);
                iMov.nTubeR(iRow,iCol) = NaN;
            end
        end
        
        % sets the region index fields
        if isfield(iMov,'indR')
            % if the field exists, then reduce it
            iMov.indR = iMov.indR(ok0);
        else
            % otherwise, initialise the field
            iMov.indR = find(ok0);
        end
        
        % resets the sub-region data struct         
        iMov.ok = iMov.ok(ok0);
        [iMov.iR,iMov.iC] = deal(iMov.iR(ok0),iMov.iC(ok0));
        [iMov.iRT,iMov.iCT] = deal(iMov.iRT(ok0),iMov.iCT(ok0));
        [iMov.xTube,iMov.yTube] = deal(iMov.xTube(ok0),iMov.yTube(ok0));
        [iMov.pos,iMov.Status] = deal(iMov.pos(ok0),iMov.Status(ok0));
        iMov.pInfo.gName = iMov.pInfo.gName(ok0);
        
        %
        if iscell(iMov.flyok)
            iMov.flyok = iMov.flyok(ok0);
        else
            iMov.flyok = iMov.flyok(:,ok0);
        end
        
        % resets the background image arrays       
        for i = 1:length(iMov.Ibg)
            if iMov.vPhase(i) == 1
                iMov.Ibg{i} = iMov.Ibg{i}(ok0);
            end
        end        
    end
end

% updates the summary file (if in need of update)
if updateSumm
    iStim = smData.iStim;
    save(smFile,'iStim','iExpt','tStampS','tStampV');
end

% closes the waitbar (if created in the function)
if wOfs == 0
    h.closeProgBar();
end

% reverts the warnings back to the original state
warning(wState);

% --- back-formats the region data struct
function [iMov,isChange] = backFormatRegionDataStruct(iMov)

% initialisations
addFld = {'flyok','is2D','pInfo'};
rmvFld = {'pStats','tempSet','dTube','isUse'};
isChange = {false(length(addFld),1),false(length(rmvFld),1)};

% determines if there are any missing fields that need to be added
for i = 1:length(addFld)
    if ~isfield(iMov,addFld{i})
        switch addFld{i}
            case 'flyok'
                iMov.flyok = true(getSRCountMax(iMov),nApp);
            case 'is2D'
                iMov.is2D = is2DCheck(iMov);
            case 'pInfo'
                iMov.pInfo = getRegionDataStructs(iMov);
        end
        
        % updates the change flag to true
        isChange{1}(i) = true;
    end
end

% determines if there are any obsolete fields that need to be removed
for i = 1:length(rmvFld)
    if isfield(iMov,rmvFld{i})
        % removes the fields
        iMov = rmfield(iMov,rmvFld{i});
        
        % updates the change flag to true
        isChange{2}(i) = true;        
    end
end
