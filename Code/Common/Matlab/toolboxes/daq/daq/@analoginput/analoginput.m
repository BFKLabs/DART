function obj = analoginput(varargin)
%ANALOGINPUT Construct analog input object.
%
%    AI = ANALOGINPUT('ADAPTOR')
%    AI = ANALOGINPUT('ADAPTOR',ID) constructs an analog input object
%    associated with adaptor, ADAPTOR, with device identification, ID.
%
%    The supported adaptors are:
%       advantech
%       mcc
%       nidaq
%       winsound
% 
%    ID does not need to be specified for the winsound adaptor if the
%    ID = 0.  The analog input object is returned to AI.
%
%    In order to perform a data acquisition task with the object, AI,
%    channels must be added with ADDCHANNEL.
%
%    Examples:
%       AI = analoginput('winsound');
%       AI = analoginput('nidaq','Dev1');
%
%    See also ADDCHANNEL, PROPINFO.
%

%    Copyright 1998-2009 The MathWorks, Inc.
%    $Revision: 1.16.2.24 $  $Date: 2011/05/13 17:04:06 $

%    Object fields
%       .uddobject  - Handle to the underlying udd object for the device.
%       .version    - Class version number.
%       .info       - Structure containing strings used to provide object
%                     methods with information regarding the object.  Its
%                     fields are:
%                       .prefix     - 'a' or 'an' prefix that would precede the
%                                     object type name.
%                       .objtype    - object type with first characters capitalized.
%                       .addchild   - method name to add children, ie. 'addchannel'
%                                     or 'addline'.
%                       .child      - type of children associated with the object
%                                     such as 'Channel' or 'Line'.
%                       .childconst - constructor used to create children, ie. 'aichannel',
%                                     'aochannel' or 'dioline'.

daq.internal.errorIfLegacyInterfaceUnavailable

% Initialize variables.
tlbxVersion = 2.0;
className = 'analoginput';

adaptor  = [];

% Adaptor names used by special case code
nidaqAdaptorName = 'nidaq';
nidaqmxAdaptorName = 'nidaqmx';

% OOPS object passed in as first parameter
if ( nargin > 0 && strcmp(class(varargin{1}), className) )
   % Just return the object as is.
   obj = varargin{1};
   return;
end

% Check for CompactDAQ device ID's
try
    if nargin >= 2
        devices = daq.getDevices;
        for dev = 1:length(devices)
            if isa(devices(dev), 'daq.ni.CompactDAQModule')
                 boardName = devices(dev).Model;
                 boardID = devices(dev).ID;

                 if strcmpi(boardID, varargin{2})
                     error('daq:analoginput:v3', 'This device is not supported by the DAQ Legacy Interface. To use this device you must use the DAQ Session Based Interface.\nFor more information, see <a href="matlab:helpview(fullfile(docroot, ''toolbox'', ''daq'', ''daq.map''), ''transition'')">documentation on the session-based interface</a>.');
                end
            end
        end
    end
catch me
    throwAsCaller(me)
end

% Adaptor name passed in as first parameter - User is calling constructor.
if ( nargin > 0 && ischar(varargin{1}) )
   % Expect an adaptor name, possibly an ID and other parameters.
   % Create and return the object to the user.
   try
      if isempty(varargin{1}),
         error('daq:analoginput:invalidadaptor', 'ADAPTOR specified cannot be empty.')
      end
      
      % Convert all numeric input to strings.
      for i=2:nargin,
         if any(strcmp(class(varargin{i}),{'double' 'char'})) && ~isempty(varargin{i}),
            varargin{i} = num2str(varargin{i}); % convert numbers to string
         else
            error('daq:analoginput:invalidid', 'ID must be specified as a string or number.')
         end                  
      end
    
      
      % Store the adaptor name.
      adaptor = varargin{1};
      
      warnInfo = daqgate('privateCheckAdaptorMismatch', adaptor);
      if ~isempty(warnInfo)
          warning('daq:analoginput:adaptormismatch', '%s', warnInfo)
      end
      
      if strcmpi(adaptor,nidaqmxAdaptorName)
          % Geck 281433:  We explicitly block direct access to the NIDAQmx
          % adaptor in order to ensure that it's not an "undocumented" feature.
          error('daq:analoginput:unexpected','Failure to find requested data acquisition device: nidaqmx.');
      end         

      % Geck 281433:  In order to make NIDAQmx and NIDAQ adaptors look like a
      % single adaptor, we handle nidaq specially
      if strcmpi(adaptor,nidaqAdaptorName)
          obj = localCreateNIDAQAnalogInputObject(className,varargin{:});
      else
          % Calling here will handle cases where we were able to create the
          % object but it is on the deprecation path for adaptors other
          % than the nidaq family.
          daqgate('privateCheckObsoleteAdaptor', className, adaptor);

          obj = localCreateAnalogInputObject(className,varargin{:});      
      end
   catch e
       % Calling here will handle cases where we were not able to create
       % the object which would indicate that the adaptor is already
       % deprecated. We only do this for the truly deprecated adaptors:
       % Keithley and VXI.
       keithleyAdaptorName = 'keithley';
       hpe1432AdaptorName = 'hpe1432';
       
       if (strcmpi(adaptor, keithleyAdaptorName) || ...
               strcmpi(adaptor, hpe1432AdaptorName))
           daqgate('privateCheckObsoleteAdaptor', className, adaptor);
       end
       
       error('daq:analoginput:unexpected', '%s', deblank(e.message))
   end
   return;
