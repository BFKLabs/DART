function [iGrpPhF,dT] = getPhaseEndIndices(Ttot,iFrmPh,tFrmF)

% memory allocation and initialisations
nGrp = length(iFrmPh);
dT = cell(nGrp,3);
iGrpPhF = cell(nGrp,3);

% sets the start/end times for each phase
TtotPh = cellfun(@(x)(reshape(Ttot(x),size(x))),iFrmPh,'un',0);

% sets the start/end indices of each phase
for i = 1:size(iFrmPh,1)        
    % sets the indices at the start of the phase
    iGrpPhF{i,1} = cellfun(@(x)(find((Ttot>=x(1)) & ...
                    (Ttot<=(x(1)+tFrmF)))),num2cell(TtotPh{i},2),'un',0);
        
    % sets the indices at the start of the phase
    iGrpPhF{i,2} = cellfun(@(x)(find((Ttot<=x(2)) & ...
                    (Ttot>=(x(2)-tFrmF)))),num2cell(TtotPh{i},2),'un',0);
    
    % sets the indices for the entire phase
    iGrpPhF{i,3} = cellfun(@(x)(find((Ttot>=x(1)) & ...
                    (Ttot<=x(2)))),num2cell(TtotPh{i},2),'un',0);
    
    % calculates the duration of each phase
    for j = 1:size(dT,2)
        dT{i,j} = cellfun(@(x)(diff(Ttot(x([1,end])))),iGrpPhF{i,j});
    end
end