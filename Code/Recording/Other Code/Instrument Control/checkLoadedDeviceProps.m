% --- determines if the currently set up devices are capable of handling
%     the loaded experiment
function ok = checkLoadedDeviceProps(hFig,sTrain)

% initialisations
ok = true;
hMain = getappdata(hFig,'hMain');
                
% check to see if there is a valid experiment stimuli train
if isempty(sTrain) || isempty(hMain)
    % recording only, then exit the function
    return
end

% determines if there are any custom signals (and is valid to run)
sObjC = detCustomSignals(hFig,sTrain);
if ~isempty(sObjC) && ~exist('SignalObj','file')
    % if the stimuli train file contains custom signals, but the SignalObj
    % class object is missing, then output an error to screen
    qStr = sprintf(['You do not have the neccessary packages to ',...
                    'generate the custom signals contained within ',...
                    'the loaded experimental protocol file.\n\n',...
                    'To gain access to these files please contact ',...
                    'BFKLabs (info@bfklab.com).']);
    waitfor(errordlg(qStr,'Missing Program Packages!','modal'))
    
    % exits the function with a false flag
    ok = false;
    return
end

% if no experimental stimuli, then exit the function
if isempty(sTrain.Ex)
    return
end

% initialisations
devStr = {'Motor','Opto'};
objDACInfo = getappdata(hMain,'objDACInfo'); 
objDACInfo0 = getappdata(hMain,'objDACInfo0'); 

% determines the device names/channel counts from the currently loaded
devType = objDACInfo0.sType;
nCh = objDACInfo0.nChannel(1:length(devType));
nDev = cellfun(@(x)(sum(strContains(devType,x))),devStr);
                    
