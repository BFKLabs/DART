% --- appends the new Serial information to the data struct
function [A,isOK] = appendSerialInfo(A,pStr,vStr)

% parameters
bRate = 9600;
% bRate = 115200;

% memory allocation
nStr = size(pStr,1);
[Control,BoardNames] = deal(cell(nStr,1));
[isOK,sType] = deal(true(nStr,1),cell(nStr,1));

% creates the serial objects
for i = 1:nStr
    % sets up the controller handle and boardname string
    Control{i} = serial(pStr{i,1},'BaudRate',bRate,'Parity',...
                                  'none','DataBits', 8,'StopBits', 1);    
    BoardNames{i} = pStr{i,2};    
    
    % opens the controller and determines what type it is
    switch BoardNames{i}
        case {'STMicroelectronics Virtual COM Port', 'USB Serial Device'}
            [isOK(i),sTypeNw] = detValidSerialContollerV2(Control{i},vStr);
            if isOK(i)
                sType{i} = sprintf('%s%s',upper(sTypeNw(1)),lower(sTypeNw(2:end)));
            end
        otherwise
            [isOK(i),sType{i}] = detValidSerialContollerV1(Control{i},vStr);
    end
end

% if there are no valid serial controllers, then exit the loop
if (~any(isOK))
    cellfun(@(x)(delete(instrfind({'Port'},x(1)))),num2cell(pStr(~isOK,:),2))
    return; 
end

% appends the data to the overall data struct
if (~isempty(A))    
    % resets the serial count/name strings
    [nStrNw,pStr,sType] = deal(sum(isOK),pStr(isOK,:),sType(isOK));
    bName = cellfun(@(x,y)(sprintf('%s - %s',x,y)),BoardNames(isOK),sType,'un',0);
    
    % removes any extraneous objects
    hS = cellfun(@(x)(instrfind({'Port'},x(1))),num2cell(pStr,2),'un',0);
    cellfun(@(x)(delete(x(1:end-1))),hS);
    
    % creates spaces for the other fields
    A.Control = [A.Control;Control(isOK)];
    A.BoardNames = [A.BoardNames;bName];
    A.InstalledBoardIds = [A.InstalledBoardIds,num2cell(1:nStrNw)];    
    A.ObjectConstructorName = [A.ObjectConstructorName;cell(nStrNw,3)];
    A.dType = [A.dType,repmat({'Serial'},1,nStrNw)];
    
    if isfield(A,'sType')
        A.sType = [A.sType,sType(:)'];
    end
end