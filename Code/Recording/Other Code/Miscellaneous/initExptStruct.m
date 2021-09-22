% --- initialises the experiment information data struct
function iExpt = initExptStruct(varargin)

% initialisations
tStartH = 8;
tNow = datevec(now());
tOfs = tNow(4) >= tStartH;

% 
if isa(varargin{1},'matlab.ui.Figure')
    hFig = varargin{1};
    infoObj = getappdata(hFig,'infoObj');
    [exptType,objIMAQ] = deal(infoObj.exType,infoObj.objIMAQ);
else
    [exptType,objIMAQ] = deal(varargin{1},varargin{2});
end

% initialises the information field
outDir = pwd;
tStr = sprintf('Experiment Date - %s',datestr(tNow,1));
Info = struct('Title',tStr,'OutDir',outDir,'FileName',[],...
              'BaseName','Video','Type',exptType);

% initialises the timing field
Timing = struct('T0',[],'Tp',5,'Texp',[0,12,0,0],...
                'fixedT0',false,'TexpU','Hours');
Timing.T0 = [tNow(1:2),tNow(3)+tOfs,tStartH,0,0];

% initialises the video field
Video = struct('nCount',[],'Ts',[],'Tf',[],'FPS',5,...
               'Dmax',[0,30,0],'Type',3,'vCompress','Motion JPEG AVI');

% sets the sub-struct fields
if ~isempty(objIMAQ)
    % sets the camera frame rate
    [fRate,~,iSel] = detCameraFrameRate(getselectedsource(objIMAQ),[]);
    Video.FPS = fRate(iSel); 
    
    % sets the camera specific properties
    switch get(objIMAQ,'Name')
        case 'Logitech Webcam Pro 9000'
            Timing.Tp = 10;
    end
end 
           
% final struct initialisation
iExpt = struct('Info',Info,'Timing',Timing,'Video',Video);