% --- retrieves the batch processing information from the incomplete batch
%     processing directories. for a batch processing to be feasible, it
%     must have A) the movie/solution file directories on the current
%     machine), B) have at least one solution file present, and C) the
%     number of solution files is less than the current number of movies
function [bpData,isSeg] = getFeasBatchProcessDir(sDir,redoAll) 

% sets the search directory to be the working directory (if not provided)
if nargin == 0
    sDir = getProgFileName();
end

% creates the waitbar figure
wStr = {'Determining Batch Processing Directories...'};
h = ProgBar(wStr,'Retrieving Batch Processing Data'); pause(0.01);

% retrieves the batch processing directories
bpDir = detBatchProcessDir(sDir);

% memory allocation
nFile = length(bpDir);
[isOK,bpData,isSeg] = deal(true(nFile,1),cell(nFile,1),cell(nFile,1));

% checks each of the batch processing files to determine if they can/need
% to be processed further
for i = 1:nFile
    % updates the waitbar figure
    wStr = sprintf('Reading Batch Processing Data (%i of %i)',i,nFile);
    if h.Update(1,wStr,0.5*(1+(i/nFile)))
        % if the user cancelled, then exit the function
        [bpData,isSeg] = deal([]);
        return
    end
    
    % loads the batch processing file
    A = load(fullfile(bpDir{i},'BP.mat'));
    
    % determines if the current batch processing directory is feasible
    if ~exist(A.bData.MovDir,'dir')
        % if the movie/solution file directories do not exist on the
        % local machine, then flag that the file is not feasible
        isOK(i) = false;
    else
        % otherwise, retrieves the file data of the movie/solution files in
        % their respective directories        
        movFile = detectMovieFiles(A.bData.MovDir);
        solnFile = dir(fullfile(bpDir{i},'*.soln'));
        
        % checks to see if the directory is still feasible
        if isempty(solnFile)
            % if there are no solution file present, then flag that the
            % directory is not feasible for batch processing
            isOK(i) = false;
        elseif (length(solnFile) > length(movFile))            
            % if the number of solutions is greater than or equal to the
            % number of movies, then flag that batch processing is not
            % required on that directory
            isOK(i) = false;                        
        else
            % determines which videos are fully segmented
            isSeg{i} = detSegmentedVideos(bpDir{i},movFile,solnFile);            
            
            % if all of the solution files have been segmented, then flag
            % that the solution directory does not need resegmenting
            if all(isSeg{i}) && (~redoAll || (length(isSeg{i}) > 1))
                isOK(i) = false;
            elseif ~exist(A.bData.sName,'file')
                % determines if the summary file need to be updated
                sStrM = fullfile(A.bData.MovDir,'Summary.mat');
                if exist(sStrM,'file')
                    % if the file exists, then set the summary file as that
                    A.bData.sName = sStrM;
                else
                    % sets the solution file directory summary file
                    sStrS = fullfile(bpDir{i},'Summary.mat');
                    if exist(sStrS,'file')
                        % if the solution file directory summary file
                        % exists, then reset that as the summary file
                        A.bData.sName = sStrS;
                    else
                        % otherwise, flag that the BP is infeasible
                        isOK(i) = false;
                    end
                end                
            end                                    
        end
        
        % set the batch processing data for the file (if ok)
        if isOK(i)
            % checks the final videos (to see if they are actually not 
            % corrupted or too short)
            isFeas = detFeasibleVideos(movFile);
            isSeg{i} = isSeg{i}(isFeas);            
            if all(isSeg{i})
                % if the reduced set has all been segmented, then reset the
                % video flag to false
                isOK(i) = false;
            else
                % otherwise, reduces down the feasible video files
                movFile = movFile(isFeas);
                A.bData.mName = A.bData.mName(isFeas);
                A.bData.movOK = A.bData.movOK(isFeas);
                A.bData.dpImg = A.bData.dpImg(isFeas);

                % sets the batch processing fields
                bpData{i} = A.bData;
                bpData{i}.SolnDirName = getFinalDirString(bpDir{i});
                [bpData{i}.SolnDir,~,~] = fileparts(bpDir{i});                
                bpData{i}.mName = cellfun(@(x)(fullfile...
                    (A.bData.MovDir,x)),field2cell(movFile,'name'),'un',0);
                bpData{i}.sName = fullfile(bpData{i}.MovDir,'Summary.mat');

                % ensures the video status flag array has been set
                if ~isfield(bpData{i},'movOK')
                    bpData{i}.movOK = ones(length(bpData{i}.sName),1);
                end
            end
        end        
    end
