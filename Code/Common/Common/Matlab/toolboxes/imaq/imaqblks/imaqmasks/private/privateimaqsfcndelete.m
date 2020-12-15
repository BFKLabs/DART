function privateimaqsfcndelete(uddObj, uniqueObjName)
%PRIVATEIMAQSFCNDELETE Deletes the Image Acquisition Toolbox object.
%
%    PRIVATEIMAQSFCNDELETE(UDDOBJ, UNIQUEOBJNAME) finds the image
%    acquisition object pointed by UDDOBJ, and deletes it.
%    
%    The function does not delete the object if the UserData field on the Image
%    Acquisition Object matches the object name, UNIQUEOBJNAME. 
%
%    SS 10-28-11
%    Copyright 2011 The MathWorks, Inc.

% Find the image acquisition object.
imaqobj = imaqfind(imaqfind, 'UserData', uniqueObjName);
if ~isempty(imaqobj) % Object found
    % Do nothing. The object has been created by imaq.VideoDevice system
    % Object. 
    return;
end

% Find the image acquisition object.
imaqobj = imaqgate('privateUDDToMATLAB', uddObj);
% Delete the image acquisition object.
delete(imaqobj);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%