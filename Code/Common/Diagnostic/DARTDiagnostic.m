function varargout = DARTDiagnostic(varargin)
% Last Modified by GUIDE v2.5 19-Dec-2013 03:33:33

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DARTDiagnostic_OpeningFcn, ...
                   'gui_OutputFcn',  @DARTDiagnostic_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before DARTDiagnostic is made visible.
function DARTDiagnostic_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for DARTDiagnostic
handles.output = hObject;

% sets the font-size
if (ispc)
    fSize = 9;
else
    fSize = 10;    
end

% sets the diagnostic strings into the listbox
h = waitbar(0,'Generating Program Diagnostic Report...');
set(handles.listDiagText,'string',checkSystemConfig,'fontsize',fSize)
centreFigPosition(hObject);

% closes the waitbar
waitbar(1,h,'Report Generation Complete!'); pause(0.1); close(h)

% Update handles structure
guidata(hObject, handles);

% % UIWAIT makes DARTDiagnostic wait for user response (see UIRESUME)
set(hObject,'WindowStyle','modal')

% --- Outputs from this function are returned to the command line.
function varargout = DARTDiagnostic_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = [];

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------%

% --- function that determines if the 
function totStr = checkSystemConfig()

% global variables
global mainProgDir

% memory allocation
wState = warning('off','all');
[nCheck,a,recOK,warnOK,trkOK] = deal(4,'',true,true,true);
[hStr,tStr,tCol] = deal(cell(nCheck,1));
hCol = repmat({repmat({'k'},3,1)},nCheck,1);

% sets the overall 
tStr{1} = {{'DIVX Codecs'};{'Image Acquisition Adaptors'};...
       {'Data Acquisition Adaptors'};{'Requisite Matlab Toolboxes'};{a};...
       {'Recording Program'};{'Tracking Program'};{a};{'Other Warnings:'}};
tCol{1} = repmat({{'g'}},length(tStr{1}),1);       

% sets the header string
hStr1 = '*** OVERALL PROGRAM STATUS ***'; b = {repmat('*',1,length(hStr1))};
hStr{1} = [b;hStr1;b];

% ------------------------- %
% --- IMAQ DRIVER CHECK --- %
% ------------------------- %

% retrieves the image acquistion information 
try
    imaqInfo = imaqhwinfo;
    adaptIMAQ = imaqInfo.InstalledAdaptors;
    adaptIMAQ = reshape(adaptIMAQ,length(adaptIMAQ),1);
catch
    adaptIMAQ = []; 
end
    
% sets the header string
hStr2 = '*** IMAGE ACQUISITION ADAPTORS ***'; b = {repmat('*',1,length(hStr2))};
hStr{2} = [b;hStr2;b];

% determines if the winvideo codecs have been installed
if (isempty(adaptIMAQ))
    % if not, then output a warning
    tStr{2} = {'No Image Acquisition Drivers Detected';a;...               
               'Install image acquisition devices drivers and then type';...
               '"imaqregister(''[ADAPTOR TYPE]'') in the command prompt';a;...
               'NOTE - Run MATLAB in Administrator Mode when registering'};
    tCol{2} = [repmat({'r'},5,1);{'p'}];
    
    % flags that no adaptors were found
    tStr{1}{2}{1} = sprintf('%s - No Device Adaptors Detected',tStr{1}{2}{1});     
    tCol{1}{2}{1} = 'r';            
    
    % flag that the recording program is non functional
    if (recOK)
        recOK = false;
        tStr{1}{6}{1} = sprintf('%s - Incomplete Component Installation',tStr{1}{6}{1});     
    end
        
    % add to the errorbar string
    tStr{1}{6}{end+1} = '- Unable to detect/run any Image Acquisition devices';
    [tCol{1}{6}{1},tCol{1}{6}{end+1}] = deal('r');         
