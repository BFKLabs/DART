function daqsupport(varargin)
%DAQSUPPORT Debugging utility.
%
%    DAQSUPPORT('ADAPTOR'), where ADAPTOR is the name of the data
%    acquisition card you are using, returns diagnostic information to
%    help troubleshoot setup problems.  Output is saved in a text file,
%    DAQTEST.
%
%    DAQSUPPORT('ADAPTOR','FILENAME'), saves the results to the text file
%    FILENAME.
%
%    DAQSUPPORT tests all installed hardware adaptors.
%
%    Examples:
%       daqsupport('winsound')
%       daqsupport('winsound','myfile.txt')

%   SM 4-15-99
%   Copyright 2011-2013 The MathWorks, Inc.

localSaveRestoreWarningState;

filename = 'daqtest.txt';
adaptors = [];
onWin64 = strcmp(computer('arch'), 'win64');

% If we discover that any of the registered adaptors did not match the
% current matlabroot we will warn the user to restart MATLAB.
warnAboutAdaptorMismatch = false;
			
if( ~onWin64 )
    try
        hwInfo = daqhwinfo;
    catch e
        error('daq:daqsupport:daqhwinfofailed','Unable to execute daqhwinfo, no information will be generated.')
    end
end
    
switch nargin,
    case 0,
        if( ~onWin64 )
            adaptors = hwInfo.InstalledAdaptors;
        end
        try
            vendors = daq.getVendors;
            sessionAdaptors = {vendors.ID};
        catch e
            error('daq:daqsupport:getVendors', ['Unable to execute daq.getVendors, no information will be generated.' ...
                                                e.message]);
        end
    
    case 1,
        adaptors = varargin(1);
        sessionAdaptors = varargin(1);
    case 2,
        adaptors = varargin(1);
        sessionAdaptors = varargin(1);
        filename = varargin{2};
    otherwise,
        ArgChkMsg = nargchk(0,2,nargin); %#ok<NCHK>
        if ~isempty(ArgChkMsg)
            localSaveRestoreWarningState;
            error('daq:daqsupport:argcheck', ArgChkMsg);
        end
end % switch

% Check that adaptor string is contained in a cell.
if( ~onWin64 )
    if ( ~iscellstr(adaptors))
        localSaveRestoreWarningState;
        error('daq:daqsupport:argcheck', 'ADAPTOR must be specified as a string.')
    end
end

if ( ~iscellstr(sessionAdaptors))
        localSaveRestoreWarningState;
        error('daq:daqsupport:argcheck', 'ADAPTOR must be specified as a string.')
end


nidaqmxAdaptorName = 'nidaqmx';
if( ~isempty(adaptors) )
    if ~isempty(strfind(adaptors{1},nidaqmxAdaptorName))
        localSaveRestoreWarningState;
        % Geck 281433:  We explicitly block direct access to the NIDAQmx
        % adaptor in order to ensure that it's not an "undocumented" feature.
        error('daq:daqhwinfo:unexpected','Failure to find requested data acquisition device: nidaqmx.');
    end
end

% Check that the filename is a string.
if ~ischar(filename),
    localSaveRestoreWarningState;
    error('daq:daqsupport:argcheck', 'FILENAME must be specified as a string.')
end

% Delete the output file if it already exists.
if ~isempty(dir(filename))
    delete(filename);
end

