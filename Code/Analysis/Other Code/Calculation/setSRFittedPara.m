% --- 
function plotD = setSRFittedPara(plotD,p,tBefore,nGrp)

%
if (iscell(plotD.Y_fit))
    nSig = length(plotD.Y_fit);
else
    nSig = 1;
end

% memory allocation for signal/fitted parameter metrics
b = repmat({NaN(1,nGrp)},nSig,1);
[plotD.Tmax,plotD.Yamp_mn,plotD.YampR_mn] = deal(b);
[plotD.kA_mn,plotD.kI1_mn,plotD.kI2_mn] = deal(b);
[plotD.kA_sem,plotD.kI1_sem,plotD.kI2_sem] = deal(b);
[plotD.Yamp_sem,plotD.YampR_sem] = deal(b);

% sets the signal fitted parameters (for each day/time group)
for j = 1:length(b)
    for k = 1:nGrp
        % sets the main metrics
        plotD.Tmax{j}(k) = p{j}(k).Tmax;                  
        plotD.Yamp_mn{j}(k) = p{j}(k).yMax;

        % sets the mean raw amplitude
        if (~isempty(p{j}(k).yMaxR))
            plotD.YampR_mn{j}(k) = p{j}(k).yMaxR; 
        end

        % sets the time constant values
        plotD.kA_mn{j}(k) = p{j}(k).kA(1);
        plotD.kA_sem{j}(k) = p{j}(k).kA(2);                
        plotD.kI1_mn{j}(k) = p{j}(k).kI1(1);
        plotD.kI1_sem{j}(k) = p{j}(k).kI1(2);                
        plotD.kI2_mn{j}(k) = p{j}(k).kI2(1);                        
        plotD.kI2_sem{j}(k) = p{j}(k).kI2(2);                        
    end
end

% calculates the mean pre-stimuli SEM signal
xiT = 1:tBefore;
if ~iscell(plotD.Y_sem); plotD.Y_sem = num2cell(plotD.Y_sem,1); end
plotD.Y0_sem = cellfun(@(x)(mean(x(xiT,:),1,'omitnan')),plotD.Y_sem,'un',0); 

% sets the fitted amplitude error values
for k = 1:length(b)
    Yamp_sem = cellfun(@(x,y,z)(y(x==z)),...
            num2cell(plotD.Y_fit{k},1),num2cell(...
            plotD.Y_sem{k},1),num2cell(plotD.Yamp_mn{k}),'un',0);
    for j = 1:length(Yamp_sem)
        if (length(Yamp_sem{j}) == 1)
            plotD.Yamp_sem{k}(j) = Yamp_sem{j};
        end
    end

    % sets the raw amplitude error values
    YampR_sem = cellfun(@(x,y,z)(y(x==z)),...
            num2cell(plotD.Y_rel{k},1),num2cell(...
            plotD.Y_sem{k},1),num2cell(plotD.YampR_mn{k}),'un',0);                
    for j = 1:length(YampR_sem)
        if (length(YampR_sem{j}) == 1)
            plotD.YampR_sem{k}(j) = YampR_sem{j};
        end
    end            
end
