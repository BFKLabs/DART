% --- creates a webcam object (to be used within DART)
function wObj = createWebCamObj(devName,pInfo,sFormatF)

% creates the webcam object
wObj = webcam(devName);

% adds in the other property fields
addprop(wObj,'pInfo');
addprop(wObj,'pROI');
addprop(wObj,'resTemp');
addprop(wObj,'hTimer');
addprop(wObj,'DiskLogger');

% sets the webcam object fields
wObj.pInfo = pInfo;

% determines the camera resolution string
if exist('sFormatF','var')
    % determines the feasible resolutions
    availForm = wObj.AvailableResolutions;
    sFormatF = strsplit(sFormatF,'_');
    sFormatN = regexp(sFormatF{2},'(\d*)','match');
    sFormatW = strjoin(sFormatN,'x');
   
    % sets the camera fields
    wObj.resTemp = availForm{strcmp(availForm,sFormatW)};
    wObj.pROI = [0,0,cellfun(@str2double,sFormatN)];
end