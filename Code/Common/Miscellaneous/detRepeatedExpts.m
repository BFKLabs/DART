function indRep = detRepeatedExpts(sInfo)

% memory allocation
nExp = length(sInfo);
indRep = zeros(length(sInfo),1);

% if there is only one experiment, then exit
if nExp == 1
    return
end

% retrieves the experimental information 
expInfo = cellfun(@(x)(x.expInfo),sInfo,'un',0);

%
j = 1;
for i = 1:(nExp-1)
    if indRep(i) == 0    
        % determines if there are any matching experiments
        xi = (i+1):nExp;
        isM = cellfun(@(x)(isequal(expInfo{i},x)),expInfo(xi));

        % if there are matches
        if any(isM)
            [indRep([i;xi(isM)]),j] = deal(j,j+1);
        end
    end
end