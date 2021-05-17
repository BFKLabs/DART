% --- check if the video resolution is valid for the compression type
function ok = checkVideoResolution(objIMAQ,vPara,varargin)

% retrieves the video resolution
vRes = getVideoResolution(objIMAQ);

% sets the video extension string based on the video data struct format
if isfield(vPara,'vExtn')
    % case is recording a test video
    vExtn = vPara.vExtn;
    
elseif isfield(vPara,'vCompress')
    % case is recording for an experiment
    switch vPara.vCompress
        case 'MPEG-4'
            % case is mp4 compression
            vExtn = '.mp4';
            
        case 'Archival'
            % case is archival compression
            vExtn = '.mj2';
            
        otherwise
            % case is avi compression
            vExtn = '.avi';
    end
    
else
    % invalid case
    ok = false;
    return
end

% determines if the video resolution is feasible based on video compression
switch vExtn
    case '.mp4' % case is .mp4 compression
        
        % sets the minimum/maximum video resolutions
        [vResMin,vResMax,eStr] = deal([64,64],[1920,1088],[]);

        % determines if the resolution meets the min/max requirements
        if any(vRes < vResMin)
            % the video resolution is too low
            eStr = sprintf(['The video recording resolution (%i x %i) ',...
                            'is less than the minimum .mp4 video ',...
                            'resolution (%i x %i).\nEither select ',...
                            'another video compression type or ',...
                            'increase the video recording resolution.'],...
                            vRes(1),vRes(2),vResMin(1),vResMin(2));
                        
        elseif any(vRes > vResMax)
            % the video resolution is too high
            eStr = sprintf(['The video recording resolution (%i x %i) ',...
                            'exceeds the maximum .mp4 video ',...
                            'resolution (%i x %i).\n\nEither select ',...
                            'another video compression type or ',...
                            'decrease the video recording resolution.'],...
                            vRes(1),vRes(2),vResMax(1),vResMax(2));
            
        end
        
        % determines if there is an error message
        ok = isempty(eStr);
        if ~ok && (nargin == 2)
            % if so, then output it to screen
            waitfor(errordlg(eStr,'Video Resolution Error','modal'))
        end
        
    otherwise % case is other video compression types
        
        % flag that the resolution is feasible
        ok = true;
        
%         % sets the minimum/maximum video resolutions
%         vResMax = [2000,1500];
%         if any(vRes > vResMax)
%             % the video resolution is too high, so prompt the user if they
%             % want to continue recording
%             tStr = 'High Video Resolution Warning';
%             wStr = sprintf(['The video recording resolution (%i x %i) ',...
%                         'is quite high which could potentially ',...
%                         'lead to memory leak errors.\n\nAre you sure ',...
%                         'you still wish to continue recording?'],...
%                         vRes(1),vRes(2));
%             ok = strcmp(questdlg(wStr,tStr,'Yes','No','Yes'),'Yes');
%             
%         else
%             % otherwise, flag that the video resolution is feasible
%             ok = true;
%         end        
        
end