function toggleOptoLights(handles,hObject,isIR,yAmp)

% sets the light amplitude (if not provided)
if nargin < 4; yAmp = '050'; end

% initialisations
hFig = handles.output;
objDAQ = getappdata(hFig,'objDAQ');

% sets the light properties based on the checked state of the menu item
if strcmp(get(hObject,'Checked'),'off')
    % turns on the lights
    if isIR
        sStr = sprintf('3,000,000,000,000,%s\n',yAmp);
    else
        sStr = sprintf('4,000,000,000,%s\n,000',yAmp);
    end
        
    set(hObject,'Checked','on')
else
    % turns off the lights
    if isIR
        sStr = '3,000,000,000,000,000\n';
    else
        sStr = '4,000,000,000,000,000\n';
    end
        
    set(hObject,'Checked','off')
end

% writes the serial string to each of the devices
hOpto = objDAQ.Control(strcmp(objDAQ.sType,'Opto'));
if ~isempty(hOpto)
    for i = 1:length(hOpto)
        try
            writeSerialString(hOpto{i},sStr);
        end
    end
end