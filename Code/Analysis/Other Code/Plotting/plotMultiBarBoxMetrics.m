% --- plots multiple field bar graph/boxplot metrics
function [hPlot,xTick,Y] = plotMultiBarBoxMetrics(hAx,p,pStr,pP)

% initialisations
hold(hAx,'on')

% creates the graph based on the plot type
if (strcmp(pP.pType,'Bar Graph'))
    % retrieves the mean/SEM values
    if (isa(pStr,'char'))
        [Y0,Y0s] = field2cell(p,{[pStr,'_mn'],[pStr,'_sem']});
    else
        [Y0,Y0s] = deal(pStr,[]);
    end
    
    % reorders the arrays (if not grouping by type)
    if (~pP.grpType)
        NN = num2cell(1:length(Y0{1}));
        Y0 = cellfun(@(x)(cellfun(@(y)(y(x)),Y0)'),NN,'un',0);
        if (~isempty(Y0s))
            Y0s = cellfun(@(x)(cellfun(@(y)(y(x)),Y0s)'),NN,'un',0);
        end
    end
    
    % sets the final plot values
    Y = cell2mat(Y0(:)')';
    nGrp = size(Y,2)/length(Y0);
    if (isempty(Y0s))
        Ysem = [];
    else
        Ysem = cell2mat(Y0s(:)')';
    end
    
    % creates the bar + errorbars
    col = num2cell(distinguishable_colors(nGrp,'w'),2); 
    [hPlot,xTick] = plotBarError(hAx,Y,Ysem,pP.plotErr,0.75,col);
else
    % retrieves the plot values
    if (isa(pStr,'char'))
        Y0 = field2cell(p,pStr);
        if (iscell(Y0{1}))
            Y0 = cellfun(@(x)(cell2mat(x(:))),Y0,'un',0);    
        else
            Y0 = cellfun(@(x)(x'),Y0,'un',0);    
        end        
    else
        Y0 = pStr;
    end
    
    % reorders the arrays (if not grouping by type)
    if (~pP.grpType)
        Y0 = cellfun(@(x)(combineNumericCells(cellfun(@(y)(y(:,x)),Y0,'un',0))),...
                            num2cell(1:size(Y0{1},2)),'un',0);        
    end    
    
    % creates the boxplot    
    [Y,uData0] = deal(combineNumericCells(Y0,1),get(hAx,'UserData')); 
    nGrp = size(Y,2)/length(Y0);
    
    % creates the box plot
    if (pP.plotErr)
        % outliers are included
        hh = boxplot(Y,'sym','r*');    
    else
        % outliers are not included
        hh = boxplot(Y,'sym','r');
    end    
    
    % resets the colours of the boxplots
    hPlot = zeros(nGrp,1);
    if (nGrp > 1)         
        col = num2cell(distinguishable_colors(nGrp,'w'),2);        
        for i = 1:nGrp        
            set(hh(1:end-1,i:nGrp:size(Y,2)),'color',col{i})
            hPlot(i) = hh(3,i);
        end
    end    
    
    % sets the x-tick indices
    xTick = ((nGrp/2):nGrp:size(Y,2)) + 0.5;  
    
    % updates the axis properties
    delete(findall(hAx,'type','text'))
    set(hAx,'ticklength',[0 0],'box','on','UserData',uData0)          
end