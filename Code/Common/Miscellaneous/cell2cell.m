function B = cell2cell(A,isCol)

% returns an empty array (if the original array is empty)
if isempty(A)
    B = [];
    return
end

% memory allocation
A = rmvEmptyCells(A);
if isempty(A)
    B = []; 
    return
else
    [szA,B] = deal(cell2mat(cellfun(@size,A(:),'un',0)),[]);
    if (nargin == 1)
        try
            isCol = range(szA(:,2)) == 0;
        catch
            isCol = (max(szA(:,2))-min(szA(:,2))) == 0;
        end
    end

    % sets the cell arrays into the 
    mxSz = max(szA,[],1);
    for i = 1:length(A)
        if (isCol)
            if (szA(i,2) == mxSz(2))
                % array is the same size as the maximum
                B = [B;A{i}];    
            else
                switch (class(A{i}))
                    case ('logical')
                        C = numcell(false(szA(i,1),mxSz(2)-szA(i,2)));
                    case {'numeric','double'}
                        C = num2cell(NaN(szA(i,1),mxSz(2)-szA(i,2)));
                    case ('cell')
                        C = cell(szA(i,1),mxSz(2)-szA(i,2));
                end               
                
                % appends the new data to the array
                B = [B;[A{i},C]];    
            end
        else
            if (szA(i,1) == mxSz(1))
                % array is the same size as the maximum
                B = [B,A{i}];
            else                
                switch (class(A{i}))
                    case ('logical')
                        C = false(mxSz(1)-szA(i,1),szA(i,2));
                    case {'numeric','double'}
                        C = NaN(mxSz(1)-szA(i,1),szA(i,2));
                    case ('cell')
                        C = num2cell(NaN(mxSz(1)-szA(i,1),szA(i,2)));
                end

                % appends the new data to the array
                B = [B,[A{i};C]];
            end
        end
    end
end
