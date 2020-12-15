% --- calculates the regional statistics from the neighbouring regions to
%     the binary masks form around the objects location
function pStats = calcRegionStats(pStats,Inw,IBGL,Bw,fxPos,nDS)
                            
% turns off all warnings
wState = warning('off','all');

% global variable
global muDiff statOpt 
if (isempty(muDiff)); muDiff = 10; end

% initialisations
% IBGL,Bw] = deal(dsimage(IBGL,nDS),dsimage(Bw,nDS));
% Inw = cellfun(@(x)(dsimage(x,nDS)),Inw,'un',0);
[iter,pT,iterMx,nDil,sz] = deal(0,1-1e-6,10,3*nDS,size(IBGL));
isIn = (fxPos(:,1) > 0) & (fxPos(:,1) <= sz(2)) & ...
       (fxPos(:,2) > 0) & (fxPos(:,2) <= sz(1));

% calculates the binary spots for the known object locations
BB = cellfun(@(x)(bwmorph(genFlySpotBinary(sz,x),'dilate',nDil)),...
                        num2cell(roundP(fxPos(isIn,:)*nDS),2),'un',0);
                    
% calculates the residual image for the binary spots
IRLbg = cellfun(@(x)(IBGL - x),Inw(isIn),'un',0);
Y = cell2mat(cellfun(@(x,y)(x(y & Bw)),IRLbg,BB,'un',0));

% calculates gaussian model and index of the max residual distribution
while (1)      
    try
        gM = fitgmdist(Y(Y>0),2,'Options',statOpt);
        if (abs(diff(gM.mu)) > muDiff)
            % only exit loop if decent seperation between the
            % two groups has been achieved
            [~,igM] = max(gM.mu);                            

            % determines the residual pixel value for thresholding
            xi = (floor(min(gM.mu)):ceil(max(gM.mu)))';
            [~,~,PDF] = cluster(gM,xi);           
            pStats.pMu = gM.mu(igM);                                 
            pStats.pTol = xi(find(PDF(:,igM) > pT,1,'first'));
            if (isempty(pStats.pTol)); pStats.pTol = xi(1); end            
            pStats.fxPos = NaN(1,2);
            break
        else
            % otherwise, increment the counter
            iter = iter + 1;
            if (iter > iterMx)
                % if the counter is above max, then try using
                % the k-means classifier instead
                try
                    % calculates the k-means classifier
                    Z = Y(Y>0);
                    [~,pMaxNw] = kmeans(Z,2,'start',[max(Z),mean(Z)]');

                    % sets the threshold values
                    pStats.pMu = pMaxNw(1);                                 
                    pStats.pTol = pMaxNw(1);     
                    pStats.fxPos = NaN(1,2);
                end

                break
            end
        end     
    catch
        % increments the counter
        iter = iter + 1;
        if (iter > iterMx)
            % if the counter is above max, then try using
            % the k-means classifier instead
            try
                % calculates the k-means classifier
                Z = Y(Y>0);
                [~,pMaxNw] = kmeans(Z,2,'start',[max(Z),mean(Z)]');

                % sets the threshold values
                pStats.pMu = pMaxNw(1);                                 
                pStats.pTol = pMaxNw(1);     
                pStats.fxPos = NaN(1,2);
            end

            break
        end        
    end
end

% determines the mean binary group size
if (~isnan(pStats.pMu))
    % thresholds the groups that intersect with the position points
    BGrp = cellfun(@(x,y)(detGroupOverlap(x>pStats.pTol,roundP(y))),...
                                        IRLbg,num2cell(fxPos(isIn,:),2),'un',0);
    
    % if any empty groups, determines the largest residual group
    ii = cellfun(@isempty,BGrp);
    if (any(ii))
        BGrp(ii) = cellfun(@(x)({find(rmvGroups(x>pStats.pTol))}),IRLbg(ii),'un',0);
    end
    
    % calculates the size of the binary groups
    pStats.Nsz = cellfun(@(x)(length(x{1})),BGrp);
end

% turns on all warnings
warning(wState)