function Yex = extrapBlobPosition(Y)

% determines the valid coordinates
isOK = ~isnan(Y(:,1));
Yex = NaN(1,size(Y,2));

% if there are no coordinates, then exit
if isempty(Y)
    return
end

% extrapolates the coordinates (based on the valid inputs)
nP = sum(isOK);
switch nP
    case 0
        % do nothing...
    
    case 1
        % case is there only 1 valid point
        Yex = Y(isOK,:);

    otherwise                
        % case is there are multiple valid points
        for j = 1:size(Y,2)
            a = arburg(Y(isOK,j),nP-1);            
            if any(isnan(a))
                % case is the filter is invalid, so take the mean of the
                % coordinates
                Yex(j) = nanmean(Y(isOK,j));
            else
                % otherwise, calculate the extrapolated value
                [~, zf] = filter(-[0 a(2:end)], 1, Y(isOK,j));  
                Yex(j) = filter([0 0], -a, 0, zf);
            end
        end
end