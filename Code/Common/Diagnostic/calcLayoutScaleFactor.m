function fScale = calcLayoutScaleFactor()

% command string
cStr = 'wmic path Win32_VideoController get CurrentHorizontalResolution';

% determines the screen resolutions
[~,a] = system(cStr);
b = strsplit(a,'\n');
szD = str2double(strtrim(b{2}));

% calculates the scale factor
mPos = get(0,'MonitorPositions');
fScale = szD/mPos(3);
