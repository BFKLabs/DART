% --- determines the video file index from the file name
function iVid = getVideoFileIndex(vidName)

% retrieves the nummerical components from the video file name
numStr = regexp(vidName,'\d*','match');
if isempty(numStr)
    % if no match is made, then set the file index to the first video
    iVid = 1;
else
    % otherwise, determine which of the number strings contains the valid
    % file index (the 4-digit number)
    nLen = cellfun('length',numStr);
    isOK = nLen == 4;
    switch sum(isOK)
        case 0
            % case is there is no valid index string
            iVid = 1;
            
        case 1
            % case is there is only one valid index string
            iVid = str2double(numStr{isOK});
            
        otherwise
            % invalid video file name?
            iVid = str2double(numStr{find(isOK,1,'last')});
    end
end