else
    % sets the adaptor types and a warning about missing camera types
    tStr{2} = {'Installed Image Acquisition Adaptors:';a};    
    tCol{2} = repmat({'k'},2,1);
    for i = 1:length(adaptIMAQ)
        tStr{2} = [tStr{2};{['* ',adaptIMAQ{i}]}];        
        tCol{2} = [tCol{2};{'g'}];        
    end
    
    % flags that adaptors were found
    tStr{1}{2}{1} = sprintf('%s - Detected',tStr{1}{2}{1});     
    
    % sets the warning string at the end of the section
    tStr{2} = [tStr{2};{a};...
               {'For missing adaptors, install the image acquisition devices drivers';...
                'and type "imaqregister(''[ADAPTOR TYPE]'') in the command prompt';a;...
                'NOTE - Run MATLAB in Administrator Mode when registering'}];
    tCol{2} = [tCol{2};repmat({'k'},4,1);{'p'}]; 
end

% ------------------------ %
% --- DAQ DRIVER CHECK --- %
% ------------------------ %

% retrieves the image acquistion information 
if (verLessThan('matlab','9.2'))
    try
        daqInfo = daqhwinfo;
        adaptDAQ = daqInfo.InstalledAdaptors;
        adaptDAQ = reshape(adaptDAQ,length(adaptDAQ),1);
    catch
        adaptDAQ = [];
    end
else
    [adaptDAQ,isOper] = getInstalledDeviceVendors();
end
    
% sets the header string
hStr3 = '*** DATA ACQUISITION ADAPTORS ***'; b = {repmat('*',1,length(hStr3))};
hStr{3} = [b;hStr3;b];

% sets the error strings and the consequence strings
daqStr = {'winsound';'mcc';'nidaq'};
rStrDAQ = {'Unable to run the Built-in Soundcard (winsound)';...
           'Unable to run Measurement Computing DAQ (mcc) devices';...
           'Unable to run National Instrument DAQ (nidaq) devices'};
tStr{3} = {'Data Acquistion Device Adaptor Driver Status:';a};
tCol{3} = repmat({'k'},2,1);       

% determines if the winvideo codecs have been installed
if (isempty(adaptDAQ))
    % if not, then output a warning
    tStr{3} = {'No Data Acquisition Drivers Detected';a;...               
               'Install data acquisition devices drivers and then type';...
               '"daqregister(''[ADAPTOR TYPE]'') in the command prompt';a;...
               'NOTE - Run MATLAB in Administrator Mode when registering'};    
    tCol{3} = [repmat({'r'},5,1);{'p'}];
    
    % flag that no devices were detected
    tStr{1}{3}{1} = sprintf('%s - No Devices Adaptors Detected',tStr{1}{3}{1});      
    tCol{1}{3}{1} = 'r';
    
    % flag that the recording program is non functional
    if (recOK)        
        tStr{1}{6}{1} = sprintf('%s - Incomplete Component Installation',tStr{1}{6}{1});     
        tCol{1}{6}{1} = 'r';
        recOK = false;
    end
    
    % adds the error flags indicating that data acquisition is not possible
    tStr{1}{6}{end+1} = '- Unable to detect/run any Data Acquisition devices';
    tCol{1}{6}{end+1} = 'r';       
