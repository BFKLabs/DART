function objDAC = setupDACDevice(objDAC,dType,varargin)

%
for i = 1:length(objDAC)
    % determines what type of DAC is being set up
    isNew = detDACType(objDAC{i});
    
    switch (dType)
        case ('Test')
            % sets the input arguments
            YYtot = varargin{1};

            % creates the devices based on the type
            if (isNew)            
                objDAC(i) = setupDACDeviceNew(objDAC(i),'Test',YYtot(i));
            else
                objDAC(i) = setupDACDeviceOld(objDAC(i),'Test',YYtot(i));
            end
        case ('Expt')
            % sets the input arguments
            [ExptSig,h] = deal(varargin{1},varargin{2});

            if (isNew)
                objDAC(i) = setupDACDeviceNew(objDAC(i),'Expt',ExptSig(i),h);
            else
                objDAC(i) = setupDACDeviceOld(objDAC(i),'Expt',ExptSig(i),h);
            end        
        case ('RTShock')

    end
end
    
% --- determines what type of device the object is being set up
function isNew = detDACType(objDAC)

if (verLessThan('matlab','9.2'))
    isNew = strContains(get(objDAC,'Name'),'nidaq');
else
    isNew = true;
end