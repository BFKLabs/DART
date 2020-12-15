function [errMsg, uddobj] = privateimaqsfcncreate(constructor, videoFormat, uniqueObjName, varargin)
%PRIVATEIMAQSFCNCREATE Creates a Image Acquisition Toolbox object for the S-Function.
%
%    [ERR, OBJ] = PRIVATEIMAQSFCNCREATE(CONSTRUCTOR, VIDEOFORMAT, UNIQUEOBJNAME) finds 
%    an existing image acquisition object with the unique UserData String,
%    UNIQUEOBJNAME. Otherwise, it creates create an image acquisition object
%    using the object constructor, CONSTRUCTOR, and the format, 
%    VIDEOFORMAT, specified. 
%
%    [ERR, OBJ] = PRIVATEIMAQSFCNCREATE(..., P1, V1, P2, V2, ...) can be used to
%    specify additional property value pairs that OBJ needs to be
%    configured to.
%
%    If an image acquisition object is successfully created and configured,
%    the underlying UDD object is returned in OBJ with ERR set to ''.
%    Otherwise OBJ will be returned as [] and ERR will be set to the last
%    error message.

%    SS 10-28-06
%    Copyright 2006-2010 The MathWorks, Inc.

% Initialize the required variables.
errMsg = '';
uddobj = [];
imaqobj = [];

try 
    % Find the image acquisition object.
    if ~isempty(imaqfind)
        imaqobj = imaqfind(imaqfind, 'UserData', uniqueObjName);
    end
    objConstructor = strrep(constructor,')',[',''' videoFormat ''')']);
    if ~isempty(imaqobj) % Object found.
        imaqobj = imaqobj{1}; % Get the object from the cell array.
    else % No object found.
        % Create an image acquisition object.
        imaqobj = eval(objConstructor);
    end
        
    uddobj = imaqgate('privateGetField', imaqobj, 'uddobject');
    
    % Show an unique tag. 
    set(uddobj, 'Tag', objConstructor);
    
    % Set Frames per trigger to 1 and Timeout to Inf.
    set(imaqobj, 'FramesPerTrigger', 1, 'Timeout', Inf);

    % Set other PV pairs and trigger information. 
    if nargin>3
        % varargin -> 'VideoSource', <videoSource>
        %             'TriggerRepeat', <triggerRepeat>
        %             'ROIPosition', <roiPosition>
        %             <triggerType>, <triggerCondition>, <triggerSource>.
        set(imaqobj, varargin{1:4});
        
        % Set source specific properties. 
        % g641714: This needs to be done before ROI and other engine
        % properties. MATROX has XScaleFactor and YScaleFactor properties
        % that when set affect the ROI setting. 
        imaqslgate('privatesetvideosourceprops', imaqobj, varargin{end});
        
        % Set the ROI Position
        roiPosition = str2num(varargin{6}); %#ok<ST2NM>
        set(imaqobj, 'ROIPosition', roiPosition([2 1 4 3]));
        
        % Set color space setting and bayer setting.
        set(imaqobj, varargin{7:10});
        
        % Set the trigger settings. 
        triggerconfig(imaqobj, varargin{11:end-1});
    end
catch exception
    if ( ~isempty(imaqobj) && isvalid(imaqobj) )
        delete(imaqobj);
    end
    % Assign error Message string to last error.
    errMsg = exception.message;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%