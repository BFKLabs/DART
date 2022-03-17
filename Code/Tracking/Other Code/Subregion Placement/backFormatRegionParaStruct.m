function [Para,isChange] = backFormatRegionParaStruct(Para)

% initialisations
isChange = false;

% removes the automatic detection field
if isfield(Para,'isAuto')
    [Para,isChange] = deal(rmfield(Para,'isAuto'),true);
end

% sets the positional parameter struct
if ~isfield(Para,'pPos')
    [Para.pPos,isChange] = deal(para2pos(Para),true);
end

% resets the region specific fields
switch Para.Type
    case 'Circle'
        % case is for circular regions
        
        % ensures the 
        if (numel(Para.R) == 1) && (numel(Para.X0) > 1)
            isChange = true;
            Para.R = Para.R*ones(size(Para.X0));
            Para.XC = Para.XC/max(abs(Para.XC));
            Para.YC = Para.YC/max(abs(Para.YC));
        end
end