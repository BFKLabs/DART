% --- retrieves the parameter for the current signal
function sParaEx = getExptParaInfo(varargin)

%
if nargin == 1
    % case is the figure handle is provided
    hFig = varargin{1};
    sPara = getappdata(hFig,'sParaEx');
    sType = getappdata(hFig,'sType');
else
    % case is the individual values are provided
    [sPara,sType] = deal(varargin{1},varargin{2});
end

% calculates the duration of the signal (given the current para)
sParaEx = eval(sprintf('sPara.%s',sType(1)));