end %if
   
% Structure of descriptive information used to generalize object methods.
info.prefix='an';
info.objtype='Analog Input';
info.addchild='addchannel';
info.child='Channel';
info.childconst='aichannel';

% DAQMEX is calling the default constructor.
if nargin==0 
   % Create the object with an empty handle
   obj.uddobject = handle(0);

% MATLAB code is calling the constructor to create a wrapper of a AI UDD object.
elseif ( nargin == 1 && ...
         (~isempty(strfind(class(varargin{1}), 'daq.') ) || ...
           strcmp(class(varargin{1}), 'handle') ) )
   obj.uddobject = varargin{1};
% Anything else is invalid.   
else
    error('daq:analoginput:invalidadaptor', 'ADAPTOR must be passed as a single string.') 
end

obj.version = tlbxVersion;
obj.info = info;
      
dev = daqdevice;
obj = class(obj, className, dev);

    function [obj] = localCreateNIDAQAnalogInputObject(className,varargin)
        % Attempt to create the NIDAQmx analog input object first          
        try
            param = varargin;
            param{1} = nidaqmxAdaptorName;
            obj = localCreateAnalogInputObject(className,param{:});      
        catch nidaqmxException
            if nargin < 3 || isempty(str2num(varargin{2})) || str2num(varargin{2}) < 0 %#ok<ST2NM>
                rethrow(nidaqmxException);
            end
            % Otherwise attempt to create the NIDAQ analog input object
            param = varargin;
            param{1} = nidaqAdaptorName;
            try
                % Calling here will handle the traditional nidaq adaptor 
                % that is on the deprecation path.
                daqgate('privateCheckObsoleteAdaptor', className, adaptor);
                
                obj = localCreateAnalogInputObject(className,param{:});
            catch thisException
                % OK, they both failed, but which error do we choose?
                % Use NIDAQmx error message if it was installed, but NIDAQ
                % traditional wasn't
                if ~strcmp(nidaqmxException.identifier,'daq:analoginput:invalidadaptor') &&...
                    strcmp(thisException.identifier,'daq:analoginput:invalidadaptor')
                    rethrow(nidaqmxException);
                end
                % otherwise, throw the NIDAQ error
                rethrow(thisException);
            end
        end
    end

    function [obj] = localCreateAnalogInputObject(className,varargin)
          % Use the daq package to create the analog input object.
          obj = [];
          try
              daqmex;
              uddobj = daq.engine.createobject( className, varargin{:} );

              % Call the constructor again to wrap UDD object in OOPS.
              obj = analoginput(uddobj);
          catch generalException
              % If the adaptor wasn't registered yet, do it and try again.
              if strcmp(generalException.identifier,'daq:adaptor:adaptorNotFound')
                  % Geck 284563:  If we need to register nidaqmx, register nidaq
                  try
                      if(strcmpi(varargin{1},nidaqmxAdaptorName))
                          evalc('daqregister(nidaqAdaptorName); uddobj = daq.engine.createobject( className, varargin{:} ); obj = analoginput(uddobj);');
                      else
                          evalc('daqregister(varargin{1}); uddobj = daq.engine.createobject( className, varargin{:} ); obj = analoginput(uddobj);');
                      end
                  catch nidaqException
                      generalException = nidaqException;
                  end
              end    

              % Still didn't work
              if isempty(obj)
                  if strcmp(generalException.identifier,'daq:adaptor:adaptorNotFound')
                      error('daq:analoginput:invalidadaptor', generalException.message);
                  else
                      error('daq:analoginput:unexpected', generalException.message);
                  end
              end
          end
    end
end