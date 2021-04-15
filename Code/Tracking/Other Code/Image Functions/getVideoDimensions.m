% --- determines the video dimensions
function szImg = getVideoDimensions(fDir,fName)

% sets the full movie file name
szImg = NaN(1,2);
fStr = fullfile(fDir,fName);

% attempts to determine if the movie file is valid
[~,~,fExtn] = fileparts(fStr);
if exist(fStr,'file')
    try
        % uses the later version of the function 
        switch fExtn
            case {'.mj2', '.mov'}
                mObj = VideoReader(fStr);
                szImg = [mObj.Height mObj.Width];
                
            case '.mkv'
                mObj = ffmsReader();
                [~,~] = mObj.open(fStr,0);
                szImg = size(mObj.getFrame(1));
                
            otherwise
                [V,~] = mmread(fStr,inf,[],false,true,'');
                szImg = [V.height V.width];
        end        
    end
end