% --- plots a double bar graph/boxplot figure
function [hPlot,xTick] = plotDoubleBarBoxMetrics(hAx,p,pStr,pP,col)   

% converts the metric string to a cell array (if it is not already)
if (~iscell(pStr)); pStr = {pStr}; end

%
if (isfield(pP,'grpTime'))
    grpTime = pP.grpTime;
else
    grpTime = false;
end

% determines the plot type
hold(hAx,'on')
[isBar,N,Np] = deal(strcmp(pP.pType,'Bar Graph'),length(p),length(pStr));

% creates the graph based on the plot type
if (isBar)
    % retrieves the mean/SEM values
    [YY,YYs] = deal(cell(Np,1));
    for i = 1:Np
        [YY{i},YYs{i}] = field2cell(p,{[pStr{i},'_mn'],[pStr{i},'_sem']});
    end
        
    % retrieves the mean/SEM values
    [Y,Ysem] = deal([]);
    if (N == 1)        
        % sets the data into a single array        
        for i = 1:Np
            [Y,Ysem] = deal([Y;cell2mat(YY{i})],[Ysem;cell2mat(YYs{i})]);
        end
        
        % if not grouping by time, then transpose the mean/sem data arrays
        if (grpTime); [Y,Ysem] = deal(Y',Ysem'); end                   
    else
        % sets the data into a single array
        for i = 1:Np
            [Y,Ysem] = deal([Y;cell2mat(YY{i})],[Ysem;cell2mat(YYs{i})]);
        end
        
        % if not grouping by time, then transpose the mean/sem data arrays
        if (~grpTime); [Y,Ysem] = deal(Y',Ysem'); end                           
    end
            
    % creates the bar + errorbar plot
    if (nargin < 5); col = []; end
    [hPlot,xTick] = plotBarError(hAx,Y,Ysem,pP.plotErr,pP.pW,col);
else    
    % retrieves the overall data values
    if (N == 1)
        % sets the data into a single cell array
        Y1 = eval(sprintf('p.%s',pStr{1}));
        Y2 = eval(sprintf('p.%s',pStr{2}));
        
        % combines the data into a single array based on type
        [m1,n1] = size(Y1);
        if (size(Y1,3)*m1 > 1) || ((n1 > 1) && (m1 == 1))
            % case is raw data over multiple experiments
            Yc = [num2cell(cell2mat(Y1(:)),1)',...
                  num2cell(cell2mat(Y2(:)),1)']';
        else
            % case is mean data
            Yc = [Y1(:),Y2(:)];
        end                
        
        if (pP.grpTime)
            % data is grouped by pre/post-stimuli 
            nGrp = 2;        
            Yc = [Yc',cellfun(@(x)(NaN(size(x))),Yc(1,:),'un',0)']';   
        else
            % data is grouped by time
            nGrp = size(Yc,2);
            Yc = [Yc,cellfun(@(x)(NaN(size(x))),Yc(:,1),'un',0)]';
        end

        % combines the data into a single array
        Y = combineNumericCells(cellfun(@(x)(x(:)),Yc(:),'un',0));  
        Y = Y(:,1:end-1);        
    else
        % data is from more than one group          
        for i = 1:N
            % retrieves the new values
            Ynw = [];
            for j = 1:Np
                Yval = eval(sprintf('p(i).%s',pStr{j}));                
                Ynw = [Ynw,Yval(:)]; 
            end
               
            % sets the values into the overall array
            if (grpTime)
                % memory allocations
                if (i == 1)
                    [Y,nGrp] = deal(repmat({NaN},1,(1+2*(Np-1))*N-(Np-1)),Np); 
                end                                                   
                
                % sets the values into the array
                for j = 1:Np; Y{(i-1)*Np+((Np-1)*(i-1)+j)} = Ynw(:,j); end
            else
                % memory allocations
                if (i == 1); [Y,nGrp] = deal(repmat({NaN},1,Np*N-(Np-1)),N); end                                                   
                
                % sets the values into the array
                for j = 1:Np; Y{(j-1)*(N+(Np-1))+i} = Ynw(:,1); end                
            end            
        end
        
        %
        for i = 1:length(Y)
            if (iscell(Y{i}))
                Y{i} = cell2cell(Y{i});
            end
        end
        
        % combines the data into a single array
        Y = combineNumericCells(Y);
    end
    
    % sets the boxplot colours (if not provided)
    if (nargin < 5); col = num2cell(distinguishable_colors(nGrp,'w'),2); end
    
    % creates the boxplot    
    uData0 = get(hAx,'UserData');
    
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
        for i = 1:nGrp        
            set(hh(1:end-1,i:(nGrp+1):size(Y,2)),'color',col{i})
            hPlot(i) = hh(3,i);
        end
    end
    
    % sets the x-tick indices
    xTick = ((nGrp/2):(nGrp+(Np-1)):size(Y,2)) + 0.5;
    
    %
    delete(findall(hAx,'type','text'))
    set(hAx,'ticklength',[0 0],'box','on','UserData',uData0)      
end