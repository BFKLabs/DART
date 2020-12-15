% Data Acquisition Toolbox
% DAQ Legacy Interface
%
% Note: For daq session based interface, see <a href="matlab:help SESSIONBASEDINTERFACE">Session Based Interface</a>.
%
% Data acquisition object construction.
%   <a href="matlab:help daq/analoginput">daq/analoginput</a>   - Construct analog input object.
%   <a href="matlab:help daq/analogoutput">daq/analogoutput</a>  - Construct analog output object.
%   <a href="matlab:help daq/digitalio">daq/digitalio</a>     - Construct digital input/output object.
%
% Getting and setting parameters.
%   <a href="matlab:help daqdevice/get">daqdevice/get</a>     - Get value of data acquisition object property.
%   <a href="matlab:help daqdevice/set">daqdevice/set</a>     - Set value of data acquisition object property.
%   <a href="matlab:help daqdevice/inspect">daqdevice/inspect</a> - Open property inspector and configure data acquisition 
%                       object properties.         
%   <a href="matlab:help setverify">setverify</a>         - Set and return value of data acquisition object 
%                       property.   
%
% Execution.
%   <a href="matlab:help daqdevice/start">daqdevice/start</a>   - Start object running.
%   <a href="matlab:help daqdevice/stop">daqdevice/stop</a>    - Stop object running and logging/sending. 
%   <a href="matlab:help daqdevice/trigger">daqdevice/trigger</a> - Manually initiate logging/sending for running object.
%   <a href="matlab:help daqdevice/wait">daqdevice/wait</a>    - Wait for the object to stop running.
%
% Analog input functions.
%   <a href="matlab:help addchannel">addchannel</a>        - Add channels to analog input object.
%   <a href="matlab:help addmuxchannel">addmuxchannel</a>     - Add mux'd channels to analog input object.
%   <a href="matlab:help flushdata">flushdata</a>         - Remove data from engine.
%   <a href="matlab:help getdata">getdata</a>           - Return acquired data samples.
%   <a href="matlab:help getsample">getsample</a>         - Immediately acquire a single sample.
%   <a href="matlab:help muxchanidx">muxchanidx</a>        - Return scan channel index associated with mux board.
%   <a href="matlab:help peekdata">peekdata</a>          - Preview most recent acquired data.
%   <a href="matlab:help islogging">islogging</a>         - Determine if object is logging data.
%
% Analog output functions.
%   <a href="matlab:help addchannel">addchannel</a>        - Add channels to analog output object.
%   <a href="matlab:help putdata">putdata</a>           - Queue data samples for output.
%   <a href="matlab:help putsample">putsample</a>         - Immediately output single sample to object.
%   <a href="matlab:help issending">issending</a>         - Determine if object is sending data.
%
% Digital input/output functions.
%   <a href="matlab:help addline">addline</a>           - Add lines to digital input/output object.
%   <a href="matlab:help getvalue">getvalue</a>          - Read line values.
%   <a href="matlab:help putvalue">putvalue</a>          - Write line values.
%
% General.
%   <a href="matlab:help binvec2dec">binvec2dec</a>        - Convert binary vector to decimal number.
%   <a href="matlab:help daq/private/clear">daq/private/clear</a> - Clear data acquisition object from the workspace. 
%   <a href="matlab:help daqcallback">daqcallback</a>       - Display event information for specified event.
%   <a href="matlab:help daqfind">daqfind</a>           - Find specified data acquisition objects.
%   <a href="matlab:help daqmem">daqmem</a>            - Allocate or display memory for one or more device 
%                       objects.
%   <a href="matlab:help daqread">daqread</a>           - Read Data Acquisition Toolbox (.daq) data file.
%   <a href="matlab:help daqregister">daqregister</a>       - Register or unregister adaptor DLLs.
%   <a href="matlab:help daqreset">daqreset</a>          - Delete and unload all data acquisition objects and 
%                       DLLs.
%   <a href="matlab:help daqdevice/delete">daqdevice/delete</a>  - Remove data acquisition objects from the engine.
%   <a href="matlab:help dec2binvec">dec2binvec</a>        - Convert decimal number to binary vector.
%   <a href="matlab:help ischannel">ischannel</a>         - Determine if object is a channel.
%   <a href="matlab:help isdioline">isdioline</a>         - Determine if object is a line.
%   <a href="matlab:help isvalid">isvalid</a>           - Determine if object is associated with hardware.
%   <a href="matlab:help isrunning">isrunning</a>         - Determine if object is running.
%   <a href="matlab:help length">length</a>            - Determine length of data acquisition object.
%   <a href="matlab:help daq/private/load">daq/private/load</a>  - Load data acquisition objects from disk into MATLAB
%                       workspace.
%   <a href="matlab:help makenames">makenames</a>         - Generate cell array of names for naming channels/lines.
%   <a href="matlab:help obj2mfile">obj2mfile</a>         - Convert data acquisition object to MATLAB code.
%   <a href="matlab:help daq/private/save">daq/private/save</a>  - Save data acquisition objects to disk.
%   <a href="matlab:help showdaqevents">showdaqevents</a>     - Display summary of event log.
%   <a href="matlab:help size">size</a>              - Determine size of data acquisition object.
%   <a href="matlab:help softscope">softscope</a>         - Data Acquisition oscilloscope GUI.
%
% Information and help.
%   <a href="matlab:help daqhelp">daqhelp</a>           - Data acquisition property and function help.
%   <a href="matlab:help daqhwinfo">daqhwinfo</a>         - Information on available hardware.
%   <a href="matlab:help daqsupport">daqsupport</a>        - Data acquisition technical support tool.
%   <a href="matlab:help propinfo">propinfo</a>          - Property information for data acquisition objects.
%
% Data acquisition demos.
%   <a href="matlab:help demodaq_intro">demodaq_intro</a>     - Introduction to Data Acquisition Toolbox.
%   <a href="matlab:help demodaq_save">demodaq_save</a>      - Methods for saving and loading data acquisition objects.
%   <a href="matlab:help demodaq_callback">demodaq_callback</a>  - Introduction to data acquisition callback functions.
%   <a href="matlab:help daqtimerplot">daqtimerplot</a>      - Example callback function which plots the data acquired.
%
% Analog input demos.
%   <a href="matlab:help daqrecord">daqrecord</a>         - Record data from the specified adaptor.
%   <a href="matlab:helpview(fullfile(matlabroot, 'toolbox', 'daq', 'daqdemos', 'html', 'demoai_channel.html'))">Introduction to analog input channels.</a>
%   <a href="matlab:helpview(fullfile(matlabroot, 'toolbox', 'daq', 'daqdemos', 'html', 'demoai_fft.html'))">FFT display of an incoming analog input signal.</a>
%   <a href="matlab:helpview(fullfile(matlabroot, 'toolbox', 'daq', 'daqdemos', 'html', 'demoai_intro.html'))">Introduction to analog input objects.</a>
%   <a href="matlab:helpview(fullfile(matlabroot, 'toolbox', 'daq', 'daqdemos', 'html', 'demoai_logging.html'))">Demonstrate data logging.</a>
%   <a href="matlab:helpview(fullfile(matlabroot, 'toolbox', 'daq', 'daqdemos', 'html', 'demoai_trig.html'))">Demonstrate the use of immediate, manual and software triggers.</a>
%   <a href="matlab:help daqscope">daqscope</a>          - Example function generator for the Data Acquisition Toolbox.
%   
% Analog output demos.
%   <a href="matlab:help daqplay">daqplay</a>           - Output data to the specified adaptor.
%   <a href="matlab:helpview(fullfile(matlabroot, 'toolbox', 'daq', 'daqdemos', 'html', 'demoai_trig.html'))">Demonstrate the use of immediate, manual and software triggers.</a>
%   <a href="matlab:helpview(fullfile(matlabroot, 'toolbox', 'daq', 'daqdemos', 'html', 'demoao_channel.html'))">Introduction to analog output channels.</a>
%   <a href="matlab:helpview(fullfile(matlabroot, 'toolbox', 'daq', 'daqdemos', 'html', 'demoao_intro.html'))">Introduction to analog output objects.</a>
%   <a href="matlab:helpview(fullfile(matlabroot, 'toolbox', 'daq', 'daqdemos', 'html', 'demoao_trig.html'))">Demonstrate the use of immediate and manual triggers.</a>
%   <a href="matlab:help daqfcngen">daqfcngen</a>        - Output data to the specified adaptor.
%
% Digital I/O demos.
%   <a href="matlab:helpview(fullfile(matlabroot, 'toolbox', 'daq', 'daqdemos', 'html', 'demodio_intro.html'))">Introduction to digital I/O objects.</a>
%   <a href="matlab:helpview(fullfile(matlabroot, 'toolbox', 'daq', 'daqdemos', 'html', 'demodio_line.html'))">Introduction to digital I/O lines.</a>
%   <a href="matlab:help diopanel">diopanel</a>         - Display digital I/O panel.
%
% See also <a href="matlab:help SESSIONBASEDINTERFACE">Session Based Interface</a>.
%

% MP 5-29-98
% Copyright 1998-2012 The MathWorks, Inc.

