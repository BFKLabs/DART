function Ifcn = calcImageStackFcn(I,fType,varargin)

% if the function type isn't provided then calculate the mean
if ~exist('fType','var'); fType = 'mean'; end

% reshapes the array into a numerical array
isOK = ~cellfun(@isempty,I);
Ic = cell2mat(reshape(I(isOK),[1,1,sum(isOK(:))]));

% runs the function based on the type
switch fType
    case 'mean'
        Ifcn = mean(Ic,3,'omitnan');
        
    case 'median'
        Ifcn = median(Ic,3,'omitnan');
        
    case 'max'
        Ifcn = max(Ic,[],3,'omitnan');
        
    case 'min'
        Ifcn = min(Ic,[],3,'omitnan');
        
    case 'ptile'
        Ifcn = prctile(Ic,varargin{1},3);
        
    case 'var'
        Ifcn = var(Ic,[],3,'omitnan');   
        
    case 'sum'
        Ifcn = sum(Ic,3,'omitnan');
        
    case 'weighted-sum'
        pW = num2cell(varargin{1}); 
        Ic = cellfun(@(x,y)(x.*y),pW(:),I(:),'un',0);        
        Ifcn = calcImageStackFcn(Ic,'sum');
        
    case 'range'
        Ifcn = range(Ic,3);
        
    case 'isnan'
        Ifcn = any(isnan(Ic),3);
        
end
