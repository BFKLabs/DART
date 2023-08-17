% --- retrieves the analysis function documentation file (if it exists)
function fDocD = getAnalysisFuncDoc(fcnName)

% initialisations
fDocD = [];
docDirP = getProgFileName('Documentation','Analysis','Doc');

% determines if the documentation file exists
if exist(docDirP,'dir')
    fDocD0 = fullfile(docDirP,fcnName); 
    fDoc = fullfile(fDocD0,[fcnName,'.ddoc']);
    
    if exist(fDocD0,'dir') && exist(fDoc,'file')    
        fDocD = fDocD0;
    end
end