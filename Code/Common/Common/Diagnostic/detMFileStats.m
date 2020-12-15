% --- determines the stats for each of the 
function fStats = detMFileStats(mFile)

% opens the m-file and reads all the lines
fid = fopen(mFile);

% reads the text from the file and splits them up by line
mText = splitStringRegExp(fread(fid, '*char')','\n');
isComment = false(length(mText),1);

% determines the white, comment and code lines within the text
nChar = cellfun(@(x)(length(regexp(x,'[\S]'))),mText);
isWhite = nChar == 0;
isComment(~isWhite) = cellfun(@(x)(...
        strcmp(x(find(~strcmp(x,' '),1,'first')),'%')),mText(~isWhite));
isCode = ~(isWhite | isComment);

% sets the files stats
fStats = struct('nLine',length(mText),'nComment',sum(isComment),...
                'nWhite',sum(isWhite),'nCode',sum(isCode),...
                'mFile',mFile,'nChar',sum(nChar(isCode)));