% determines the device names/channel counts from the loaded file      
chInfo = [sTrain.Ex.sTrain(1).devType,sTrain.Ex.sTrain(1).chName];
[devTypeL,~,iC] = unique(chInfo(:,1),'stable');
nChL = arrayfun(@(x)(sum(iC==x)),(1:max(iC))');
nDevL = cellfun(@(x)(sum(strContains(devTypeL,x))),devStr);
    
% determines if the current device configuration can accomodate that from
% the loaded experiment data file
if any(nDevL > nDev) || (length(devTypeL) > length(devType))
    % if there isn't enough loaded of a specific device, then prompt the
    % user for the correct configuration
    updateDev = true;
else
    % otherwise, check to see the correct number of channels have been set
    % (only important for motors as opto channels are fixed)
    N = nCh(strContains(devType,'Motor'));
    NL = nChL(strContains(devTypeL,'Motor'));
    isOK = cell2mat(arrayfun(@(n)(n<=N(:)'),NL,'un',0));    
    updateDev = ~all(any(isOK,2));
end
                    
% prompts the user for the correct device configuration (if required)
if updateDev   
    % if not testing then prompt the user for the correct configuration
    reqdCFig = setupReqdConfigDataStuct(devTypeL,nChL);
    if ~outputConfigMessage(reqdCFig,devType,nCh)
        ok = false;
        return
    else    
        % retrieves the new DAC information
        setappdata(hMain,'objDACInfo',objDACInfo0)
        [~,objDACInfoNw] = AdaptorInfo(hMain,reqdCFig);        
        if isempty(objDACInfoNw)
            % if the user cancelled then return a false flag value and exit
            setappdata(hMain,'objDACInfo',objDACInfo)
            ok = false;
            return
        else
            % updates the device information struct into the main GUI
            setappdata(hMain,'objDACInfo0',objDACInfoNw)        
        end
    end
end

% ensure that the stimuli train order matches the device order
reduceDevInfo(hMain,devTypeL,nChL)

% --- prompts the user of the configuration requirements and whether they
%     wish to continue with resets the device configuration
function isCont = outputConfigMessage(rData,devType,nCh)

% sets the initial message string
qStr = sprintf(['The current device configuration does not meet the ',...
                'required configuration:\n\n CURRENT CONFIGURATION\n']);

% appends the current figuration results to the string
for i = 1:length(devType)    
    qStr = sprintf('%s%s',qStr,getNewConfigString(devType{i},nCh(i)));
end

% sets the required configuration heading
qStr = sprintf('%s\n REQUIRED CONFIGURATION\n',qStr);

% appends the required figuration devices to the string
for i = 1:rData.nDev
    qStr = sprintf('%s%s',qStr,...
                getNewConfigString(rData.dType{i},rData.nCh(i)));
end
                
% sets the final question text
qStr = sprintf('%s\nDo you want to reset the device configuration?',qStr);

% prompts the user if they wish to continue
uChoice = questdlg(qStr,'Reset Device Configuration?','Yes','No','Yes');
isCont = strcmp(uChoice,'Yes');

% --- retrieves the new configuration string based on device/channel count
function qStr = getNewConfigString(devType,nCh)

switch devType
    case 'Opto'
        % case is the opto device
        qStr = sprintf('  - %s (RGB + W)\n',devType);
    otherwise
        % case is the other devices
        qStr = sprintf('  - %s (nCh = %i)\n',devType,nCh);
end

% --- reduces down the fields of the device information object
function reduceDevInfo(hMain,devTypeL,nChL)

% initialisations
objD = getappdata(hMain,'objDACInfo0');
nDev0 = length(objD.sRate);
[devTypeD,nChD] = deal(objD.sType(:),objD.nChannel(1:nDev0));
nChD(isnan(nChD)) = 0;

% memory allocation
iDev = NaN(length(devTypeL),1);
isAvail = true(length(devTypeD),1);

% determines the matching device properties based on what is available and
% what is required
for i = 1:length(devTypeL)
    % determines the next viable match
    if isnan(nChL(i))
        % case is a non-channel device (i.e., opto)
        iDevNw = find(strcmp(devTypeD,devTypeL{i}) & isAvail,1,'first');
    else    
        % case is a channel dependent device (i.e., motor)
        iDevNw = find(strcmp(devTypeD,devTypeL{i}) & ...
                    isAvail & (nChD(:) <= nChL(:)),1,'first');
    end
       
        
    if isempty(iDevNw)
        % if there is no match, then exit the function
        return
    else
        % otherwise, updates the index array
        [iDev(i),isAvail(iDevNw)] = deal(iDevNw,false);
    end
end

% re-orders the device object array to match the loaded device details
pFld = fieldnames(objD);
for i = 1:length(pFld)
    % sets the field string
    pStr = sprintf('objD.%s',pFld{i});
    
    % re-orders the field based on the type
    switch pFld{i}
        case 'ObjectConstructorName'
            % case is 2D array field
            eval(sprintf('%s = %s(iDev,:);',pStr,pStr));        
            
        case 'vSelDAC'
            % case is the device selection index array
            eval(sprintf('%s = 1:length(iDev);',pStr));
            
        case 'vStrDAC'
            % case is the device selection index array
            Y = eval(pStr);
            ii = num2cell(1:length(Y))';
            Ynw = cellfun(@(x,y)(sprintf('%i%s',x,y(2:end))),...
                                            ii(iDev),Y(iDev),'un',0);
            eval(sprintf('%s = Ynw;',pStr));            
            
        otherwise
            % case is 1D array field
            eval(sprintf('%s = %s(iDev);',pStr,pStr));
            
    end
end

% updates the device data object 
setappdata(hMain,'objDACInfo',objD)

% --- sets up the required configuration data struct
function reqdCFig = setupReqdConfigDataStuct(devTypeL,nChL)

% memory allocation
reqdCFig = struct('dType',[],'nCh',nChL,'nDev',length(nChL));

% sets the device type names
reqdCFig.dType = cellfun(@(x)(regexp(x,'[\w]+','match','once')),...
                              devTypeL,'un',0);
redqCFig.nCh(strContains(reqdCFig.dType,'Opto')) = NaN; 
