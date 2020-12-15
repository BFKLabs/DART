% --- 
function [pC,isOK] = getBinaryOutlineCoords(iGrp,sz)

% determines the indices/lengths of the feasible contours (contours that
% have start/end points that are the same)
hh = contourc(double(setGroup(iGrp,sz)),0.25*[1 1]);
if (isempty(hh)); return; end

% determines if the 
[cOfs,iLvl] = deal(1,[]);
while (cOfs <= size(hh,2))
    % sets the number of indices for the current contour level
    Nnw = hh(2,cOfs);
    iCnw = cOfs + [1 Nnw];
    
    % determines if the contour start/end are coincident
    if ((diff(hh(1,iCnw)) == 0) && (diff(hh(2,iCnw)) == 0))
        % if so, then set the contour indices/level values
        iLvl = [iLvl;iCnw];
    end
    
    % increments the column offset counter
    cOfs = cOfs + (Nnw+1);
    if (cOfs > size(hh,2)); break; end
end

% splits the contours
iC = cellfun(@(x)(x(1):x(2)),num2cell(iLvl,2),'UniformOutput',0);
pC = cellfun(@(x)([hh(1,x)',hh(2,x)']),iC,'UniformOutput',0);

%
ind = zeros(length(iGrp),1);
for i = 1:length(iGrp)
    [yGrp,xGrp] = ind2sub(sz,iGrp{i});
    j = 1;
    
    while (1)
        ii = cellfun(@(x)(inpolygon(xGrp(j),yGrp(j),x(:,1),x(:,2))),pC);
        if (any(ii))
            ind(i) = find(ii);
            break
        else    
            j = j + 1;
            if (j > length(xGrp))
                break
            end
        end
    end
end

%
isOK = ind>0;
pC = pC(ind(isOK));