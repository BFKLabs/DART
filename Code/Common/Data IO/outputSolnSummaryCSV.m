% --- output the solution summary CSV files
function outputSolnSummaryCSV(bData,pData,iMov,iFile)

% if the summary file data struct is not provided, then create on
sfData = bData.sfData;

% sets the output solution file directory name
fPos = pData.fPos;
[nFile,nApp,nFly] = deal(length(bData.mName),sum(iMov.ok),length(fPos{1}));
solnDir = fullfile(bData.SolnDir,bData.SolnDirName);

% retrieves the file name and the previous data array (if appending)
switch (sfData.Type)
    case ('Append') % case is appending to the total summary file
        fName = fullfile(solnDir,'Total Summary File.csv');
        if (iFile > 1)               
            % more than file has been segemented
            if (~exist(fName,'file'))
                % file does not exist, so exit function
                return
            else
                % otherwise, retrieve the data from the file
                [Data0,addHeader] = deal(readCSVFile(fName),false);
            end
        else
            % otherwise, initialise the data arrays
            [Data0,addHeader] = deal([],true);
        end
    case ('WriteNew') % case is writing a new summary file each time  
        [Data0,addHeader] = deal([],true);
        fName = fullfile(solnDir,sprintf('Summary File (%i of %i).csv',iFile,nFile));
end

% retrieves the new summary data from the current solution data set
DataV = setupNewDataArray(sfData,pData,iMov,Data0,pData.T(1),addHeader);

% creates the final data array 
if addHeader
    % calculates the start/
    T0 = roundP(convertTime(pData.T(1),'sec','min'),0.01);
    Tf = roundP(convertTime(pData.T(end),'sec','min'),0.01);
    
    % adds the header text to the the data values
    DataH = {'Video Directory',NaN,bData.MovDir;
             'Current Video',NaN,iFile;
             'Video Count',NaN,nFile;
             'Start Time (min)',NaN,T0;
             'Final Time (min)',NaN,Tf;
             'Region Count',NaN,nApp;
             'Fly Count',NaN,nFly;
             'Bin Size (sec)',NaN,sfData.tBin;
             NaN,NaN,NaN};        
    Data = combineCellArrays(DataH,DataV,0);
else
    % combines the data from the previous data file
    Data0{2,3} = iFile;
    Data0{5,3} = roundP(convertTime(pData.T(end),'sec','min'),0.01);
    
    % appends the new/existing data arrays
    if (str2double(Data0{end,2}) == DataV{1,2})
        Data = combineCellArrays(Data0(1:end-1,:),DataV,0);
    else
        Data = combineCellArrays(Data0,DataV,0);
    end
end

% writes the CSV file
while (~writeCSVFile(fName,Data,1))
    eStr = 'Error! Unable to write CSV file while open. Close the file and press OK.';
    waitfor(errordlg(eStr,'CSV File Write Error','modal'))
end

%-------------------------------------------------------------------------%
%                             OTHER FUNCTIONS                             %
%-------------------------------------------------------------------------% 

% --- sets up the new summary data array 
function DataV = setupNewDataArray(sfData,pData,iMov,Data0,T0,addHeader)

% initialises the time vector and sets data sub-structs
[nFrm,ii] = deal(size(pData.fPos{1}{1},1),1:iMov.sRate:length(pData.T));
[T,fPos] = deal(pData.T(ii(1:nFrm)),pData.fPos(iMov.ok));

% interpolates any missing time values
jj = isnan(T);
T(jj) = interp1(find(~jj),T(~jj),find(jj),'linear');

% array dimensioning and memory allocation
[nFly,nApp] = deal(cellfun(@(x)(length(x)),fPos),sum(iMov.ok));
[indB,VB] = deal(detTimeBinIndices(T,sfData.tBin,1),cell(1,nApp));
D0 = cellfun(@(x)(zeros(1,x)),num2cell(nFly),'un',0);

% calculates the time for each bin region
dTB = num2cell(repmat(cellfun(@(x)(diff(T(x([1 end])))),indB),1,nApp),1); 
dTB = cellfun(@(x,y)(repmat(x,1,length(y))),dTB,...
                 reshape(num2cell(nFly),1,length(nFly)),'un',0);
             
