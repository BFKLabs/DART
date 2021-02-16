% --- retrieves the background images
function iMov = resetBGImages(iMov)

% retrieves the background images
if (iscell(iMov.Ibg{1}))
    i0 = find(cellfun(@(x)(~isempty(x{1})),iMov.Ibg),1,'first');
    [Ibg,bgCell] = deal(iMov.Ibg{i0},true);
else
    [Ibg,bgCell] = deal(iMov.Ibg,false);
end

if (iscell(iMov.iR{1}))
    [iR,iC] = deal(cell2cell(iMov.iR),cell2cell(iMov.iC));
else
    [iR,iC] = deal(iMov.iR,iMov.iC);
end

% determines if the background image array matches the sub-region counts
if (length(Ibg) ~= length(iR))
    % if not, attempt to match the regions by their sizes
    szBG = cell2mat(cellfun(@size,Ibg(:),'un',0));        
    [nR,nC] = deal(cellfun(@length,iR),cellfun(@length,iC));
    
    % determines the closest matching regions 
    ind = zeros(length(nR),1);
    for i = 1:length(nR)
        % calculates the size differences between the images and the size
        % of the row/column index arrays
        dszBG = sum(abs(szBG - repmat([nR(i),nC(i)],size(szBG,1),1)),2);        
        if (i == 1)
            % case is the first sub-region
            ind(i) = find(dszBG==0,1,'first');
        else
            % case is the other sub-regions
            ind(i) = ind(i-1) + find(dszBG((ind(i-1)+1):end)==0,1,'first');
        end
    end
    
    % resets the background images
    if (bgCell)
        % background images are stored for multiple phases
        for i = 1:length(iMov.Ibg)
            iMov.Ibg{i} = iMov.Ibg{i}(ind);
        end
    else
        % background images are stored for a single phases
        iMov.Ibg = iMov.Ibg(ind);
    end
end
