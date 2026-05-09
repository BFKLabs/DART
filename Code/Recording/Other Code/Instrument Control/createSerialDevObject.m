% --- function that creates a serial device object    
function hS = createSerialDevObject(pStr,varargin)
    
% serial controller baud rate
bRate = 9600;
% bRate = 115200;

% creates the serial device object
useSP = false;
% useSP = exist('serialport','file');
if useSP
    hS = serialport(pStr,bRate,'Parity','none',...
                         'DataBits',8,'StopBits',1); 
else
    hS = serial(pStr,'BaudRate',bRate,'Parity','none',...
                     'DataBits',8,'StopBits',1);    
end

% opens it (if required)
if (nargin == 2); fopen(hS); end
