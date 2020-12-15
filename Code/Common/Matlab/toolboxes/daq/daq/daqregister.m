function result = daqregister(varargin)
%DAQREGISTER Register or unregister Data Acquisition Toolbox adaptor DLLs. 
%
%    DAQREGISTER('ADAPTOR') registers the ADAPTOR for the Data Acquisition
%    Toolbox.  
%
%    DAQREGISTER('ADAPTOR','unload') unregisters ADAPTOR. 
%
%    RESULT = DAQREGISTER(...) captures the resulting message in RESULT.
%
%    Example:
%      daqregister('nidaq')
%
%    See also DAQHELP.
%

%    Copyright 1998-2008 The MathWorks, Inc.
%    $Revision: 1.11.2.11 $  $Date: 2008/06/16 16:34:26 $

% Adaptor names used by special case code
nidaqName = 'nidaq';
nidaqmxName = 'nidaqmx';

ArgChkMsg = nargchk(1,2,nargin);
if ~isempty(ArgChkMsg)
    error('daq:daqregister:argcheck', ArgChkMsg);
end

if ~iscellstr(varargin), 
   error('daq:daqregister:argcheck', 'ADAPTOR and the ''unload'' option must be strings.')
end

if ~isempty(strfind(lower(varargin{1}),nidaqmxName))
    % Geck 281433:  We explicitly block direct access to the NIDAQmx
    % adaptor in order to ensure that it's not an "undocumented" feature.
    result = '''nidaqmx.dll'' not found.  Make sure it is on the MATLAB path.';
    return
end         

% If two arguments passed in, then user is attempting to use the 'unload' option.
if nargin == 2,
   option=varargin{2};
   if ~strcmpi(option,'unload'),
      error('daq:daqregister:argcheck', 'The second input: ''%s'' is not recognized.\nTo unload the ADAPTOR, the second input argument must be ''unload''.', option)
   end
else
   option = '';
end

result = localDaqRegister(varargin{1:end});

    function [result] = localDaqRegister(varargin)
    % Local version so that we can bypass the nidaqmx registration restriction

    % Register all UDD classes.
    daqmex;

    % Determine what was provided by the user:
    [filepath, name, ext]=fileparts(varargin{1});

    if isempty(filepath),
       % If no path specified, check the extension.
       % If no extension, prepend with 'mw' and append with '.dll'.
       % If extension specified, then we have the dll name.
       if isempty(ext)
          dll=['mw', name, '.dll'];
          if exist(dll)~=3
                dll=[name, '.dll'];
          end
       else
          dll=varargin{1};
       end

       % Since no path provided, use which to find where the file lives.
       % If the file is not found, and the user was attempting to
       % register, we display message and return. If the user was 
       % attempting to unregister, we continue on.
       dllpath=which(dll);
       if isempty(dllpath)
          if isempty(option)
             if nargout == 1
                result = sprintf(['''', dll, ''' not found.  Make sure it is on the MATLAB path.']);
             else
                warning('daq:daqregister:notfound', '''%s'' not found.  Make sure it is on the MATLAB path.', dll);
             end
             return
          end
       end

    else
       % If path was specified, then we use it and assemble the
       % dll name with extension..
       dll=[name, ext];
       dllpath=[filepath, filesep, name, ext];
    end

    nidaqmxregistersucceeded = false;
    if ~isempty(strfind(lower(dll),nidaqName)) && isempty(strfind(lower(dll),nidaqmxName))
        % Geck 281433:  In order to make NIDAQmx and NIDAQ adaptors look like a
        % single adaptor, we register nidaqmx as well when NIDAQ is registered.
        callargs = varargin;
        callargs{1} = nidaqmxName;
        try
            localDaqRegister(callargs{1:end});
            nidaqmxregistersucceeded = true;
        catch e %#ok<NASGU>
            % Ignore any and all errors from this attempt
        end
    end

    
    try
        % Register
        if isempty(option)
            try
                % Determine adaptor path
                adaptorpath=fileparts(dllpath);
                % Save current directory
                curPath = pwd; 
                % Determine if adaptor is an internal adaptor (i.e. in \private)
                if ~isempty(findstr(adaptorpath, 'private'))
                    % Change to adaptor directory for registration
                    cd (adaptorpath);
                end
                % Register adaptor with daq engine
                daq.engine.registeradaptor(dllpath);
            catch e
                % If we failed to register nidaq, but succeeded in nidaqmx,
                % then we succeeded.
                cd(curPath);		
                if nidaqmxregistersucceeded
                    result = sprintf('%s','''',dll,''' successfully registered.');
                    return
                end
                if nargout == 1
                    result = e.message;
                    return;
                else
                    error('daq:daqregister:unexpected', '%s', e.message);
                end
            end
            % Restore saved directory
            cd(curPath);		
            result = sprintf('%s','''',dll,''' successfully registered.');
        % Unregister
        else
            try
                % Determine adaptor path
                adaptorpath=fileparts(dllpath);
                % Save current directory
                curPath = pwd; 
                % Determine if adaptor is an internal adaptor (i.e. in \private)
                if ~isempty(findstr(adaptorpath, 'private'))
                    % Change to adaptor directory for registration
                    cd (adaptorpath);
                end
                daq.engine.unregisteradaptor(dllpath);
            catch e %#ok<NASGU>
                cd(curPath);		
                warning('daq:daqregister:unregister', 'Unable to self unregister adaptor.  Manually removing from registry')
                daq.engine.unregisteradaptor(name);
            end
            % Restore saved directory
            cd(curPath);		
            result = sprintf('%s','''',dll,''' successfully unregistered.');
        end
    catch e
       if nargout == 1
          result = e.message;
          return;
       else
          error('daq:daqregister:unexpected', '%s', e.message);
       end
    end
end
end