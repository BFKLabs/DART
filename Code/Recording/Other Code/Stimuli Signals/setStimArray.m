% --- sets up the array from the sub-struct pStr --- %
function stimArr = setStimArray(pStr,nCount)

% sets the array based on whether the parameter is random or not
if (isfield(pStr,'pI'))
    % array is LED parameters
    stimArr = (pStr.pI/100)*ones(nCount,1);    
else
    if isfield(pStr,'isRand')
        if pStr.isRand
            % array is random
            stimArr = pStr.pMin + (pStr.pMax - pStr.pMin)*rand(nCount,1);  
            return
        end
    end
    
    % array is fixed
    stimArr = pStr.pVal*ones(nCount,1);
end  