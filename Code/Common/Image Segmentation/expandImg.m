function [Iexp,N] = expandImg(I,N)

% sets the input arguments
if ~exist('N','var'); N = 10; end

% returns the original image if zero/negative expansion
if all(N <= 0)
    Iexp = I;
    return
end

%
sz = size(I);
N = min(N,min(sz));
Iexp = zeros(sz(1)+2*N,sz(2)+2*N);

% sets the main image (in the middle)
Iexp(N+(1:sz(1)),N+(1:sz(2))) = I;

% sets the image edges (left, right, top and bottom)
Iexp(1:N,N+(1:sz(2))) = I(N:-1:1,:);
Iexp((N+sz(1))+(1:N),N+(1:sz(2))) = I(end:-1:(end-N+1),:);
Iexp(N+(1:sz(1)),1:N) = I(:,N:-1:1);
Iexp(N+(1:sz(1)),(N+sz(2))+(1:N)) = I(:,end:-1:(end-N+1));

% sets the image corners
Iexp(1:N,1:N) = I(N:-1:1,N:-1:1);
Iexp(1:N,(N+sz(2))+(1:N)) = I(N:-1:1,end:-1:(end-N+1));
Iexp((N+sz(1))+(1:N),1:N) = I(end:-1:(end-N+1),N:-1:1);
Iexp((N+sz(1))+(1:N),(N+sz(2))+(1:N)) = I(end:-1:(end-N+1),end:-1:(end-N+1));
