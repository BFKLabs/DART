% --- calculates the normalized signal for each phase
function p = calcSignalPhases(snTot,cP)

% memory allocation
p = struct('ind1',[],'iPeak1',NaN,'yPeak1',NaN,'Ynorm1',[],...
           'ind2',[],'iPeak2',NaN,'yPeak2',NaN,'Ynorm2',[]);

% array dimensioning
[pSD,pStart,nBase] = deal(cP.pSD,cP.pStart,cP.nBase);
[Ysig,YsigN] = deal(snTot.Ysig,snTot.YsigN);
[nRows,nCols] = size(Ysig);

% sets the indices for the first half of the signal
ind1 = 1:ceil(nRows/2);

% calculates the signal peaks for the current signal
iPeakH = NaN(1,nCols);
for iCol = 1:nCols    
    [~,iPeakH(iCol)] = max(Ysig(ind1,iCol));    
end

% calculates the mean/std indices of the signal peaks
[iPeakMn,iPeakSD] = deal(mean(iPeakH),std(iPeakH));

% removes any outlying peaks and recalculates the meak peak index. from
% this, set the index array for determining the plateau point
ii = (iPeakH >= (iPeakMn-pSD*iPeakSD)) & (iPeakH <= (iPeakMn+pSD*iPeakSD));
ind2 = (round(mean(iPeakH(ii)))+1):nRows;

% finds the plateau point of endocytosis
[~,imx] = max(YsigN(ind2));
[~,imn] = min(YsigN(ind2(1:imx)));
iPlateau = ind2(imn);

% determines the locations of the 1st/2nd signal peaks
[~,iPeak1] = max(Ysig(1:(ind2(1)-1),:));
[~,iPeak2] = max(Ysig(iPlateau:end,:));
[iPeak1Mx,iPeak2Mx] = deal(max(iPeak1),max(iPeak2));

% creates a vector consisting of the final peak locations
[dInd1,dInd2] = deal(iPeak1Mx-iPeak1,iPeak2Mx-iPeak2);
Yshift1 = NaN(max(dInd1)+nRows,nCols);
Yshift2 = NaN(max(dInd2)+nRows,nCols);

% sets the shift arrays for each phase
for iCol = 1:nCols
    Yshift1(dInd1(iCol)+(1:nRows),iCol) = Ysig(:,iCol);
    Yshift2(dInd2(iCol)+(1:nRows),iCol) = Ysig(:,iCol);
end

% determines the start times of the phases
iAvgS1 = find(mean(~isnan(Yshift1),2)>=pStart,1,'first');
iAvgS2 = find(mean(~isnan(Yshift2),2)>=pStart,1,'first');

% calculates the baseline normalised signals for each phase
Ynorm1 = calcBaseNormSignal(Yshift1(iAvgS1+(0:nRows-1),:),nBase);
Ynorm2 = calcBaseNormSignal(Yshift2(iAvgS2+(0:nRows-1),:),nBase);

% sets the 
N = min(120,iPlateau);

% sets the final values
[p.ind1,p.ind2] = deal(1:iPlateau,iPeak1Mx:length(Ynorm2));
[p.Ynorm1,p.Ynorm2] = deal(Ynorm1(1:iPlateau),Ynorm2(iPeak1Mx:end));
[p.yPeak1,p.yPeak2] = deal(max(p.Ynorm1(1:N)),max(p.Ynorm2));
[p.iPeak1,p.iPeak2] = deal(ind2(1)-1,iPlateau);

% --- calculates the baseline normalised signals
function Ynorm = calcBaseNormSignal(Y,nBase)

% calculates the mean signal
Ymn = mean(Y,2,'omitnan');

% divides the mean signal by the baseline section of the signal
Ynorm = (Ymn/mean(Ymn(1:nBase))) - 1;