function Z = nandiff(X,Y)

Z = zeros(size(X));
ii = ~(isnan(X) | isnan(Y));
Z(ii) = X(ii)-Y(ii);