else        
    % determines if the driver is detected or not       
    for i = 1:length(daqStr)
        if (any(strcmp(adaptDAQ,daqStr{i})))
            if (verLessThan('matlab','9.2'))
                try
                    appInfo = daqhwinfo(daqStr{i});                
                    if (isempty(appInfo.ObjectConstructorName))
                        % device drivers detected, but not operational
                        dType = 1;
                    else
                        % device is fully operational
                        dType = 2;
                    end
                catch
                    % can't connect to device
                    dType = 3;
                end
            else
                % sets the device driver operationality
                dType = 1 + isOper(i);
            end
                    
            switch (dType)
                case (1)
                    % sets text strings/colours
                    tStr{3} = [tStr{3};{sprintf('* %s - Driver Detected But Not Working',daqStr{i})}];                    
                    tCol{3} = [tCol{3};{'o'}];   

                    % appends the warning flag array
                    tStr{1}{9}{end+1} = ['* ',rStrDAQ{i}];
                    tCol{1}{9}{end+1} = 'o';
                    warnOK = false;                            
                case (2)
                    % driver is detected for the adaptor type
                    tStr{3} = [tStr{3};{sprintf('* %s - Driver Detected & Working',daqStr{i})}];  
                    tCol{3} = [tCol{3};{'g'}];   
                case (3)
                    % sets text strings/colours
                    tStr{3} = [tStr{3};{sprintf('* %s - Driver Not Detected',daqStr{i})}];                    
                    tCol{3} = [tCol{3};{'r'}];   

                    % appends the warning flag array
                    tStr{1}{9}{end+1} = ['* ',rStrDAQ{i}];
                    tCol{1}{9}{end+1} = 'o';
                    warnOK = false;                                  
            end
        else
            % sets text strings/colours
            tStr{3} = [tStr{3};{sprintf('* %s - Driver Not Detected',daqStr{i})}];                    
            tCol{3} = [tCol{3};{'r'}];   
            
            % appends the warning flag array
            tStr{1}{9}{end+1} = ['* ',rStrDAQ{i}];
            tCol{1}{9}{end+1} = 'o';
            warnOK = false;
        end
    end

    % flags that adaptors were found
    tStr{1}{3}{1} = sprintf('%s - Detected',tStr{1}{3}{1});         
    
    % sets the solution string for any missing adaptor types
    tStr{3} = [tStr{3};{a};...
               {'For missing adaptors, install the data acquisition device drivers';...
                'and type "daqregister(''[ADAPTOR TYPE]'') in the command prompt';a;...
                'NOTE - Run MATLAB in Administrator Mode when registering'}];
    tCol{3} = [tCol{3};repmat({'k'},4,1);{'p'}];        
end
    
% --------------------- %
% --- TOOLBOX CHECK --- %
% --------------------- %

% retrieves the toolbox versions and set the required toolbox strings
toolVer = cellfun(@(x)(x.Name),num2cell(ver),'un',0);
           
% sets the header string
hStr4 = '*** REQUISITE MATLAB TOOLBOXES ***'; b = {repmat('*',1,length(hStr4))};
hStr{4} = [b;hStr4;b];       
       
% determines if the winvideo codecs have been installed
if (isempty(toolVer))
    % if not, then output a warning
    tStr{4} = {'No Matlab Toolboxes Detected';a;...               
               'Reinstall Matlab with the requisite toolboxes'};           
    tCol{4} = repmat({'r'},5,1);

    % no toolboxes
    tStr{1}{4}{1} = sprintf('%s - No Toolboxes Detected',tStr{1}{4}{1});     
    tCol{1}{4}{1} = 'r';        
