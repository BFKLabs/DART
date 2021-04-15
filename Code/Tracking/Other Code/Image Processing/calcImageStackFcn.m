function Ifcn = calcImageStackFcn(I,fType,varargin)

% if the function type isn't provided then calculate the mean
if ~exist('fType','var'); fType = 'mean'; end

% reshapes the array into a numerical array
Ic = cell2mat(reshape(I,[1,1,length(I)]));

% runs the function based on the type
switch fType
    case 'mean'
        Ifcn = nanmean(Ic,3);
        
    case 'median'
        Ifcn = nanmedian(Ic,3);
        
    case 'max'
        Ifcn = nanmax(Ic,[],3);
        
    case 'min'
        Ifcn = nanmin(Ic,[],3);
        
    case 'ptile'
        Ifcn = prctile(Ic,varargin{1},3);
        
    case 'var'
        Ifcn = nanvar(Ic,[],3);        
        
end
