% --- combines the solution files from a real-time tracking experiment
function combineRTSolnFiles(iExpt,varargin)

% ----------------------- %
% --- INITIALISATIONS --- %
% ----------------------- %

% sets the video/solution file directories
vDir = fullfile(iExpt.Info.OutDir,iExpt.Info.Title);
sDir = fullfile(iExpt.Info.OutSoln,iExpt.Info.Title);

% loads the summary file and creates a copy in the solution directory
summFile = fullfile(vDir,'Summary.mat');
Asumm = load(summFile);
copyfile(summFile,sDir,'f');

% retrieves the summary and temporary files
tName = dir(fullfile(sDir,'TempRT_*.mat'));

% creates a waitbar figure
if nargin == 1
    wStr = {'Outputting RT-Tracking Solution Files'};
    h = ProgBar(wStr,'Solution File Output');
    pause(0.05);
end

% ---------------------------- %
% --- SOLUTION FILE OUTPUT --- %
% ---------------------------- %

% other initialisations
[nSoln,stimP] = deal(length(tName),[]);
[bName,iMov] = deal(Asumm.iExpt.Info.BaseName,Asumm.iMov);
tFileNw = cell(nSoln,1);

% retrieves the video file information data structs
fDataT = dir(fullfile(vDir,sprintf('%s*',bName)));

% creates the solution files for each of the output videos
for i = 1:nSoln
    % updates the waitbar figure
    if nargin == 1
        wStrNw = sprintf('%s (%i of %i)',wStr{1},i,nSoln);
        h.Update(1,wStrNw,i/(nSoln+1));            
    end
    
    % loads the temporary file
    tFileNw{i} = fullfile(sDir,tName(i).name);
    Atmp = load(tFileNw{i});           
            
    % -------------------------------- %
    % --- FLY POSITION DATA STRUCT --- %
    % -------------------------------- %
        
    % initialises the position data struct
    [rtPos,pData] = deal(Atmp.rtPos,setupDataArray('pData'));
    ii = 1:rtPos.ind;
    
    % sets the other fields
    [pData.nApp,pData.nTube] = deal(length(iMov.iR),getSRCount(iMov));
    [pData.frmOK,pData.nCount,pData.isSeg] = deal({true},1,true);    
    
    % sets the time/positiona arrays
    pData.T = rtPos.T(ii);
    [pData.fPos,pData.fPosL] = deal(rtPos.fPos);
    
    % sets the final positional arrays for each sub-region
    for j = 1:length(pData.fPos)
        % sets the x/y-offsets for the current sub-region
        [xOfs,yOfs] = deal(iMov.iC{j}(1)-1,iMov.iR{j}(1)-1);
                
        % updates the position arrays for the current sub-region
        for k = 1:pData.nTube(j)
            % reduces the global positional array
            pData.fPos{j}{k} = pData.fPos{j}{k}(ii,:);
            pData.fPos{j}{k}(:,2) = pData.fPos{j}{k}(:,2) - yOfs;
            
            % reduces/offsets the local positional array            
            pOfs = repmat([xOfs,(yOfs+iMov.iRT{j}{k}(1)-1)],rtPos.ind,1);
            pData.fPosL{j}{k} = pData.fPos{j}{k}(:,2) - pOfs;
            
            % resets the fly status flags
            if (iMov.flyok(k,j))
                if (isempty(iMov.IbgE{k,j}))
                    % fly has moved sufficiently over the experiment
                    iMov.Status{j}(k) = 1;
                else
                    % fly has not moved sufficiently
                    iMov.Status{j}(k) = 2;
                end
            end
        end
    end
    
    % ------------------------------------- %
    % --- EXPERIMENTAL PARAMETER STRUCT --- %
    % ------------------------------------- %
    
    % sets up the experimental parameter data structs
    if (i == 1)
        % only set up for the first solution file
        exP = setupDataArray('exP');
        exP.FPS = roundP(1/mean(diff(pData.T)));
        exP.sFac = Asumm.iExpt.rtP.trkP.sFac;        
    end
    
    % ------------------------------------ %
    % --- FILE INFORMATION DATA STRUCT --- %
    % ------------------------------------ %
    
    % sets the file info data struct for the current file
    fData = fDataT(i);    
    fData.dir = vDir;
    
    % removes the folder field (if set)
    if (isfield(fData,'folder'))
        fData = rmfield(fData,'folder');
    end
    
    % ------------------------------------ %
    % --- FILE INFORMATION DATA STRUCT --- %
    % ------------------------------------ %    
    
    % sets up the solution file 
    nwID = sprintf('%s%i',repmat('0',1,3-floor(log10(i))),i);
    sFile = fullfile(sDir,sprintf('%s - %s.soln',bName,nwID));    
    
    % saves the file solution file
    save(sFile,'iMov','pData','exP','stimP','fData');        
end

% deletes the temporary file
cellfun(@delete,tFileNw);

% updates and closes the waitbar figure
if nargin == 1   
    h.ProgBar(1,'Solution File Output Complete!',1);            
    pause(0.05); 
    h.closeProgBar()
end

% --- initialises the data struct based on the type string, pStr
function p = setupDataArray(pStr)

% initialises the data struct based on the type
switch (pStr)
    case ('pData') % case is the positional data struct
        p = struct('fPos',[],'fPosL',[],'frmOK',[],'isSeg',[],...
                   'nTube',[],'nApp',[],'T',[],'nCount',[]);
    case ('exP') % case is the experimental info data struct
        p = struct('FPS',[],'sFac',[]);        
end