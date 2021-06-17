% --- retrieves the region grouping indices (based on the setup type
%     and the format of the sub-region data struct)
function iGrp = getRegionGroupIndices(iMov,gName,iApp)

if ~isfield(iMov,'pInfo')
    % case is either 1D expt setup or an old format solution file  
    [gNameS,nFly] = deal(gName,size(iMov.flyok,1));
    if exist('iApp','var')
        gNameS = gNameS(iApp);
    end
    
    % case is either 1D expt setup or an old format solution file   
    iGrp0 = cellfun(@(x)(getMatchingGroupIndex(gName,x)),gNameS);
    iGrp = cell2mat(arrayfun(@(x)(x*ones(nFly,1)),iGrp0(:)','un',0));
    
else
    if iMov.is2D
        iGrp = iMov.pInfo.iGrp;
    else
        iGrp0 = arr2vec(iMov.pInfo.iGrp')';
        iGrp = repmat(iGrp0,size(iMov.flyok,1),1);
    end
    
%     % case is 2D with the new format
%     
%     if exist('iApp','var')
%         
%     end
    
    % determines the matchinging grouping indices for each region
    if iMov.is2D
        isOK = iGrp > 0;
        iGrp(isOK) = cellfun(@(x)...
                (getMatchingGroupIndex(gName,x)),gName(iGrp(isOK)));
    else
        [~,~,iC] = unique(gName,'stable');
        iGrp = repmat(iC(:)',size(iMov.flyok,1),1);
        iGrp(:,~iMov.ok) = 0;
    end
            
    % removes any rejected flies
    if exist('iApp','var')
        iGrp(~iMov.flyok(:,iApp)) = 0;
        iGrp = iGrp(:,iApp);
    else
        iGrp(~iMov.flyok) = 0;
    end            
end 

% --- determines the first match group index value
function iMatch = getMatchingGroupIndex(gName,gNameNw)

% determines the unique group names
gNameU = unique(gName,'stable');

% determines if there is a match with the name list
iMatch = find(strcmp(gNameU,gNameNw),1,'first');
if isempty(iMatch)
    % if not, return a zero value
    iMatch = 0;
end