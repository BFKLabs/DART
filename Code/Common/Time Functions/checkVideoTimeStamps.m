function tStampV = checkVideoTimeStamps(tStampV,Tp)

% initialisations
nExpt = length(tStampV);
dT = cellfun(@(x)(median(diff(x),'omitnan')),tStampV);
dTmd = median(dT,'omitnan');

% check each of the videos 
for i = 1:nExpt
    if isnan(dT(i)) 
        if ~isnan(dTmd)
            % if all time-stamps are NaN, then calculate them manually
            if i == 1
                T0 = 0;
            else
                T0 = tStampV{i-1}(end)+Tp;
            end

            % sets the time vector
            tStampV{i} = T0 + dTmd*(0:(length(tStampV{i})-1))';
        end
        
    else
        % otherwise, interpolate any missing values
        isN = isnan(tStampV{i});
        if any(isN)
            [xi,xiN] = deal(find(~isN),find(isN));
            tStampV{i}(xiN) = interp1(xi,tStampV{i}(xi),xiN);
        end
    end
end