else
    % sets the toolbox strings
    [toolInd,isAllOK] = deal([1 1 2 2 2],true);
    toolStr = {'Data Acquisition Toolbox';...
               'Image Acquisition Toolbox';...
               'Image Processing Toolbox';...
               'Optimization Toolbox';...
               'Statistics and Machine Learning Toolbox';...
               'Curve Fitting Toolbox'};

    % determines if the driver is detected or not       
    for i = 1:length(toolStr)
        if any(strcmp(toolVer,toolStr{i})) || isdeployed
            % driver is detected for the adaptor type
            tStr{4} = [tStr{4};{sprintf('* %s - Detected',toolStr{i})}];  
            tCol{4} = [tCol{4};{'g'}];   
        else
            % flags that the toolbox was not found
            tStr{4} = [tStr{4};{sprintf('* %s - Not Detected',toolStr{i})}];        
            tCol{4} = [tCol{4};{'r'}];   
            isAllOK = false;
            
            if (toolInd(i) == 1)
                % flags that the recording program isn't working correctly
                if (recOK)
                    tStr{1}{6}{1} = sprintf('%s - Incomplete Component Installation',tStr{1}{6}{1});     
                    tCol{1}{6}{1} = 'r';                              
                    recOK = false;
                end
                
                % adds in the error string
                tStr{1}{6}{end+1} = sprintf('- Missing Toolbox - "%s"',toolStr{i});
                tCol{1}{6}{end+1} = 'r';                
            else
                % flags that the recording program isn't working correctly
                if (trkOK)
                    tStr{1}{7}{1} = sprintf('%s - Incomplete Component Installation',tStr{1}{7}{1});     
                    tCol{1}{7}{1} = 'r';                                
                    trkOK = false;
                end
                
                % adds in the error string
                tStr{1}{7}{end+1} = sprintf('- Missing Toolbox - "%s"',toolStr{i});
                tCol{1}{7}{end+1} = 'r';                                
            end
        end
    end    
    
    % updates the overall toolbox flag
    if (isAllOK)
        % sets the toolboxes as being correct
        tStr{1}{4}{1} = sprintf('%s - Detected',tStr{1}{4}{1});         
    else
        % sets the toolboxes as being in error
        tStr{1}{4}{1} = sprintf('%s - Toolboxes Missing',tStr{1}{4}{1});     
        tCol{1}{4}{1} = 'r';    
    end
end

% ------------------------------- %
% --- HOUSE-KEEPING EXERCISES --- %
% ------------------------------- %

% if the recording is ok, then set the functional flag
if (recOK)
    tStr{1}{6}{1} = sprintf('%s - Requisite Installations Complete',tStr{1}{6}{1});     
end

% if the tracking is ok, then set the functional flag
if (trkOK)
    tStr{1}{7}{1} = sprintf('%s - Requisite Installations Complete',tStr{1}{7}{1});                
end

% if there is no warnings, then set the string (otherwise reset the colour)
if (warnOK)
    tStr{1}{9}{1} = sprintf('%s None',tStr{1}{9}{1});
else
    tCol{1}{9}{1} = 'o';
end

%
ii = [(2:6) (8:9)];
[tStr{1},tCol{1}] = deal(tStr{1}(ii),tCol{1}(ii));

% sets the final total string array
for i = 1:nCheck
    if (i == 1)
        % intialises the total strings/colours
        [totStr,totCol] = deal([hStr{i};{a}],[hCol{i};{'k'}]);
        
        % updates the strings/colours
        for j = 1:length(tStr{1})
            for k = 1:length(tStr{1}{j})
                if (isempty(tStr{1}{j}{k}))
                    totStr = [totStr;{a}];
                else
                    totStr = [totStr;tStr{1}{j}{k}];
                end
                totCol = [totCol;tCol{1}{j}{k}];
            end
        end
        
        % sets the gap string
        [totStr,totCol] = deal([totStr;{a}],[totCol;{'k'}]);
    else
        % case is for the other status types
        totStr = [totStr;hStr{i};{a};tStr{i};{a}];
        totCol = [totCol;hCol{i};{'k'};tCol{i};{'k'}];
    end
end

% adds the colours to the strings for each row
for i = 1:length(totStr)    
    switch (totCol{i})
        case ('r') % case is red (error)
            totStr{i} = sprintf('<html><font color="red">%s',totStr{i});        
        case ('p') % case is purple (information)
            totStr{i} = sprintf('<html><font color="#FF00FF">%s',totStr{i});
        case ('g') % case is green (ok)
            totStr{i} = sprintf('<html><font color="green">%s',totStr{i});  
        case ('o') % case is orange (warning)
            totStr{i} = sprintf('<html><font color="#FF8000">%s',totStr{i});                          
    end
end

% turns on all the warnings
warning(wState);