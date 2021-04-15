% --- calculates the N-point numerical derivative
function [dY,C] = calcNPointDeriv(Y,N)

% set the coefficients based on the inputs
if (length(N) == 1)
    % sets the derivative coefficients based on the order
    switch (N) 
        case (1) % 1-point derivative
            C = NaN;
        case (2) % 2-point derivative
            C = [-1 1]';
        case (3) % 3-point derivative
            C = [1 -4 3]'/2;
        case (4) % 4-point derivative
            C = [-2 9 -18 11]'/6;
        case (5) % 5-point derivative
            C = [-25 -48 36 -16 3]'/12;          
        case (6) % 6-point derivative
            C = [-12 75 -200 300 -300 137]'/60;            
        case (7) % 7-point derivative
            C = [10 -72 225 -400 450 -360 147]'/60;      
    end
    
    % if the points are not provided, then only return the coefficients
    if (isempty(Y))
        dY = NaN; return
    end               
else
    % if the coefficients have been provided, then set them instead    
    C = N;
end
            
% calculates the numerical derivative
if (size(Y,1) == length(C))
    % number of points is the same as the length of coefficients
    dY = sum(Y.*repmat(C,1,size(Y,2)),1);
elseif (size(Y,1) > length(C))
    % number of points is greater than the length of coefficients
    dY = calcNPointDeriv(Y((end-(length(C)-1)):end,:),C);
else
    % number of points is less than the length of coefficients
    dY = calcNPointDeriv(Y,size(Y,1));    
end
