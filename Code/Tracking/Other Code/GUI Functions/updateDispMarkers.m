function updateDispMarkers(handles)

% retrieves the main GUI handle/struct arrays
trkP = getappdata(handles.figAnalyOpt,'trkP');
trkP0 = getappdata(handles.figAnalyOpt,'trkP0');
hGUI = getappdata(handles.figAnalyOpt,'hGUI');
iMov = getappdata(hGUI,'iMov');

% retrieves the tracking parameters (based on operating system)
if ispc
    [pTrk,pTrk0] = deal(trkP.PC,trkP0.PC);
else
    [pTrk,pTrk0] = deal(trkP.Mac,trkP0.Mac);
end

% updates the tube region markers
hTube = getappdata(hGUI,'hTube');
if ~isempty(hTube)
    updateDispMarkerProps(hTube,pTrk,pTrk0,{'pCol'});
end

% updates the individual object markers
hMark = getappdata(hGUI,'hMark');
if ~isempty(hMark)
    sepCol = iMov.sepCol;
    updateDispMarkerProps(hMark,pTrk,pTrk0,{'pCol','pMark','mSz'},sepCol);
end

% updates the initial tracking parameter struct
setappdata(handles.figAnalyOpt,'trkP0',trkP)

%
function updateDispMarkerProps(hObj,pTrk,pTrk0,pStrF,sepCol)

% initialisations
pFld = fieldnames(pTrk);
hObj = cell2cell(hObj(:));

% default input arguments
if exist('sepCol','var') 
    % case is the fly markers are being updated
    isP = false;
    if sepCol
        % if separating colours, remove the colour field
        pStrF = pStrF(~strcmp(pStrF,'pCol'));
    end
else
    % case is the region outlines are being updated
    [sepCol,isP] = deal(false,true); 
end

%
for i = 1:length(pFld)
    % retrieves the sub-field data
    pTrkS = eval(sprintf('pTrk.%s',pFld{i}));
    pTrk0S = eval(sprintf('pTrk0.%s',pFld{i}));
    
    %
    isM = true(length(hObj),1);
    for j = 1:length(pStrF)        
        isM = isM & cellfun(@(x)(detFldMatch(x,pTrk0S,pStrF{j},isP)),hObj);
        if ~any(isM); break; end
    end
    
    % updates the marker properties (if any match)
    if any(isM)
        cellfun(@(x)(updateMarkerProp(x,pTrkS,pStrF,isP)),hObj(isM));
    end
end

% if using separate colours 
if sepCol
    pCol = num2cell(distinguishable_colors(length(hObj)),2);
    cellfun(@(h,c)(set(h,'Color',c)),hObj,pCol(:))
end

% --- 
function updateMarkerProp(hObj,pTrk,pStr,isP)

% updates the field values
for i = 1:length(pStr)
    fStr = getObjFieldString(pStr{i},isP);
    set(hObj,fStr,eval(sprintf('pTrk.%s',pStr{i})))
end

% --- 
function isMatch = detFldMatch(hObj,pTrk,pStr,isP)

% determines if the object properties match
fStr = getObjFieldString(pStr,isP);
isMatch = isequal(get(hObj,fStr),eval(sprintf('pTrk.%s',pStr)));

% --- retrieves the object field strings
function fStr = getObjFieldString(pStr,isP)

%
switch pStr
    case 'pCol'
        if isP
            fStr = 'FaceColor';
        else
            fStr = 'Color';
        end
        
    case 'pMark'
        fStr = 'Marker';
        
    case 'mSz'
        fStr = 'MarkerSize';
end