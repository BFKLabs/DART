% --- maps the serial devices to their corresponding drives
function [diskStr,isOK] = mapSerialDrives(comStr,iPathID)

% memory allocation
nCOM = length(comStr);
[ii3,ii4] = deal(zeros(size(comStr)));
isOK = true(nCOM,1);

% -------------------------------- %
% --- USB DEVICE QUERY STRINGS --- %
% -------------------------------- %

% registry query string
usbKey = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\';

% retrieces the container ID string
[~, cID] = dos(['REG QUERY ' usbKey ' /s /f "ContainerID" /t "REG_SZ"']);
sStrCID = splitRegQueryString(cID,'ContainerID');
sStrVP = splitRegQueryString(cID,usbKey);
sStrVP = cellfun(@(x)(getFinalDirString(x)),sStrVP,'un',0);

% sets the final contain ID strings
cidStr = sStrCID(cellfun(@(x)(find(strcmpi(sStrVP,x))),iPathID),:);

% --------------------------------- %
% --- USB STORAGE QUERY STRINGS --- %
% --------------------------------- %

% registry query string
usbSKey = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USBStor\';

% 
[~, cID] = dos(['REG QUERY ' usbSKey ' /s /f "ContainerID" /t "REG_SZ"']);
sStrCID = splitRegQueryString(cID,'ContainerID');
sStrMID = splitRegQueryString(cID,usbSKey);

%
for i = 1:length(ii3)
    ii3(i) = find(cellfun(@(x)(...
                    strContains(x,cidStr{i,end})),sStrCID(:,end)));
end

% sets the final mounted device ID strings
midStr = cellfun(@(x)(getFinalDirString(x)),sStrMID(ii3,:),'un',0);

% ----------------------------------- %
% --- MOUNTED DRIVE QUERY STRINGS --- %
% ----------------------------------- %

% registry query string
mdKey = 'HKEY_LOCAL_MACHINE\SYSTEM\MountedDevices\';

% queries the registry for the mounted drives
[~, mID] = dos(['REG QUERY ' mdKey]);
sStrMID = splitRegQueryString(mID,'DosDevices');

% converts the hexadecimal strings to ASCII. from this, determine which
% drives currently hold a USB device (ie, the serial device)
mdStr = cellfun(@(x)(splitMountedDriveStrings(x)),sStrMID(:,end),'un',0);

%
for i = 1:length(ii4)
    ii = cellfun(@(x)(strContains(x,midStr{i})),mdStr);
    if (any(ii))
        ii4(i) = find(ii);
    else
        isOK(i) = false;
    end
end

% sets the final disk drive strings
ii4 = ii4(isOK);
diskStr = cellfun(@(x)(getFinalDirString(x)),sStrMID(ii4,2),'un',0);

% --- 
function sStr = splitRegQueryString(rqStr,rqName)

% reduces the string array to only those line which contain rqName
rqStr = strsplit(rqStr,'\n')';
rqStr = rqStr(cellfun(@(x)(strContains(x,rqName)),rqStr));
sStr = cell2cell(cellfun(@(x)(strsplit(x,'    ')),rqStr,'un',0));
% [~,ind,~] = unique(sStr(:,end));
% sStr = sStr(ind,:);

% --- 
function mdStr = splitMountedDriveStrings(hexStr)

%
ind = num2cell(1:2:length(hexStr)); 
mdStr = cellfun(@(x)(char(hex2dec(hexStr(x+(0:1))))),ind(1:2:end-1));