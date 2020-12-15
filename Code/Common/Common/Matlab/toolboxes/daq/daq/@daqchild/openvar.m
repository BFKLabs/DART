function openvar(name, obj) %#ok<INUSL>
%OPENVAR Open a data acquisition object for graphical editing.
%
%    OPENVAR(NAME, OBJ) open a data acquisition object, OBJ, for graphical 
%    editing. NAME is the MATLAB variable name of OBJ.
%
%    See also DAQDEVICE/SET, DAQDEVICE/GET, DAQDEVICE/PROPINFO,
%             DAQHELP.
%

%    DTL 10-1-2004
%    Copyright 2004-2008 The MathWorks, Inc.
%    $Revision: 1.1.6.2 $  $Date: 2008/06/16 16:35:03 $

if ~isa(obj, 'daqchild')
    errordlg('OBJ must be an data acquisition object.', 'Invalid object', 'modal');
    return;
end

if ~isvalid(obj)
    errordlg('The data acquisition object is invalid.', 'Invalid object', 'modal');
    return;
end

try
    inspect(obj);
catch e
    errordlg(e.message, 'Inspection error', 'modal');
end
