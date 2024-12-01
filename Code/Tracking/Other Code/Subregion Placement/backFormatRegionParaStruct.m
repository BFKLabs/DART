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
        
        % resets 
        isF = cellfun(@(x)(all(x(1:2)>0)),Para.pPos);
        Rpos = cellfun(@(x)(x(3)),Para.pPos);
        if any(abs(Rpos(:) - Para.R(:)*2) > 10) || any(~isF(:))
            Para.pPos = para2pos(Para);
            isChange = true;
        end
        
        % ensures the circle parameters are setup correctly 
        if (numel(Para.R) == 1) && (numel(Para.X0) > 1)
            isChange = true;
            Para.R = Para.R*ones(size(Para.X0));
            Para.XC = Para.XC/max(abs(Para.XC));
            Para.YC = Para.YC/max(abs(Para.YC));
        end
end