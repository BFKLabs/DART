% --- retrieves the stimuli response values
function [Ynw,Ysem,Ymx] = getSRValues(p,pD,pP,pStr)

% initialisations
[Ysem,Ymx] = deal([],NaN);    

% retrieves the plot values
if (strcmp(pStr(1),'k'))
    Ynw = [eval(sprintf('p.%s_mn',pStr));...         
           eval(sprintf('p.%s_sem',pStr))];    
else
    Ynw = eval(sprintf('p.%s',pStr));         
end         

% converts any plot value cell arrays into a numerical array
if (iscell(Ynw)); Ynw = cell2mat(Ynw); end

% sets the SEM signal 
switch (pStr)
    case ('gof') % case is the fit statistics
        % initialisations
        [Ytmp,Ysem,Ymx] = deal(Ynw,[],1);

        % sets plot data based on the fit type
        if (strcmp(pP.gofType,'R-Squared'))
            % case is using R-Squared values
            Ynw = max(0,field2cell(Ytmp,'rsquare',1));
        else
            % case is using adjusted R-Squared values
            Ynw = max(0,field2cell(Ytmp,'adjrsquare',1));
        end
    case {'Yamp_mn','YampR_mn'} % case is the raw/fitted amplitudes
        Ynw = abs(Ynw);
        if (pP.plotRaw)
            % sets the raw amplitude SEM
            Ysem = p.YampR_sem;
            
            % sets the overall y-axis limits
            Ymx = max(cellfun(@(x,y)(max(x(:)+y(:))),...
                      cell2cell(field2cell(pD,'YampR_mn')),...
                      cell2cell(field2cell(pD,'YampR_sem'))));            
        else
            % sets the fitted amplitude SEM
            Ysem = p.Yamp_sem; 
            
            % sets the overall y-axis limits
            Ymx = max(cellfun(@(x,y)(max(x(:)+y(:))),...
                      cell2cell(field2cell(pD,'Yamp_mn')),...
                      cell2cell(field2cell(pD,'Yamp_sem'))));            
        end
    case ('Y0_mn') % case is the pre-stimuli speed
        Ysem = p.Y0_sem;
    case ('Tmax') % case is the max response time
        Ymx = detOverallLimit(cellfun(@(x)(...
                detOverallLimit(x)),field2cell(pD,pStr)));
    otherwise % case is the time constants   
        N = size(Ynw,1)/2;        
        [Ysem,Ynw] = deal(Ynw((N+1):end,:),Ynw(1:N,:));
        Ysem(isnan(Ysem)) = 0;

        % sets the over y-axis limit values
        if (all(isnan(Ynw+Ysem)))
            Ymx = detOverallLimit(Ynw);
        else
            Ymx = detOverallLimit(Ynw+Ysem);
        end
end

% converts any SEM cell arrays into a numerical array
if (iscell(Ysem)); Ysem = cell2mat(Ysem); end