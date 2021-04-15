% --- determines the orphan functions within the program directory
function [orpFile,orpFilePart] = detOrphanFunc()

% sets the file/code directories
% fDir = 'E:\Work\Code\DART\Program\';
fDir = pwd;
[fName,codeDir] = deal('DART.m',fullfile(fDir,'Code'));

% retrieves all the search directories
h = waitbar(0,'Finding Dependent Sub-Directories...');
sDir = sort(searchSubDirectories(codeDir,'search',1));   

% determines all the m-files in the code directory
waitbar(0.33,h,'Finding All M-Files...');
mName = findFileAll(codeDir,'*.m');

% determines all the figure files in the code directory
waitbar(0.66,h,'Finding All Figure Files...');
figName = findFileAll(codeDir,'*.fig');    

% updates and closes the waitbar
waitbar(1,h,'Sub-Directory Search Complete!');
pause(0.25); close(h)    

% sets the m/fig-files into a single array
totFile = sort([mName;figName]);

% determines the dependent m-/fig-files
fcnDep = detAllDepFunc(fName,sDir);

% determines the files that are used by the program, and returns those that
% are not in use
isUse = cellfun(@(x)(any(strcmp(x,fcnDep))),totFile);
isUse(cellfun(@(x)(strContains(x,'toolboxes')),totFile)) = true;

% sets the final orphan strings
orpFile = totFile(~isUse);
orpFilePart = cellfun(@(x)(getFileNames(x)),orpFile,'un',0);

% --- determines the list of all the dependent functions 
function fcnDep = detAllDepFunc(fName,sDir,mNameG,mIndG,mFile)

% global variables
global h nLevel nLevelMx isFound

