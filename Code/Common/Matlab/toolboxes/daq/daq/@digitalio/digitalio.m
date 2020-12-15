function obj = digitalio(varargin)
%DIGITALIO Construct digital I/O object.
%
%    DIO = DIGITALIO('ADAPTOR',ID) constructs a digital I/O object
%    associated with adaptor, ADAPTOR, with device identification, ID.
%
%    The supported adaptors are:
%       advantech
%		mcc
%       nidaq
%       parallel
% 
%    The digital I/O object is returned to DIO.
%
%    Examples:
%       DIO = digitalio('nidaq','Dev1');
%
%    See also ADDLINE, PROPINFO.
%

%    Copyright 1998-2009 The MathWorks, Inc.
%    $Revision: 1.14.2.22 $  $Date: 2010/11/08 02:17:34 $

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
className = 'digitalio';

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

% Adaptor name passed in as first parameter - User is calling constructor.
if ( nargin > 0 && ischar(varargin{1}) )
   % Expect an adaptor name, possibly an ID and other parameters.
   % Create and return the object to the user.
   try
      if isempty(varargin{1}),
         error('daq:digitalio:invalidadaptor', 'ADAPTOR specified cannot be empty.')
      end
      
      % Convert all numeric input to strings.
      for i=2:nargin,
         if any(strcmp(class(varargin{i}),{'double' 'char'})) && ~isempty(varargin{i}),
            varargin{i} = num2str(varargin{i}); % convert numbers to string
         else
            error('daq:digitalio:invalidid', 'ID must be specified as a string or number.')
         end                  
      end
      
      % Store the adaptor name.
      adaptor = varargin{1};

      warnInfo = daqgate('privateCheckAdaptorMismatch', adaptor);
      if ~isempty(warnInfo)
          warning('daq:digitalio:adaptormismatch', '%s', warnInfo)
      end
      
      if strcmpi(adaptor,nidaqmxAdaptorName)
          % Geck 281433:  We explicitly block direct access to the NIDAQmx
          % adaptor in order to ensure that it's not an "undocumented" feature.
          error('daq:digitalio:unexpected','Failure to find requested data acquisition device: nidaqmx.');
      end         

      % Geck 281433:  In order to make NIDAQmx and NIDAQ adaptors look like a
      % single adaptor, we handle nidaq specially
      if strcmpi(adaptor,nidaqAdaptorName)
          obj = localCreateNIDAQDigitalIOObject(className,varargin{:});
      else
          % Calling here will handle cases where we were able to create the
          % object but it is on the deprecation path for adaptors other
          % than the nidaq family.
          daqgate('privateCheckObsoleteAdaptor', className, adaptor);

          obj = localCreateDigitalIOObject(className,varargin{:});      
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
       
      error('daq:digitalio:unexpected', '%s', deblank(e.message))
   end
   return;
end
   
% Structure of descriptive information used to generalize object methods.
info.prefix='a';
info.objtype='DigitalIO';
info.addchild='addline';
info.child='Line';
info.childconst='dioline';

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
    error('daq:digitalio:invalidadaptor', 'ADAPTOR must be passed as a single string.') 
end

obj.version = tlbxVersion;
obj.info = info;
      
dev = daqdevice;
obj = class(obj, className, dev);

    function [obj] = localCreateNIDAQDigitalIOObject(className,varargin)
        % Attempt to create the NIDAQmx digital i/o object first
        try
            param = varargin;
            param{1} = nidaqmxAdaptorName;
            obj = localCreateDigitalIOObject(className,param{:});      
        catch nidaqmxException
            % Backup the error message: we might need it
            if nargin < 3 || isempty(str2num(varargin{2})) || str2num(varargin{2}) < 0 %#ok<ST2NM>
                rethrow(nidaqmxException);
            end
            % Otherwise attempt to create the NIDAQ digital i/o object
            param = varargin;
            param{1} = nidaqAdaptorName;
            try
                % Calling here will handle the traditional nidaq adaptor 
                % that is on the deprecation path.
                daqgate('privateCheckObsoleteAdaptor', className, adaptor);
                
                obj = localCreateDigitalIOObject(className,param{:});     
            catch thisException
                % OK, they both failed, but which error do we choose?
                % Use NIDAQmx error message if it was installed, but NIDAQ
                % traditional wasn't
                if ~strcmp(nidaqmxException.identifier,'daq:digitalio:invalidadaptor') &&...
                    strcmp(thisException.identifier,'daq:digitalio:invalidadaptor')
                    rethrow(nidaqmxException);
                end
                % otherwise, throw the NIDAQ error
                rethrow(thisException);
            end
        end
    end

    function [obj] = localCreateDigitalIOObject(className,varargin)
    % Use the daq package to create the digital i/o object.
      obj = [];
      try
          daqmex;
          uddobj = daq.engine.createobject( className, varargin{:} );

          % Call the constructor again to wrap UDD object in OOPS.
          obj = digitalio(uddobj);
      catch generalException
          % If the adaptor wasn't registered yet, do it and try again.
          if strcmp(generalException.identifier,'daq:adaptor:adaptorNotFound')
              try
                  % Geck 284563:  If we need to register nidaqmx, register nidaq
                  if(strcmpi(varargin{1},nidaqmxAdaptorName))
                      evalc('daqregister(nidaqAdaptorName); uddobj = daq.engine.createobject( className, varargin{:} ); obj = digitalio(uddobj);');
                  else
                      evalc('daqregister(varargin{1}); uddobj = daq.engine.createobject( className, varargin{:} ); obj = digitalio(uddobj);');
                  end
              catch nidaqException
                  generalException = nidaqException;
              end
          end    
          
          % Still didn't work
          if isempty(obj)
             if strcmp(generalException.identifier,'daq:adaptor:adaptorNotFound')
                 error('daq:digitalio:invalidadaptor', generalException.message);
             else
                 error('daq:digitalio:unexpected', generalException.message);
             end
          end
      end
    end
end