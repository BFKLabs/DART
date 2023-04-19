% --- function that creates a serial device object    
function hS = createSerialDevObject(pStr,varargin)
    
% serial controller baud rate
bRate = 9600;
% bRate = 115200;

% creates the serial device object
hS = serial(pStr,'BaudRate',bRate,'Parity','none','DataBits',8,'StopBits',1);    

% opens it (if required)
if (nargin == 2); fopen(hS); end