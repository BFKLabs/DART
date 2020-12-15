% ISMEMBERWITHINTOL  True for within tolerance of set member
%   isMemberWithinTol( a, B ) is true if there exists j such that a is
%   "within tolerance" of B(j,:).
%
%   isMemberWithinTol is similar to ismember, but where ismember uses exact
%   comparisons, isMemberWithinTol uses a tolerance to check for membership.
%
% Usage:
%   [LIA, LOCB] = curvefitlib.internal.isMemberWithinTol(A, B, C)
% Where:
%   A    = A Matrix of row values, rows are considered to be part of the
%           same value. A vector of values should be column oriented.
%   B    = A Matrix of row values, rows are considered to be part of the
%           same value. A vector of values should be column oriented.
%   C    = Specifies the infinity-norm tolerance using an absolute 
%           tolerance. 
%   LIA  = Boolean vector with the same number of rows as A. 
%           LIA(i) is true if A(i,:) is "similar" to a row in B.
%   LOCB = Has same number of rows as A. LOCB(i) indicates one row in B 
%           that is "similar" to A(i,:).
%
% Here, similarity (~) is defined as the infinity-norm, i.e.:
%   all(B(i,:) - A(j,:) < tol)
%
% Conditions satisfied by outputs:
%   - If LIA(i) = true => there exists a j such that: A(i,:) ~ B(j,;)
%   - Where LOCB(i) = j: 
%       if j ~= 0 => B(i,:) ~ A(j,:)
%       if j == 0 => LIA(i) = false, A(i,:) is not similar to any row in B
%   - The above two conditions give the following identity relating A and B:
%       B(LOCB(LIA),:) ~ A(LIA,:)
%
% Note that due to the way the algorithm is implemented the indexes returned
% in LOCB may not return the first "similar" index. Also this function 
% finds a mapping that satisfies the conditions but this may not be the
% "optimal" mapping.
%
% Example:
%   % A is a matrix of real values
%   A = [0.05, 0.11, 0.18;
%        0.18, 0.21, 0.29;
%        0.34, 0.36, 0.41;
%        0.46, 0.52, 0.76;
%        0.82, 0.91, 1.00];
%   % B is a matrix with the same values of A after recalculation
%   B = log10( 10.^A );
%   % ismember uses exact equality, most of the rows are not matched
%   ismember( A, B, 'rows' )
%   % By using a small tolerance the rows will be matched
%   curvefitlib.internal.isMemberWithinTol( A, B, eps )
%
% See also: ismember

%  Copyright 2012 The MathWorks, Inc.

function [LIA, LOCB] = isMemberWithinTol(A, B, tol)

if size(A,2) ~= size(B,2)
    error(message('curvefitlib:internal:isMemberWithinTol:incorrectSizeInputs'))
end

if ~isnumeric(tol) || (size(tol,1) ~= 1)
    error(message('curvefitlib:internal:isMemberWithinTol:unknownTolerance'))
elseif isvector(tol) && ~(size(tol,2)==1 || size(tol,2) == size(A,2))
    error(message('curvefitlib:internal:isMemberWithinTol:wrongSizeTolerance'))
elseif any(tol < 0)
    error(message('curvefitlib:internal:isMemberWithinTol:negativeTolerance'))
end
    
[LIA, LOCB] = isMemberWTFast(A, B, tol);



function [LIA, LOCB] = isMemberWTFast(A, B, tol)
% A(AInd,:) == As
[As, AInd] = sortrows(A);
[Bs, BInd] = sortrows(B);

% is member by rows
N = size(As, 1);
M = size(Bs, 1);

LIA = false(N,1);
LOCB = zeros(N,1);
startInd = 1;
for i = 1:N
    for j = startInd:M
        if Bs(j,1) > As(i,1)+tol(1)
            % case where B(j,1) is too big for A(j,1), there is no point looking further
            break
        elseif Bs(j,1)+tol(1) < As(i,1)
            % case where B(i,1) is too small and will never be within tol of A(j,1)
            startInd = j;
        elseif ~any(abs(As(i,:) - Bs(j,:)) > tol)
            % other case where A(i,1) and B(i,1) are within tolerance of each other
            LIA(i) = true;
            LOCB(i) = j;
            break
        end
    end
end
LIA(AInd) = LIA;

% map the B indexes back into the unsorted inputs
LOCB(AInd) = LOCB;
nonzeros = (LOCB ~= 0); % don't map back values that are not in B
LOCB(nonzeros) = BInd(LOCB(nonzeros));