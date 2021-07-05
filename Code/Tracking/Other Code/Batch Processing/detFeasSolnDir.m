% --- determines the feasible solution directories for combining --- %
function [fDir,fFileGrp,tOfs] = detFeasSolnDir(fDir,fFileGrp)

% parameters
Tmax = 60;          % maximum time between 

% memory allocation
nDir = length(fDir);
isFeas = false(nDir,1);
[T0,TF] = deal(NaN(nDir,6));

% creates the waitbar figure
wStr = {'Scanning Candidate Directories'};
h = ProgBar(wStr,'Determining Directory Feasibility',1);

% loops through each of the directories
for i = 1:nDir
    % updates the waitbar figure
    wStrNw = sprintf('%s (Directory %i of %i)',wStr{1},i,nDir);
    h.Update(1,wStrNw,i/nDir);
    
    % determines all the solution files in the new directory
    solnDir = dir(fullfile(fDir{i},'*.soln'));
    smFile = fullfile(fDir{i},'Summary.mat');
    
    %
    if ~exist(smFile,'file')
        % if the solution file summary file does not exist, then determine
        % if the summary file exists in the movie file directory
        sFile0 = fullfile(solnDir(1).folder,solnDir(1).name);
        sData = importdata(sFile0,'-mat');
        
        % if the sumrry file does exist, then copy it over to the 
        smFileV = fullfile(sData.fData.folder,'Summary.mat');
        if exist(smFileV,'file')
            copyfile(smFileV,fDir{i});
        end
    end
    
    % if there are solution files and a summary file, then determines the
    % start/finish time of the experiment
    if ~isempty(solnDir) && exist(smFile,'file')
        % loads the summary file data and determines the last feasible
        % movie
        aa = load(smFile,'tStampV','iExpt');
        [tStampV,iExpt] = deal(aa.tStampV,aa.iExpt);
        dT = 1/aa.iExpt.Video.FPS;
        
        % determines the first feasible video index
        i0 = find(~isnan(cellfun(@(x)(x(1)),tStampV)),1,'first');                
        if isempty(i0)
            % sets the initial index and time offset
            [tOfs,i0] = deal(0,1);
            
            % sets the time stamps for each of the videos
            for j = 1:length(tStampV)
                tStampV{j} = tOfs + dT*((1:length(tStampV{j}))'-1);
                tOfs = tStampV{j}(end) + aa.iExpt.Timing.Tp;
            end
        end
        
        % sets the last feasible video index
        iFin = find(~isnan(cellfun(@(x)(x(end)),tStampV)),1,'last');
        
        T0new = iExpt.Timing.T0;
        if (T0new(1) < 0)            
            a = dir(smFile); b = datevec(a.datenum);
            T0new = abs(T0new); T0new(1) = b(1);
        end
        
        % sets the experiment start/finish times
        T0dir = tStampV{i0}(1);
        T0(i,:) = datevec(addtodate(datenum(T0new),floor(T0dir),'second'));        
        TF(i,:) = datevec(addtodate(datenum(T0(i,:)),...
                                 ceil(tStampV{iFin}(end)-T0dir),'second'));
        
        % flag that the directory is feasible
        isFeas(i) = true;
    end
end

% closes the waitbar figure
h.closeProgBar();

% if there are no feasible directories, then return an empty array
if ~any(isFeas)  
    % if there are no feasible directories, then display an error
    fDir = [];
    eStr = ['The selected directories either have no solution files ',...
            'or the experiment "Summary.mat" file is missing.'];
    waitfor(errordlg(eStr,'Batch Processing Feasibility Error','modal'))
    
    % exits the function
    return
    
elseif nDir == 1
    % if there is one directory and it is feasible, then exit
    return
    
else
    % otherwise, sort the start times by ascending order
    [~,ii] = sort(datenum(T0),'ascend');
    [T0,TF,isFeas,fDir] = deal(T0(ii,:),TF(ii,:),isFeas(ii),fDir(ii));
end

% sets the indices where experiments can be grouped
[indG,i] = deal(cell(nDir,1),1);
while (i < nDir)
    % while there are still directories to search, determine if there are
    % any 
    [j,cont] = deal((i+1),true);
    while (cont)
        % calculates the time difference between two adjacent solution file
        % directories
        dT = calcTimeDifference(T0(j,:),TF(j-1,:));
        if (dT < 0) || (dT > Tmax*60)
            % if the time difference is not feasible, then exit the loop
            cont = false;
        else
            % adds the new grouping index and increments the counter
        	[indG{i},j] = deal([indG{i},j],j+1);
            if (j > nDir)
                cont = false;
            end
        end
    end
    
    % updates the counter
    i = j;
    if (i < nDir)
        % if the next directory is not feasible then exit
        if (~isFeas(i))
            break
        end
    end
end

% determines the 
nGrp = cellfun(@length,indG);
jj = find(nGrp>0);

% determines the number of multi-experiments that were selected
switch length(jj)
    case 0 % no feasible multi-experiment detected
        [fDir,fFileGrp] = deal([]);
        eStr = 'No feasible solution file directories were selected';
        waitfor(errordlg(eStr,'Batch Processing Feasibility Error','modal'))    
        
    case 1 % unique multi-experiment found
        kk = [jj,indG{jj}];
        [fDir,fFileGrp] = deal(fDir(kk),fFileGrp(kk));        
        T0 = num2cell(T0(kk,:),2);
        tOfs = cellfun(@(x)(calcTimeDifference(x,T0{1})),T0);
        
    otherwise % more than one feasible multi-experiment detected
        [fDir,fFileGrp] = deal([]);
        eStr = 'More than one multi-experiment selected. Please refine selection';
        waitfor(errordlg(eStr,'Batch Processing Feasibility Error','modal'))        
end
