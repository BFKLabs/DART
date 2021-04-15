% --- outputs a solution file through the batch processing algorithm --- %
function iData = outputBatchSolnFile(...
                            bData,sFileNw,outDir,iData,iMov,pData,iFile,h)

% otherwise, retrieve the solution file information struct and set
% the selected file directory name
a = 1;
save(sFileNw,'a')
iData.sfData = dir(sFileNw);
iData.sfData.dir = outDir;        

% if the experiment data struct is not set, then retrieve from summary file
if ~isfield(iData,'iExpt')
    aa = load(fullfile(outDir,'Summary.mat'));
    iData.iExpt = aa.iExpt;
end

% outputs the final solution file to disk
if nargin == 8
    % updates the waitbar figure and saves the .soln file
    h.Update(5,'Saving Solution File...',1);    
    saveSolutionFile(sFileNw,iData,iMov,pData)

    % outputs the partial solution summary data file (if requested)
    if (isfield(bData,'sfData'))
        if (bData.sfData.isOut)
            % retrieves the experiment data struct
            outputSolnSummaryCSV(bData,pData,iMov,iFile)
        end
    end    
    
    % updates the waitbar figure again
    h.Update(5,'Solution File Save Complete!',1);      
else
    % outputs the solution file without the waitbar figure
    saveSolutionFile(sFileNw,iData,iMov,pData)
end
