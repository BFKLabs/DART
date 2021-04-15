% --- sets/initialises the fields of the format data struct --- %
function pF = setFormatFields(varargin)

% sets/initialises the parameter struct (based on the input arguments)
if (nargin == 1)    
    % initialises the parameter struct (for each apparatus)
    nApp = varargin{1};
    
    % initialises the data struct
    pF = struct('Title',[],'xLabel',[],'yLabel',[],'zLabel',[],...
                'Axis',[],'Legend',[]);     
    
    % sets the default axis/title font structs
    pF.Title = setFormatFields(setupFontStruct('FontSize',20),[],nApp);
    pF.xLabel = setFormatFields(setupFontStruct('FontSize',14),[]);
    pF.yLabel = setFormatFields(setupFontStruct('FontSize',14),[]);
    pF.zLabel = setFormatFields(setupFontStruct('FontSize',14),[]);    
    pF.Axis = setFormatFields(setupFontStruct('FontSize',12),[]);
    pF.Legend = setFormatFields(setupFontStruct('FontSize',10),[]);    
else
    % updates the fields within the format struct    
    if (nargin == 2)
        nApp = 1;
    else
        nApp = varargin{3};
    end
    
    % sets the font data struct
    if (isempty(varargin{1}))
        Font = setupFontStruct;
    else
        Font = varargin{1};
    end
    
    % initialises the parameter struct    
    pF = repmat(struct('Font',Font,'String',varargin{2},'ind',1),nApp,1);        
end