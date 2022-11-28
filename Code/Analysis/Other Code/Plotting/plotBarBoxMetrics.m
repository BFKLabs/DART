% --- function that creates either a bar graph or boxplot for the metric
%     specified by the variable, pStr
function yLim = plotBarBoxMetrics(hAx,xi,p,pStr,pP,yL,col,sMlt)

% sets the default input values
if (nargin < 7); col = 'b'; end
if (nargin < 8); sMlt = 1; end
if (isempty(pP))
    pP = struct('pType','Bar Graph','plotErr',false); 
end

% determines the plot type
isBar = strcmp(pP.pType,'Bar Graph');

% creates the graph based on the plot type
if isBar
    % retrieves the mean/SEM values
    Y = field2cell(p,[pStr,'_mn'],1)*sMlt;
    Ysem = field2cell(p,[pStr,'_sem'],1)*sMlt;
            
    % creates the bar graph
    bar(hAx,xi,Y,pP.pW,col,'tag','hBar');    
        
    % plots the errorbars (if requested)
    if (pP.plotErr && any(Ysem(:) > 0))
        addBarError(hAx,xi,Y,Ysem,'g');
        yLim = [0,max(max(Y+Ysem))];
    else
        yLim = [0,max(Y)];        
    end    
    
    % removes the tick-marks from the axis
    set(hAx,'ticklength',[0 0],'box','on') 
else
    % retrieves all the data values and places into single array
    if length(p) == 1
        Yc = eval(sprintf('p.%s',pStr));
        if size(Yc,3)*size(Yc,1) > 1
            Yc = num2cell(cell2mat(Yc(:)),1);
        else
            Yc = Yc';
        end
        
        if size(Yc,1) ~= 1
            % determines the empty cells and removes them
            Yc = Yc(~cellfun('isempty',Yc(:,1)),:);            
            if isempty(Yc)
                Yc = {NaN};
            else
                sz = cell2mat(cellfun(@size,Yc(:,1),'un',0));                
                if range(sz(:,1)) == 0
                    Yc = cellfun(@(x)(cell2mat(x')),num2cell(Yc,1),'un',0);
                else
                    Yc = cellfun(@(x)(cell2mat(x)),num2cell(Yc,1),'un',0);
                end
            end
        end
    else
        Yc = field2cell(p,pStr)';
        Yc = cellfun(@(x)(reshape(x,numel(x),1)),Yc,'un',0);
        
        if (length(p) > 1) && (iscell(Yc{1}))
            % vectorises all array cells
            if (~all(cellfun(@(y)(all(cellfun(@(x)(size(x,2)),y)==1)),Yc)))
                for i = 1:length(Yc)
                    Yc{i} = cellfun(@(x)(x(:)),Yc{i},'un',0);
                end
            end
            
            % combines the sub-cells into a single array 
            Yc = cellfun(@(x)(cell2mat(x)),Yc,'un',0);            
        end    
    end
       
    % sets the values into a single array
    Y = combineNumericCells(cellfun(@(x)(x(:)),Yc,'un',0))*sMlt;
    uData0 = get(hAx,'UserData');
    
    % creates the box plot and retrieves the max value
    if pP.plotErr
        % outliers are included
        hBox = boxplot(Y,'sym','r*');
        yLim = [min(Y(~isinf(Y)),[],'omitnan'),...
                max(Y(~isinf(Y)),[],'omitnan')];          
    else
        % outliers are not included
        hBox = boxplot(Y,'sym','r');
        yLim = [min(cellfun(@(x)(min(get(x,'yData'))),num2cell(hBox(2,:)))),...
                max(cellfun(@(x)(max(get(x,'yData'))),num2cell(hBox(1,:))))];        
    end
        
    % expands the boxplot width
    yLim = yLim + 0.025*diff(yLim)*[-1 1];
    expandBoxPlot(hBox)
    
    % removes the x-tick marker strings and determines the overall limit
    delete(findall(hAx,'type','text'))
    set(hAx,'ticklength',[0 0],'box','on','UserData',uData0)         
end

% determines the overall y-axis limit
if isempty(yL)
    if isBar
        if pP.plotErr
            yL = [0,detOverallLimit(Y+Ysem)]; 
        else
            yL = [0,detOverallLimit(Y)]; 
        end        
    else
        yL = yLim;
    end        
end

% sets the x/y-axis limits
xLim = xi([1 end]) + 0.5*[-1 1];
if all(isnan(Y(:))) || all(isnan(yL)) || (range(yL) == 0)
    set(hAx,'xlim',xLim,'ylim',[0 1],'xtick',xi)            
else
    if (length(yL) == 1); yL = [0,yL]; end
    set(hAx,'xlim',xLim,'ylim',yL,'xtick',xi)            
end    

% if there is a large range of sleep latency values, then change the
% graphs y-axis scale to log
YY = Y(~isinf(Y));
if (log10(max(YY(:)+1,[],'omitnan')/max(1,min(YY(:),[],'omitnan'))) >= 3)
    yLim = [max(1,min(YY(:),[],'omitnan')),max(get(hAx,'ylim'))];
    set(hAx,'ylim',yLim,'yscale','log')
end

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- expands the boxplot width
function expandBoxPlot(hBox)

% parameters and initialisations
[Wbox,ii] = deal(0.5,[1 1 2 2 1]);
hTag = get(hBox(:,1),'tag');
pStr = {'Upper Adjacent Value','Lower Adjacent Value','Box','Median'};

% sets the indices of the 
iStr = cellfun(@(x)(find(strcmp(x,hTag))),pStr);

% adjusts the widths for each of the objects
for j = 1:size(hBox,2)
    % sets the x-values for the 
    xx = j + (Wbox/2)*[-1 1];
    
    % updates the object properties
    for i = 1:length(pStr)
        switch (pStr{i})
            case ('Box')
                set(hBox(iStr(i),j),'xdata',xx(ii))
            otherwise
                set(hBox(iStr(i),j),'xdata',xx)
        end
    end
end


