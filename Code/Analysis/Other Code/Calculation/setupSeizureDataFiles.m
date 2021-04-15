% --- sets up and outputs the likely seizure event data files 
function setupSeizureDataFiles(svm)

% sets the default input arguments
if (nargin == 0); svm = []; end

% attempts to load a valid solution file from the analysis GUI
[snTot,dDir,eStr,tStr] = loadExptSolnFile();
if (~isempty(eStr))
    % if there is an error, then exit the function
    waitfor(errordlg(eStr,tStr,'modal'))
    return    
end

% creates a waitbar figure
wStr = {'Sub-Region Analysis','Fly Analysis','Seizure Metric Calculations'};
h = ProgBar(wStr,'Detecting Seizure Events');

% determines the likely seizure events for each file
[indF,Pmet] = detLikelySeizureEvents(snTot,h);
if isempty(indF)
    % if the user cancelled, then exit the function
    return
end

% collapses the waitbar figure
h.collapseProgBar(2); 
pause(0.05);

% outputs the seizure event data/metrics to file
writeSeizureDataFile(snTot,dDir,indF,Pmet,svm,h)

% --- attempts to load a valid 2D solution file for analysis
function [snTot,dDir,eStr,tStr] = loadExptSolnFile()

% initialisations
[snTot,eStr,tStr] = deal([]);

% retrieves the analysis GUI object handle
h = findall(0,'type','figure','tag','figFlyAnalysis');
if (isempty(h))
    % if the GUI is not open, then output an error and exit    
    eStr = 'DART Analysis GUI is not open. Open the GUI and retry.';
    tStr = 'Analysis GUI Not Open';
    return
end

% retrieves the solution file from the analysis GUI
snTot = getappdata(h,'snTot');
if (isempty(snTot))
    % if none are open, then output an error and exit
    eStr = 'No data is loaded in Analysis GUI. Open a file and retry.';
    tStr = 'Solution File Not Open'; 
    return
else
    % sets the data output file directory
    iProg = getappdata(h,'iProg');
    dDir = iProg.OutData;
end

% checks the solution files is feasible
if ~isfield(snTot,'iMov')
    eStr = 'Obsolete solution file. Open a suitable 2D solution file and retry.';
    tStr = 'Obsolete Solution File Type';
    return
elseif ~is2DCheck(snTot.iMov)
    eStr = 'Experiment must be 2D. Open a suitable 2D solution file and retry.';
    tStr = 'Incorrect Experiment Type';
    return    
end

% --- writes the likely seizure event metrics to file
function writeSeizureDataFile(snTot,dDir,indF,Pmet,svm,h)

% array indexing
[nFile,nFly,nApp] = size(Pmet);

% sets the output file name
xlsName = sprintf('Seizure Metrics (%s).xlsx',snTot.iExpt.Info.Title);
xlsFile = fullfile(dDir,xlsName);

% sets the header strings
hStr = {'Predict','Type','Start','Finish','Pd','Pp','dD(mx)',...
        'dP(mx)','D(mx)','D(ratio)','dP(mu)','dP(sum)'};   

%
for iFile = 1:nFile   
    % updates the waitbar figure
    wStrNw = sprintf('Writing Worksheet Data (%i of %i)',iFile,nFile);
    if h.Update(1,wStrNw,iFile/(nFile+1))
        % if the user cancelled, then exit the function
        return
        
    else
        % memory allocation
        A = cell(nFly,nApp);            
    end       
    
    % sets the data arrays for each of the flies
    for iApp = 1:nApp
        for iFly = 1:nFly
            % determines the number of events
            nEvent = size(Pmet{iFile,iFly,iApp},1);
            A{iFly,iApp} = cell(nEvent+3,length(hStr)+1);
            
            % sets the sub-region string
            if iFly == 1
                A{iFly,iApp}{1,1} = sprintf('Sub-Region %i',iApp);
            end
            
            % sets the fly index string
            A{iFly,iApp}{2,1} = sprintf('Fly #%i',iFly);
            A{iFly,iApp}(3,1:end-1) = hStr;
            
            % sets the metric values
            Ynw = [indF{iFile,iFly,iApp},Pmet{iFile,iFly,iApp}];
            A{iFly,iApp}(4:end,3:end-1) = num2cell(Ynw);
            
            % sets the prediction values (if the classifier is provided)
            if ~isempty(svm) && ~isempty(Pmet{iFile,iFly,iApp})
                Pnw = predict(svm,Pmet{iFile,iFly,iApp}); 
                A{iFly,iApp}(4:end,1) = num2cell(Pnw);
            end
        end
    end
    
    % combines all the data into a single array
    DataNw = A{1,1};
    for i = 2:numel(A)
        DataNw = combineCellArrays(DataNw,A{i},1);
    end
    
    % removes any NaN values
    ii = find(cellfun(@isnumeric,DataNw) & ~cellfun(@isempty,DataNw));
    DataNw(ii(cellfun(@isnan,DataNw(ii)))) = {[]};
    
    % writes the data to file
    xlswrite(xlsFile,DataNw,iFile);
end

% updates and closes the waitbar figure
if ~h.Update(1,'Data Output Complete',1)
    h.closeProgBar();
end