% determines how to add the new data to the previous data (if it exists)
if (~isempty(Data0))
    % calculates the time difference 
    TT = [str2double(Data0{end-1,2}),str2double(Data0{end,2})];
    if (mod(sfData.tBin,60) == 0)
        % converts time from mins to seconds        
        [T0,dT] = deal(convertTime(T0,'sec','min'),sfData.tBin/60);
    else
        dT = sfData.tBin;
    end
    
    % if the start time is before the end of the previous row, then skip
    % the first time bin
    [T0Pr,Ts,j0] = deal((TT(end) + diff(TT)/2),str2double(Data0{5,3}),4);
    if (T0 < T0Pr)     
        % sets the initial time band distance and modifies the time for the
        % first time band 
        for i = 1:length(dTB)
            D0{i} = str2double(Data0(end,j0+(1:nFly(i))))*mod(Ts,1)*60;
            [dTB{i}(1),j0] = deal(dTB{i}(1) + mod(Ts,1)*60,j0+(nFly(i)+1));
        end
        
        % removes the last line of the previous data array
        T0Pr = T0Pr - dT;
    end
else
    if (sfData.tBin >= 0)
        T0Pr = floor(T(1)/60);
    else
        T0Pr = sfData.tBin*floor(T(1)/sfData.tBin);
    end
end

% calculates the distance travelled over each time bin
D = cellfun(@(xx)([zeros(1,size(xx,2));cell2mat(cellfun(@(x)(sum(...
                        diff(x,[],1).^2,2).^0.5),xx,'un',0))]),...
                        fPos','un',0);
for i = 1:nApp
    % calculates the distance travelled over the time bands (the first
    % row is compensated for the previous video distance)
    Dnw = cell2mat(cellfun(@(x)(nansum(D{i}(x,:),1)),...
                                            indB,'un',0));
    Dnw(1,:) = Dnw(1,:) + D0{i};
        
    % calculates the average speed over the time bin
    VB{i} = Dnw./repmat(dTB{i},1,getSRCount(iMov,i));
end

% sets up the time string
if (mod(sfData.tBin,60) == 0)
    % set time string as minutes
    [tMin,tt] = deal((sfData.tBin/60),'min');
    xi = (T0Pr:tMin:(floor(T(end)/(tMin*60))+1)*tMin)';        
    xiS = num2cell([xi(1:end-1),xi(2:end)],2);    
else
    % set time string as seconds
    tt = '(sec)';
    xi = (T0Pr:sfData.tBin:(floor(T(end)/sfData.tBin)+1)*sfData.tBin)';
    xiS = num2cell([xi(1:end-1),xi(2:end)],2);
end

% sets up the time/fly string and time halfway point
tStrH = {sprintf('Bin (%s)',tt),sprintf('Bin Mid-Point (%s)',tt)};
fStrH = cellfun(@(x)(sprintf('Fly #%i',x)),num2cell(1:nFly(1)),'un',0);
tStr = cellfun(@(x)(sprintf('="%i-%i"',x(1),x(2))),xiS,'un',0);

% sets the time component of the table
T = [tStr,num2cell(0.5*(xi(1:end-1)+xi(2:end)))];
if (addHeader)    
    % adds in the headers
    DataV = combineCellArrays(combineCellArrays({NaN},tStrH,0),T,0);
else
    % no headers added to the table
    DataV = T;
end

% sets the data cell array
[DataV,ind] = deal(combineCellArrays(DataV,{NaN}),find(iMov.ok));
for i = 1:nApp
    % sets the new data for the new apparatus
    if (addHeader)
        % adds in the headers
        B = combineCellArrays({sprintf(...
                    'Region #%i Avg Speed (mm/sec)',ind(i))},fStrH,0);
        C = combineCellArrays(B,num2cell(VB{i}),0);    
    else
        % no headers added to the table
        C = num2cell(VB{i});
    end

    % appends the data array to the total data array
    DataV = combineCellArrays(combineCellArrays(DataV,{NaN}),C);
end