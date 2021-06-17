% compute the set of all integer divisors of the positive integer N
function divs = getAllDivisors(N)

% gets the list of prime factors of N.
facs = factor(N);

divs = [1,facs(1)];
for fi = facs(2:end)
    % if N is prime, then facs had only one element,
    % and this loop will not execute at all, In that case
    % The set of all divisors is simply 1 and N.
    
    % this outer product will generate all combinations of
    % the divisors found so far, combined with the current
    % divisor fi.
    divs = [1;fi]*divs;
    
    % unique eliminates the replicate divisors, making
    % this an efficient code.
    divs = unique(divs(:)');
end
