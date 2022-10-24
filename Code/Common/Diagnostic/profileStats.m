function pStats = profileStats(p)

% initialisations
pFld = {'nCall','Ttot','Tmn'};
pTmp = struct('Tmn',[],'Ttot',[],'nCall',[]);

% field retrieval
eType = p.FunctionHistory(1,:); 
iFcn = p.FunctionHistory(2,:);
tFcn = p.FunctionHistory(4,:);

% other memory allocations
nFcn = max(iFcn);
pStats = cell(nFcn,1);

%
for i = 1:nFcn
    % determines the matching function indices
    iiF = find(iFcn == i);    
    
    % determines
    N = length(iiF)/2;
    dT = zeros(N,1);
    eTypeT = eType(iiF);        
    
    %
    for j = 1:N
        % determines 
        i0 = find(eTypeT==0,1,'first');
        i1 = find(eTypeT==1,1,'first');
        
        dT(j) = abs(diff(tFcn(iiF([i0,i1]))))/1000;
        eTypeT([i0,i1]) = NaN;
    end
    
    %
    [pTmp.Tmn,pTmp.Ttot,pTmp.nCall] = deal(mean(dT),sum(dT),N);
    pStats{i} = pTmp;
end

%
figure
for i = 1:length(pFld)
    subplot(3,1,i);
    bar(cellfun(@(x)(getStructField(x,pFld{i})),pStats));
    
    if strcmp(pFld{i},'nCall')
        set(gca,'yscale','log');      
    end
end