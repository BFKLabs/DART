% --- calculates the binned fly movement. the movement is calculated
%     using the binned indices array, indB, for the feasible flies
%     given by the boolean array, flyok and the apparatus index, ind --- %
function I = calcBinnedActivity(snTot,T,indB,cP,ind,flyok)

% memory allocation
V0 = repmat({NaN(1,length(flyok))},length(indB),1);

% calculates the binned fly movement
jj = cellfun('length',indB) > 1;
V0(jj) = calcBinnedFlyMovement(snTot,T,indB(jj),cP,ind,flyok);

% converts the binned activity array to the full sized array
Vtmp = NaN(length(V0),length(flyok));
Vtmp(:,flyok) = cell2mat(V0);
V = num2cell(Vtmp,2);
clear V0 Vtmp

% calculates the mean proportional movement (based on movement type)
switch cP.movType
    case 'Midline Crossing'
        % case is using midline crossing
        I = cellfun(@(x)(x > 0),V,'un',0);
    
    otherwise
        % case is using absolute distance
        I = cellfun(@(x)(x > cP.dMove),V,'un',0);        
end
