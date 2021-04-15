% --- determines the indices of the final cell groups from the correlation
%     coefficient calculations
function iGrp = detFinalCellGroups(R2S,pTolCC)

% parameters
if (nargin == 1); pTolCC = 0.7; end
[iGrp0,dpTol] = deal([],0.05);

% determines the initial search indices
isFHi = ~setGroup(find(max(R2S,[],1) > pTolCC),[1,size(R2S,2)]);
isFLo = ~setGroup(find(max(R2S,[],1) > pTolCC-dpTol),[1,size(R2S,2)]);

% while there are groups to be 
while (any(~isFHi))
    % determines the index of the next non-classified pixel
    iGrpNw = find(~isFHi,1,'first');    
        
    % sets the initial search 
    indNw = find(R2S(:,iGrpNw));    
    indS = indNw(~isFLo(indNw));
    [isFHi([iGrpNw;indS]),isFLo([iGrpNw;indS])] = deal(true);
    
    %
    while (~isempty(indS))
        % determines the new 
        indNw = find(R2S(:,indS(1)));    
        indSNw = indNw(~isFLo(indNw));
        
        % appends the new search indices and flag that the new pixels have
        % been found (in the isFound array)
        if (~isempty(indSNw))
            [isFHi(indSNw),isFLo(indSNw)] = deal(true);
            indS = [indS;indSNw];
        end
        
        % appends the new values to the current cell and reduces the search
        % array by the last value
        iGrpNw(end+1) = indS(1);
        indS = indS(2:end);
    end
    
    % 
    iGrp0{end+1} = iGrpNw;
end

% removes any small groups
if (~isempty(iGrp0))
    iGrp = iGrp0;
else
    iGrp = [];
end