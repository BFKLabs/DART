% --- loads a combined solution file --- %
function [snTot,ok] = loadExptSolnFiles...
                            (TempDir,fName,sepData,handles,ind,indApp,h)

% sets the waitbar figure title
[p0,ok] = deal(0.2,true);

% ------------------------------- %
% --- SOLUTION FILE UNTARRING --- %
% ------------------------------- %

% removes any previous files
a = [dir(fullfile(TempDir,'*.mj2'));dir(fullfile(TempDir,'*.mat'))];
if ~isempty(a)
    aa = cellfun(@(x)(fullfile(TempDir,x)),field2cell(a,'name'),'un',0);
    cellfun(@delete,aa)
end

% unzips the files to the temporary directory
A = untar(fName,TempDir);
fNameS = cellfun(@(x)(getFileName(x)),A,'un',0);

% determines the data and x/y position files in the solution file
indD = cellfun(@(x)(strContains(x,'Data')),fNameS);
indX = find(cellfun(@(x)(strContains(x,'Px')),fNameS));
indY = find(cellfun(@(x)(strContains(x,'Py')),fNameS));
indP = find(cellfun(@(x)(strContains(x,'Pp')),fNameS));  
% indN = find(cellfun(@(x)(strContains(x,'Pa')),fNameS));

% ------------------------- %
% --- DATA FILE LOADING --- %
% ------------------------- %

% loads the base data file
switch nargin
    case (3) 
        % case is loading from single combined solution files
        wStr = {'Loading Data File','Current File Progress'};
        [indApp,wOfs,isSave] = deal([],0,false);
        h = ProgBar(wStr,'Loading Experimental Solution File'); 
        
    case (4) 
        % case is loading from multiple combined solution files
        [indApp,wOfs,isSave,h] = deal([],1,false,handles);
        
    case (7)
        % case is save the combined solution files, so need reshaping
        [isSave,wOfs] = deal(true,1);
        
    otherwise
        [snTot,ok] = deal([],false);
        return
end

% memory allocation
[anyY,anyP] = deal(~isempty(indY),~isempty(indP));
pS = [p0 (1-p0)/(1+(anyY+anyP))];

% loads the base solution file
if h.Update(1+wOfs,'Loading Base Data File...',p0)
    % if the user cancelled, then exit the function
    [snTot,ok] = deal([],false);
    return 
    
else
    % otherwise, load the file data file
    snTot = load(fullfile(TempDir,fNameS{indD}));
    if ~isfield(snTot,'Type')
        % sets the type if it hasn't been set
        snTot.Type = 0; 
        snTot = orderfields(snTot);
    end
    
    % check to see if the solution file obsolete
    if checkIfSolnObsolete(snTot)
        % if the file is obsolete, then output a message to screen 
        switch nargin
            case (3)
                eStr = {['This single experimental solution file ',...
                         '(.ssol) has an obsolete format.'];'';...
                        ['You will need to recombine the .ssol file ',...
                         'before being able to analyse the data ',...
                         'within the DART Analysis GUI.']};                    
            case (4)
                eStr = {['The current single experimental solution ',...
                         'file (.ssol) within this multi-experiment ',...
                         'solution file (.msol) has an obsolete format.'];'';...
                        ['You will need to recombine the .ssol ',...
                         'file(s) before being able to analyse the ',...
                         'data within the DART Analysis GUI.']};                     
            case (7)
                eStr = {['The current single experimental solution ',...
                         'file (.ssol) within this multi-experiment ',...
                         'solution file (.msol) has an obsolete format.'];'';...
                        ['You will need to recombine the .ssol ',...
                         'file(s) before being able to combine the ',...
                         'data within the DART Data Combining GUI.']};                                     
        end
                 
        % exit the function with a false flag
        waitfor(errordlg(eStr,'Obsolete Solution File Format','modal'));
        [snTot,ok] = deal([],false);
        return  
        
    elseif isSave
        % calculates the reshaping the solution struct        
        nFrame = cellfun(@length,snTot.T);
        iParaR = setupReshapeParaStruct(handles,snTot,ind);            
        snTot = reshapeSolnStruct(snTot,iParaR,1);

        % sets the indices to be re-read            
        indFrm = (sum(nFrame(1:(iParaR.indS(1)-1)))+iParaR.indS(2)):...
                 (sum(nFrame(1:(iParaR.indF(1)-1)))+iParaR.indF(2));
    else
        ii = find(~isnan(field2cell(snTot.pMapPx,'nFrame',1)),1,'first');        
        indFrm = (1:snTot.pMapPx(ii).nFrame);
    end
