% --- reduces down the device information data struct to only include those
%     fields that were selected by the user
function [objDACInfo,objDACInfo0] = reduceDevInfo(objDACInfo0,isTest)

% global variables
global mainProgDir

% retrieves the serial device strings from the parameter file
A = load(fullfile(mainProgDir,'Para Files','ProgPara.mat'));

% initialisations
objDACInfo = objDACInfo0;
if isempty(objDACInfo)
    return    
end

% reduces the sub-fields
vSel = objDACInfo.vSelDAC;
objDACInfo.vStrDAC = objDACInfo.vStrDAC(vSel);
objDACInfo.nChannel = objDACInfo.nChannel(vSel);
objDACInfo.sRate = objDACInfo.sRate(vSel);    

if ~isTest   
    % reduces the device object properties
    objDACInfo.BoardNames = objDACInfo.BoardNames(vSel);
    objDACInfo.InstalledBoardIds = objDACInfo.InstalledBoardIds(vSel);
    objDACInfo.ObjectConstructorName = ...
                            objDACInfo.ObjectConstructorName(vSel,:);
    objDACInfo.Control = objDACInfo.Control(vSel);

    % opens the required serial device (if this is the device type)
    if ~isempty(objDACInfo.vSelDAC)
        isS = find(strcmp(objDACInfo.dType,'Serial'));
        for i = 1:length(isS)
            % sets the device type (based on the associated info)
            iType = cellfun(@(x)(strContains(...
                        objDACInfo.vStrDAC{isS(i)},x)),A.sDev);
            if any(iType)
                sType = find(iType);
            else
                sType = 0;
            end
            
            % sets the control flag ID numbers
            set(objDACInfo.Control{isS(i)},'UserData',sType)
            set(objDACInfo0.Control{isS(i)},'UserData',sType)

            % opens the device
            if strcmp(get(objDACInfo.Control{isS(i)},'status'),'closed')
                fopen(objDACInfo.Control{isS(i)});  
            end
        end
    end
else
    % otherwise, set the device type name to be a DAC
    objDACInfo.dType = 'DAC';
end
