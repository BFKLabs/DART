% --- creates an executable of the program given the directory working
%     directory, progDir, and the analysis function directory, funcDir
function createDARTExecutable(progDir,outDir,ProgDef)

% global variables
global mainProgDir

% clears the screen
clc

% other initialisations
tagStr = 'hTimerExe';

% changes directory to the main program directory
cd(mainProgDir);

% ---------------------------------- %
% --- EXECUTABLE DIRECTORY SETUP --- %
% ---------------------------------- %

% sets the analysis function directory
fcnDir = ProgDef.Analysis.DirFunc;

% sets the executable temporary file output directory. if it does not
% exist, then create the directory
exeDir = fullfile(progDir,'Executable');
if ~exist(exeDir,'dir')
    mkdir(exeDir)
end

% deletes all previous files in the executable directory
[isdir,name] = field2cell(dir(exeDir),{'isdir','name'});
cellfun(@(x)(delete(fullfile(exeDir,x))),name(~cell2mat(isdir)))

% ------------------------------- %
% --- ANALYSIS FUNCTION SETUP --- %
% ------------------------------- %

% prompts the user for the analysis functions that are to be added
[fDir,fName,isDef,pkgName] = AnalysisFunc(ProgDef);
if isempty(fDir)
    % exits the function
    return
else    
    % copies any non-default files to the analysis function directory
    if any(~isDef)     
        % sets the copy files, and their names within the analysis function
        % directory (to be removed afterwards)
        cpyFile = cellfun(@(x,y)...
                    (fullfile(x,y)),fDir(~isDef),fName(~isDef),'un',0);
        rmvFile = cellfun(@(x)(fullfile(fcnDir,x)),fName(~isDef),'un',0);            

        % copies the files from the
        cellfun(@(x)(copyfile(x,fcnDir,'f')),cpyFile)     
    else
        % no files to remove
        rmvFile = [];
    end    
    
    % retrieves the computer hostname
    [~, hName] = system('hostname');
    
    % retrieves the analysis function file sizes
    fFile = cellfun(@(x,y)(fullfile(x,y)),fDir,fName,'un',0); 
    A = cell2mat(cellfun(@(x)(dir(x)),fFile,'un',0));
    fSize = field2cell(A,'bytes',1);
    
    % set the analysis function file name
    pFile = fullfile(progDir,'Para Files','AnalysisFunc.mat');
    if (exist(pFile,'file'))
        % if the file already exists, then rename it
        pFileT = fullfile(progDir,'Para Files','AnalysisFuncTemp.mat');
        copyfile(pFile,pFileT);
    else
        pFileT = '';
    end
       
    % saves the analysis function file
    save(pFile,'fDir','fName','fSize','hName');    
end

% saves the package file
pkgFile = fullfile(progDir,'ExternalPackages.mat');
save(pkgFile,'pkgName');

% ------------------------------- %
% --- EXECUTABLE STRING SETUP --- %
% ------------------------------- %

% prompts the user for the executable type to be created
uChoice = questdlg({'Which type of executable do you wish to create:';'';...
                    [' * Console Application (creates command ',...
                     'window on opening)'];...
                    [' * Windows Standalone Application (no ',...
                     'command window on opening)']},...
                    'Executable Type Selection','Console Application',...
                    'Windows Standalone Application','Console Application');
if isempty(uChoice)
    % user cancelled
    return
    
elseif strcmp(uChoice,'Console Application')                
    % creates a console application (creates command window)
    outStr = '-C -o DART -m';
    
else
    % creates a windows standalone application (no command window)
    outStr = '-o DART -W WinMain:ImageStack -T link:exe';
end
   
% creates the loadbar object
hLoad = ProgressLoadbar('Creating DART Program Executable...');
set(hLoad.Control,'CloseRequestFcn',[]);

% sets up the support package string
srcStr = sprintf('-d ''%s''',exeDir);
igDir = {'.','..','External Apps','Git'};
spkgStr = getSupportPackageDir();

% sets up the toolbox addition string
toolStr = sprintf(...
       ['-N -p daq -p imaq -p images -p signal -p instrument ',...
        '-p optim -p stats -p curvefit -p shared -p wavelet ',...
        '-p vision -p nnet %s'],spkgStr);
    
% warning string
warnStr = '-w disable:all_warnings';  
       
% determines files the directories that need to be added
codeDirAll = dir(fullfile(progDir,'Code'));
codeDir = cell(length(codeDirAll),1);
for i = 1:length(codeDir)
    if ~any(strcmp(igDir,codeDirAll(i).name))  && codeDirAll(i).isdir
        codeDir{i} = fullfile(progDir,'Code',codeDirAll(i).name);
    end
end

% sets the final code directory array
codeDir = [rmvEmptyCells(codeDir);pkgName(:)];

