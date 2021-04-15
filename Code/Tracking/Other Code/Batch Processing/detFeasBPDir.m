% --- scans the summary files to determine which experiments can feasibly
%     combined into a single batch processing
function [bpData,sData,ind0,isChange] = detFeasBPDir(handles,scDir)

% retrieves the current 
bpData = getappdata(handles.figBatchProcess,'bpData');
sData = getappdata(handles.figBatchProcess,'sData');
ind0 = getappdata(handles.figBatchProcess,'ind0');

% memory allocation
[nFileNw,isChange] = deal(length(scDir),false);
[sDataNw,ok] = deal(cell(nFileNw,1),zeros(nFileNw,1));

% ensures the directory names are a row cell array
scDir = reshape(scDir,nFileNw,1);
scDir0 = field2cell(bpData,'MovDir');
bDir = bpData(ind0).SolnDir;

% if any of the directories are repeats, then flag them as being so
for i = 1:length(scDir)
    if (any(strcmp(scDir{i},scDir0)))
        ok(i) = 4;
    end
end

% if all the directories are infeasible, then output an error and exit
if (all(ok))
    eStr = getErrorString(ok,scDir);
    waitfor(errordlg(eStr,'Batch Processing Feasibility Error','modal'))
    return    
end

% creates the waitbar figure
wStr = {'Determining Batch Processing Directories Feasibility...'};
h = ProgBar(wStr,'Retrieving Batch Processing Data'); pause(0.01);

% retrieves the summary file data from the new directories
for i = 1:nFileNw
    % updates the waitbar figure
    wStr = sprintf('Batch Processing Directory (%i of %i)',i,nFileNw);
    if h.Update(1,wStr,i/nFileNw)
        % if the user cancelled, then exit the function
        bpData = [];
        return
    end    
    
    % sets the new summary file path
    if (ok(i) == 0)        
        smFile = fullfile(scDir{i},'Summary.mat');
        if (~exist(smFile,'file'))
            % if the file does not exist, then flag the directory is infeasible
            ok(i) = 1;
        else
            % determines if there are any movie files in the directory            
            mFile = detectMovieFiles(scDir{i});
            if (isempty(mFile))
                % if not, then flag that the directory has no movies
                ok(i) = 2;
            else
                % loads the summary file and retrieves the data from it
                sDataNw{i} = orderfields(load(smFile));
                if (~isfield(sDataNw{i},'sData'))
                    sDataNw{i}.sData = [];
                    sDataNw{i} = orderfields(sDataNw{i});
                end
            end
        end
    end
end

% if all the directories are infeasible, then output an error and exit
if all(ok)
    h.closeProgBar();
    eStr = getErrorString(ok,scDir);
    waitfor(errordlg(eStr,'Batch Processing Feasibility Error','modal'))        
    return    
end

% determines the feasible directories and resets the data structs
jj = find(ok == 0);
sDataNw = sDataNw(jj);

% converts the cell array to a struct array
sDataNw = cell2mat(sDataNw);
iExptNw = field2cell(sDataNw,'iExpt',1); 

% reorders the selected arrays by their chronological order
T0Nw = field2cell(field2cell(iExptNw,'Timing',1),'T0');
[~,ii] = sort(cellfun(@(x)(datenum(x)),T0Nw));
sDataNw = sDataNw(ii);

% determines the final feasible movie from each batch processing directory,
% and retrieves the final date-stamp from that movie (i.e., determines the
% final frame date stamp over the entire movie)
tStampV = field2cell(sDataNw,'tStampV'); 
Tf = cellfun(@(x)(x{find(~isnan(...
                    cellfun(@(y)(y(end)),x)),1,'last')}(end)),tStampV);

