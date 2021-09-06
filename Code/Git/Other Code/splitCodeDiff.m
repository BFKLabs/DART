% --- splits the difference code into separate blocks
function pDiff = splitCodeDiff(dStr)

% memory allocation
pDiff = struct('Altered',[],'Added',[],'Removed',[],'Moved',[]);

% if there is no difference, then exit the function
if isempty(dStr); return; end

% splits the string into separate lines
dStrSp = strsplit(dStr,'\n')';

% determines the start indices of the difference blocks
iDiff = find(cellfun(@(x)(startsWith(x,'diff --git')),dStrSp));
iBlk = num2cell([iDiff,[iDiff(2:end)-1;length(dStrSp)]],2);

% retrieves the details for each file that has a difference
for i = 1:length(iBlk)
    % retrieves the data block
    dBlk = dStrSp(iBlk{i}(1):iBlk{i}(2));
    dBlkSp = strsplit(dBlk{1});
    
    % splits the information field
    fileFull = getFileName(dBlkSp{end},1);
    [pStr,fName,fExtn] = fileparts(fileFull);

    % retrieves the new code block
    CBlk = getCodeBlocks(dBlk);
    
    % sets up the new data struct
    dataNw = struct('Path',pStr(2:end),'Name',[fName,fExtn],...
                    'CBlk',CBlk,'iBlk',iBlk{i});
    
    % adds the 
    if strContains(dBlk{2},'new file mode')
        % case is adding a new file   
        if ~isempty(pDiff.Added)        
            pDiff.Added(end+1) = dataNw;       
        else
            pDiff.Added = dataNw;
        end            
    elseif strContains(dBlk{2},'deleted file mode')
        % case is removing an existing file
        if ~isempty(pDiff.Removed)        
            pDiff.Removed(end+1) = dataNw;       
        else
            pDiff.Removed = dataNw;
        end        
    else
        % case is altering an existing file
        if ~isempty(pDiff.Altered)        
            pDiff.Altered(end+1) = dataNw;       
        else
            pDiff.Altered = dataNw;
        end               
    end        
end

% --- retrieves the code blocks
function CBlk = getCodeBlocks(dBlk)

% determines the lines where the code blocks start
iDiffC = find(cellfun(@(x)(startsWith(x,'@@')),dBlk));            
if isempty(iDiffC)
    % if there are none, then exit with an empty array
    CBlk = [];
    return;
end

% splits the codes into the separate blocks
iBlkC = num2cell([iDiffC,[iDiffC(2:end)-1;length(dBlk)]],2);
CBlk = repmat(struct('Code',[],'iLine',[],'Type',[]),length(iBlkC),1);

%
for j = 1:length(iBlkC)
    % retrieves the new code block
    cBlkNw = dBlk(iBlkC{j}(1):iBlkC{j}(2));
    while 1            
        if isempty(cBlkNw{end}) || ...
                    strcmp(cBlkNw{end},'\ No newline at end of file')
            cBlkNw = cBlkNw(1:end-1); 
        else
            break
        end
    end

    % sets the new code block into the data struct
    CBlk(j).Code = cellfun(@(x)(x(2:end)),cBlkNw(2:end),'un',0);            
    CBlk(j).iLine = cell(length(CBlk(j).Code),2);  
    CBlk(j).Type = zeros(length(CBlk(j).Code),1);  

    % determines the insertion/deletion parameters
    cInfo = strsplit(cBlkNw{1});
    iLine = cell2mat(cellfun(@(y)(cellfun(@(x)(abs(...
            str2double(x))),strsplit(y,','))),cInfo(2:3)','un',0));
    ind = iLine(:,1)';    

    for k = 1:length(CBlk(j).Code)                             
        if strcmp(cBlkNw{k+1}(1),'+')
            [CBlk(j).Type(k),cNw] = deal(2,num2str(ind(1)));
            CBlk(j).iLine(k,:) = {cNw,repmat('*',1,length(cNw))};
            ind(1) = ind(1) + 1;
        elseif strcmp(cBlkNw{k+1}(1),'-')
            [CBlk(j).Type(k),cNw] = deal(1,num2str(ind(end)));
            CBlk(j).iLine(k,:) = {repmat('*',1,length(cNw)),cNw};
            ind(end) = ind(end) + 1;
        else
            CBlk(j).iLine(k,:) = arrayfun(@(x)(num2str(x)),ind,'un',0);
            ind = ind + 1;
        end
    end
end