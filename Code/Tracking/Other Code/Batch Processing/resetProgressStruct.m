% --- resets the segmentation progress struct --- %
function iMov = resetProgressStruct(iData,iMov,solnChk,iPhase) 

% sets the solution check flag to false (if not checking solution)
if (nargin < 3); solnChk = false; end

% sets the phase indices
if nargin < 4
    pInd = [1 iData.nFrm];
else
    pInd = iMov.iPhase(iPhase,:);
end       

% sets the number of frames
nFrm = diff(pInd) + 1;
% nFrmS = iMov.sRate.*floor(NN./iMov.sRate);  % number of frames to be read per image stack
nFrmS = getFrameStackSize;                  % number of frames to be read per image stack
nFrmT = (iMov.sRate*nFrm);                  % the total number frames (full and sampled)
nFrmR = iMov.sRate*ceil(nFrmS/iMov.sRate);  % number of total movie frames to be read per image stack
nStackS = ceil(nFrm/nFrmS);                 % number of sub-image stacks
nStackR = ceil((iMov.sRate*nFrm)/nFrmR);    % number of sub-image sub-stack read groups

% ------------------------------------------- %
% --- PROGRESS DATA STRUCT INITIALISATION --- %
% ------------------------------------------- %

% sets the temporary image stack directory
tDir = iData.ProgDef.TempFile;

% initialises the data struct
sProg0 = struct('movFile',[],'Status',[],'frmR',[],'frmS',[],'isRead',[],...
                'isComplete',0,'nFrmS',nFrmS,'nFrmR',nFrmR,'nFrmRS',[]);
[iStackR,frmS] = deal(num2cell(1:nStackR)',(1:iMov.sRate:nFrmT)');
 
% sets the struct fields            
sProg0.movFile = fullfile(iData.fData.dir,iData.fData.name);
sProg0.Status = NaN(nStackS,1);  
sProg0.isRead = false(nStackR,1);  

sProg0.frmR = cellfun(@(x)(min([1 nFrmR]+(x-1)*nFrmR,nFrmT)),iStackR,'un',0);
                
% sets the image stack/video stack indices
indS = cellfun(@(x)(find((frmS >= x(:,1)) & ...
                (frmS <= x(:,2)))),sProg0.frmR,'un',0);
sProg0.frmS = cellfun(@(x,y)([floor((x-1)/nFrmS)+1 (mod(x-1,nFrmS)+1) ...
                (frmS(x)-(y-1)*nFrmR)]),indS,iStackR,'un',0);

% % removes any empty elements                
% A = cell2mat(sProg0.frmR); 
% ii = (A(:,2)-A(:,1)) > 0;
% [sProg0.frmS,sProg0.frmR,sProg0.isRead] = ...
%                 deal(sProg0.frmS(ii),sProg0.frmR(ii),sProg0.isRead(ii));

sProg0.nFrmRS = find(cellfun(@(x)(any(x(:,1) == 2)),sProg0.frmS),1,'first')-1; 
if (isempty(sProg0.nFrmRS))
    sProg0.nFrmRS = length(sProg0.frmS);
end

% ------------------------------ %
% --- PROGRESS STRUCT UPDATE --- %
% ------------------------------ %                
            
% determines if the progress file has been set
pFile = fullfile(tDir,'Progress.mat');
if exist(pFile,'file') == 0 || ~solnChk
    [sProg,solnChk] = deal(sProg0,false);     
    save(pFile,'sProg');    
else
    % otherwise, load the progress file
    A = load(pFile); sProg = A.sProg;
end    

% checks to see if the current movie matches the progress file stack (only
% if checking the solution)
if solnChk
    if ~strcmp(sProg0.movFile,sProg.movFile)
        % if the current and stored movie file names do not match, then delete
        % the image stack and reset the progress file
        sProg = sProg0;
        save(pFile,'sProg');   
    end                
end
