% --- reduces down the device information data struct to only include those
%     fields that were selected by the user
function [objDAQ,objDAQ0] = reduceDevInfo(objDAQ0,vSel)

% global variables
global mainProgDir

% retrieves the serial device strings from the parameter file
A = load(fullfile(mainProgDir,'Para Files','ProgPara.mat'));

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
        iType = cellfun(@(x)(strContains(...
                    objDAQ.vStrDAQ{isS(i)},x)),A.sDev);
        if any(iType)
            sType = find(iType);
        else
            sType = 0;
        end

        % resets user data (serial device ID flags)
        set(objDAQ.Control{isS(i)},'UserData',sType)
        set(objDAQ0.Control{isS(i)},'UserData',sType)

        % opens the device
        if strcmp(get(objDAQ.Control{isS(i)},'status'),'closed')
            fopen(objDAQ.Control{isS(i)});  
        end
    end
end
