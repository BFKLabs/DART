% --- determines the valid serial control device information
function [pStr,iPathID] = detValidSerialDeviceInfo(comAvail,sStr)

% initialisations
[pStr,iPathID] = deal([]);

% determines the attached usb devices
if isunix
    % case is linux

    % searches for the device among the plugged devices
    sysStr = sprintf('lsusb | grep "%s"',sStr);
    [~,a] = system(sysStr);
    if isempty(a)
        % if no match, then exit
        return
    end

    % retrieves the device information
    pause(0.05)
    infoStr = '\<(idVendor|iManufacturer|iProduct|iSerial)';
    [~,b] = system(sprintf('lsusb -v | grep -E "%s"',infoStr));
    b = splitStringRegExp(b,'\n');

    % determines the currently connected devices
    pause(0.05)
    comName = cellfun(@(x)(...
        getArrayVal(strsplit(x,'/'),3)),comAvail(:),'un',0);
    [~,dInfo] = system('ls -l /dev/serial/by-id/');
    dInfo = strsplit(dInfo,'\n');

    %
    isM = find(contains(b,sStr));
    pStr = cell(length(isM),3);
    hasM = false(length(isM),1);
    for i = 1:length(isM)
        % strips out the matching field information
        devStrNw = cell(1,3);
        for j = 1:3
            strSp = strsplit(b{isM(i)+j});
            devStrNw{j} = strjoin(strSp(4:end),'_');
        end

        % determines if the device matches any connected devices
        devStr = strjoin(devStrNw,'_');  
        jj = contains(dInfo,devStr);
        if any(jj)
            % if so, then retrieve the port name
            kk = cellfun(@(x)(contains(dInfo{j},x)),comName);
            if any(kk)
                hasM(i) = true;
                pStr(i,:) = {comAvail{kk},sStr, ''};
            end
        end
    end

    % removes non matching devices
    pStr = pStr(hasM,:);
else
    % case is windows
    ufFile = which('devcon.exe');
    [~,a] = system(sprintf('"%s" find "%s"',ufFile,'USB*'));

    % determines the match between the serial device name strings and the 
    % COM port name strings
    b = splitStringRegExp(a,'\n');
    hasDev = cellfun(@(x)(strContains(x,sStr)),b);     

    % matches the device names to the available COM port
    ind = NaN(length(comAvail),1);
    for i = 1:length(ind)
        indNw = find(hasDev & ~cellfun('isempty',strfind(b,comAvail{i})));
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
    end    
end
