% --- determines the valid serial control device information
function [pStr,iPathID] = detValidSerialDeviceInfo(comAvail,sStr)

% determines the attached usb devices
ufFile = which('devcon.exe');
[~,a] = system(sprintf('"%s" find "%s"',ufFile,'USB*'));

% determines the match between the serial device name strings and the COM
% port name strings
b = splitStringRegExp(a,'\n');
c = cellfun(@(x)(strContains(x,sStr)),b);     

%
ind = NaN(length(comAvail),1);
for i = 1:length(ind)
    indNw = find(c & ~cellfun('isempty',strfind(b,comAvail{i})));
    if ~isempty(indNw)
        ind(i) = indNw;
    end
end

% sets the final matches (com port name and drive letter)
ii = ~isnan(ind);
if any(ii)
    % retrieves the device path ID strings
    d = b(ind(ii));
    [iPathID,vpStr,cName] = deal(cell(length(d),1));
    for i = 1:length(d)
        dT = strsplit(d{i});
        iPathID{i} = lower(getFinalDirString(dT{1}));
        vpStr{i} = getFinalDirString(dT{1},1);
        cName{i} = dT{end}(2:end-1);
    end    
    
    % sets the BFKLabs serial controller name string
    if (strcmp(sStr,'STMicroelectronics STLink Virtual COM Port') || ...
        strcmp(sStr,'STMicroelectronics STLink COM Port'))
        sStr = 'BFKLabs Serial Controller';
    end
    
    % sets the final data array
    pStr = [cName,repmat({sStr},sum(ii),1),vpStr];
else
    % no matches so return empty array
    [pStr,iPathID] = deal([]);
end
