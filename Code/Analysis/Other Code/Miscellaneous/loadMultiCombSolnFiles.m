% --- loads a multi-combined solution file --- %
function [snTot,sName,ok] = loadMultiCombSolnFiles(TempDir,mName,ind)

% ------------------------------- %
% --- SOLUTION FILE UNTARRING --- %
% ------------------------------- %

% creates a waitbar figure
wStr = {'Overall Progress','Current File Progress','Data Output'};
h = ProgBar(wStr,'Loading Experimental Solution File'); 
setObjVisibility(h.hFig,'on')  

% unzips the files to the temporary directory
if ~iscell(mName)
    wStrNw = sprintf('%s (%s)',wStr{1},'Loading Experimental Solution File');
    h.Update(1,wStrNw,0);    
    A = untar(mName,TempDir);   
    
else    
    wStrNw = sprintf('%s (%s)',wStr{1},'Copying Experimental Solution File');
    h.Update(1,wStrNw,0);
    cellfun(@(x)(copyfile(x,TempDir)),mName);
    mNameBase = cellfun(@(x)(getFileName(x)),mName,'un',0);
    A = cellfun(@(x)(fullfile(TempDir,[x,'.ssol'])),mNameBase,'un',0);
end
    
% array indexing and memory allocation
sName = cellfun(@(x)(getFileName(x)),A,'un',0);
nFile = length(sName);

% sets the indices for loading the solution files
if nargin == 2; ind = 1:nFile; end        

% ------------------------- %
% --- DATA FILE LOADING --- %
% ------------------------- %

% memory allocation
nSoln = length(ind);
snTot = cell(nSoln,1);

% loads all the combined solution files
for i = 1:nSoln
    % updates the waitbar figure
    wStrNw = sprintf('%s (File %i of %i)',wStr{1},i,nSoln);
    h.Update(1,wStrNw,(i+1)/(nSoln+2));

    % loads the current solution file
    [snTot{i},ok] = loadCombSolnFiles(TempDir,A{ind(i)},h);
    if ~ok
        % if the user cancelled, then exit the function
        cellfun(@delete,A)
        return
    else        
        % initialisations
        nFly = cellfun(@(x)(size(x,2)),snTot{i}.Px);        
        if ~iscell(snTot{i}.appPara.flyok)
            snTot{i}.appPara.flyok = num2cell(snTot{i}.appPara.flyok,1);
        end
        
        % check to see if the accept/reject flags have been set correctly
        isOk = cellfun(@(x)(sum(x)),snTot{i}.appPara.flyok);
        nOk = cellfun(@(x)(length(x)),snTot{i}.appPara.flyok);        
        if ~isequal(nOk,isOk) && isequal(isOk,nFly)
            % if not, then reset them
            snTot{i}.appPara.flyok = ...
                            cellfun(@(x)(true(x,1)),num2cell(isOk),'un',0);
        end
    end
end
    
% deletes the temporary solution files
cellfun(@delete,A)

% determines the fields for each of the solution files
fStr = cellfun(@(x)(fieldnames(x)),snTot,'un',0);
nStr = cellfun(@length,fStr);

% determines if there are any missing fields
if range(nStr) ~= 0
    % if so, determine which solution files are missing fields
    fStrT = unique(cell2cell(fStr));
    i0 = nStr(:)' ~= length(fStrT);    
    
    % for each of these solution files add in the missing fields
    for i = find(i0)
        for j = find(~cellfun(@(x)(any(strcmp(x,fStr{i}))),fStrT(:)'))
            switch (fStrT{j})
                % updates the fields based on the field type
                case ('Type') % case is the type field
                    ii = cellfun(@(x)(any(strcmp(x,'Type'))),fStr);
                    if (~any(ii))
                        % if there are no other matches, then set the field
                        % type to 0 (flags an older solution file type)
                        snTot{i}.Type = 0;
                    else
                        % otherwise, update to the field value from a
                        % matching solution file
                        snTot{i}.Type = snTot{find(ii,1,'first')}.Type;
                    end
                otherwise % case is the other field types
                    eval(sprintf('snTot{i}.%s = [];',fStrT{j}));
            end
        end
        
        % re-orders the fields so that they are in the correct order
        snTot{i} = orderfields(snTot{i},snTot{find(~i0,1,'first')});
    end
end

% converts the cell array to a struct and closes the waitbar figure
snTot = cell2mat(snTot);
h.Update(1,'Multi-Experimental Solution File Load Complete!',1);
h.closeProgBar();

