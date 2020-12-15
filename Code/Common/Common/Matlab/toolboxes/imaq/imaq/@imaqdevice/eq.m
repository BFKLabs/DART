function iseq=eq(arg1, arg2)
%EQ Overload of == for image acquisition objects.
%
%    See also IMAQDEVICE/NE, IMAQDEVICE/ISEQUAL.
%

%    CP 9-02-02
%    Copyright 2001-2010 The MathWorks, Inc.

% Error appropriately if one of the input arguments is empty.
if isempty(arg1)
    if (length(arg2) == 1)
        iseq = [];
    else
        error(message('imaq:eq:dimagree'));
    end
    return;
elseif isempty(arg2)
    if (length(arg1) == 1)
        iseq = [];
    else
        error(message('imaq:eq:dimagree'));
    end
    return;
end

% Determine if both objects are image acquisition objects.
try   
    
    % Make sure that the imaqdevice object is always arg1.
    if ~isa(arg1, 'imaqdevice')
        [arg1 arg2] = deal(arg2, arg1);
    end
    
    % Now we know that arg1 is imaqdevice object.  If arg2 is not an
    % imaqdevice object, then there is no way that the objects are equal.
    if ~isa(arg2, 'imaqdevice')
        iseq = localGetLogicalZeros(arg1, arg2);
        return;
    end
    
    % Initialize variables.
    uddarg1 = imaqgate('privateGetField', arg1, 'uddobject');
    uddarg2 = imaqgate('privateGetField', arg2, 'uddobject');
    
    % Error if both the objects have a length greater than 1 and have
    % different sizes.
    sizeOfArg1 = size(uddarg1); 
    sizeOfArg2 = size(uddarg2); 
    
    if (numel(uddarg1)~=1) && (numel(uddarg2)~=1)
        if ~(all(sizeOfArg1 == sizeOfArg2)) 
            error(message('imaq:eq:dimagree'));
        end
    end
    
    iseq = (uddarg1 == uddarg2);
catch exception
    % Rethrow error from above.
    if strcmp(exception.identifier, 'imaq:eq:dimagree')
        throw(exception);
    end
    
    % One of the object's is not our object and therefore unequal.
    % Error if both the objects have a length greater than 1 and have
    % different sizes.    
    if (numel(arg1)~=1 && numel(arg2)~=1)
        if (size(arg1,1)~=size(arg2,1) || size(arg1,2)~=size(arg2,2))
            error(message('imaq:eq:dimagree'));
        end
    end
    
    iseq = localGetLogicalZeros(arg1, arg2);
end

iseq = logical(iseq);

function iseq = localGetLogicalZeros(arg1, arg2)
    if length(arg1) ~= 1
        iseq = false(1, length(arg1));
    else
        iseq = false(1, length(arg2));
    end
