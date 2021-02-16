function Ifcn = calcImageStackFcn(I,fType)

%
if ~exist('fType','var'); fType = 'mean'; end

%
Ic = cell2mat(reshape(I,[1,1,length(I)]));

%
switch fType
    case 'mean'
        Ifcn = nanmean(Ic,3);
        
    case 'median'
        Ifcn = nanmedian(Ic,3);
        
    case 'max'
        Ifcn = nanmax(Ic,[],3);
        
    case 'min'
        Ifcn = nanmin(Ic,[],3);
        
end