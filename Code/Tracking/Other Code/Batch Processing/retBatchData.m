% --- retrieves the batch processing data          
function bData = retBatchData(handles,dirName,baseDir) 

% initialises the batch processing data struct
ProgDef = getappdata(handles.figBatchProcess,'ProgDef');
bData = struct('MovDir',[],'SolnDir',[],'SolnDirName',[],...
               'mName',[],'sName',[],'sfData',[],'movOK',[],...
               'Img0',[],'dpImg',[]);

% removes any path seperators from the end of the directory names
if (strcmp(dirName(end),'/') || strcmp(dirName(end),'\'))
    dirName = dirName(1:end-1);
end
           
% finds any movie files in the directory
bData.MovDir = dirName;
mFile = detectMovieFiles(dirName);  

% sets the full movie names from the selected directory and the
% comparison movie name
bData.mName = cellfun(@(x)(fullfile(dirName,x)),field2cell(mFile,'name'),'un',0);
bData.sName = fullfile(dirName,getSummFileName(dirName));

% sets the solution file output directory name
dirPart = getDirSuffix(dirName);
if (nargin < 3)
    if (isempty(bData.SolnDir))
        % if the solution directory is not set, then set the base
        % directory to be the default solution directory
        baseDir = ProgDef.DirSoln;
    else
        % otherwise, split up the solution directory string
        [baseDir,~,~] = fileparts(bData.SolnDir);
    end
end
    
% updates the solution file string
[bData.SolnDir,bData.SolnDirName] = deal(baseDir,dirPart);  
bData.sfData = struct('isOut',false,'Type','Append','tBin',60);
bData.movOK = ones(length(bData.mName),1);
