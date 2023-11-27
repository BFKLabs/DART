% --- sets up the video compression popup box --- %
function setupVideoCompressionPopup(vObj,hPopup,varargin)

% retrieves the video profiles names/file extensions
vidProf = num2cell(VideoWriter.getProfiles());
pStr = cellfun(@(x)(x.Name),vidProf,'un',0)';
uStr = cellfun(@(x)(x.FileExtensions{1}),vidProf,'un',0)';

% sets the feasible compression types (ignore indexed AVI)
ii = ~cellfun(@(x)(strcmp(x,'Indexed AVI')),pStr);
if isa(vObj,'webcam')
    % removes the grayscale AVI compression type
    ii = ii & ~cellfun(@(x)(strcmp(x,'Grayscale AVI')),pStr);
    
elseif isa(vObj,'VideoReader')
    if vObj.BitsPerPixel == 24
        % removes the uncompressed AVI compression type
        ii = ii & ~cellfun(@(x)(strcmp(x,'Uncompressed AVI')),pStr);        
    else
        % removes the grayscale AVI compression type
        ii = ii & ~cellfun(@(x)(strcmp(x,'Grayscale AVI')),pStr);        
    end
else
    if vObj.NumberOfBands == 1
        % removes the uncompressed AVI compression type
        ii = ii & ~cellfun(@(x)(strcmp(x,'Uncompressed AVI')),pStr);
    else
        % removes the grayscale AVI compression type
        ii = ii & ~cellfun(@(x)(strcmp(x,'Grayscale AVI')),pStr);
    end
end

% removes the .mp4 video compression (if resolution is not feasible)
if ~checkVideoResolution(vObj,struct('vExtn','.mp4'),1)
    ii = ii & ~strcmp(uStr,'.mp4');
end

% removes the non-feasible compression types
[vidProf,pStr,uStr] = deal(vidProf(ii),pStr(ii),uStr(ii));

% sorts the list by extension
[~,jj] = sort(uStr);
[vidProf,pStr,uStr] = deal(vidProf(jj),pStr(jj),uStr(jj));

% updates the string to make it longer
setappdata(hPopup,'pStr',pStr)
if nargin == 3
    pStr = cellfun(@(x,y)(sprintf('%s (*%s)',x,y)),pStr,uStr,'un',0);
end

% sets the popup strings/user data
set(hPopup,'string',pStr,'UserData',vidProf,'Value',1)
