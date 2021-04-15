% --- converts an array of digits to the base, N
function Ydec = nbase2dec(Y,N)

% converts the array of digits to the decimal
Ydec = sum(Y.*repmat(3.^((size(Y,2)-1):-1:0),size(Y,1),1),2);

% removes any numbers whose digits that are >= the base
Ydec(any(Y >= N)) = NaN;