% --- retrieves the region image stack
function [IL,BL] = getRegionImgStack(iMov,I0,iFrm,iApp,isHiV)

% sets the default input arguments
if ~exist('isHiV','var'); isHiV = false; end

% ensures the image data is stored in a cell array
if ~iscell(I0); I0 = {I0}; end

% retrieves the new image frame
IL = cell(size(I0));           
[hasF,hasT] = deal(false);
isMltTrk = detMltTrkStatus(iMov);
[iR,iC] = deal(iMov.iR{iApp},iMov.iC{iApp});

% sets the image fluctuation flag
if isfield(iMov,'phInfo')
    if isfield(iMov.phInfo,'hasF')
        [hasF,hasT] = deal(iMov.phInfo.hasF,iMov.phInfo.hasT(iApp));
    end
end

% sets the sub-image stacks
isOK = ~cellfun('isempty',I0);
IL(isOK) = cellfun(@(I)(I(iR,iC)),I0,'un',0); 
if any(~isOK)
    % if the image is empty, then return NaN arrays
    szT = [sum(~isOK),1];
    IL(~isOK) = repmat({NaN(length(iR),length(iC))},szT);
end              

% corrects image fluctuation (if required)
if hasF || (isHiV && ~isMltTrk)
    % if there is fluctuation, then apply the hm filter and the
    % histogram matching to the reference image
    h = iMov.phInfo.hmFilt{iApp};
    Imet = cellfun(@(x)(applyHMFilterWrapper(x,h)),IL(:),'un',0); 
    IL = cellfun(@(x)(x - median(x(:),'omitnan')),Imet,'un',0);
    if ~hasT && (nargout == 2)
        BL = cellfun(@(x)(x < mean(x(:),'omitnan')),IL,'un',0);
    end

elseif (nargout == 2)
    % case is there is no light fluctuation
    BL = cell(length(IL),1);
end

% corrects image fluctuation
if hasT
    p = iMov.phInfo.pOfs{iApp};
    pOfsT = interp1(iMov.phInfo.iFrm0,p,iFrm,'linear','extrap');
    IL = cellfun(@(x,p)(applyImgTransWrapper(x,p)),...
                        IL(:),num2cell(pOfsT,2),'un',0);

    if iMov.phInfo.hasF && (nargout == 2)
        BL = cellfun(@(x)(x < mean(x(:),'omitnan')),IL,'un',0);
    end                                
end

% --- applies the image translation 
function IT = applyImgTransWrapper(I,pOfs)

% if the image is empty or all NaNs then exit with the original image
N = min(10,min(size(I)));
if isempty(I) || all(isnan(arr2vec(I(1:N,1:N))))
    IT = I;
    return;
end

% pads the array by the movement magnitude
sz = size(I);
dpOfs = ceil(abs(flip(pOfs)));
Iex = padarray(I,dpOfs,'both','symmetric');

% translates and sets the final offset image
IT0 = imtranslate(Iex,-pOfs);
IT = IT0(dpOfs(1)+(1:sz(1)),dpOfs(2)+(1:sz(2)));

% --- applies the homomorphic filter to the image, I
function Ihm = applyHMFilterWrapper(I,hF)

Ihm = applyHMFilter(I,hF);
Ihm = 255*normImg(Ihm - min(Ihm(:)));            

