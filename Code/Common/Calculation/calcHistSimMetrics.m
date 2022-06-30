function Q = calcHistSimMetrics(I1,I2,sType)

% sets the default input arguments
if ~exist('sType','var')
    sType = {'edist','mdist','isect','cos','chi2'};
end

% memory allocation
dDtol = 25;
pLim = [2.5,97.5];
Q = NaN(1,length(sType)+1);

% calculates the thresholded pixels from the 1st image
pTol1 = prctile(I1(:),pLim);
B1 = (I1 >= pTol1(1)) & (I1 <= pTol1(2));

% calculates the thresholded pixels from the 2nd image
pTol2 = prctile(I2(:),pLim);
B2 = (I2 >= pTol2(1)) & (I2 <= pTol2(2));

% calculates the histograms for each of the images and aligns them
B12 = B1 & B2;
[xiH,NT] = deal((0:255)',sum(B12(:)));
[N1,N2] = deal(hist(I1(B12),xiH)/NT,hist(I2(B12),xiH)/NT);
[N2a,N1a,Q(end)] = alignsignals(N2,N1,[],'truncate');

% calculates the histogram metrics for each of the stated types
for i = 1:length(sType)
    switch sType{i}
        case 'edist'
            % case is the euclidean distance
            Q(i) = sqrt(sum((N1a - N2a).^2));
            
        case 'mdist'
            % case is the manhattan distance
            Q(i) = sum(abs(N1a - N2a));
            
        case 'isect'
            % case is the intersection distance
            Q(i) = sum(min([N1a(:),N2a(:)],[],2));
            
        case 'cos'
            % case is the vector cosine distance
            QD1 = sqrt(sum(N1a.^2));
            QD2 = sqrt(sum(N2a.^2));
            Q(i) = sum(N1a.*N2a)/(QD1.*QD2);
            
        case 'chi2'
            % case is the chi-squared distance
            Q(i) = 2*sum(((N1a-N2a).^2)./(N1a+N2a),'omitnan');
            
        case 'jsd'
            % case is the jensen-shannon divergence distance
            QD = 2./(N1a + N2a);
            Q(i) = sum(N1a.*log(QD.*N1a) + N2a.*log(QD.*N2a),'omitnan');
    end
end

a = 1;