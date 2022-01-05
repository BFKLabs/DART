function pC = calcNumericalDerivCoeff(Type,nPt,nOrder)

% sets the default input arguments
if ~exist('nOrder','var'); nOrder = 1; end

% sets the lhs matrix and multiploer
switch lower(Type)
    case 'central'
        % case is a central derivative
        [X,mlt] = deal(repmat(-nPt:nPt,2*nPt+1,1),1);
        
    case {'forward','backward'}
        X = repmat(0:(nPt-1),nPt,1);
        mlt = 1-2*strcmp(Type,'Backward');
end

% sets the linear system rhs vector
nR = size(X,1);
b = setGroup(nOrder+1,[nR,1]);
h = repmat(0:(nR-1),nR,1)';

% calculates the numerical derivative coefficients
pC = (mlt*X.^h)\b;
        
% reverses the coefficients (for backward derivatives)
if strcmpi(Type,'backward')
    pC = flip(pC);
end