% Wrap diagnostic generation in a try/catch so on fatal error we can notify the user.
try
    % Display message to command window.
    disp('Generating diagnostic information ...');

    dispCapture = [];
    cr = sprintf('\n');
    sp = sprintf(' %s','----------'); %#ok<NASGU>

    % General Info
    dispCapture = [dispCapture evalc('disp([cr,sp,''General Information '',sp])')];

    % Current Time and date
    dispCapture = [dispCapture evalc('disp([cr,''Current Time & Date: '']);disp(datestr(now))')];

    % MATLAB and Data Acquisition Toolbox version
    try
        % Catch any errors in case the current directory is a UNC path.
        vOS=evalc('!ver');
    catch e
        localSaveRestoreWarningState;
        error('daq:daqsupport:uncpath', ...
            'DAQSUPPORT can not execute when the current directory is a UNC path.');
    end
    vOS=vOS(3:end-1); %#ok<NASGU>
    dispCapture = [dispCapture evalc('disp([cr,''Operating System: '']);disp(vOS)')];

    % Capture hardware configuration.
    try
        % Record the CPU information.
        dispCapture = [dispCapture evalc('disp([cr,''Hardware Configuration:'']);disp(feature(''getcpu''))')];
        % Record the CPU clock speed.
        mhz = num2str(ceil(matlab.internal.timing.timing('cpuspeed')/1000000));
        dispCapture = [dispCapture 'The measured CPU speed is ' mhz ' MHz'];

        % Record the computer memory size.
        cmp    = evalc('feature(''memstats'')');
        pts    = strfind(cmp, 'Total:');
        mem    = regexp(cmp(pts(1):end), '[0-9]+', 'once', 'match');
        dispCapture = [dispCapture cr 'RAM is ' mem ' MB'];
        
        % And the amount of swap space.
        mem    = regexp(cmp(pts(2):end), '[0-9]+', 'once', 'match');
        dispCapture = [dispCapture cr 'Swap space is ' mem ' MB' cr];
        
        % Use the standard Windows environment variables to capture
        % whether where on a 32 or 64 bit machine.
        processor_architecture = getenv('PROCESSOR_ARCHITECTURE');
        dispCapture = [dispCapture cr 'PROCESSOR_ARCHITECTURE = ' processor_architecture];

        processor_architew6432 = getenv('PROCESSOR_ARCHITEW6432');
        if isempty(processor_architew6432)
            dispCapture = [dispCapture cr 'PROCESSOR_ARCHITEW6432 = undefined' cr];
        else
            dispCapture = [dispCapture cr 'PROCESSOR_ARCHITEW6432 = ' processor_architew6432  cr];
        end
    catch e %#ok<NASGU>
        % Ignore any failures in the above block. The command 'feature' is
        % undocumented and can change without warning.
    end

    [v,d] = version;  %#ok<ASGLU,NASGU> % MATLAB version information
    dispCapture = [dispCapture evalc('disp([cr,''MATLAB version: '']);disp(v)')];

    if isdeployed()
        % Ver doesn't work in deployed applications
        daqver = 'Toolbox version info is not available in deployed applications.'; %#ok<NASGU>
    else
        daqver = ver('daq'); %#ok<NASGU> Data Acquistion version information
    end
    dispCapture = [dispCapture evalc('disp([cr,''Data Acquisition Toolbox version: '']); disp(daqver)')];

    %MATLAB License Number
    dispCapture = [dispCapture evalc('disp([cr,''MATLAB License Number:'']);disp(license)')];

    if ~onWin64
        % DAQMEM information
        dispCapture = [dispCapture evalc('disp([cr,sp,''Memory Information: '',sp]); disp(daqmem)')];
    end
    
    % Find the MATLABROOT directory (use CTF root when we're deployed)
    if isdeployed
        root = ctfroot;  %#ok<NASGU>
        % Display to screen
        dispCapture = [dispCapture evalc('disp([cr,sp,''CTF root directory: '',sp]);disp(root)')];
    else
        root = matlabroot;  %#ok<NASGU>
        % Display to screen
        dispCapture = [dispCapture evalc('disp([cr,sp,''MATLAB root directory: '',sp]);disp(root)')];
    end

    % toolbox directory
    % Display to screen
    datroot = toolboxdir('daq'); %#ok<NASGU>
    dispCapture = [dispCapture evalc('disp([cr,sp,''Data Acquisition Toolbox directory: '',sp]);disp(datroot)')];

    if ~onWin64
        % Output daqhwinfo and expand adaptor list
        dispCapture = [dispCapture evalc(['disp([cr,sp,''DAQ Legacy Interface Hardware Available: '',sp,cr]);disp(hwInfo),',...
            'disp([cr,sp,''Adaptor List'',sp,cr]);disp(hwInfo.InstalledAdaptors)'])];
        
        for lp=1:length(adaptors),
            % Display adaptor being tested %
            dispCapture = [dispCapture evalc('disp([cr,sp,adaptors{lp} '' adaptor:'',sp])')]; %#ok<AGROW>
            
            try
                dispCapture = [dispCapture evalc('disp([cr,sp,''Registering adaptor: '' adaptors{lp},sp]),')]; %#ok<AGROW>
                result = daqregister(adaptors{lp});
                if ~isempty(strfind (result,'successfully registered'))
                    dispCapture = [dispCapture evalc('disp([cr,''Successfully registered '' adaptors{lp} '' adaptor'']);')]; %#ok<AGROW>
                else
                    ME = MException('daqsupport:CouldNotRegister', ...
                        'Could not register adaptor %s: %s', adaptors{lp}, result);
                    throw (ME);
                end
            catch e %#ok<NASGU>
                dispCapture = [dispCapture evalc(['disp([cr,''Error registering '' adaptors{lp} '' adaptor'']),',...
                    'disp([cr,e.message])'])]; %#ok<AGROW>
            end % try
            
            try
                dispCapture = [dispCapture evalc(['disp([cr,sp,''Adaptor Information for adaptor '',adaptors{lp},sp,cr]),',...
                    'adaptorInfo=daqhwinfo(adaptors{lp})'])]; %#ok<AGROW>
                if ~isempty(adaptorInfo)
                    adaptorMismatchWarning = privateCheckAdaptorMismatch(adaptors{lp});
                    if ~isempty(adaptorMismatchWarning)
                        warnAboutAdaptorMismatch = true;
                    end
                    
                    dispCapture = [dispCapture evalc('disp([cr,sp,''Adaptor DLL Name'',sp,cr]);disp(adaptorInfo.AdaptorDllName),')];  %#ok<AGROW>
                    
                    adaptorDllInfo = dir(adaptorInfo.AdaptorDllName);
                    if ~isempty(adaptorDllInfo)
                        dispCapture = [dispCapture evalc('disp([cr,''Size: '', num2str(adaptorDllInfo.bytes), '',  Date: '', adaptorDllInfo.date])')]; %#ok<AGROW>
                    end
                    
                    if isempty(strfind(lower(adaptorInfo.AdaptorDllName),'toolbox\daq\daq\private'))
                        dispCapture = [dispCapture evalc('disp([cr,''This adaptor is developed and supported by the hardware manufacturer.''])')]; %#ok<AGROW>
                    else
                        dispCapture = [dispCapture evalc('disp([cr,''This adaptor is developed and supported by MathWorks.''])')]; %#ok<AGROW>
                    end
                    
                    dispCapture = [dispCapture evalc('disp([cr adaptorMismatchWarning])')];  %#ok<AGROW>
                    dispCapture = [dispCapture evalc('disp([cr,sp,''Adaptor Name'',sp,cr]);disp(adaptorInfo.AdaptorName)')]; %#ok<AGROW>
                    dispCapture = [dispCapture evalc('disp([cr,sp,''Object Constructor Names '',sp,cr]);')]; %#ok<AGROW>
                    for inLp2 = 1:numel(adaptorInfo.ObjectConstructorName)
                        dispCapture = [dispCapture evalc('disp(adaptorInfo.ObjectConstructorName{inLp2})')]; %#ok<AGROW>
                    end % for
                    
                    nidaqAdaptorName = 'nidaq';
                    if strcmpi(adaptorInfo.AdaptorName,nidaqAdaptorName)
                        % Geck 281433:  If NIDAQ is installed, add a special case
                        % to retrieve additional info about NIDAQ adaptor, in case
                        % NIDAQmx adaptor is "shadowing" it
                        try
                            dispCapture = [dispCapture evalc(['disp([cr,sp,''Additional Adaptor Information for adaptor '',nidaqAdaptorName,sp,cr]),',...
                                'xtraInfo=daq.engine.getadaptorinfo(nidaqAdaptorName)'])]; %#ok<AGROW>
                            if ~isempty(xtraInfo)
                                dispCapture = [dispCapture evalc(['disp([cr,sp,''Adaptor DLL Name'',sp,cr]);disp(xtraInfo.AdaptorDllName),',...
                                    'disp([cr,sp,''Adaptor Name'',sp,cr]);disp(xtraInfo.AdaptorName)'])]; %#ok<AGROW>
                            end % if ~isempty(xtraInfo)
                        catch e %#ok<NASGU>
                            % if it errors, then nidaq traditional isn't installed,
                            % and we can ignore it
                            dispCapture = [dispCapture evalc(['disp([cr,sp,''Additional Adaptor Information for adaptor '',nidaqAdaptorName,sp,cr]),',...
                                'disp(''NIDAQ Traditional is not installed.'')'])]; %#ok<AGROW>
                        end
                    end % if strcmpi
                end % if ~isempty(adaptorInfo)
            catch e %#ok<NASGU>
                dispCapture = [dispCapture evalc('disp([cr,''Error displaying DAQHWINFO for adaptor '',adaptors{lp}])')]; %#ok<AGROW>
                dispCapture = [dispCapture evalc('disp(e.message)')]; %#ok<AGROW>
                adaptorInfo = [];
            end % try
            
            % Test all Analoginput, Analogoutput, Digital I/O objects
            if ~isempty(adaptorInfo)
                sizeObjectConstructorName = size(adaptorInfo.ObjectConstructorName);
                for inLp=1:sizeObjectConstructorName(1)
                    for inLp2=1:sizeObjectConstructorName(2)
                        objConstructorString = adaptorInfo.ObjectConstructorName{inLp,inLp2};
                        if ~isempty(objConstructorString) &&...
                                isempty(strfind(objConstructorString,'Requires daq.createSession')) &&...
                                isempty(strfind(objConstructorString,'Not Supported'))
                            try
                                dispCapture = [dispCapture evalc('disp([cr,sp,''Creating '' objConstructorString '' object for adaptor '' adaptors{lp},sp])')]; %#ok<AGROW>
                                b=eval(objConstructorString);
                                dispCapture = [dispCapture evalc('b') cr]; %#ok<AGROW>
                                uddb = daqgetfield(b, 'uddobject');
                                if isprop(uddb,'IsSimulated')
                                    if strcmpi(uddb.IsSimulated, 'On')
                                        dispCapture = [dispCapture evalc('disp([''Device is simulated.'',cr])')];  %#ok<AGROW>
                                    end
                                end
                                dispCapture = [dispCapture evalc('daqhwinfo(b)')]; %#ok<AGROW>
                                delete(b);
                            catch e %#ok<NASGU>
                                dispCapture = [dispCapture evalc('disp([cr,''Error creating '' adaptorInfo.ObjectConstructorName{inLp,inLp2} '' object for adaptor'' adaptors{lp}])')]; %#ok<AGROW>
                                dispCapture = [dispCapture evalc('disp(e.message)')]; %#ok<AGROW>
                            end % try
                        end %if ~isempty(adaptorInfo.ObjectConstructorName{inLp})
                    end %for inLp2
                end %for inLp
            end % if ~isempty(adaptorInfo)
            
        end % for lp
    end
    
    % Collect information for Session Based Adaptors
    dispCapture = [dispCapture evalc('disp([cr,sp,''DAQ Session Based Vendors Available: '',sp,cr])')];
   	dispCapture = [dispCapture evalc('feature(''hotlinks'', 0);disp(daq.getVendors)')];
    dispCapture = [dispCapture evalc('disp([cr,sp,''DAQ Session Based Devices Available: '',sp,cr])')];
	dispCapture = [dispCapture evalc('feature(''hotlinks'', 0);disp(daq.getDevices)')];
    devices = daq.getDevices;
      
    % Print device details only if devices are present.
    if ~isempty(devices)
        dispCapture = [dispCapture evalc('disp([cr,sp,''Session Based Device Details: '',sp,cr])')];
        for iSessionAdaptors = 1:length(sessionAdaptors)
              dispCapture = [dispCapture evalc('disp([sp,''Device Details for vendor: '',sessionAdaptors{iSessionAdaptors},sp,cr])')]; %#ok<AGROW>
            for iDevices = 1:length(devices)
                currentDevice = devices(iDevices);
                currentVendorID = currentDevice.Vendor.ID;
                
                if( strcmp(currentVendorID, sessionAdaptors{iSessionAdaptors}))
                    dispCapture = [dispCapture evalc('disp([cr,sp,''Device '',num2str(iDevices),sp,cr])')]; %#ok<AGROW>
                    dispCapture = [dispCapture evalc('feature(''hotlinks'', 0);disp(devices(iDevices))')]; %#ok<AGROW>
                    
                    % The only vendor that supports 'IsSimulated' is 'ni'.
                    if strcmpi(currentVendorID, 'ni')
                        if currentDevice.IsSimulated
                            dispCapture = [dispCapture evalc('disp([''Device is simulated.'',cr])')];  %#ok<AGROW>
                        end
                    end
                    for subsys = 1:length(currentDevice.Subsystems)
                        dispCapture = [dispCapture evalc('get(devices(iDevices).Subsystems(subsys))')]; %#ok<AGROW>
                    end
                end
            end
        end
    end
    
    
    % MATLAB path
    % Display to screen
    dispCapture = [dispCapture evalc('disp([cr,sp,''MATLAB path: '',sp]);path')];
    
    dispCapture = [dispCapture evalc(['disp([cr,sp,sp,''End test'',sp,sp]),',...
        'disp([cr,''This information has been saved in the text file:'',cr,filename]),',...
        'disp([cr,''If any errors occurred, please visit the MathWorks Technical Support Web Site'',cr,''at http://www.mathworks.com/contact_TS.html ''])'])];

    if warnAboutAdaptorMismatch == true
        disp('WARNING: The version of one or more registered adaptors did not match this release of MATLAB.')
        disp('The correct adaptor version has been automatically registered.')
        disp('You must EXIT and restart MATLAB for this registration to take effect.')
    end
    
    % Open the file up for writing.

    [fid, errMsg] = fopen(filename, 'wt');

    % Verify the file is accessible.
    if fid==-1
        disp(dispCapture);
        disp([cr,'WARNING: Unable create the output file in current directory.' cr 'Error: ' errMsg cr 'Information being output to the command window only.'])
    else

        % Write information out.
        fprintf(fid,'%s',dispCapture);
        fclose(fid);
        % Don't do this in a deployed application
        if ~isdeployed()
            edit(filename)
        end
    end

catch e
    % Catch any otherwise uncaught errors from the try that wraps the entire file
    % Output everything we've already collected. Where it ends will help us
    % know what went wrong.
    disp(dispCapture);
    
    localSaveRestoreWarningState;
    error('daq:daqsupport:uncaughterror', ...
        'DAQSUPPORT caught an unhandled error. Only partial information has been generated and output to the command window.\nError:%s',...
        e.message);

end

localSaveRestoreWarningState;

% end daqsupport

function localSaveRestoreWarningState
% First time called will save the warning state and suppress the warnings of
% interest.
% Second time called will restore the state.

persistent OldWarningState;
persistent AdaptorMismatchWarningStateAI;
persistent AdaptorMismatchWarningStateAO;
persistent AdaptorMismatchWarningStateDIO;
persistent SessionBasedInterfaceWarningState;
persistent AdaptorObsoleteDIOState;
persistent AdaptorObsoleteAIState;
persistent AdaptorObsoleteAOState;

if isempty(OldWarningState)
    OldWarningState = warning('off', 'backtrace');

    % We put the adaptor mismatch warning into the output and don't need to
    % display it when creating the test objects.
    AdaptorMismatchWarningStateAI  = warning('off','daq:analoginput:adaptormismatch');
    AdaptorMismatchWarningStateAO  = warning('off','daq:analogoutput:adaptormismatch');
    AdaptorMismatchWarningStateDIO = warning('off','daq:digitalio:adaptormismatch');
    SessionBasedInterfaceWarningState = warning('off','daq:daqhwinfo:v3');
    AdaptorObsoleteDIOState = warning('off','daq:digitalio:adaptorobsolete');
    AdaptorObsoleteAIState = warning('off','daq:analoginput:adaptorobsolete');
    AdaptorObsoleteAOState = warning('off','daq:analogoutput:adaptorobsolete');
else
    warning(OldWarningState); 
    % Clear old warning state in case program run again (persistent hold
    % the value between runs.
    OldWarningState = [];
    warning(AdaptorMismatchWarningStateAI); 
    warning(AdaptorMismatchWarningStateAO); 
    warning(AdaptorMismatchWarningStateDIO); 
    warning(SessionBasedInterfaceWarningState); 
    warning(AdaptorObsoleteDIOState);
    warning(AdaptorObsoleteAIState);
    warning(AdaptorObsoleteAOState);
end

