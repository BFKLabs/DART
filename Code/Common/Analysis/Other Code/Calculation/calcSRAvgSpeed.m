% --- calculates the average velocities of the time-grouped position 
%     array, P, using a surrounding average bin size of nAvg
function [V,Vsd,Vtot] = calcSRAvgSpeed(P,cP,N,indF,indS,is2D,varargin)

% calculation parameters
[nAvg,cType,nGrp] = deal(cP.nAvg,cP.cType,str2double(cP.nGrp));

% sets the number of frames that each signal (should!) have
if (nargin == 6)
    nFrm = max(cellfun(@(x)(size(x,1)),P{1}(:)));
    nDay = size(P{1},1);
else
    P = cellfun(@(x)(x'),P,'un',0);
    [nFrm,nDay] = deal(max(cellfun(@(x)(size(x,1)),P{1})),1+cP.sepDN);
end
    

% memory allocation
if (isempty(indF)); indF = cell(nDay,nGrp); end
if (isempty(indS)); indS = cell(nDay,nGrp); end

% sets up the temporary time vector
Tall = -(N(1)+nAvg):N(2);

% determines if there are any frames to calculate values for
[V,Vsd,Vtot] = deal(cell(nDay,nGrp));
if (nFrm == 0)
    % if not, then exit the function
    return    
end

% sets the indices over which to bin the velocities calculations
ind = cellfun(@(x)(max(1,x-nAvg):x),num2cell((nAvg+1):nFrm)','un',0);
                        
% calculates the average velocity over each of the groups (speeds are 
% calculated as the average speed over the previous nAvg frames)
for i = 1:nDay
    for j = 1:nGrp
        if (isempty(P{1}{i,j}))
            % if the array is empty, then set a NaN array
            [V{i,j},Vsd{i,j}] = deal(NaN(length(ind),1));
        else
            % sets the signal values for the current group and calculates the
            % average speed trace
            if (is2D)
                [V{i,j},Vsd{i,j},Vtot{i,j}] = calcGroupSRAvgSpeed(...
                        P{1}{i,j},P{2}{i,j},Tall,cType,indF{i,j},indS{i,j},ind);
            else           
                [V{i,j},Vsd{i,j},Vtot{i,j}] = calcGroupSRAvgSpeed(...
                        P{1}{i,j},[],Tall,cType,indF{i,j},indS{i,j},ind);
            end                            
        end
    end
end
    
% converts the cell arrays to numerical arrays
V = cellfun(@(x)(cell2mat(x)),num2cell(V,2),'un',0);
Vsd = cellfun(@(x)(cell2mat(x)),num2cell(Vsd,2),'un',0);
                        
% --- calculates the movement using the absolute distance
function [V,Vsd,Vtot] = calcGroupSRAvgSpeed(Px,Py,Ttot,cType,indF,indS,indB)

% calculates the movement based on whether the y-distances are included
if (isempty(Py))
    % calculates the binned distances from the summed absolute
    % difference in the x-locations
    Vt = cellfun(@(x)(nansum(abs(diff(Px(x,:),1)),1)/...
                    diff(Ttot(x([1 end])))),indB,'un',0);
else
    % sets the binned x/y locations 
    PxB = cellfun(@(x)(Px(x,:)),indB,'un',0);
    PyB = cellfun(@(x)(Py(x,:)),indB,'un',0);
    dT = cellfun(@(x)(diff(Ttot(x([1 end])))),indB,'un',0);

    % calculates the total distance travelled using Phythagoras
    Vt = cellfun(@(x,y,z)(nansum(sqrt(diff(x,[],1).^2 + ...
                diff(y,[],1).^2),1))/z,PxB,PyB,dT,'un',0);        
end

% sets the total signal array
Vtot = cell2mat(Vt);

%
if (~isempty(indS))
    iGrp = cellfun(@(x)(find(indS == x)),num2cell(unique(indS)),'un',0);
    
    VtotF = cell(1,length(iGrp));
    for i = 1:length(iGrp)
        % determines the traces belonging to the current stimuli
        if (~isempty(iGrp{i}))  
            VtotF{i} = Vtot(:,iGrp{i});
        end        
    end
    
    % calculates the signal SEM values
    N = cellfun(@(x)(sum(~isnan(x(1,:)))),VtotF,'un',0);
    Vsd = cellfun(@(x)(nanstd(x,[],2)),VtotF,'un',0)/sqrt(N);
    
    % runs the averageing function (based on type)
    switch (lower(cType))
        case ('mean') % case is calculating average speed
            V = cellfun(@(x)(nanmean(x,2)),VtotF,'un',0);
        case ('median') % case is calculating median speed
            V = cellfun(@(x)(nanmedian(x,2)),VtotF,'un',0);
    end

%     % converts the cell arrays to numerical arrays
%     [V,Vsd] = deal(cell2mat(V),cell2mat(Vsd));
    
    % converts the cell arrays to numerical arrays
    V = cell2mat(reshape(V,[1 1 length(V)]));
    Vsd = cell2mat(reshape(Vsd,[1 1 length(Vsd)]));
else
    % sets the indices of the traces belonging to each fly
    if (isempty(indF))
        VtotF = Vtot;
    else
        iGrp = cellfun(@(x)(find(indF == x)),num2cell(1:max(indF)),'un',0);

        % calculates the mean trace over the 
        VtotF = NaN(size(Vtot,1),max(indF));
        for i = 1:length(iGrp)
            % determines the traces belonging to the current fly
            if (~isempty(iGrp{i}))   
                VtotF(:,i) = mean(Vtot(:,iGrp{i}),2); 
            end
        end
    end

    % calculates the signal SEM values
    N = sum(~isnan(VtotF(1,:)));
    Vsd = nanstd(VtotF,[],2)./sqrt(sum(~isnan(VtotF(1,:))));

    % runs the averageing function (based on type)
    switch (lower(cType))
        case ('mean') % case is calculating average speed
            V = nanmean(Vtot,2);
        case ('median') % case is calculating median speed
            V = nanmedian(Vtot,2);
    end
end