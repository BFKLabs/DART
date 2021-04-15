% --- checks an image name so as to remove an special characters
function imgName = checkImageName(imgName)

% initialisations
[eStr,imgName0] = deal(num2cell('/\:?"<>|@$#!^'),imgName);

% removes any of the special characters from the filename string
for i = 1:length(eStr)
    ii = strfind(imgName,eStr{i});
    if (~isempty(ii))
        jj = true(length(imgName),1); jj(ii) = false;        
        imgName = imgName(jj);
    end
end

% outputs a warning if the filename has changed 
if (~strcmp(imgName,imgName0))
    wStr = {'Warning! File name has been altered to remove special characters:';...
            '';sprintf(' * Old Name = "%s"',imgName0);sprintf(' * New Name = "%s"',imgName)};
    waitfor(warndlg(wStr,'Special Characters Detected','modal'));
end