end

% resets the batch processing cell array
if ~any(isOK)
    % no valid batch processing so exit the function with empty arrays
    [bpData,isSeg] = deal([]);
    h.closeProgBar();
    return
else
    % otherwise, reduce down the arrays 
    [bpData,isSeg] = deal(bpData(isOK),isSeg(isOK));
end

% determines if all of the fields have been set
nF = cellfun(@(x)(length(fieldnames(x))),bpData);
if range(nF) > 0
    % determines the field that contains all of the fields and retrieves
    % the names of these fields
    imx = find(nF == max(nF),1,'first');
    fStr = fieldnames(bpData{imx})';
    
    % determines if the 
    for i = 1:length(nF)
        if nF(i) ~= max(nF)
            % adds in the missing fields and reorders them
            if ~isfield(bpData{i},'sfData')
                bpData{i}.sfData = struct('isOut',0,'Type','Append','tBin',60);
                bpData{i} = orderfields(bpData{i},fStr);
            end
            
            % adds in 
            if ~isfield(bpData{i},'Img0')
                nMov = length(bpData{i}.mName);
                bpData{i}.Img0 = [];
                bpData{i}.dpImg = zeros(nMov,2);
                bpData{i} = orderfields(bpData{i},fStr);
            end
        end
    end
else
    fStr = fieldnames(bpData{1});
    for i = 2:length(bpData)
        bpData{i} = orderfields(bpData{i},fStr);
    end
end

% combines the cell arrays into the final struct array
bpData = cell2mat(bpData);

% closes the waitbar figure
h.closeProgBar();

% --- determines the feasible videos from the list, movDir
function isFeas = detFeasibleVideos(movFile)

% memory allocation
nFrmMin = 10;
nFile = length(movFile);
fDir = movFile(1).folder;
isFeas = true(length(movFile),1);

% determines the feasible video files
for iFile = nFile:-1:1
    % determines if the current file is feasible
    vFile = fullfile(fDir,movFile(iFile).name);
    [mObj,vObj,isFeas(iFile)] = setupVideoObject(vFile,1);
    
    % if feasible, then determine if the video has feasible length
    if isFeas(iFile)        
        [~,~,fExtn] = fileparts(vFile);
        nFrmT = getVideoFrameCount(mObj,vObj,fExtn);
        isFeas(iFile) = nFrmT > nFrmMin;
        
        if isFeas(iFile)
            break
        end
    end
end

% --- determines which videos have been segmented (for a given directory)
function isSeg = detSegmentedVideos(bpDir,movFile,solnFile)

% memory allocation
isSeg = false(length(movFile),1);                

% determines which of the solution files have been segmented
for j = length(solnFile):-1:1
    % loads the solution file and checks that the positional
    % data has been calculated. if not, then flag that the
    % solution file has not been segmented
    sNameNw = fullfile(bpDir,solnFile(j).name);
    B = load(sNameNw,'-mat','pData');                
    if isempty(B.pData)
        if j ~= 1
            delete(sNameNw);
        end
    else
        % determines if the current video has been entirely segmented
        isSeg(j) = all(B.pData.isSeg);
        if isSeg(j)
            % if so, then flag the previous have also been segmented and
            % exit the function
            isSeg(1:(j-1)) = true;
            break
        end
    end
end
