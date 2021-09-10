% --- saves the data in the experimental solution file, snTot, to the 
%     combined solution file, fName --- %
function ok = saveExptSolnFileOld(dDir,fName,snTot,oPara,h,varargin)

% initialisations
[nApp,calcPhi] = deal(length(snTot.Px),isfield(snTot,'Phi'));

% sets the output parameter struct (if not provided)
if isempty(oPara)
    oPara = struct('outY',snTot.iMov.is2D);
end

% removes any previous files
a = [dir(fullfile(dDir,'*.mj2'));dir(fullfile(dDir,'*.mat'))];
if ~isempty(a)
    aa = cellfun(@(x)(fullfile(dDir,x)),field2cell(a,'name'),'un',0);
    cellfun(@delete,aa)
end

% determines if there are any quotation marks in the file name. if so, then
% add in an extra quotation mark for each instance
iNw = regexp(fName,[''''],'once');
if ~isempty(iNw)
    for i = length(iNw):-1:1
        fName = [fName(1:iNw(i)),char(39),fName((iNw(i)+1):end)];
    end
end

% sets the field names
isOut = ~cellfun(@isempty,snTot.Px);
B = arrayfun(@(x)(sprintf('Px%i.mj2',x)),1:nApp,'un',0);
[A,tmpFile] = deal(['Data.mat',B],fullfile(dDir,'Temp.tar'));
tarFiles = cellfun(@(x)(fullfile(dDir,x)),A,'un',0);
pW = (length(fieldnames(snTot))-1) + (oPara.outY + calcPhi);

% creates the waitbar figure
if exist('h','var')
    % case is multiple experiment solution files are being output 
    wOfs = 1+(nargin==6);
else
    % otherwise, create the waitbar figure within the function
    wStr = {'Overall Progress',...
            'Current Experiment Progress',...
            'Output Data Field'};
    [h,wOfs] = deal(ProgBar(wStr,'Saving Experimental Solution Files'),0);
end
    
% updates the waitbar figure and creates the x-position movie
h.Update(1+wOfs,'Creating X-Position Movie...',1/pW);
[snTot.pMapPx,ok] = createPosMovie(snTot.Px,tarFiles(2:end),0,h);
if ~ok; return; end

% outputs the y-position video (if 2D)
if oPara.outY
    % updates the waitbar figure
    h.Update(1+wOfs,'Creating Y-Position Movie...',2/pW);

    % sets the new tar files
    C = cellfun(@(x)(sprintf('Py%i.mj2',x)),num2cell(1:nApp),'un',0);
    tarFilesY = cellfun(@(x)(fullfile(dDir,x)),C,'un',0);        
    tarFiles = [tarFiles,tarFilesY];        

    % output the y-position videos. exit the function if cancelled
    [snTot.pMapPy,ok] = createPosMovie(snTot.Py,tarFilesY,0,h);
    if (~ok); return; end  
    
else
    % otherwise, set an empty y-coordinate mapping array
    snTot.pMapPy = [];
end

% removes the fields from the solution struct
snTot = rmfield(snTot,{'Px','Py'});

% outputs the orientation angles (if calculated)
if calcPhi
    % -------------------------------- %
    % --- ORIENTATION ANGLE OUTPUT --- %
    % -------------------------------- %
    
    % updates the waitbar figure
    h.Update(1+wOfs,'Creating Orientation Angle Movie...',3/pW);
    
    % sets the new tar files
    D = cellfun(@(x)(sprintf('Pp%i.mj2',x)),num2cell(1:nApp),'un',0);
    tarFilesP = cellfun(@(x)(fullfile(dDir,x)),D,'un',0);        
    tarFiles = [tarFiles,tarFilesP];   
    
    % output the y-position videos. exit the function if cancelled
    [snTot.pMapPhi,ok] = createPosMovie(snTot.Phi,tarFilesP,1,h);
    if ~ok; return; end  
        
    % removes the fields from the solution struct
    snTot = rmfield(snTot,'Phi');       
    
    % -------------------------- %
    % --- OBJECT SIZE OUTPUT --- %
    % -------------------------- %    

%     if hasAxR
%         % updates the waitbar figure
%         h.Update(1+wOfs,'Creating Object Aspect Ratio Movie...',3/pW);
% 
%         % sets the new tar files
%         D = arrayfun(@(x)(sprintf('Pa%i.mj2',x)),1:nApp,'un',0);
%         tarFilesN = cellfun(@(x)(fullfile(dDir,x)),D,'un',0);        
%         tarFiles = [tarFiles,tarFilesN];   
%     
%         % output the y-position videos. exit the function if cancelled    
%         [snTot.pMapAxR,ok] = createPosMovie(snTot.AxR,tarFilesN,0,h);
%         if ~ok; return; end  
%         
%         % removes the fields from the solution struct
%         snTot = rmfield(snTot,'AxR');            
%     end    
else
    % removes the mapping field
    if isfield(snTot,'pMapPhi')
        snTot = rmfield(snTot,'pMapPhi');
    end
end

% sets the number of fields being output
fStr = fieldnames(snTot);
nField = length(fStr);

% loops through each of the fields outputting the data to file
for i = 1:nField
    % updates the waitbar figure
    wStrNw = sprintf('%s - "%s"',h.wStr{1},fStr{i});
    if h.Update(1+wOfs,wStrNw,(i+1+(oPara.outY+calcPhi))/pW)
        % if the user cancelled, then delete the solution file and exit
        ok = false;
        delete('Data.mat')
        return
        
    else
        % otherwise, reset the other field
        h.Update(2+wOfs,'Output Field To File...',0);
    end
    
    % outputs the data to file
    if i == 1
        % first first field, so save the file
        eStr = sprintf('save(tarFiles{1},''-struct'',''snTot'',''%s'')',...
                        fStr{i});
    else
        % other fields, so append to the solution file
        eStr = sprintf(['save(tarFiles{1},''-struct'',''snTot'',',...
                        '''%s'',''-append'')'],fStr{i});
    end
    
    % resaves the solution file
    eval(eStr);
    h.Update(2+wOfs,'Field Output Complete!',1);
end

% sets the new indices
isOut = [true;repmat(reshape(isOut,length(isOut),1),...
         1+(oPara.outY+calcPhi),1)];

% creates and renames the tar file to a solution file extension
tar(tmpFile,tarFiles(isOut))
movefile(tmpFile,fName);

% deletes the temporary files
for i = 1:length(tarFiles)
    if isOut(i)
        delete(tarFiles{i})
    end
end

% removes any temporary files
if exist(tmpFile,'file'); delete(tmpFile); end

% closes the waitbar figure (if created in the function)
if wOfs == 0; h.closeProgBar(); end