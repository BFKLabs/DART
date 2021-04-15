% --- wrtites the data in the cell array to the xlsx file, fName, to the
%     worksheet, sName
function writeXLSXFile(fFile,Data,sName,iSheet,nSheet,h)

% retrieves the dimensions of the data array
nMax = 200;
[nRow,nCol] = size(Data);

% determines the number of row/column outputs
[nRS,nCS] = deal(ceil(nRow/nMax),ceil(nCol/nMax));
[iR,iC] = deal(roundP(linspace(0,nRow,nRS+1)),roundP(linspace(0,nCol,nCS+1)));
[wStr,nReg] = deal('Outputting Data File',nRS*nCS);

% loops through all of the row/column regions outputting the data to file
for i = 1:nRS
    % sets the new output data rows
    iRnw = (iR(i)+1):iR(i+1);
    
    % loops through each of the column regions
    for j = 1:nCS                 
        % updates the loadbar
        wStrNw = sprintf('%s (Sheet %i of %i - Sub-Region %i of %i)',...
                                    wStr,iSheet,nSheet,(i-1)*nCS+j,nReg);
        if (~updateLoadbar(h,wStrNw))    
            % if the user closed the loadbar, then exit the function
            delete(fFile)
            return
        end               
        
        % sets the new output data column
        iCnw = (iC(j)+1):iC(j+1);        
        
        % outputs the sub-region to file
        tic
        xlwrite(fFile,Data(iRnw,iCnw),sName,setSheetRange(iRnw,iCnw));
        sprintf('Region %i = %.f',i,toc)
    end
end

% --- sets the worksheet range string
function rngStr = setSheetRange(iR,iC)

%
cStr = getSheetColumnStrings(iC([1 end]));
cStr = cellfun(@(x)(x(uint8(x)~=32)),cStr,'un',0);
rngStr = sprintf('%s%i:%s%i',cStr{1},iR(1),cStr{2},iR(end));