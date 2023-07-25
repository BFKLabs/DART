% --- retrieves the serial device type string
function sType = getSerialDeviceType(pStr,sStr,vpStr,varargin)

% sets the default input arguments
if nargin < 2; sStr = 'Default'; end

% sets the utility directory/file name
utDir = getProgFileName('Code','Common','Utilities','Serial Builds');
ufFile = fullfile(utDir,'devcon.exe');

% sets up the controller handle and boardname string
hS = createSerialDevObject(pStr);              
             
switch sStr        
    case {'STMicroelectronics Virtual COM Port', 'USB Serial Device'}
        % case is the V2 controller type
        
        % opens the controller and determines what type it is        
        [~,sTypeTmp] = detValidSerialContollerV2(hS);
        switch sTypeTmp
            case ('lightcycle')
                sType = 'Light Cycle';
            case ('motor')
                sType = 'Motor';
            case ('opto')
                sType = 'Opto';
            case ('inuse')
                sType = [];
            otherwise
                sType = sTypeTmp;
        end
        
        % deletes any serial objects
        delete(instrfindall)
        
    otherwise
        % case is the V1 Controller Type
        
        % opens the controller and determines what type it is
        [~,sTypeTmp] = detValidSerialContollerV1(hS);
        switch sTypeTmp
            case ('LightCycle')
                % case is a light cycle device (obsolete?)
                sType = 'Light Cycle';
                
            case ('Motor')
                % case is a motor controller
                sType = 'Motor';
                
            case ('Opto')
                % case is an optogenetics device
                sType = 'Optogenetics';
                
            case ('HTControllerV1')
                % case is a HT controller (version 1)
                sType = 'HTControllerV1';
                
            case {'HT ControllerV2','HTControllerV2'}
                % case is a HT controller (version 2)
                sType = 'HTControllerV2';
                
            case ('InUse')
                % current device is currently in use
                sType = [];
                
            otherwise
                % otherwise, there was an issue initially loading the
                % device. close and reopent the device and try again...
                if (nargin == 2)
                    % deletes the serial controller 
                    fclose(hS);
                    delete(hS);

                    % disables/reenables the device type
                    [~,~] = system(sprintf('"%s" disable "USB\\%s"',ufFile,vpStr));
                    [~,~] = system(sprintf('"%s" enable "USB\\%s"',ufFile,vpStr));

                    % retries retrieving the serial device type
                    sType = getSerialDeviceType(pStr,sStr,vpStr,1);
                    
                else
                    % if retrying didn't work then flag the device as not
                    % being usable within DART
                    sType = 'Not Applicable';
                end
        end        
end        
