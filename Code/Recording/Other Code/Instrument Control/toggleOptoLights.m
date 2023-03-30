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
    dType = strcmp(objDAQ.sType,'HTControllerV1') + ...
            2*strcmp(objDAQ.sType,'Opto');
    if ~any(dType > 0)
        % if there are no connected opto devices, then exit
        return 
    end
end

% sets the light properties based on the checked state of the menu item
if strcmp(get(hObject,'Checked'),'off')
    % turns on the lights
    if isIR
        sStr = {sprintf('4,%f\n',2*str2double(yAmp)),...
                sprintf('3,000,000,000,000,%s\n',yAmp)};
    else
        sStr = sprintf('4,000,000,000,%s\n,000',yAmp);
    end
        
    set(hObject,'Checked','on')
else
    % turns off the lights
    if isIR
        sStr = {sprintf('4,%f\n',0),...
                sprintf('3,000,000,000,000,%s\n',yAmp)};
    else
        sStr = '4,000,000,000,000,000\n';
    end
        
    set(hObject,'Checked','off')
end

% writes the serial string to each of the devices
iDev = find(dType > 0);
hDev = objDAQ.Control(iDev);
if ~isempty(hDev)
    for i = 1:length(hDev)
        try
            writeSerialString(hDev{i},sStr{iDev(i)});
        end
    end
end
