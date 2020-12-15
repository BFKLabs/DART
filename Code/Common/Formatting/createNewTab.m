% --- wrapper function for creating a new tab
function hTab = createNewTab(hParent,varargin)

% creates the tab object
if (isHG1)
    % case is for R2014a and earlier
    wState = warning('off','all');
    hTab = uitab('v0',hParent);
    warning(wState);
else
    % case is for R2014b and later
    hTab = uitab(hParent); 
end

% determines if the input arguments are correct
if (mod(length(varargin),2) ~= 0)
    eStr = 'Error! Tab creation function inputs must come in pairs';
    waitfor(errordlg(eStr,'Incorrect Function Inputs','modal'))
else
    for i = 1:2:length(varargin)
        set(hTab,varargin{i},varargin{i+1})
    end
end