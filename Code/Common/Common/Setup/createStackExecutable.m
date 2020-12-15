% --- creates an executable of the image stack creation program given the 
%     directory, progDir, and the output directory, outDir
function createStackExecutable(progDir)

% clears the screen
clc

% sets the executable/output directory
exeDir = fullfile(progDir,'Code','Common','Stack');
outDir = fullfile(progDir,'Code','Common','Utilities');

% ---------------------------------- %
% --- EXECUTABLE DIRECTORY SETUP --- %
% ---------------------------------- %

% sets the executable temporary file output directory. if it does not
% exist, then create the directory
if (~exist(exeDir,'dir'))
    mkdir(exeDir)
end

% % deletes all previous files in the executable directory
[isdir,name] = field2cell(dir(exeDir),{'isdir','name'});
ii = ~cell2mat(isdir) & ~strcmp(name,'createImageStack.m');
cellfun(@(x)(delete(fullfile(exeDir,x))),name(ii))

% creates the loadbar object
hLoad = ProgressLoadbar('Creating Stack Program Executable...');
set(hLoad.Control,'CloseRequestFcn',[]);

% sets the file strings
fStr = fullfile(progDir,'Code','Common','Utilities','mmread');

% ------------------------------- %
% --- EXECUTABLE STRING SETUP --- %
% ------------------------------- %

% sets the output, toolbox and enabled string fields
outStr = '-o ImageStack -W WinMain:ImageStack -T link:exe';
srcStr = sprintf('-d %s',exeDir);
toolStr = '-N -p images';
enabStr = ['-w enable:specified_file_mismatch -w enable:repeated_file -w ',...
           'enable:switch_ignored -w enable:missing_lib_sentinel -w ',...
           'enable:demo_license'];

% sets the files/directories to add string       
addStr = sprintf('-v %s',fullfile(exeDir,'createImageStack.m'));       
addStr = sprintf('%s -a %s',addStr,fStr); 


% --------------------------- %
% --- EXECUTABLE CREATION --- %
% --------------------------- %     

% creates and starts the timer object
tObj = timer('TimerFcn',{@exeTimerFunc,hLoad,exeDir,outDir},'Period',1,...
             'ExecutionMode','fixedRate','BusyMode','queue');
start(tObj); 
         
% runs the compiler to create the executable
try
    eval(sprintf('mcc %s %s %s %s %s',outStr,srcStr,toolStr,enabStr,addStr));
catch err 
    delete(hLoad);
    waitfor(errordlg('Error while creating executable'))
    rethrow(err);
end

% --- sets the executable timer function
function exeTimerFunc(tObj,~,hLoad,exeDir,outDir)

% sets the exe/ctf file names
exeFile = fullfile(exeDir,'ImageStack.exe');
ctfFile = fullfile(exeDir,'DART.ctf');

% check to see if the executable file has turn up in the executable
% directory. if so, then move the executable file to the program directory
if (exist(exeFile,'file'))
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
        end
    end
       
    % stops and deletes the timer object/loadbar figure        
    movefile(ctfFile,outDir); 
    pause(2.0); delete(hLoad); pause(0.2);    
    clc 
end
       