% --- resets the output data structs for the time constants to include the
%     mean and SEM metrics
function [plotD,pData] = setFittedParaOutput(plotD,pData,kInd)

% initialisations
[plotD,kStr,Str] = deal(num2cell(plotD),pData.oP(kInd,2),{'_mn','_sem'});

% resets the time constant fields to incorporate the mean/SEM values
for i = 1:length(plotD)
    for j = 1:length(kStr)
        % retrieves the data values
        Ynw = eval(sprintf('plotD{i}.%s;',kStr{j}));        
        a = zeros(size(Ynw,1),size(Ynw,3));
        
        % sets the variable strings
        pStr = cellfun(@(x)(...
                sprintf('plotD{i}.%s%s',kStr{j},x)),Str,'un',0);        
            
        % memory allocation
        if (i == 1)
            eval(sprintf('[%s,%s] = deal(a);',pStr{1},pStr{2}));            
        end
            
        % sets the data values for each day/night group        
        for k = 1:size(Ynw,3)
            eval(sprintf('%s(:,k) = Ynw(:,1,k);',pStr{1}));
            eval(sprintf('%s(:,k) = Ynw(:,2,k);',pStr{2}));
        end
        
        % transposes the arrays (if length of plot data struct is one)
        if (length(plotD) == 1)
            eval(sprintf('%s = %s'';',pStr{1},pStr{1}))
            eval(sprintf('%s = %s'';',pStr{2},pStr{2}))
        end
    end
end

% resets the time constant parameter fields
% oPnw = cellfun(@(x)(repmat(x,2,1)),num2cell(pData.oP(kInd,:),2),'un',0);
for i = reshape(kInd(end:-1:1),1,length(kInd))
    % makes a copy of the current output metric
    oPnw = repmat(pData.oP(i,:),3,1);
    
    % resets the fields for the mean metrics
    oPnw{2,1} = sprintf('%s (Mean)',oPnw{2,1});   
    oPnw{2,2} = sprintf('%s_mn',oPnw{2,2});    
    oPnw{2,3} = oPnw{2,3}{1};
    
    % resets the fields for the SEM metrics
    oPnw{3,1} = sprintf('%s (SEM)',oPnw{3,1});    
    oPnw{3,2} = sprintf('%s_sem',oPnw{3,2});
    oPnw{3,3} = oPnw{3,3}{1};
    
    % resets the indices of the variables (if they are affected by the
    % addition of the new variables into the array)
    oPend = pData.oP((i+1):end,:);
    kk = cellfun(@isnumeric,oPend(:,3));
    oPend(kk,3) = cellfun(@(x)(x+2*(x>i)),oPend(kk,3),'un',0);
    
    % places the new array into the overall data array
    pData.oP = [pData.oP(1:(i-1),:);oPnw;oPend];
end

% resets cell array back to a struct array
plotD = cell2mat(plotD);