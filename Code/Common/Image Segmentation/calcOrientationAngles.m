% --- calculates the fly orientation angles from their binary images
function Phi = calcOrientationAngles(I,fPos,sz,NszP)

% global variables
global Nsz
N = roundP((pi/2)*(Nsz/2)^2);

% memory allocation
del = ceil(sqrt(NszP)+1);
fPos = num2cell(roundP(fPos),2);

% sets the local images surrounding the position vectors
A = cellfun(@(x,y)(getLocalImage(x,y,del,sz)),I,fPos,'un',0);

% calculates the local image orientation angles
Phi = cell2mat(cellfun(@(x)(calcLocalImageAngle(x,N)),A,'un',0));
Phi(:,1) = Phi(:,1)*(180/pi);

% determines if there were any NaN-values in the angle calculations
ii = isnan(Phi(:,1));
if (any(ii))
    % if so, then if not all values are NaNs, then fill in the gaps
    if (~all(ii))
        % determines the non-NaN values
        isOk = find(~ii);
        
        % loops through each of the groups removing the NaN-values
        iGrp = getGroupIndex(ii);
        for i = 1:length(iGrp)
            if (iGrp{i}(1) == 1)
                % case is group contains NaN value at start of stack
                Phi(iGrp{i},:) = repmat(Phi(iGrp{i}(end)+1,:),length(iGrp{i}),1);
            elseif (iGrp{i}(end) == size(Phi,1))
                % case is group contains NaN value at end of stack
                Phi(iGrp{i},:) = repmat(Phi(iGrp{i}(1)-1,:),length(iGrp{i}),1);
            else
                % case is NaN values are surrounded by non-NaN values
                Phi(iGrp{i},1) = interp1(isOk,Phi(isOk,1),iGrp{i});
                Phi(iGrp{i},2) = interp1(isOk,Phi(isOk,2),iGrp{i});
            end
        end
    end
end
