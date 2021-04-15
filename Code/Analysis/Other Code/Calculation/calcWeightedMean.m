% --- calculates the weighted mean by column for the array, Y --- %
function Ymn = calcWeightedMean(Y,W,nIter)

% initialisations
if (isempty(Y)); Ymn = NaN; return; end
sz = size(Y);

% sets the parameters based on the dimensions
if (sz(1) == 1)
    % only one value, so no need to take weighted mean...
    Ymn = Y;
    return
else
    switch (nargin)
        case (1)
            [nIter,calcW] = deal(5,true);
        case (2)
            nIter = 5;  
            calcW = isempty(W);
        otherwise 
            calcW = isempty(W);
    end
end
    
% calculates the mean
Ytol = 0.1;
Ymn0 = nanmean(Y,1);

% resets the weight array depending if it has been set or not
if (~calcW)
    % repeats the array for the reqd number of columns
    Wp = repmat(W,1,sz(2));
else
    % otherwise, set a uniform weight array
    Wp = ones(sz);
end
    
% loops through all of the iterations calculating the new weighted mean
for i = 1:nIter
    % calculates the new weights
    Ymn0Pr = Ymn0;
    W = Wp./((Y - repmat(Ymn0,sz(1),1)).^2 + 1); 
    W = W./repmat(nansum(W),sz(1),1);
        
    % calculates the new mean    
    Ymn0 = nansum(W.*Y,1);
    if (abs(Ymn0 - Ymn0Pr) < Ytol)
        % if the change in the mean is less than tolerance, then exit the
        % loop
        break
    end
end

% sets the final value
Ymn = Ymn0;