end    

% reshape the index array to only include those to output
if ~isempty(indApp) 
    indX = indX(indApp);
    if ~isempty(indY); indY = indY(indApp); end
    if ~isempty(indP); indP = indP(indApp); end
%     if ~isempty(indN); indN = indN(indApp); end
end

% load the fly X-locations
h.Update(1+wOfs,'Recalculating X-Locations...',pS(1));
h.Update(2+wOfs,'Fly X-Location Reading',0);
snTot.Px = retMoviePos(snTot.pMapPx,A(indX),indFrm,h);
        
% if the user cancelled while reading the X-locations, then exit
% the function
if isempty(snTot.Px)
    [snTot,ok] = deal([],false);
    return               
else
    h.Update(2+wOfs,'Fly X-Location Reading Complete!',1);
end    

% determines if the Y-values need to be loaded (if there are any files)
if anyY
    % otherwise, load the fly locations
    h.Update(1+wOfs,'Recalculating Y-Locations...',pS(1)+pS(2));
    h.Update(2+wOfs,'Fly Y-Location Reading',0);    
    snTot.Py = retMoviePos(snTot.pMapPy,A(indY),indFrm,h);               
        
    % if the user cancelled while reading the X-locations, then 
    % exit the function    
    if isempty(snTot.Py)
        [snTot,ok] = deal([],false);
        return         
    else
        h.Update(2+wOfs,'Fly Y-Location Reading Complete!',1);
    end            
else
    % otherwise, set an empty array for the y-locations
    [snTot.Py,snTot.pMapPy] = deal([]);
end

% determines if the Y-values need to be loaded (if there are any files)
if anyP
    % otherwise, load the fly locations
    h.Update(1+wOfs,'Recalculating Orientation Angle...',pS(1)+2*pS(2));
    h.Update(2+wOfs,'Fly Orientation Angle Reading',0);    
    snTot.Phi = retMoviePos(snTot.pMapPhi,A(indP),indFrm,h);               
        
    % if the user cancelled while reading the X-locations, then 
    % exit the function    
    if isempty(snTot.Phi)
        [snTot,ok] = deal([],false);
        return         
    else
        h.Update(2+wOfs,'Fly Orientation Angle Reading Complete!',1);
    end            
end

% resets the actual fly count (if not set properly)
if isfield(snTot,'iMov')
    if isfield(snTot.iMov,'nTubeR')
        nFlyS = cellfun(@(x)(size(x,2)),snTot.Px(:));
        if ~isequal(snTot.iMov.nTubeR,nFlyS)
            snTot.iMov.nTubeR = nFlyS;
        end
    end
end

% creates the stimuli train timing/parameter structs (if missing)
if ~isfield(snTot,'stimP')
    [snTot.stimP,snTot.sTrainEx] = getExptStimInfo(snTot);
end

% % determines if the Y-values need to be loaded (if there are any files)
% if anyN
%     % otherwise, load the fly locations
%     h.Update(1+wOfs,'Recalculating Object Size...',pS(1)+2*pS(2));
%     h.Update(2+wOfs,'Object Size Reading',0);    
%     snTot.AxR = retMoviePos(snTot.pMapAxR,A(indN),indFrm,h);               
%         
%     % if the user cancelled while reading the X-locations, then 
%     % exit the function    
%     if isempty(snTot.AxR)
%         [snTot,ok] = deal([],false);
%         return         
%     else
%         h.Update(2+wOfs,'Object Size Reading Complete!',1);
%     end            
% end

