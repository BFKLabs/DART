% --- determines the optimal downsampling rate
function nDS = detOptDownSampleRate(iMov,sImg,xcP)

%
D = floor(size(xcP.ITx,1)/2); 
[nApp,iMov.nDS] = deal(length(iMov.iR),1);
nRowMn = min(cellfun(@(x)(min(cellfun(@length,x))),iMov.iRT));
nColMn = min(cellfun(@length,iMov.iCT));

% determines the maximum downsample rate
nDSmx = min(ceil(nRowMn/(D)),ceil(nColMn/(D)));
if (nDSmx == 1)
    % if the maximum downsample rate is 1, then exit the function
    nDS = 1;
    return
end

% memory allocation
ZZ = cell(1,nApp);

% determines the 
for i = 1:nApp
    % on
    if (iMov.ok(i))    
        % memory allocation
        Bw0 = getExclusionBin(iMov,size(sImg.I{1,i}),i);
        ZZ{i} = NaN(nDSmx,getAppFlyCount(iMov,i));
        dI = cellfun(@(x)(Bw0.*abs(sImg.I{1,i}-x)),sImg.I(2:end,i),'un',0);
%         dI0 = min(cell2mat(reshape(sImg.I(:,i),[1 1 size(sImg.I,1)])),[],3);
        
        % calculates the optimal down-sampled values
        for iDS = 1:nDSmx          
            %
            if (iDS == 1)
                ind = zeros(size(sImg.I{1,i},1),1);
                for j = 1:length(iMov.iRT{i})
                    ind(iMov.iRT{i}{j}) = j;
                end
            end
            
            % sets the down-sampled image            
            ILds = dsimage(dI0,iDS);

            % calculates the cross-correlation
            [Gx,Gy] = imgradientxy(ILds,'Sobel');
            Z = 0.5*(calcXCorr(xcP.ITx,Gx,D) + calcXCorr(xcP.ITy,Gy,D));
            
            % sets the downsampled local index array
            indL = 1:iDS:length(ind);
            
            %
            for j = 1:size(ZZ{i},2)
                if (iMov.flyok(j,i))                     
                    % calculates the 
                    ZR = Z(ind(indL) == j,:);
%                     ZZ{i}(iDS,j) = max(ZR(:))/median(abs(ZR(:)));
                    ZZ{i}(iDS,j) = max(ZR(:))/mean(abs(ZR(:)));
                end
            end
        end                
    end
end

% determines the optimal down-sample rate
nDS = argMax(nanmean(cell2mat(ZZ(iMov.ok)),2));