function objS = setupHT1TestPulse(objDAQ,iDevHT)

% retrieves the HT1 controller index
if ~exist('iDevHT','var')
    iDevHT = find(strContains(objDAQ.sType,'HTController'));
end

% device parameters
sRate = 50;
xySig = {[0;0.5],[100;0]};
% xySig = {[0;0.5;1;1.5],[100;0;100;0]};

% creates the test serial device object
objS = {setupSerialDevice(objDAQ,'Test',{xySig},sRate,iDevHT)};
                