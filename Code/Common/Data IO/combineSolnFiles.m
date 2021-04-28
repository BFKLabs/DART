% --- sets the combined solution file data struct --- %
function [snTot,iMov] = combineSolnFiles(sName)

% global variables
global hh hDay

% parameters and initialisations
updateSumm = false;
wState = warning('off','all');

% sets the summary file name from the solution file data
A = importdata(sName{1},'-mat');
smFile = getSummaryFilePath(A.fData);
if isempty(smFile)
    smFile = getSummaryFilePath(struct('movStr',sName{1}));
end

% sets the video/stimuli arrays
if exist(smFile,'file')
    % creates the load bar
    smData = load(smFile);
    h = ProgressLoadbar('Determining Valid Solution Files...');
    
    % retrieves the index of the first file
    i0 = getVideoFileIndex(sName{1})-1;
    if isnan(i0)
        % if there is an issue, then exit
        [snTot,iMov] = deal([]);
        return      
    end
        
    % retrieves the stimuli protocol/experiment information
    [stimP,sTrainEx] = getExptStimInfo(smFile);     
    
    % if the summary file exists, then load it and set the time fields 
    [iExpt,nFile] = deal(smData.iExpt,length(sName));
    [xi,Tp,T0] = deal(i0+(1:nFile)',smData.iExpt.Timing.Tp,NaN(nFile,1));
    
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
    tStampVF = tStampV(1:min(length(sName),length(tStampV)));
    T0 = cellfun(@(x)(x(1)),tStampVF);
    Tf = cellfun(@(x)(x(end)),tStampVF);
    dT = T0(2:end) - Tf(1:(end-1)); 
    
    % checks to see if the time difference between videos is not too large
    ii = dT > 6*iExpt.Timing.Tp;
    if any(ii)
        % if there are such videos, then reset their time-stamps
        jj = find(ii) + 1;
        for i = 1:length(jj)
            j = jj(i);
            T = tStampV{j}-tStampV{j}(1)+(iExpt.Timing.Tp+tStampV{j-1}(end));
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
    if i0 ~= 0
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
    
    % closes the load bar
    try; close(h); end
    pause(0.05);
    
else
    % otherwise, set an empty time-stamp array
    [tStampS,tStampV,T0,iExpt,stimP,sTrainEx] = deal([]); 
end
    
% memory allocation
nFile = min(length(sName),length(tStampV));
isOK = true(nFile,1);
sgP = struct('T0',T0,'sRate',[],'fRate',[]);
snTot = orderfields(struct('T',[],'Px',[],'Py',[],'Phi',[],'AxR',[],...
                           'stimP',stimP,'sTrainEx',sTrainEx,...
                           'isDay',[],'sgP',sgP,'iExpt',iExpt,...
                           'pMapPx',[],'pMapPy',[],...
                           'pMapPhi',[],'pMapAxR',[],...
                           'appPara',[],'iMov',[],'Type',1));           
           
% sub-struct memory allocation           
[snTot.T,Px,Py] = deal(cell(nFile,1)); 
if ~isempty(sData); snTot.sData = sData; end
   
% retrieves the waitbar figure properties
if ~isempty(hh)
    [h,wOfs] = deal(hh,1);
    if isa(h,'ProgBar')
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
        [snTot,iMov] = deal([]);
        return        
    end        
            
    % loads the positional data from the solution file
    A = load(sName{i},'-mat','pData');
    if isempty(A.pData)          
        % if it is empty, then flag that the movie is not suitable
        isOK(i) = false;
        
    else                        
        % otherwise, load the solution file
        a = load(sName{i},'-mat');            
        fPos = a.pData.fPos;
        [nFrm,sRate] = deal(size(fPos{1}{1},1),a.iMov.sRate); 
        
        % retrieves the index of the file to be analysed
        vFile = getFileName(a.fData.name);
        D0 = cellfun(@(x)(fzsearch(x,vFile)),sName(:),'un',0);
        D = cell2mat(cellfun(@(x)(x(1:2)),D0,'un',0));
        ii = argMin(D(:,1));
        
        % sets the region count
        if (isfield(a.pData,'nApp'))
            nApp = a.pData.nApp;
        else
            nApp = numel(fPos);
        end        
        
        % more than one row, so use the region row indices as offset
        yOfs = cellfun(@(x)(x(1)-1),a.iMov.iR);
        
        % sets the essential parameters (for the first frame)
        if i == 1
            % sets the experimental recording/segmentation parameters       
            sgP = struct('sRate',a.iMov.sRate,'fRate',a.exP.FPS,...
                         'sFac',a.exP.sFac);
            [snTot.Px,snTot.Py] = deal(cell(nApp,1));            
            [snTot.sgP,iMov,snTot.iMov] = deal(sgP,a.iMov,a.iMov);             
            if (i0 ~= 0); tStampS = tStampS - tOfs; end                   
            
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
                [snTot.Phi,PhiF] = deal(cell(nApp,1),cell(nFile,1));
                [snTot.AxR,AxRF] = deal(cell(nApp,1),cell(nFile,1));
            else
                % if the orientation angles are not calculated, then remove
                % the field from the data struct
                try
                    snTot = rmfield(snTot,{'Phi','pMapPhi'});
                    snTot = rmfield(snTot,{'AxR','pMapAxR'});                
                end
            end
        end    
        
        % sets the orientation angles (if they were calculated)
        if calcPhi; [Phi,AxR] = deal(a.pData.PhiF,a.pData.axR); end

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
        for j = 1:nApp                         
            % fills any missing data values with NaN's
            kk = cellfun(@isempty,fPos{j});
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
            dyOfs = yOfs(j); %-yOfs(1);
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
    
% initialises the fly feasibility boolean flags (if not set)
if ~isfield(iMov,'flyok')
    iMov.flyok = true(getSRCountMax(iMov),nApp);
end

% checks to see which of the solution files were feasible
if all(~isOK)
    % all were infeasible
    snTot = []; 
    return
    
elseif any(~isOK)
    % some were infeasible    
    [Px,Py,sName] = deal(Px(isOK),Py(isOK),sName(isOK)); 
    [snTot.T,snTot.isDay] = deal(snTot.T(isOK),snTot.isDay(isOK));
    if calcPhi; [PhiF,AxRF] = deal(PhiF(isOK),AxRF(isOK)); end
end

% sets the apparatus/individual fly boolean flags
[snTot.appPara.ok,snTot.appPara.flyok] = deal(iMov.ok,iMov.flyok);
[snTot.sName,snTot.appPara.aInd] = deal(sName,(1:length(iMov.ok))');

% sets the sub-region selection type
if ~isfield(iMov,'autoP')
    % no sub-region field, so set an empty type
    snTot.appPara.Type = [];
    
elseif isempty(iMov.autoP)
    % if the field exists, but is empty, then set an empty type
    snTot.appPara.Type = [];
    
else
    % otherwise, set the sub-region type
    snTot.appPara.Type = iMov.autoP.Type;
end

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

% removes the rejected apparatus from the analysis fields
if ~isempty(iMov)
    if isfield(iMov,'ok')        
        % retrieves the acceptance/rejection flags
        ok0 = iMov.ok;
        
        % resets the solution data struct
        snTot.Px = snTot.Px(ok0);
        snTot.Py = snTot.Py(ok0);         
        snTot.appPara.flyok = snTot.appPara.flyok(:,ok0);
        snTot.appPara.ok = snTot.appPara.ok(ok0);
        snTot.appPara.aInd = snTot.appPara.aInd(ok0);
        
        % resets the orientation angles (if calculated)
        if calcPhi
            snTot.Phi = snTot.Phi(ok0); 
            snTot.AxR = snTot.AxR(ok0); 
        end
        
        % resets the sub-region data struct        
        [iMov.ok,iMov.flyok] = deal(iMov.ok(ok0),iMov.flyok(:,ok0));
        [iMov.iR,iMov.iC] = deal(iMov.iR(ok0),iMov.iC(ok0));
        [iMov.iRT,iMov.iCT] = deal(iMov.iRT(ok0),iMov.iCT(ok0));
        [iMov.xTube,iMov.yTube] = deal(iMov.xTube(ok0),iMov.yTube(ok0));
        [iMov.pos,iMov.Status] = deal(iMov.pos(ok0),iMov.Status(ok0));
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
