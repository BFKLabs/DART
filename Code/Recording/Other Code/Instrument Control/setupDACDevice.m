function objDAC = setupDACDevice(objDAC,dType,varargin)

% initialisations
nDev = length(objDAC);

% retrieves the input arguments
switch dType
    case ('Test')
        % sets the input arguments
        xySig = varargin{1};        
        
    case ('Expt')            
        % sets the input arguments
        [ExptSig,h] = deal(varargin{1},varargin{2});        
        
end

%
for i = 1:nDev
    % determines what type of DAC is being set up
    switch dType
        case ('Test')
            % set
            xySigD = xySig{i};
            ii = ~cellfun(@isempty,xySigD);
            xySigD(ii) = cellfun(@(x)({x}),xySigD(ii),'un',0);              
            
            % sets the input arguments           
            objDAC(i) = setupDACDeviceNew(objDAC(i),dType,xySigD);
            
        case ('Expt')
            % creates the devices based on the type            
            objDAC(i) = setupDACDeviceNew(objDAC(i),dType,ExptSig(i),h);

    end
end
