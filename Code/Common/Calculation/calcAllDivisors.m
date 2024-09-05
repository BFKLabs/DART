% --- calculates all divisors of t
function D = calcAllDivisors(N)

K = 1:ceil(sqrt(N));
D0 = K(rem(N,K) == 0);
D = [D0(:),N./D0(:)];