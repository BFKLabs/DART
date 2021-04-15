% --- sets the overall minimum font size
function fSzNw = setMinFontSize(fSz,type)

% sets the minimum font size depending on the label type
switch (lower(type))
    case {'text','other'}
        fSzNw = max(fSz,7);
    case {'axes','axis'} % case is an axis or text object
        fSzNw = max(fSz,8);
    case ('legend') % case is a legend
        fSzNw = max(fSz,9);
    case ('title') % case is a title
        fSzNw = max(fSz,11);
    otherwise % other case (x/y/z-label)
        fSzNw = max(fSz,10);
end