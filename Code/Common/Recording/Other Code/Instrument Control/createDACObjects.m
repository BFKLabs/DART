% --- creates the DAC objects for outputting stimuli events --- %
function objDAC = createDACObjects(objDACInfo,sRate,ind)   

% turns off all warnings
wState = warning('off','all');

% sets the index array (if not provided)
if (nargin == 2); ind = find(strcmp(objDACInfo.dType,'DAC')); end

% sets the sampling rate fields (if not provided)
if (verLessThan('matlab','9.2'))
    if (length(sRate) > 1)
        if (length(sRate) ~= length(ind))
            eStr = 'Error! Incorrect sampling rate array applied to DAC devices.';
            waitfor(errordlg(eStr,'Incorrect Sample Rate','modal'))
            objDAC = [];
            return
        end
    else
        % otherwise, convert the scalar to an array
        sRate = sRate*ones(length(ind),1);
    end
else
    % resets the daq devices
    daq.reset;
end
    
% sets the important fields
nChannel = objDACInfo.nChannel(ind);
vStrDAC = objDACInfo.vStrDAC(ind);
iChannel = objDACInfo.iChannel(ind);

% memory allocation
objDAC = cell(length(ind),1);

% otherwise, set the video object to the user selection
for i = 1:length(ind)
    % creates the motor object
    if (isempty(objDACInfo.ObjectConstructorName{ind(i),2}))
        eStr = sprintf('Warning! The adaptor "%s" is not connected!',vStrDAC{i});
        waitfor(warndlg(eStr,'Missing DAC Adaptor','modal'));
    else
        % otherwise, evaluate the object constructor name string
        j = ind(i);
        iCh = 1:nChannel(i);
        
        % sets up the device based on the matlab release
        if (verLessThan('matlab','9.2'))
            % case is the older device handling code
            objDAC{i} = eval(objDACInfo.ObjectConstructorName{j,2});
            
            % adds a channel to the motor object and set the properties
            addchannel(objDAC{i}, iChannel{i}(iCh));
            set(objDAC{i},'TriggerType','Immediate','SampleRate',sRate(i));    
        else
            % case is the newer device handling code            
            dID = objDACInfo.ObjectConstructorName{j,2};
            ssStr = objDACInfo.ObjectConstructorName{j,3};
            objDAC{i} = daq.createSession(dID);
            
            % adds a channel to the motor object and set the properties
            wState = warning('off','all');
            objDAC{i}.addAnalogOutputChannel(ssStr.ID,ssStr.chName(iCh),ssStr.mType);
            warning(wState)
        end                                 
    end
end

% reverts all warning back to original
warning(wState);