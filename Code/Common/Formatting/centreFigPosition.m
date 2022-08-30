% --- centres the figure position to the screen's centre
function centreFigPosition(hFig,varargin)

% resets the GUI name to include the program directory
[showFig,updateTitle,rmvCloseReq] = deal(true);

%
if nargin == 2
    switch varargin{1}
        case 1
            showFig = false;
        case 2
            updateTitle = false;
        case 3
            [rmvCloseReq,updateTitle] = deal(false);
    end
end
 
% updates the figure title (if required)
if updateTitle
    % retrieves the original/program names
    [~,pName] = fileparts(getProgFileName());
    [progName, origName] = deal(sprintf('(%s)',pName), get(hFig,'Name'));

    % removes any previous program name tags from the title
    iMatch = strfind(origName, progName);
    if ~isempty(iMatch)
        origName = origName(1:(iMatch(1)-2));
    end

    % updates the figure name
    set(hFig,'Name',sprintf('%s %s',origName, progName))
end

% global variables
global scrSz
if isempty(scrSz)
    scrSz = getPanelPosPix(0,'Pixels','ScreenSize');
end

% retrieves the screen and figure position
hPos = get(hFig,'position');
p0 = [(scrSz(3)-hPos(3))/2,(scrSz(4)-hPos(4))/2];
if ~isequal(p0,hPos(1:2))
    set(hFig,'position',[p0,hPos(3:4)])
end

% removes the close request function (if currently set)
if rmvCloseReq && ~isempty(get(hFig,'CloseRequestFcn'))
    set(hFig,'CloseRequestFcn',[]);    
end

% shows the final figure
% if showFig; showFinalFigure(hFig); end