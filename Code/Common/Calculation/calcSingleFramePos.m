% --- calculates the locations of the flies 
function [fPos,iMov,isChange] = calcSingleFramePos(iMov,ImgFrm,p0)

% global variables
global Nsz

% parameters
[rMin,rTol] = deal(5,3);

% memory allocation
nDS = getDownSampleRate(iMov);
nTube = getSRCountVec(iMov);
[nApp,isChange] = deal(length(p0),false);
[Ibg,IbgE,pStats] = deal(iMov.Ibg{1},iMov.IbgE,iMov.pStats);
[fPos,fok] = deal(cell(1,nApp),iMov.flyok);
isGen = strcmp(getDetectionType(iMov),'General');
    
% loops through all the apparatus calculating the fly locations
for i = 1:nApp
    if iMov.ok(i)
        % ------------------------------------------- %
        % --- MEMORY ALLOCATION & INITIALISATIONS --- %
        % ------------------------------------------- %
        
        % determines which tube regions are stationary
        [ii,fPos{i}] = deal(find(fok(:,i)),NaN(nTube(i),2));
        [jj,iRT] = deal(cellfun(@isempty,iMov.IbgE(ii,i)),iMov.iRT{i});         
        [isS,isM] = deal(ii(~jj),ii(jj));
        
        % sets the x/y offsets         
        xOfs = iMov.iC{i}(1)-1;
        yOfs = cellfun(@(x)(x(1)-(2-iMov.iR{i}(1))),iMov.iRT{i});

        % sets the local background/raw images
        ImgFrmL = ImgFrm(iMov.iR{i},iMov.iC{i});
        IbgL = cellfun(@(x)(Ibg{i}(x,:)),iRT,'un',0); 
        ImgL = cellfun(@(x)(double(ImgFrmL(x,:))),iRT,'un',0);  
        ImgR = cellfun(@(x,y)(x-y),IbgL,ImgL,'un',0);
        
        % ----------------------------------------------- %
        % --- STATIONARY OBJECT TRACKING CALCULATIONS --- %
        % ----------------------------------------------- %        
        
        % calculates the locations of the stationary objects
        if (any(~jj))
            % calculates the SVM image stack
            iMov.nDS = 1;
            Isvm = cellfun(@(x)(setupClassifierStack(...
                            iMov,dsimage(x,nDS),NaN,1)),ImgL(isS),'un',0);
                        
            % sets the local indices
            indL = cellfun(@(x,y)(getLocalIndices(x/nDS,size(y)/nDS)),...
                                p0{i}(isS),ImgL(isS),'un',0);
                        
            % sets the local images and calculates the minimum of each
            IsvmL = cellfun(@(x,y)(x(y{2},y{1})),Isvm,indL,'un',0);
            
            % calculates the local residuals
            ImgRS = ImgR(isS);
            ImgRL = cellfun(@(x,y)(x(y{2},y{1})),ImgRS,indL,'un',0);
            
            % calculates the maximum residuals in the local and global
            % image frames
            ImgRLmx = max(rMin,cellfun(@(x)(max(x(:))),ImgRL));
            ImgRmx = max(rMin,cellfun(@(x)(max(x(:))),ImgRS));
            
            % determines which frames are less than tolerance
            ii = (ImgRmx./ImgRLmx) < rTol;
            
            % for each of the regions where the object is still in the
            % image frame, calculate the local positions and update the
            % background image (if the object has partially moved)
            if (any(ii))
                % retrieves the local positions
                kk = find(ii);
                fPosL = cellfun(@(x)(calcMaxValueLocation(x,'min')*nDS),...
                                        IsvmL(kk),'un',0);
                pOfs = cellfun(@(x)([x{1}(1)-1,x{2}(1)-1]*nDS),...
                                        indL(kk),'un',0);             
                for j = 1:length(pOfs)
                    % sets the overall index
                    k = isS(kk(j));
                    sz = size(ImgL{k});
                    
                    % determines the binary region surrounding the object 
                    fPos{i}(k,:) = roundP(fPosL{j} + pOfs{j});
                    BwD = setGroup(sub2ind(sz,fPos{i}(k,2),fPos{i}(k,1)),sz);
                    BPos = bwdist(BwD)<(3*Nsz/4+1);

                    % determines the residual empty background image region
                    BPosR = IbgE{k,i} & ~BPos;
                    if (any(BPosR(:)))   
                        % sets the missing regions
                        [IbgL,isChange] = deal(Ibg{i}(iRT{k},:),true);
                        IbgL(BPosR) = ImgL{k}(BPosR);
                        Ibg{i}(iRT{k},:) = IbgL;

                        % removes the background regions that are found
                        IbgE{k,i} = IbgE{k,i} & ~BPosR; 
                        if (~any(IbgE{k,i}(:)))
                            % if completely empty, then set the region as empty
                            IbgE{k,i} = [];

                            % calculates the tube region statistics                            
                            Bw = getExclusionBin(iMov,size(ImgL{k}),i,k,1);
                            pStats{i}(k) = calcRegionStats(...
                                pStats{i}(k),ImgL(k),IbgL,Bw,fPos{i}(k,:),1);
                        end
                    end                
                end
            end
            
            % for each of the regions where object is not within the local
            % image frame, then recalculate the background image and the
            % local image statistics
            for j = reshape(find(~ii),1,sum(~ii))
                % sets the overall index
                k = isS(j);
                
                % updates the background image
                IbgL = Ibg{i}(iRT{k},:);
                IbgL(IbgE{k,i}) = ImgL{isS(j)}(IbgE{k,i});                
                [IbgE{k,i},Ibg{i}(iRT{k},:),isChange] = deal([],IbgL,true);
                
                % calculates the location of the maximum point
                Bw = getExclusionBin(iMov,size(ImgL{k}),i,k,1);
                fPos{i}(k,:) = calcMaxValueLocation(Bw.*(IbgL-ImgL{k}));
                
                % calculates the tube region statistics                
                pStats{i}(k) = calcRegionStats(...
                            pStats{i}(k),ImgL(k),IbgL,Bw,fPos{i}(k,:),1);
            end                                                            
        end           
        
        % ------------------------------------------ %
        % --- MOVED OBJECT TRACKING CALCULATIONS --- %
        % ------------------------------------------ %
        
        % calculates the locations of the moved objects
        if (any(jj))
            % calculates the local residual images
            pStatsNw = num2cell(pStats{i}(isM));        
            ImgRM = ImgR(isM);
            
            if (isGen)
                BwG = cellfun(@(x)(getExclusionBin(iMov,[],i,x,1)),...
                                num2cell(isM),'un',0);
                ImgRM = cellfun(@(x,y)(x.*y),BwG,ImgRM,'un',0);
            end
            
            % calculates and sets the fly locations
            fPosNw = cellfun(@(x,y,z,pp)(calcLocalFrameLocations('BGsub',...
                            {x},{y},z,NaN,pp)),ImgRM,ImgL(isM),p0{i}(isM),...
                            pStatsNw,'un',0);  
            fPos{i}(isM,:) = cell2mat(fPosNw);                                  
        end                    
        
        % calculates the locations of the flies        
        fPos{i} = fPos{i} + [repmat(xOfs,nTube(i),1),yOfs];
    else
        % if not ok, then set NaN values
        fPos{i} = NaN(nTube(i),2);
    end
end   

% if there was a change in the background, then update the data struct
if (isChange)
    [iMov.Ibg{1},iMov.IbgE,iMov.pStats] = deal(Ibg,IbgE,pStats);
end

% --- sets the local indices
function ind = getLocalIndices(p0,sz)

% global variables
global Nsz

% sets the indices
[del,ind] = deal(roundP(3*Nsz/2),cell(1,2));

% sets the indices and ensures they are within the image frame
for i = 1:length(ind)
    ind{i} = roundP(p0(i)) + (-del:del);
    ind{i} = ind{i}((ind{i}>0) & (ind{i}<=sz((1:2) ~= i)));
end