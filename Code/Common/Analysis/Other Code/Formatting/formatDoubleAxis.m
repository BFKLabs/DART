% --- 
function pF = formatDoubleAxis(hAx,hBar,pF,ind)

% updates the axis colours
if (length(pF) == 1)
    % resets the axis/y-label font colours
    pF = repmat(pF,1,2);

    % resets the stricts for each of the labels
    [pF(2).xLabel.String,pF(2).Title(ind).String] = deal('');  
    col = cellfun(@(x)(get(x,'FaceColor')),hBar,'un',0);                
    [pF(1).yLabel(1).Font.Color,...
            pF(1).Axis.Font.Color] = deal(col{1});
    [pF(2).yLabel(1).Font.Color,...
            pF(2).Axis.Font.Color] = deal(col{2});                                                
    pF(2).Title(1).Font.Color = 'w';                                                
end

% resets the axis-limits
set(hAx(2),'xticklabel',[]);

% formats the plot axis
formatPlotAxis(hAx(1),pF(1),ind);   
formatPlotAxis(hAx(2),pF(2),ind); 
set(hAx(1),'xcolor','k')
set(hAx(2),'xcolor','k')

