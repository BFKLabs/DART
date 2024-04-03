% --- initialises the experiment information data struct
function iExpt = initExptStruct(varargin)

% initialisations
tStartH = 8;
tNow = datevec(now());
tOfs = tNow(4) >= tStartH;

% retrieves the device details
if isa(varargin{1},'matlab.ui.Figure')
    hFig = varargin{1};
    infoObj = getappdata(hFig,'infoObj');

    exptType = infoObj.exType;
    [objIMAQ,objDAQ] = deal(infoObj.objIMAQ,infoObj.objDAQ);
else
    [exptType,objIMAQ,objDAQ] = deal(varargin{1},varargin{2},varargin{3});
end

% initialises the information field
outDir = pwd;
isWebCam = isa(objIMAQ,'webcam');
tStr = sprintf('Experiment Date - %s',datestr(tNow,1));
Info = struct('Title',tStr,'OutDir',outDir,'FileName',[],...
              'BaseName','Video','Type',exptType);

% initialises the timing field
% Tp = 1 + 4*(~isWebCam);
Tp = 5;
Timing = struct('T0',[],'Tp',Tp,'Texp',[0,12,0,0],...
                'fixedT0',false,'TexpU','Hours');
Timing.T0 = [tNow(1:2),tNow(3)+tOfs,tStartH,0,0];
 
% determines if the time vector is feasible
dMax = getMonthDayCount(tNow(2));
if Timing.T0(3) > dMax
    % if the day exceeds the max count, then increment the month
    Timing.T0(2) = Timing.T0(2) + 1;
    Timing.T0(3) = mod(Timing.T0(3),dMax);
    
    % if the month is december, then start the expt next year in january
    if Timing.T0(2) > 12
        Timing.T0(1) = Timing.T0(1) + 1;
        Timing.T0(2) = 1;
    end
end

% initialises the video field
Video = struct('nCount',[],'Ts',[],'Tf',[],'FPS',5,...
               'Dmax',[0,30,0],'Type',3,'vCompress','Motion JPEG AVI');
Device = struct('IMAQ',[],'DAQ',[]);

% sets the image acquisition related sub-struct fields
if ~isempty(objIMAQ) && ~isa(objIMAQ,'DummyVideo')
    % sets the camera frame rate
    if isWebCam
        % case is for webcams
        Video.FPS = str2double(objIMAQ.pInfo.FrameRate.DefaultValue);
    else
        % case is for the other camera types
        [fRate,~,iSel] = detCameraFrameRate(getselectedsource(objIMAQ),[]);
        Video.FPS = fRate(iSel); 
    end
    
    % sets the camera specific properties
    devName = get(objIMAQ,'Name');
    if strContains(devName,'Basler GenICam Source')
        % case is a basler genicam type
        Timing.Tp = 10;
    else
        % case are other specific cameras
        switch devName
            case {'Logitech Webcam Pro 9000','USB Video Device'}
                Timing.Tp = 10;
        end
    end

    % sets the image acquisition device name
    Device.IMAQ = objIMAQ.Name;
end 

% sets the external stimuli related sub-struct fields
if ~strcmp(exptType,'RecordOnly') && ~isempty(objDAQ)
    Device.DAQ = objDAQ.BoardNames;
end
           
% final struct initialisation
iExpt = struct('Info',Info,'Timing',Timing,'Video',Video,'Device',Device);
