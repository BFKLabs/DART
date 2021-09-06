% --- splits the status difference into its components
function pDiff = splitDiffStatus(dStr,tStr,isCommit)

% memory allocation
pDiff = struct();
for i = 1:length(tStr)
    pDiff = setStructField(pDiff,tStr{i},[]);
end

% if there is no difference, then exit the function
if isempty(dStr); return; end       

% splits the string into separate lines
X = strsplit(strrep(dStr,'"',''),'\n')';
if isCommit
    dStrF = cellfun(@(x)({strip(x(1:2)),x(4:end)}),X,'un',0);
else
    dStrF = cellfun(@(x)(strsplit(x,'\t')),X,'un',0);
end

fDir = cellfun(@(x)(fileparts(x{2})),dStrF,'un',0);
fName = cellfun(@(x)(getFileName(x{2},1)),dStrF,'un',0);

for i = 1:length(dStrF)
    % sets the difference struct values
    pDiffNw = struct('Path',fDir{i},'Name',fName{i});

    % sets the struct fields
    switch dStrF{i}{1}
        case 'M'
            % case is the file was altered, added or deleted
            fStr = 'Altered';

        case {'A','??'}
            fStr = 'Added';

        case 'D'
            fStr = 'Removed';

        otherwise
            % case is the file was moved
            fStr = 'Moved';
    end

    % updates the difference struct
    if isempty(getStructField(pDiff,fStr))
        pDiff = setStructField(pDiff,fStr,pDiffNw);
    else
        eval(sprintf('pDiff.%s(end+1) = pDiffNw;',fStr));
    end
end