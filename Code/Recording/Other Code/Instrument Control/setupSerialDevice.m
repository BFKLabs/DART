% --- sets up the serial device
function objS = setupSerialDevice(objDAQ,stType,varargin)

% sets the serial device handle
if ~isempty(objDAQ)
    % sets the serial device handle
    hS = objDAQ.Control;

    % re=opens any closed devices
    for i = 1:length(hS)
        if isvalid(hS{i})
            try
                if strcmpi(get(hS{i},'Status'),'closed')
                    fopen(hS{i})
                end
            end        
        else
            comStr = regexp(objDAQ.vStrDAQ{i},'\(\w+\)','match','once');
            hS{i} = createSerialDevObject(comStr(2:end-1),1);
        end
    end
    
    % resets the serial object handles
    objDAQ.Control = hS;
end

% sets the dac device properties based on the setup type
switch stType
    case ('Test') 
        % case is testing the Serial device
        
        % sets the input arguments                
        [xySig,sRate,iDev] = deal(varargin{1},varargin{2},varargin{3});                
        
        % memory allocation 
        nDev = length(iDev);
        hS = hS(iDev);
        sType = objDAQ.sType(iDev);                         
        
        % ensures all signal trains are stored in cells of cells        
        for i = 1:nDev
            ii = ~cellfun('isempty',xySig{i});
            xySig{i}(ii) = cellfun(@(x)({x}),xySig{i}(ii),'un',0);           
        end        
        
        % sets up the stimuli timer objects for each device
        dT = 1./sRate;
        objS = StimObj(hS,xySig,dT,stType,sType);
        
    case ('Expt') 
        % case is a normal experiment   
        
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

        % sets the stop/trigger functions for the stimuli devices
        XY = field2cell(exObj.ExptSig,'XY');
        objS = StimObj(hS,XY,dT,stType,sType,exObj.hasIMAQ);
        objS.setProgressGUI(exObj.objP)                 
        
end
