% --- optimises the y-axis title strings so that they do not overlap
function optYTitlePlacement(hAx,hText)

% retrieves the extents
axP = get(hAx,'position');
[yExt,yStr] = deal(get(hText,'extent'),get(hText,'string'));
if (iscell(yExt)); yExt = cell2mat(yExt); end

% sets the top/bottom of the object
[T,B] = deal(yExt(:,2)-yExt(:,4),yExt(:,2));

% determines if there is any overlap with the y-axis titles
if (any(T(2:end) < B(1:(end-1))))
    %
    for i = 1:length(yStr)
        % splits the title strings by the white-space
        if (~isempty(yStr{i}))
            [~,ind] = regexp(yStr{i},'\s','split');
            if (~isempty(ind))
                % if white space does exist, then determine the optimal pattern
                [~,ii] = min(abs(length(yStr{i})-2*ind));
                yStrNw = {yStr{i}(1:(ind(ii)-1));yStr{i}((ind(ii)+1):end)};       
            else                
                yStrNw = {' ';yStr{i}};
            end 
            
            % resets the title to the new strings
            set(hText(i),'string',yStrNw)                 
        end        
    end
    
    % sets the new/old text object widths
    [yExtNw,axL] = deal(cell2mat(get(hText,'extent')),get(hAx,'xlim'));
    [Wnw,W0] = deal(max(yExtNw(:,3)./diff(axL)),max(yExt(:,3)./diff(axL)));
    
    % sets the new height to be the maximum of the new title string
    % heights. from this ensure all title strings are the new height. also
    % shrink the size of the axis to encompass the new titles
    [dW,dL] = deal((Wnw-W0)*axP(3),sum(yExtNw(1,[1 3]))-sum(yExt(1,[1 3])));    
    axP([1 3]) = axP([1 3]) + dW*[1 -1];
    set(hAx,'position',axP)
    
    % resets the left location of the axis labels
    yPos = get(hText,'position');
    for i = 1:length(hText)
        yPos{i}(1) = yPos{i}(1) - dL;
        set(hText(i),'position',yPos{i})
    end
end