% initialises the region parameter information field (if not set)
if isfield(snTot.iMov,'pInfo')
    % converts the data value arrays for the new format files
    if sepData
        snTot = convertDataArrays(snTot);
    end
    
    % removes the mapping array fields
    [snTot.pMapPx,snTot.pMapPy] = deal([]);
else
    % sets the 2D flag
    snTot.iMov.is2D = anyY;
    
    % sets up the region data struct based on the type
    if ~isequal(size(snTot.iMov.flyok),size(snTot.appPara.flyok))
        % case is the expt solution file is from a multi-expt file
        snTot.iMov.pInfo = getMultiRegionDataStructs(snTot);
    else
        % case is the expt solution file is loaded separately
        snTot = separateCombinedGroups(snTot);
        snTot.iMov.pInfo = getRegionDataStructs(snTot.iMov,snTot.appPara);         
    end       
    
    % sets up the fly location ID array
    snTot.cID = setupFlyLocID(snTot.iMov);
end

% % removes any extraneous fields
% if isfield(snTot,'sName')
%     snTot = rmfield(snTot,'sName');
% end

% updates the waitbar figure
snTot = orderfields(snTot);
h.Update(1+wOfs,'Recalculation Complete!',1); 
pause(0.05);
    
% closes the waitbar figure
if wOfs == 0
    try; h.closeProgBar(); end
end
   
% --- checks if the old file is obsolete. if so, then the user will have to
%     recombine the single experimental solution file
function isObs = checkIfSolnObsolete(snTot)

% initialisations
isObs = false;

% obsolete files are only 2D experiments if > 1 row
if isfield(snTot,'iMov')
    if (snTot.iMov.nRow > 1) && is2DCheck(snTot.iMov)    
        if ~iscell(snTot.iMov.iR{1})
            % determines the range in the y-mapping parameters/row indices
            yRng = range(field2cell(snTot.pMapPy,'xMin',1)/snTot.sgP.sFac);   
            rMax = max(cellfun(@(x)(diff(x([1 end]))),snTot.iMov.iR(:))); 

            % is obsolete if the row index range is > y-value range
            isObs = rMax > yRng;
        end        
    end
else
    % if the region data struct is missing then considered obsolete
    isObs = true;
end

% --- converts the data array fields so that they match the original
%     data array dimensioning
function snTot = convertDataArrays(snTot)

% initialisations
cID = snTot.cID;
iMov = snTot.iMov;
pInfo = iMov.pInfo;
nFrm = size(snTot.Px{1},1);

% sets the data array fields to 
pFld = {'Px'};
if iMov.is2D
    pFld = [pFld,{'Py'}]; 
    if iMov.calcPhi
        pFld = [pFld,{'Phi','axR'}]; 
    end
end

% converts data arrays (for all the specified fields
for i = 1:length(pFld)
    % retrieves the struct field
    if isfield(snTot,pFld{i})
        Z0 = getStructField(snTot,pFld{i});

        % converts the data arrays based on the type
        if iMov.is2D
            % case is the 2D experimental setup        
            Zf = repmat({NaN(nFrm,pInfo.nRow)},1,pInfo.nCol);        
            for j = 1:length(cID)            
                for k = 1:size(cID{j},1)
                    [iRow,iCol] = deal(cID{j}(k,1),cID{j}(k,2));
                    Zf{iCol}(:,iRow) = Z0{j}(:,k);
                end
            end                

        else
            % case is the 1D experimental setup

            % memory allocation
            nRowMx = size(snTot.iMov.flyok,1);
            szG = [pInfo.nRow,pInfo.nCol];        

            % allocates memory for each region  
            Zf = repmat({NaN(nFrm,nRowMx)},1,prod(szG));

            % sets the data values for each grouping
            for j = 1:length(cID)    
                iApp = (cID{j}(:,1)-1)*pInfo.nCol + cID{j}(:,2);        
                for k = 1:size(cID{j},1)
                    Zf{iApp(k)}(:,cID{j}(k,3)) = Z0{j}(:,k);
                end
            end            

        end   

        % resets the solution struct field   
        snTot = setStructField(snTot,pFld{i},Zf);
    end
end