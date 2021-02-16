% --- removes the partial solution data 
function rmvPartialSolnData(bData,iFile,iMov,sName)

% sets the solution directory string
sDir = fullfile(bData.SolnDir,bData.SolnDirName);
csvFile = dir(fullfile(sDir,'*.csv'));

% if working from the first file, then clear all csv files
if (iFile == 0) && (~isempty(csvFile))
    % if there are any csv files, then delete them
    fName = field2cell(csvFile,'name');
    cellfun(@(x)(delete(fullfile(sDir,x))),fName);
    
    % exits the function
    return
end

% removes the data based on the output type
switch (bData.sfData.Type)
    case ('Append') % case is appending the data to a single file        
        % loads the partial summary file data array
        sFile = fullfile(sDir,'Total Summary File.csv');  
        if (~exist(sFile,'file'))
            % if the solution file does not exist, then exit with an error
            if (iFile > 1)
                eStr = 'Error! Total summary file does not exist!';
                errordlg(eStr,'Summary File Missing','modal')
            end
            return
        else            
            % reads the total summary file
            Data0 = readCSVFile(sFile);
            [iFile0,Row0,Col0] = deal(str2double(Data0{2,3}),11,4);        
            
            % if the input file index is greater than the stored value,
            % then exit the function
            if (iFile >= iFile0); return; end
        end
            
        % retrieves the position data from the solution file
        A = load(fullfile(sDir,sName),'-mat'); pData = A.pData;  
        [nApp,nFly] = deal(pData.nApp,pData.nTube);
        
        % determines if the solution file has been completely segmented
        iApp0 = find(iMov.ok,1,'first');        
        if (~any(cellfun(@(x)(~isnan(x(end,1))),pData.fPos{iApp0})))
            % if not, then decrement the solution file index
            iFile = iFile - 1;
        end               
        
        % calculates the time difference of the last period
        T = pData.T(1:iMov.sRate:end);
        ii = find(T >= floor(T(end)/bData.sfData.tBin)*bData.sfData.tBin);        
        dT = diff(T(ii([1 end])));
        
        % sets the new output data array
        DataNw = Data0(1:(ceil(T(end)/bData.sfData.tBin)+Row0),:);
        DataNw{2,3} = num2str(iFile);
        DataNw{5,3} = num2str(roundP(convertTime(T(end),'sec','min'),0.01));
        
        % recalculates the speed for the last time bin
        iCol = cellfun(@(x)(Col0+(x*(nFly+1))+(1:nFly)),...
                                num2cell((1:nApp)-1),'un',0);
        for i = 1:length(iCol)            
            Vnw = cellfun(@(x)(sum(sqrt(sum(...
                            diff(x(ii,:),[],1).^2,2)))),pData.fPos{i})/dT;
            DataNw(end,iCol{i}) = cellfun(@num2str,num2cell(Vnw),'un',0);
        end
        
        % delete and rewrites the data file
        delete(sFile); writeCSVFile(sFile,DataNw,1);
                        
    case ('WriteNew') % case is outputting data for each file
        % determines all the single summary csv files
        fName = field2cell(csvFile,'name');
        isSum = cellfun(@(x)(strContains(x,'Summary File (')),fName);        
        fName = fName(isSum);
        
        % only delete files if they exist
        if (~isempty(fName))
            % determines the total number of files 
            nStr = regexp(fName{1},'\D','split');
            nStr = nStr(~cellfun(@isempty,nStr));
            nFile = str2double(nStr{2});
            
            % deletes the summary files whose index is > iFile
            for i = (iFile+1):nFile
                % attempts to find the next file to delete
                isNw = strcmp(fName,sprintf('Summary File (%i of %i).csv',i,nFile));            
                if (any(isNw))
                    % if the correct file is found, then delete it
                    delete(fullfile(sDir,fName{isNw}));
                end
            end
        end
        
end