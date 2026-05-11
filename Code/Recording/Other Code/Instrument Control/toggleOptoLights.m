function toggleOptoLights(handles,hObject,isIR,yAmp)

% sets the light amplitude (if not provided)
if nargin < 4; yAmp = '050'; end

% initialisations
hFig = handles.output;
objDAQ = getappdata(hFig,'objDAQ');

if isempty(objDAQ)
    % if there are no connected devices, then exit
    return
else
    % determines if there are any opto devices connected
    dType = strContains(objDAQ.sType,'HTController') + ...
            2*strcmp(objDAQ.sType,'Opto');
    if ~any(dType > 0)
        % if there are no connected opto devices, then exit
        return 
    end
end

% field retrieval
iDev = find(dType > 0);
sType = objDAQ.sType(iDev);
hDev = objDAQ.Control(iDev);
isOn = strcmp(get(hObject,'Checked'),'off');

% toggles the menu checkmark
toggleMenuCheck(hObject);

% writes the serial string to each of the devices
for i = 1:length(hDev)
    try        
        sStr = setupOptoString(sType{i},isIR,isOn);
        writeSerialString(hDev{i},sStr);
    catch
    end
end

% % runs a test pulse (HT1 controllers only)
% isHT = dType == 1;            
% if any(isHT) && isOn
%     objHT1 = setupHT1TestPulse(objDAQ);
%     runOutputDevices(objHT1,1:length(objHT1));
% end

% --- sets up the opto serial device string
function sStr = setupOptoString(sType,isIR,isOn)

%
if strcmp(sType,'HTControllerV3')
    % case is the HTContollerV3 device
    sStr = setupArduinoString(5+isIR,100*isOn);
else
    % case is other device types
    if isOn
        % turns on the lights
        if isIR
            sStr = {sprintf('4,%f\n',100)};        
        else
            sStr = {sprintf('4,000,000,000,%s\n,000','050')};
        end
    else
        % turns off the lights
        if isIR
            sStr = {sprintf('4,%f\n',0)};
        else
            sStr = {'4,000,000,000,000,000\n'};
        end
    end
end
