% --- reduces down the device information data struct to only include those
%     fields that were selected by the user
function [objDAQ,objDAQ0] = reduceDevInfo(objDAQ0,vSel)

% retrieves the serial device strings from the parameter file
A = load(getParaFileName('ProgPara.mat'));

% field resetting (device dependent)
A.sDev(strContains(A.sDev,'Future Technology')) = {'FTDI'};

% initialisations
objDAQ = objDAQ0;
if isempty(objDAQ)
    return    
elseif isempty(objDAQ.dType)
    return    
end

% sets the selection indices (if not provided)
if ~exist('vSel','var')
    vSel = objDAQ.vSelDAQ;
end

% reduces the sub-fields
objDAQ.vStrDAQ = objDAQ.vStrDAQ(vSel);
objDAQ.nChannel = objDAQ.nChannel(vSel);
objDAQ.sRate = objDAQ.sRate(vSel); 
objDAQ.dType = objDAQ.dType(vSel); 
objDAQ.sType = objDAQ.sType(vSel); 
 
% reduces the device object properties
objDAQ.BoardNames = objDAQ.BoardNames(vSel);
objDAQ.InstalledBoardIds = objDAQ.InstalledBoardIds(vSel);
objDAQ.ObjectConstructorName = ...
                        objDAQ.ObjectConstructorName(vSel,:);
objDAQ.Control = objDAQ.Control(vSel);

% opens the required serial device (if this is the device type)
if ~isempty(objDAQ.vSelDAQ)
    isS = find(strcmp(objDAQ.dType,'Serial'));
    for i = 1:length(isS)
        % sets the device type (based on the associated info)
        j = isS(i);
        iType = cellfun(@(x)(strContains(objDAQ.vStrDAQ{j},x)),A.sDev);
        if any(iType)
            sType = find(iType);
        else
            sType = 0;
        end

        % resets user data (serial device ID flags)
        set(objDAQ.Control{j},'UserData',sType)
        set(objDAQ0.Control{j},'UserData',sType)

        % opens the serial device (if not already opened)
        if ~isa(objDAQ.Control{j},'DummyDevice')
            openSerialDevice(objDAQ.Control{j},sType)
        end
    end
end
