% --- sets up the serial device
function objS = setupSerialDevice(objDACInfo,stType,varargin)

% sets the serial device handle
if ~isempty(objDACInfo)
    hS = objDACInfo.Control;

    % re=opens any closed devices
    for i = 1:length(hS)
        if isvalid(hS{i})
            try
                if strcmpi(get(hS{i},'Status'),'closed')
                    fopen(hS{i})
                end
            end        
        else
            comStr = regexp(objDACInfo.vStrDAC{i},'\(\w+\)','match','once');
            hS{i} = createSerialDevObject(comStr(2:end-1),1);
        end
    end
    
    % resets the serial object handles
    objDACInfo.Control = hS;
end

% sets the dac device properties based on the setup type
switch stType
    case ('RTStim') % case is a real-time tracking stimuli event
        % sets the input arguments   
        [hGUI,Ys] = deal(varargin{1},varargin{2});             
        [dT,ID] = deal(varargin{3},varargin{4});        
        [iDev,hS,iCh] = deal(ID(1),hS{ID(2)},ID(3));
        
        % determines the details of when there is an event change
        [iChng,yChng,tChng] = detEventChange(Ys,dT);
        iChng = cellfun(@(x)(x*iCh),iChng,'un',0);

        % sets the timer callback functions
        fcnS = {@serialStart,hS,iChng,yChng};
        fcnT = {@serialTimer,hS,iChng,yChng,tChng};        
        fcnF = {@serialStopRT,hS,hGUI,iDev}; 
        
        % initialises the timer object
        objS = timer('tag','Stim','UserData',1,'Period',dT,...
                     'StartFcn',fcnS,'TimerFcn',fcnT,'StopFcn',fcnF,...
                     'ExecutionMode','fixedRate');          
        
    case ('Test') % case is testing the Serial device
        % sets the input arguments                
        [xySig,sRate,iDev] = deal(varargin{1},varargin{2},varargin{3});                
        
        % memory allocation 
        nDev = length(iDev);
        if isempty(objDACInfo)
            % case is testing the gui
            sType = getappdata(evalin('caller','hFig'),'devType');
            hS = cell(nDev,1);
        else
            % case is using the gui within DART
            hS = hS(iDev);
            sType = objDACInfo.sType(iDev);                         
        end
        
        % ensures all signal trains are stored in cells of cells        
        for i = 1:nDev
            ii = ~cellfun(@isempty,xySig{i});
            xySig{i}(ii) = cellfun(@(x)({x}),xySig{i}(ii),'un',0);           
        end        
        
        % sets up the stimuli timer objects for each device
        dT = 1./sRate;
        objS = StimObj(hS,xySig,dT,stType,sType);
        
    case ('Expt') % case is a normal experiment      
        % sets the input arguments
        [exObj,isS] = deal(varargin{1},varargin{2});        
        ID = field2cell(exObj.ExptSig,'ID');
        hS = hS(isS);
        
        % retrieves the device type strings
        chInfo = getappdata(exObj.hExptF,'chInfo');
        sType = cellfun(@(x)(removeDeviceTypeNumbers(chInfo{find(...
                cell2mat(chInfo(:,1))==x(1,1),1,'first'),3})),ID,'un',0);
        
        % memory allocation and parameters
        sRate = field2cell(exObj.iStim.oPara,'sRate',1);
        dT = 1./sRate(1);                        
                
        % sets the current/total stimuli counts
        if exObj.isError
            % resets the stimulus counter variables 
            
            % REMOVE ME LATER
            waitfor(msgbox('REINITIALISE nCountD here!','Finish Code','modal'))
        end        

        % sets the stop/trigger functions for the experiment DAC devices
        XY = field2cell(exObj.ExptSig,'XY');
        objS = StimObj(hS,XY,dT,stType,sType);
        objS.setProgressGUI(exObj.hProg)                 
        
end

function sType = removeDeviceTypeNumbers(sType0)

% splits the string and returns the first cell
sTypeSp = strsplit(sType0);
sType = sTypeSp{1};
