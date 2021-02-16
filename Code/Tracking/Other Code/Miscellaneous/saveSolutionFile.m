% --- function for output data to the solution file given by solnName --- %
function saveSolutionFile(solnName,iData,iMov,pData)

% retrieves the data fields required for output
[exP,stimP] = deal(iData.exP,iData.stimP);
[fData,Frm0] = deal(iData.fData,iData.Frm0);

% saves the solution file
save(solnName,'iMov','pData','exP','stimP','fData','Frm0');
