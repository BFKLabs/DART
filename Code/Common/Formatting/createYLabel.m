function hYLbl = createYLabel(varargin)

if isa(varargin{1},'matlab.graphics.axis.Axes')
    % case is the first input is the axes handle
    hYLbl = ylabel(varargin{1},varargin{2},'Rotation',90);
    pLbl = varargin(3:end);
    
else
    % case is the first input is the label string
    hYLbl = ylabel(varargin{1},'Rotation',90);
    pLbl = varargin(2:end);    
end

% sets the y-label properties
nProp = length(pLbl)/2;
for i = 1:nProp
    iP = (i-1)*2 + 1;
    set(hYLbl,pLbl{iP},pLbl{iP+1});
end

