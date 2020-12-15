% --- sets up the video compression popup box --- %
function setupVideoCompressionPopup(hPopup,varargin)

% retrieves the video profiles names/file extensions
vidProf = num2cell(VideoWriter.getProfiles());
pStr = cellfun(@(x)(x.Name),vidProf,'un',0)';
uStr = cellfun(@(x)(x.FileExtensions{1}),vidProf,'un',0)';

% removes the grayscale AVI (doesn't seem to work correctly?)
ii = ~cellfun(@(x)(strcmp(x,'Grayscale AVI')),pStr) & ...
     ~cellfun(@(x)(strcmp(x,'Indexed AVI')),pStr);
[vidProf,pStr,uStr] = deal(vidProf(ii),pStr(ii),uStr(ii));

% updates the string to make it longer
setappdata(hPopup,'pStr',pStr)
if (nargin == 2)
    pStr = cellfun(@(x,y)(sprintf('%s (*%s)',x,y)),pStr,uStr,'un',0);
end

% sets the popup strings/user data
set(hPopup,'string',pStr,'UserData',vidProf,'Value',1)
