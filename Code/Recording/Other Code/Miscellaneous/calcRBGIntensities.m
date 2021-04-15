% --- calculates the LED RGB values for the current wavelength, wNM
function [grpRGB,pRGB] = calcRBGIntensities(fOpto,wNM)

% memory allocation
iDiff = find(diff([wNM;-1])~=0);
nGrp = length(iDiff);

% memory allocation
[grpRGB, pRGB, ind] = deal(ones(nGrp,2), zeros(nGrp,3), [1 2 3]);

% calculates the LED intensities for each colour channel
for i = 1:nGrp
    % sets the group indices
    if (i == 1)
        % case is the first group
        grpRGB(i,2) = iDiff(i);
    else
        % case is the other groups
        grpRGB(i,:) = [iDiff(i-1)+1,iDiff(i)];
    end
    
    % sets the RGB values for the group
    for j = 1:length(ind)
        pRGB(i, ind(j)) = ppval(fOpto(j),wNM(grpRGB(i,1)));
    end
end