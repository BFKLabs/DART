% --- calculates the metrics for the given metric name
function YmetT = calcMetrics(Y,vName)

% memory allocation
YmetT = cell(size(Y));
sz = cellfun(@(x)([1,size(x,2),size(x,3)]),Y,'un',0);

% removes any infinite values
Y = cellfun(@(x)(x.*(~isinf(x))),Y,'un',0);

% calculates the metrics based on the metric name
switch vName
    case ('sum') 
        % case is the mean            
        Ymet = cellfun(@(x)(sum(x,1,'omitnan')),Y,'un',0);
    
    case ('mn') 
        % case is the mean            
        Ymet = cellfun(@(x)(mean(x,1,'omitnan')),Y,'un',0);
    
    case ('md') 
        % case is the median
        Ymet = cellfun(@(x)(median(x,1,'omitnan')),Y,'un',0);
    
    case ('lq') 
        % case is the lower quartile            
        Ymet = cellfun(@(x)(quantile(x,0.25,1)),Y,'un',0);        
    
    case ('uq') 
        % case is the upper quartile            
        Ymet = cellfun(@(x)(quantile(x,0.75,1)),Y,'un',0);
    
    case ('rng') 
        % case is the range            
        Ymet = cellfun(@(x)(range(x,1)),Y,'un',0);
    
    case ('ci') 
        % case is the 95% confidence interval            
        Ymet = cellfun(@(x)(prctile(x,[2.5 97.5],1)),Y,'un',0);
    
    case ('sd') 
        % case is the standard deviation                    
        Ymet = cellfun(@(x)(std(x,[],1,'omitnan')),Y,'un',0);
    
    case ('sem') 
        % case is the standard error mean
        Ymet = cellfun(@(x)(std(x,[],1,'omitnan')./...
                            sqrt(sum(~isnan(x),1))),Y,'un',0);
    
    case ('min') 
        % case is the minimum
        Ymet = cellfun(@(x)(min(x,[],1,'omitnan')),Y,'un',0);
    
    case ('max') 
        % case is the maximum            
        Ymet = cellfun(@(x)(max(x,[],1,'omitnan')),Y,'un',0);
    
    case ('N') 
        % case is the N-values
        Ymet = cellfun(@(x)(sum(~isnan(x),1)),Y,'un',0);
end

% sets the final data array
for i = 1:numel(Y)
    % sets the metric strings
    if ~isempty(Ymet{i})
        switch vName
            case ('ci') 
                % case is the confidence interval
                isN = isnan(Ymet{i}(1,:,:)) | isnan(Ymet{i}(2,:,:));
                A1 = string(reshape(roundP(Ymet{i}(1,:,:),0.01),sz{i}));
                A2 = string(reshape(roundP(Ymet{i}(2,:,:),0.01),sz{i}));
                YmetNw = cell2cell(cellfun(@(x,y)(...
                        string(sprintf('%s-%s',x,y))),A1,A2,'un',0),0);
                        
            case ('N') 
                % case is the N-values
                isN = isnan(Ymet{i});
                YmetNw = string(reshape(roundP(Ymet{i},1),sz{i}));
                
            otherwise
                % case is the other metrics
                isN = isnan(Ymet{i});
                YmetNw = string(reshape(roundP(Ymet{i},0.001),sz{i}));
        end

        % stores the strings into the final array
        YmetT{i} = YmetNw;
        YmetT{i}(isN) = '';
    end
end