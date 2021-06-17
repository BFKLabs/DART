% --- wrapper function for creating a new tab
function hTab = createNewTab(hParent,varargin)

% creates the tab object
hTab = uitab(hParent); 

% determines if the input arguments are correct
if mod(length(varargin),2) ~= 0
    eStr = 'Error! Tab creation function inputs must come in pairs';
    waitfor(errordlg(eStr,'Incorrect Function Inputs','modal'))
else
    for i = 1:2:length(varargin)
        set(hTab,varargin{i},varargin{i+1})
    end
end