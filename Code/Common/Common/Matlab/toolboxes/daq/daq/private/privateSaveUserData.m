function out = privateSaveUserData(input, alreadySavedFlag)
%PRIVATESAVEUSERDATA Saves the UserData when it is a cell or structure.
%
%    PRIVATESAVEUSERDATA(INPUT, ALREADYSAVEDFLAG) recursively saves any 
%    object contained in INPUT if the ALREADYSAVEDFLAG is false, otherwise
%    is recursively assures that the udd handle of any DAQ object is
%    cleared to avoid unwanted saves of the underlying UDD object.
%

%    This is a helper function for private\privatesavecell which is used
%    by saveobj.
%
%    DTL 9-01-2004
%    Copyright 1998-2004 The MathWorks, Inc.
%    $Revision: 1.7.2.5 $  $Date: 2004/12/01 19:48:02 $

% Initialize output variable.
%out = [];

% For cell arrays...
if ( iscell(input) )
    % Recursively convert each cell element
    [m,n] = size(input);
    out = cell(m,n);
    for i=1:m
       for j=1:n
          out{i,j} = privateSaveUserData( input{i,j}, alreadySavedFlag );
       end
    end
% For structures...
elseif ( isstruct(input) )
    % Recursively convert each field value.
    fields = fieldnames(input);
    for f = 1:length(fields)
        fieldvalue = privateSaveUserData( input.(fields{f}), alreadySavedFlag );
        out.(fields{f}) = fieldvalue;
    end
else
    out = localSaveUserData(input, alreadySavedFlag );
end

% Helper function that converts scalar objects or arrays of objects. 
function out = localSaveUserData(input, alreadySavedFlag)


% Saving for the first time.
if ( ~alreadySavedFlag )
    try
        % If a daqdevice, do an internal save.
        if isa(input, 'daqdevice')
            out = helpersaveobj(input);
        % If a daqchild, another object, or anything else, do an external save.
        else
            out = saveobj(input);
        end
    catch
        % External save failed, just return input.
        out = input;
    end 
% Already saved. Clear any uddobject field to avoid unwanted UDD saves.
else
    if isa(input,'daqdevice') || isa(input, 'daqchild')
        out = daqsetfield( input, 'uddobject', 0 );
    else
        out = input;
    end
end


    