% if the top function, set the m-file group names/indices
if nargin == 2 
    % creates the waitbar figure
    [nLevel,nLevelMx] = deal(1,10);
    wStr1 = cellfun(@(x)...
                (sprintf('Level %i',x)),num2cell(2:nLevelMx)','un',0);
    wStr0 = [{'Determining M-File/Figure Names'};wStr1];
    h = ProgBar(wStr0,'Function Dependency Determination'); 
    pause(0.1);
    
    % retrieves all the p/m files names from the search directories
    mFile = cellfun(@(x)(fileSearchDir(x,'*.m')),sDir,'un',0);
    mFile = cell2mat(mFile(~cellfun(@isempty,mFile)));
    
    % retrieves all figure files from the search directories
    figFile = cellfun(@(x)(fileSearchDir(x,'*.fig')),sDir,'un',0);
    figFile = cell2mat(figFile(~cellfun(@isempty,figFile)));
    
    % retrieves the m-file/figure file names 
    mName = cellfun(@(x)(getFileNames(x)),field2cell(mFile,'name'),'un',0);
    figName = cellfun(@(x)(getFileNames(x)),field2cell(figFile,'name'),'un',0);
    
    % removes all the built-in functions from the m-file names
    isNB = cellfun(@(x)(~strContains(which(x),'built-in')),mName);    
    [mName,mFile] = deal(mName(isNB),mFile(isNB));    
    isFound = false(length(mName),1);
    
    % groups the m-file names alphabetically and by size
    [mNameG,mIndG] = alphaGroupStrings(mName);        
else
    % increments the level and expands the waitbar figure
    nLevel = nLevel + 1;
end
    
% retrieves the valid file strings groups from the current file
fStrG = getValidFileStrings(fName,mNameG);
ii = ~cellfun(@isempty,mNameG) & ~cellfun(@isempty,fStrG);

% determines the dependent functions within the current function
A = cell(size(mNameG));
A(ii) = cellfun(@(x,y)(cell2mat(cellfun(@(z)(find(strcmp(x,z),1,'first')),...
            num2cell(y),'un',0))),mNameG(ii),fStrG(ii),'un',0); 
jj = ~cellfun(@isempty,A);
        
% sets the indices of the dependent functions (removes the function name)
fcnInd = cell2mat(cellfun(@(x,y)(x(y)),mIndG(jj),A(jj),'un',0));        
if (nLevel == 1)
    % for the top level, remove the primary function (added later)
    ii = cellfun(@(x)(strContains(fName,x)),...
                                field2cell(mFile(fcnInd),'name'));
    mainInd = fcnInd(~ii);
    isFound(mainInd) = true;
end

% removes all the new function indices, and sets the remainder to be true
fcnInd = fcnInd(~isFound(fcnInd));
[isFound(fcnInd),nInd] = deal(true,length(fcnInd));

% determines recursively the function dependecies within the current
j = min(nLevel,nLevelMx);
for i = 1:nInd
    % sets the waitbar function string    
    wStr = sprintf('Level %i ("%s")',nLevel,mFile(fcnInd(i)).name);
    
    % updates the waitbar figure
    h.Update(j,wStr,i/nInd);
            
    % runs the dependency function recursively to determine the function
    % indices within the sub-functions    
    fNameNw = fullfile(mFile(fcnInd(i)).dir,mFile(fcnInd(i)).name);
    detAllDepFunc(fNameNw,sDir,mNameG,mIndG,mFile);
end
        
% decrements the level and appends the new indices
nLevel = nLevel - 1;
if nLevel == 0
    % if this is the top level, then close the waitbar figure. adds in the
    % index of the top level function
    h.closeProgBar()
    
    % determines which figures match the found m-files
    isFound(mainInd) = false;
    isFig = cellfun(@(x)(any(strcmp(mName(isFound),x))),figName);
    
    % sets the final file dependencies
    [mDirF,mNameF] = field2cell(mFile(isFound),{'dir','name'});
    [fDirF,fNameF] = field2cell(figFile(isFig),{'dir','name'});    
    fcnDep = [cellfun(@(x,y)(fullfile(x,y)),mDirF,mNameF,'un',0);...
              cellfun(@(x,y)(fullfile(x,y)),fDirF,fNameF,'un',0)];
          
    % sorts to make nice...
    fcnDep = sort(fcnDep);
    
else
    % otherwise, collapse the row    
    h.Update(j,sprintf('Level %i',j),0);
end

% --- retrieves the valid file strings from the file, fName --- %
function fStrG = getValidFileStrings(fName,mNameG)

% opens and reads the current file 
fid = fopen(fName,'r'); 
fStrI = fread(fid)'; 
fclose(fid);

% splits the strings by line 
A = splitStringRegExp(char(fStrI),'\n');
A = A(~cellfun(@isempty,A));

% removes all lines that are empty and removes the white-space from in
% front of the strings
iS = regexp(A,'\S'); ii = ~cellfun(@isempty,iS);
[A,iS] = deal(A(ii),iS(ii));
A = cellfun(@(x,y)(x(y(1):end)),A,iS,'un',0);

% removes any comment lines
ii = cellfun(@(x)(~strcmp(x(1),'%')),A) & cellfun(@(x)(~strcmp(x(1),'''')),A);
fStrI = uint8(cell2mat(A(ii)'));

% determines if there are any strings left
if (isempty(fStrI))
    % if there are no strings, then return an empty array
    fStrG = cell(size(mNameG));
else
    % removes all the non-viable characters
    nStr = uint8('(),;-.:[]{}/\=+*''!#$^&~<>|"');
    nOK = false(1,length(fStrI));

    % removes all the non-viable characters from the string
    for i = 1:length(nStr); nOK = nOK | (fStrI == nStr(i)); end
    fStrI(nOK) = uint8(' ');

    % splits the file string and removes all small/large, numeric and 
    % non-unique strings
    fStr = unique(splitString(char(fStrI)));

    % alphabetically groups the strings                             
    fStrG = alphaGroupStrings(fStr,size(mNameG,2));    
end  

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- updates the sub-directories within mainDir by the flag, type
%     (which is set to either 'add' or 'remove')
function sDir = searchSubDirectories(mainDir,type,varargin)

% searches for the files within the current directory
if (nargin == 3)
    sDir = {mainDir};
else
    sDir = [];
end

% determines the new files in the directory
mFile = dir(mainDir);

% sets the directory/name flags
fName = cellfun(@(x)(x.name),num2cell(mFile),'un',0);
isDir = cellfun(@(x)(x.isdir),num2cell(mFile));

% sets the candidate directories for adding/removing files
nwDir = find((~(strcmp(fName,'.') | strcmp(fName,'..'))) & isDir);

% loops through
for i = 1:length(nwDir)
    % adds/removes the path based on the type flag
    nwDirName = fullfile(mainDir,fName{nwDir(i)});
    sDir = [sDir;{nwDirName}];    

    % searches for the directories within the current directory
    sDir = [sDir;searchSubDirectories(nwDirName,type)];
end

% --- splits up a string, Str, by its white spaces and returns the
%     constituent components in the cell array, sStr
function sStr = splitString(Str)

% ensures the string is not a cell array
if (iscell(Str))
    Str = Str{1};
end

% determines the indices of the non-white regions in the string
ind = regexp(Str,'\S');

% calculates the indices of the non-contigious non-white space indices and
% determines the index bands that the strings belong to
ii = find(diff(ind)>1)';
indGrp = num2cell([[1;(ind(ii+1)')] [ind(ii)';ind(end)]],2);

% sets the sub-strings
sStr = cellfun(@(x)(Str(x(1):x(2))),indGrp,'un',false);

% --- retrieves the files names of the file string, fStr
function fName = getFileNames(fStr)

[~,fName,~] = fileparts(fStr);

% --- sorts the string alphabetically
function [mNameG,ind] = alphaGroupStrings(mName,nMax)

% sets the lengths of the file names
nLen = cellfun(@length,mName);
if (nargin == 1); 
    nMax = max(nLen); 
else
    nLen = min(nMax+1,nLen);
end

% memory allocation
[ind,mNameG] = deal(cell(26,nMax+1));

% loops through all the letters sorting each of the strings
for i = 1:26
    % determines all the strings that start with the current letter
    rStr = sprintf('regexp(mName,''^(%s|%s)%s*'')',char(64+i),char(96+i),'\w');       
    indT = find(~cellfun(@isempty,eval(rStr)));
    
    % sets the indices and names of the 
    ind(i,:) = cellfun(@(x)(indT(nLen(indT) == x)),num2cell(1:nMax+1),'un',0);
    mNameG(i,:) = cellfun(@(x)(mName(x)),ind(i,:),'un',0);
end

% removes the last column (these belong to the "too long" strings)
[ind,mNameG] = deal(ind(:,1:end-1),mNameG(:,1:end-1));

% --- splits up a string, Str, by its white spaces and returns the
%     constituent components in the cell array, sStr
function sStr = splitStringRegExp(Str,sStr)

% ensures the string is not a cell array
if (iscell(Str))
    Str = Str{1};
end

% determines the indices of the non-white regions in the string
if (length(sStr) == 1)
    if (strcmp(sStr,'\') || strcmp(sStr,'/'))    
        ind = strfind(Str,sStr)';
    else
        ind = regexp(Str,sprintf('[%s]',sStr))';
    end
else
    ind = regexp(Str,sprintf('[%s]',sStr))';
end

% calculates the indices of the non-contigious non-white space indices and
% determines the index bands that the strings belong to
indGrp = num2cell([[1;(ind+1)],[(ind-1);length(Str)]],2);

% sets the sub-strings
sStr = cellfun(@(x)(Str(x(1):x(2))),indGrp,'un',false);

% --- searchs the directories for files of type, fName --- %
function a = fileSearchDir(fDir,fName)

% retrieves the file names and adds the directory field
a = dir(fullfile(fDir,fName));
if (isempty(a))
    b = struct('bytes',[],'date',[],'datenum',[],'dir',[],...
               'isdir',[],'name',[]);
    a = repmat(b,0,1);
else
    % sets the directory and exist flags
    for i = 1:length(a)
        a(i).dir = fDir;
    end
    
    % reorders the fields
    a = orderfields(a);    
end

% --- finds all the toolbox strings within the function dependecies 
function toolStr = findAllToolboxes(fcnDep)

% sets the separator
if (ispc); a = '\'; else a = '/'; end

% retrieves the paths of each of the files and determines which of them
% contain the "toolbox" string
fPath = cellfun(@(x)(which(getFileNames(x),'-all')),fcnDep,'un',0);

% sets the paths which have only one or more than one match
A = cell2cell(fPath(cellfun(@length,fPath) == 1));
A = A(~cellfun(@isempty,strfind(A,'toolbox')));

% seperates out the strings by their directory seperator and returns the
% names of the directory just next to the string
fPathSp = cellfun(@(x)(splitStringRegExp(x,a)),A,'un',0); 
toolStr = unique(cellfun(@(x)(x{1+find(~cellfun(@isempty,strfind(x,'toolbox')))}),fPathSp,'un',0));