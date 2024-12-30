% --- creates the titled panel object
function hPanel = createPanelObject(hP,pPos,tHdr,varargin)

% sets the default input arguments
if ~exist('tHdr','var'); tHdr = []; end

% sets up the input parser    
ip = inputParser;
addParameter(ip,'pType','panel');
addParameter(ip,'FontSize',13);
addParameter(ip,'FontWeight','bold');

% parses the input arguments
parse(ip,varargin{:})
p = ip.Results;

% creates the panel object
hPanel = createUIObj(p.pType,hP,'Position',pPos,'Title',tHdr);

% if there are no title or other properties, then exit
if isempty(tHdr) && isempty(varargin); return; end    

% sets the main input arguments
pFldP = fieldnames(p);
set(hPanel,'FontSize',p.FontSize,'FontWeight',p.FontWeight);

% sets the other panel properties
nP = length(varargin)/2;
for i = 1:nP
    % retrieves the panel property/values
    pFld = varargin{2*(i-1)+1};
    if ~any(strcmp(pFldP,pFld))
        set(hPanel,pFld,varargin{2*i});
    end
end