% determines the 
[cont,isAdd] = deal(true,false(length(Tf),1));
Tlim = num2cell(getExptTimeLimits(sDataNw,1),2);
while cont
    % determines the new time-limits on the overall experiment batch
    % processing, and retrieves 
    Tlim0 = getExptTimeLimits(sData);    
    [Tlow,Tupp] = deal(Tlim0(1,1:2),Tlim0(end,3:4));
           
    % determines the status of the new file wrt the new upper limits
    tStatus = cellfun(@(x)(detTimeStatus(x,Tlow,Tupp)),Tlim);
    if (all(tStatus == 0))
        % exits the loop
        cont = false;
    else
        % if there are any experiments that follow the contiguous group,
        % then add the experiment info to the end of the array
        iNw = find(tStatus == 1);
        if (~isempty(iNw))
            try
                sData(end+1) = sDataNw(iNw);
                bpData(end+1) = retBatchData(handles,scDir{jj(ii(iNw))},bDir);
                isAdd(iNw) = true;
            catch
                a = 1; 
            end
        end
        
        % if there are any experiments that precede the contiguous group,
        % then add the experiment info to the start of the array
        iPr = find(tStatus == -1);
        if (~isempty(iPr))
            sData = [sDataNw(iPr),sData];
            bpData = [retBatchData(handles,scDir{jj(ii(iPr))},bDir),bpData];
            [isAdd(iPr),ind0] = deal(true,ind0+1);
        end        
    end    
end

% flags if a change was made and closes the waitbar figure
isChange = any(~ok);
h.closeProgBar();

% sets the infeasible 
ok(jj(ii(~isAdd))) = 3;
if any(ok)
    eStr = getErrorString(ok,scDir);
    waitfor(errordlg(eStr,'Batch Processing Feasibility Error','modal'))    
end
                
% --- determines the status of the experiments time limits to the feasible
%     lower/upper time limits given in Tlow/Tupp --- %
function tStatus = detTimeStatus(TlimNw,Tlow,Tupp)

% sets the status based on the time and feasibility
if ((TlimNw(2) >= Tlow(1)) && (TlimNw(2) <= Tlow(2)))
    % case is the end of the experiment is within the limits of the start
    % of the entire segmentation
    tStatus = -1;
elseif ((TlimNw(1) >= Tupp(1)) && (TlimNw(1) <= Tupp(2)))
    % case is the end of the experiment is within the limits of the start
    % of the entire segmentation    
    tStatus = 1;
else
    % case is the experiment is not within the time-limits    
    tStatus = 0;
end

% --- retrieves the upper/lower limits 
function Tlim = getExptTimeLimits(sData,varargin)
    
% feasible start/end time for a surrounding experiment (is seconds)
[dTlim,Tlim] = deal(120,zeros(length(sData),4));

% sets the experiment start lower/upper limit times 
for i = 1:length(sData)
    Texp0 = datenum(sData(i).iExpt.Timing.T0);
    Tlim(i,1:2) = [addtodate(Texp0,-dTlim,'second'),Texp0];

    % sets the experiment finish lower/upper limit times 
    iFin = find(~isnan(cellfun(@(x)(x(end)),sData(i).tStampV)),1,'last');
    TexpF = addtodate(Texp0,ceil(sData(i).tStampV{iFin}(end)),'second');
    Tlim(i,3:4) = [TexpF,addtodate(TexpF,dTlim,'second')];
end

% only have the lower/upper limits (if more than one input argument)
if (nargin == 2)
    Tlim = Tlim(:,2:3);
end
   
% --- retrieves the error strings for each of the offending directories - %
function eStr = getErrorString(ok,scDir)

% initialisations
eStr = '';
eStrL = {'do not have summary files';...
         'do not have any movie files to process';...
         'are not feasible for contiguous batch processing';...
         'are repeated directories'};
    
% for each error type, set the offending directories    
for i = 1:length(eStrL)
    iok = find(ok == i);
    if (~isempty(iok))
        % initialises the error string for the current error type
        if ~isempty(eStr)
            eStr = sprintf('%s\n',eStr);
        end
        eStr = sprintf('%sThe following %s:\n\n',eStr,eStrL{i});
        
        % adds the directories for all the offending directories
        for j = 1:length(iok)
            eStr = sprintf('%s    => "%s"\n',eStr,getDirSuffix(scDir{iok(j)}));
        end        
    end
end