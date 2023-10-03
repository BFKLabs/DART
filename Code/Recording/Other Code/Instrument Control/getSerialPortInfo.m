% --- determines the detected and available serial ports
function [comAvail,comDetect] = getSerialPortInfo()

% determines the available serial ports
try
    comAvail = serialportlist;
catch
    try
        insInfo = instrhwinfo('serial');
        comAvail = insInfo.AvailableSerialPorts;
    catch
        [comAvail,comDetect] = deal([]);
        return
    end
end

% sets the serial device registry query stings
Skey = 'HKEY_LOCAL_MACHINE\HARDWARE\DEVICEMAP\SERIALCOMM'; 

% Find connected serial devices
[~, list] = dos(['REG QUERY ' Skey]);
list = textscan(list,'%s','delimiter',' ');
list = cat(1,list{:});

% retrieves the detected COM ports
comDetect = list(cellfun(@(x)(~isempty(regexp(x,'COM[\d]','once'))),list));
comDetect = sort(comDetect);