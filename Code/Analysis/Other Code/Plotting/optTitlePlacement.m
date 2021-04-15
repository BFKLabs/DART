% --- optimises the axis title strings so that they do not overlap
function optTitlePlacement(hAx,Type)

% sets the default input arguments
if (nargin == 1); Type = 'title'; end


% converts the axes handles into a cell array
if (~iscell(hAx))
    if (length(hAx) == 1)
        hAx = {hAx}; 
    else
        hAx = num2cell(hAx);
    end
end

% retrieves the axes positions
axP = cell2mat(cellfun(@(x)(get(x(1),'position')),hAx,'un',0));

% retrieves the title string handles, and gets their extents
h = cellfun(@(x)(get(x,Type)),hAx,'un',0);
cellfun(@(x)(set(x(1),'Units','Normalized')),h)
exT = cell2mat(cellfun(@(x)(get(x(1),'extent')),h,'un',0));

% sets the update properties based on the label type
switch (lower(Type))
    case ('title') % case is the title labels
        [indD,indEx,indB,axDC] = deal(4,[1 3],2,axP(1,3));
    case ('ylabel') % case is the y-axis labels
        [indD,indEx,indB,axDC] = deal(3,[2 4],1,axP(1,4));
end

% determines the unique row/column indices
[~,~,C] = unique(axP(:,indB));
indC = cellfun(@(x)(find(C == x)),num2cell(1:max(C)),'un',0);
iC = indC{1};

% calculates the overlap of the titles
Tx = repmat(axP(iC,indEx(1)),1,2)+...
        [exT(iC,indEx(1)).*axDC,sum(exT(iC,indEx),2).*axDC];

% calculates the overlap 
switch (lower(Type))
    case ('title')
        dTx = Tx(2:end,1) - Tx(1:(end-1),2);        
    case ('ylabel')
        dTx = Tx(1:(end-1),1) - Tx(2:end,2);    
end
    
% if any titles overlap, then 
if ((any(dTx) < 0) || (any(Tx(:,1) < 0)) || (any(Tx(:,2) > 1)))
    % sets the title strings
    tStr = cellfun(@(x)(get(x,'string')),h,'un',0);
    
    % determines the optimal splitting of the title strings
    for i = 1:length(tStr)
        % if the title is already split, then recombine
        if (iscell(tStr{i}))
            A = [tStr{i},repmat({' '},length(tStr{i}),1)]'; A = A(:);
            tStr{i} = cell2mat(A(1:(end-1))');
        end
        
        % splits the title strings by the white-space
        if (~isempty(tStr{i}))
            [~,ind] = regexp(tStr{i},'\s','split');
            if (~isempty(ind))
                % if white space does exist, then determine the optimal pattern
                [~,ii] = min(abs(length(tStr{i})-2*ind));
                tStrNw = {tStr{i}(1:(ind(ii)-1));tStr{i}((ind(ii)+1):end)};       
            else                
                tStrNw = {' ';tStr{i}};
            end 
            
            % resets the title to the new strings
            set(h{i},'string',tStrNw)                 
        end
    end
        
    % sets the new/old heights
    exTnw = cell2mat(cellfun(@(x)(get(x,'extent')),h,'un',0));
    [Dnw,D0] = deal(exTnw(:,indD),exT(:,indD));
    
    % sets the new height to be the maximum of the new title string
    % heights. from this ensure all title strings are the new height. also
    % shrink the size of the axis to encompass the new titles
    dD = (Dnw - D0)*axP(1,indD);
    for i = 1:length(tStr)        
        % calculates the offsets for the axes that don't have the strings
        if (~strcmpi(Type,'title'))
            if (~isempty(tStr{i}))
                axP(i,indB) = axP(i,indB) + dD(i);
            else                
                i1 = find(cellfun(@(x)(any(x == i)),indC));
                dB = (length(iC)-i1+1)*mean(dD);
                axP(i,indB) = axP(i,indB) + dB;
            end
        end
                
        % resets the axis perpendicular dimension
        axP(i,indD) = axP(i,indD) - mean(dD);     
        if (iscell(hAx(i)))
            set(hAx{i},'position',axP(i,:))
        else
            set(hAx(i),'position',axP(i,:))
        end
    end
end