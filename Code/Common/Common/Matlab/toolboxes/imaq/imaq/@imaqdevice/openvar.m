function openvar(name, obj) %#ok<INUSL>
%OPENVAR Open an image acquisition object for graphical editing.
%
%    OPENVAR(NAME, OBJ) open an image acquisition object, OBJ, for graphical 
%    editing. NAME is the MATLAB variable name of OBJ.
%
%    See also IMAQDEVICE/SET, IMAQDEVICE/GET, IMAQDEVICE/PROPINFO,
%             IMAQHELP.
%

%    CP 04-17-02
%    Copyright 2001-2010 The MathWorks, Inc.

titleMessage = message('imaq:openvar:invalidObjTitle');
if ~isa(obj, 'imaqdevice')
    errordlg(getString(message('imaq:openvar:wrongType')), titleMessage.getString(), 'modal');
    return;
end

if ~isvalid(obj)
    errordlg(getString(message('imaq:openvar:invalidObj')), titleMessage.getString(), 'modal');
    return;
end

try
    inspect(obj);
catch exception
    newException = imaqgate('privateFixError', exception);
    errordlg(newException.message, getString(message('imaq:openvar:inspectionErrorTitle')), 'modal');
end
