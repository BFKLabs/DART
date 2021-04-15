% --- initialises the real-time batch processing for the experiment, iExpt
function ok = initRTBatchProcess()

% global variables
global objIMAQ hMain hExptF iExpt0

% retrieves the important data structs
ok = true;
rtData = getappdata(hExptF,'rtData');

% determines the type of experiment being run
switch (get(hExptF,'tag'))
    case ('figMultExpt') % case is a multi-experiment 
        iData = getappdata(hExptF,'iDataExp'); 
        
        % sets the sub-struct
        iExpt = iData.iExpt;
        for i = 1:length(iExpt)
            iExpt{i}.Info.OutDir = fullfile(iExpt0.Info.OutDir,iExpt0.Info.Title);
            iExpt{i}.Info.Title = sprintf('Phase %i - %s',i,iData.Name{i}); 
        end
    otherwise % case is a single experiment
        iExpt0 = getappdata(hExptF,'iExpt');
        iExpt = {iExpt0};
end

% --- TEMPORARY VIDEO FILE CREATION --- %
% ------------------------------------- %

% this creates a short 5-second movie file that will be used to temporarily
% allow access the solution files in the batch processing directory (in
% case there is a failure with the tracking of if the user quits). this
% temporary file will be deleted when a proper video turns up in the
% experiment movie folder (through the batch processing function)

% data struct initialsations
vPara = struct('Dir',[],'Name',[],'nFrm',[],'FPS',[],...
               'vCompress',[],'vExtn',[]);
vPara.Dir = fullfile(iExpt{1}.Info.OutDir,iExpt{1}.Info.Title);
vPara.Name = 'Temp';
vPara.FPS = iExpt{1}.Video.FPS;
vPara.vCompress = iExpt{1}.Video.vCompress;
vPara.vExtn = getMovieFileExtn(vPara.vCompress);
vPara.nFrm = vPara.FPS*5;   

% makes the new output file directory
if (~exist(vPara.Dir,'dir'))
    mkdir(vPara.Dir);
end

% sets up the video recording properties and triggers the camera
[objIMAQ,hSumm] = setupVideoRecord(objIMAQ,'Test',vPara,hMain);    
if (~isempty(objIMAQ))
    % initialises the time start
    tic; wFunc = getappdata(hSumm,'updateBar');

    % pauses the program until the wait-period has passed
    while (toc < iExpt0.Timing.Tp)
        tRem = iExpt0.Timing.Tp - toc;
        wFunc(1,sprintf('Waiting To Record Temporary BP Video (%i seconds remains)',...
                        ceil(tRem)),1-tRem/iExpt0.Timing.Tp,hSumm);
        pause(0.1);           % pause to ensure camera has initialised properly
    end

    % triggers the camera
    trigger(objIMAQ)
end

% sets the temporary file
tempFile = fullfile(vPara.Dir,[vPara.Name,vPara.vExtn]);
while (1)
    % determines if the file has been finally output. if not, then pause
    % the program for a second and try again
    try
        mObj = VideoReader(tempFile);
        break
    catch
        pause(1);
    end       
end

% --- SECONDARY DART SETUP --- % 
% ---------------------------- %

% sets the other fields for the RT batch processing data struct
iExpt = cell2mat(iExpt);
rtData.Info = field2cell(iExpt,'Info',1);
rtData.Video = field2cell(iExpt,'Video',1);
rtData.vPara = vPara;
save(fullfile(rtData.exeDir,'TempData.mat'),'-struct','rtData'); pause(0.1);

% % runs the secondary version of DART
% nwStr = sprintf('%s "%s" &',rtData.exeFile,rtData.exeDir);
% [A,~] = system(nwStr);
% 
% % check to see if the version of DART started correctly
% if (A > 0)
%     % if not, then output an error to screen
%     eStr = 'Error! Selected DART Version Not Working Correctly. Ignoring RT Batch Processing';
%     waitfor(warndlg(eStr))
%     
%     % deletes the temporary video file and exits the function
%     delete(tempFile)
%     return
% end