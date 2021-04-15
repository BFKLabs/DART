function tVec = addTime(tVec,tAdd)

%
tLim = [inf,24,60,60];
tVec = tVec + tAdd;

% keep looping until none of the values are on the time limit
while 1
    % determines if any time values are on the limit
    ii = find(tLim == tVec);
    if ~isempty(ii)
        % if so, then reset the value and increment that to the left of it
        [tVec(ii),tVec(ii-1)] = deal(0,tVec(ii-1)+1);       
    else
        % otherwise, exit the function
        break
    end
end