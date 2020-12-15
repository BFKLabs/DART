% --- initialises the plotting parameter function --- %
function pS = initSpecialPara(snTot,pData,varargin)

% initialises the parameter struct
pS = setParaFields(3);

% sets the subplot parameter fields
if (pData.hasTime)
    pS(1) = setParaFields([],'Time',snTot);
end   

% sets the subplot parameter fields
if (pData.hasSP)
    % sets the subplot count/subplot names
    [nCount,spName] = deal(length(snTot.appPara.ok),snTot.appPara.Name);        
    
    % creates the data struct
    pS(2) = setParaFields([],'Subplot',nCount,spName,pData.canComb,pData.hasRC);    
end    

% sets the stimuli response parameter fields
if (pData.hasSR)
    pS(3) = setParaFields([],'Stim',pData,varargin{1},varargin{2});    
end