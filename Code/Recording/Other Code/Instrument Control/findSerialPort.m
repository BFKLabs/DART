% --- determines the serial port corresponding to the devices in sStr
function pStr = findSerialPort(sStr,varargin)

% retrieves the serial port information and connected devices
comAvail = getSerialPortInfo();

% retrieves the serial device information
[pStr,iPathID] = deal([]);
for i = 1:length(sStr)
    [pStrNw,iPathIDNw] = detValidSerialDeviceInfo(comAvail,sStr{i});
    [pStr,iPathID] = deal([pStr;pStrNw],[iPathID;iPathIDNw]);
end
    
% determines the serial controller type (if any are detected)
nDev = size(pStr,1);
if (nDev > 0)
    % retrieves the serial device types
    [sType,inUse] = deal(cell(nDev,1),false(nDev,1));
    for i = 1:nDev
        sType{i} = getSerialDeviceType(pStr{i,1},pStr{i,2},pStr{i,3});       
        inUse(i) = isempty(sType{i});
    end
    
    % removes any controllers that are currently being used
    [pStr,sType] = deal(pStr(~inUse,:),sType(~inUse,:));
    if isempty(pStr); return; end
    
    % maps the serial device driver letters (V1 serial controllers only)
    nDevNw = size(pStr,1);
    [isOK,diskStr] = deal(true(nDevNw,1),cell(nDevNw,1));
    for i = 1:nDevNw
        switch pStr{i,2}
            case ('BFKLabs Serial Controller')
                % case is a V1 serial controller
                [diskStrNw,isOK(i)] = mapSerialDrives(pStr(i,1),iPathID);
                diskStr{i} = diskStrNw{1};
            case ('STMicroelectronics Virtual COM Port')
                % case is a V2 serial controller
                diskStr{i} = 'N/A';
        end
    end
    
    % appends the disk strings and device types into the array
    pStr = pStr(isOK,:);
    if (nargin > 1); pStr = [pStr,diskStr(isOK),sType(isOK)]; end
end