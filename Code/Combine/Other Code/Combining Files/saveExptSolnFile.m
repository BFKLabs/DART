% --- saves the data in the experimental solution file, snTot, to the 
%     combined solution file, fName --- %
function ok = saveExptSolnFile(dDir,fName,snTot,h,varargin)

% initialisations
ok = true;
tmpFile = fullfile(dDir,'TempOutput.mat');
tmpFileTar = fullfile(dDir,'TempOutput.tar');

% removes any previous files
a = dir(fullfile(dDir,'*.mat'));
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

% creates the waitbar figure
if exist('h','var')
    % case is multiple experiment solution files are being output 
    wOfs = 1+(nargin==5);
else
    % otherwise, create the waitbar figure within the function
    wStr = {'Overall Progress','Saving Temporary File'};
    [h,wOfs] = deal(ProgBar(wStr,'Saving Experimental Solution Files'),0);
end

% pause for update...
pause(0.05);

% ---------------------------- %
% --- SOLUTION FILE OUTPUT --- %
% ---------------------------- %
    
% updates the waitbar figure
h.Update(1+wOfs,'Saving Temporary File...',1/3);

% saves the temporary file
save(tmpFile,'snTot')

% updates the waitbar figure
h.Update(1+wOfs,'Creating File Solution File...',2/3);

% creates and renames the tar file to a solution file extension
tar(tmpFileTar,tmpFile)
movefile(tmpFileTar,fName);
pause(0.05);

% updates the waitbar figure
h.Update(1+wOfs,'Performing House-Keeping Operations...',1);

% removes any temporary files
if exist(tmpFile,'file'); delete(tmpFile); end
if exist(tmpFileTar,'file'); delete(tmpFileTar); end

% closes the waitbar figure (if created in the function)
if wOfs == 0; h.closeProgBar(); end