% sets the java jar files
% javaFiles = {which('ColoredFieldCellRenderer.zip');...
%              getProgFileName('Code','Executable Only','CondCheckTable.zip')};
javaFiles = {which('ColoredFieldCellRenderer.zip')};         
         
% % retrieves the names of all the folders within the Code directory
% codeDir = cell2cell(codeDir);

% removes all git and external app folders from the executable
% isOK = ~(strContains(codeDir,'\Git') | ...
%          strContains(codeDir,'\External Apps'));
% isOK = ~strContains(codeDir,'\External Apps');     

% sets up the main file, analysis function directory and other important
% file directories add string
fStr = [codeDir(:);javaFiles(:);{'Para Files'}];
addStr = sprintf('-v ''%s'' -a ''%s''',fullfile(progDir,'DART.m'),fcnDir);
for i = 1:length(fStr)
    switch fStr{i}
        case {'DART.fig'}
            addFiles = fullfile(progDir,fStr{i});
            addStr = sprintf('%s -a ''%s''',addStr,addFiles);                            
            
        otherwise
            addStr = sprintf('%s -a ''%s''',addStr,fStr{i});
    end
end

% --------------------------- %
% --- EXECUTABLE CREATION --- %
% --------------------------- %

% deletes any previous timer objects
hTimerPr = timerfindall('tag',tagStr);
if ~isempty(hTimerPr)
    stop(hTimerPr);
    delete(hTimerPr);
end
    
% creates and starts the timer object
tFcn = {@exeTimerFunc,hLoad,outDir,exeDir,rmvFile,pFileT};
tObj = timer('TimerFcn',tFcn,'Period',1,'ExecutionMode','fixedRate',...
             'BusyMode','queue','Tag',tagStr);
start(tObj); 
         
% runs the compiler to create the executable
try
    eval(sprintf('mcc %s %s %s %s %s',outStr,srcStr,toolStr,warnStr,addStr));
    delete(pkgFile)
    
catch err 
    % deletes any extraneous files
    delete(hLoad);
    if ~isempty(rmvFile); cellfun(@(x)(delete(x)),rmvFile); end    
    if exist(pFileT,'file'); copyfile(pFileT,pFile); delete(pFileT); end    
    delete(pkgFile)
    
    % outputs the error to screen
    waitfor(errordlg('Error while creating executable'))
    rethrow(err);
end

% --- determines all the imaq support package directories
function spkgDir = getSupportPackageDir()

% determines the base support package directory
mRel = matlabRelease;
bDir = sprintf(['C:\\ProgramData\\MATLAB\\SupportPackages\\%s',...
                '\\toolbox\\imaq\\supportpackages'],mRel.Release);
            
% removes the invalid support package directory strings
dName = arrayfun(@(x)(x.name),dir(bDir),'un',0);
dName = dName(~(strcmp(dName,'.') | strcmp(dName,'..')));

% sets the full support package directories
if isempty(dName)
    % case is there are no support packages installed
    spkgDir = [];
else
    % otherwise, set the full support package directories
    spkgDir0 = cellfun(@(x)(fullfile(bDir,x)),dName,'un',0);    
    spkgDir = cellfun(@(x)(sprintf('-a ''%s''',x)),spkgDir0,'un',0);
    spkgDir = strjoin(spkgDir(:)',' ');
end
    
% --- sets the executable timer function
function exeTimerFunc(tObj,~,hLoad,outDir,exeDir,rmvFile,pFileT)

% sets the exe/ctf file names
exeFile = fullfile(exeDir,'DART.exe');
ctfFile = fullfile(exeDir,'DART.ctf');

% check to see if the executable file has turn up in the executable
% directory. if so, then move the executable file to the program directory
if exist(exeFile,'file')
    % updates the loadbar string
    stop(tObj); delete(tObj); 
        
    % updates the status message
    [hLoad.Indeterminate,hLoad.FractionComplete] = deal(false,1);
    hLoad.StatusMessage = 'Finished Creating Executable';
    pause(0.2);
    
    % moves the file to the program directory. keep attempting to move the
    % file until it has successfully been moved
    while (1)
        try
            movefile(exeFile,outDir);   
            break
        catch
            pause(0.1);
        end
    end
       
    % deletes the extraneous files
    if ~isempty(rmvFile); cellfun(@(x)(delete(x)),rmvFile); end
    if exist(pFileT,'file'); delete(pFileT); end    
    
    % stops and deletes the timer object/loadbar figure        
    movefile(ctfFile,outDir);  
    pause(2.0); delete(hLoad); pause(0.2);    
    clc       
    
    % creates the executable update zip file
    zip('ExeUpdate.zip',{'DART.exe','DART.ctf'});
end
