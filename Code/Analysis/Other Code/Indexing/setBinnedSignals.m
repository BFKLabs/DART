% --- sets the signal values, Y, into an array of length, nSig and the
%     indices specified by iT --- %
function Ys = setBinnedSignals(Y,iT,nSig)

% turns off all the warnings
wState = warning('off','all');

% maximum change in position
dPmax = 10;

% memory allocation
[xi,nC] = deal((1:nSig)',size(Y,2));
[xi,Ys] = deal(xi(xi<=size(Y,1)),NaN(nSig,nC));

% from the non-empty groups, calculate the distance travelled over each
% time group (divided by the time for each time group)
iS = arrayfun(@(x)(find(iT == x)),xi,'un',0);
nM = mode(cellfun('length',iS));
jj = cellfun('length',iS) >= min(max(1,nM),max(1,nM/2));

% calculates the mean location for the given time periods
if (any(jj))
    Ys(jj,:) = cell2mat(cellfun(@(x)...
                            (mean(Y(x,:),1,'omitnan')),iS(jj),'un',0));
else    
    Ys(xi,:) = Y(xi,:);
end

% interpolates any NaN-values
for i = 1:nC
    % determines the nan-values in the array
    ii = isnan(Ys(:,i));
    if (any(ii) && ~all(ii))
        iGrp = getGroupIndex(ii);
        for j = 1:length(iGrp)
            if ((iGrp{j}(1) > 1) && (iGrp{j}(end) < nSig))        
                % linearly interpolates the missing signal points
                iiG = iGrp{j};                                
                Ys(iiG,i) = interp1(...
                    find(~ii),Ys(~ii,i),iiG,'pchip','extrap');         
                
                % determines if there is a large change in the signal
                kk = abs(diff([Ys(1,i);Ys(:,i)])) > dPmax;
                if (any(kk))
                    kkI = ~kk & ~ii;
                    Ys(kk,i) = interp1(...
                        find(kkI),Ys(kkI,i),find(kk),'linear','extrap');    
                end                 
            end
        end
    end
end

% turns on the warnings again
warning(wState);