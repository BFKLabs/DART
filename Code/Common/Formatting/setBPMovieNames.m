% --- sets the batch-processing movie names given the video/information
%     data structs given in VV/II respectively --- %
function mName = setBPMovieNames(mDir,VV,II)

% determines the 
fExtn = getMovieFileExtn(VV.vCompress);
fFile = dir(fullfile(mDir,['*',fExtn]));
ind0 = str2double(fFile(1).name((...
            length(II.BaseName)+4):(strfind(fFile(1).name,'.')-1)));

% sets the file ID strings
nwID = cellfun(@(x)(sprintf('%s%i',repmat('0',1,3-floor(log10(x))),x)),...
                num2cell(ind0:VV.nCount)','un',0);
            
% combines the basefile name, ID string and file extension into a combined 
% string (contained within a cell array)          
mName = cellfun(@(x)(fullfile(mDir,sprintf('%s - %s%s',II.BaseName,x,...
                fExtn))),nwID,'un',0);