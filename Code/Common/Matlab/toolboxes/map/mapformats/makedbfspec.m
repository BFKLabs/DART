function dbfspec = makedbfspec(S)
%MAKEDBFSPEC DBF specification structure
%  
%   DBFSPEC = MAKEDBFSPEC(S) analyzes S and constructs a DBF specification
%   suitable for use with SHAPEWRITE.  S is either a geopoint vector, a
%   geoshape vector, or a geostruct (with 'Lat' and 'Lon' coordinate
%   fields) or a mappoint vector, mapshape vector, or a mapstruct (with 'X'
%   and 'Y fields).  You can modify DBFSPEC, then pass it to SHAPEWRITE to
%   exert control over which attribute fields are written to the DBF
%   component of the shapefile, the field-widths, and the precision used
%   for numerical values.
%
%   DBFSPEC is a scalar MATLAB structure with two levels.  The top level
%   consists of a field for each attribute in S.  Each of these fields,
%   in turn, contains a scalar structure with a fixed set of four fields:
%
%   FieldName          The field name to be used within the DBF file.  This
%                      will be identical to the name of the corresponding
%                      attribute, but may modified prior to calling
%                      SHAPEWRITE.  This might be necessary, for example,
%                      because you want to use spaces your DBF field names,
%                      but the attribute fieldnames in S must be valid
%                      MATLAB variable names and cannot have spaces
%                      themselves.
%
%   FieldType          The field type to be used in the file, either 'N'
%                      (numeric) or 'C' (character).
%
%   FieldLength        The number of bytes that each instance of the field
%                      will occupy in the file.
%
%   FieldDecimalCount  The number of digits to the right of the decimal
%                      place that are kept in a numeric field. Zero for
%                      integer-valued fields and character fields. The
%                      default value for non-integer numeric fields is 6.
%
%   Example
%   -------
%   % Import a shapefile representing a small network of road segments,
%   % and construct a DBF specification.
%   s = shaperead('concord_roads')
%   dbfspec = makedbfspec(s)
%
%   % Modify the DBF spec to (a) eliminate the 'ADMIN_TYPE' attribute, (b)
%   % rename the 'STREETNAME' field to 'Street Name', and (c) reduce the
%   % number of decimal places used to store road lengths.
%   dbfspec = rmfield(dbfspec,'ADMIN_TYPE')
%   dbfspec.STREETNAME.FieldName = 'Street Name';
%   dbfspec.LENGTH.FieldDecimalCount = 1;
%
%   % Export the road network back to a modified shapefile.  (Actually,
%   % only the DBF component will be different.)
%   shapewrite(s, 'concord_roads_modified', 'DbfSpec', dbfspec)
%
%   % Verify the changes you made.  Notice the appearance of
%   % 'Street Name' in the field names reported by SHAPEINFO, the absence
%   %  of the 'ADMIN_TYPE' field, and the reduction in the precision of the
%   %  road lengths.
%   info = shapeinfo('concord_roads_modified')
%   {info.Attributes.Name}
%   r = shaperead('concord_roads_modified')
%   s(33).LENGTH
%   r(33).LENGTH
%
%   See also: SHAPEINFO, SHAPEWRITE.

% Copyright 2003-2013 The MathWorks, Inc.  

% Validate input.
types = {'struct','mappoint','geopoint','mapshape','geoshape'};
validateattributes(S, types, {'nonempty', 'vector'}, 'makedbfspec', 'S', 1)

% Convert S to a dynamic vector if it is a structure.
if isstruct(S)
    S = map.internal.struct2DynamicVector(S);
end

% Determine what types of fields to write for each attribute.
attributeNames = fieldnames(S);
nonAttributeNames = {...
    'Geometry', 'Metadata', 'X', 'Y', 'Latitude', 'Longitude'};
[~,fIndex] = setxor(attributeNames, nonAttributeNames);
attributeNames = attributeNames(sort(fIndex));

% Default to six digits to the right of the decimal point.
defaultDecimalPrecision = 6;

% Create a dbfspec structure. 
% In this version we support only types 'N' and 'C'.
for k = 1:numel(attributeNames)
    attributeName = attributeNames{k};
    v = S.(attributeName);
    
    % Typically v is a cell array. However, if S is a dynamic vector with
    % only one feature and the attribute value is a string, then v is a
    % string. In this case, convert v to a cell array for proper processing
    % by calculateMaxFieldLength.
    if ischar(v)
        v = {v};
    end
    dataClass = class(v);
    
    % Determine if attributeName is a dynamic vertex property.
    if length(v) ~= length(S)
        % Issue a warning for the dynamic vertex property, attributeName. 
        % Do not add it to the output structure.
        warning(message('map:validate:ignoringAttribute', attributeName))
        continue
    end
    
    switch(dataClass)       
        case 'double'               
            % Attributes must be real and finite.
            map.internal.assert(all(~isinf(v) & isreal(v)), ...
                'map:validate:attributeNotFiniteReal', attributeName)
                
            if all(v == 0)
                numRightOfDecimal = 0;
                fieldLength = 2;
            else
                numLeftOfDecimal = max(1, 1 + floor(log10(max(abs(v)))));
                if all(v == floor(v))
                    numRightOfDecimal = 0;
                    fieldLength = 1 + numLeftOfDecimal;
                else
                    numRightOfDecimal = defaultDecimalPrecision;
                    fieldLength = 1 + numLeftOfDecimal + 1 + numRightOfDecimal;
                end
            end
            
            fieldType = 'N';
            minNumericalFieldLength = 3;  % Large enough to hold 'NaN'
            fieldLength = max(fieldLength, minNumericalFieldLength);

        case 'cell'
            % Obtain the attribute values from the input array.            
            fieldType = 'C';
            numRightOfDecimal = 0;
                       
            % Calculate the required field length for the attribute.
            maxFieldLength = calculateMaxFieldLength(v);
            minCharFieldLength = 2;
            fieldLength = max(maxFieldLength, minCharFieldLength);
                       
        otherwise
            warning(message('map:validate:unsupportedDataClass', dataClass));
            continue
    end    
    
    dbfspec.(attributeName) = struct(...
        'FieldName', attributeName,...
        'FieldType', fieldType,...
        'FieldLength', fieldLength,...
        'FieldDecimalCount', numRightOfDecimal);
end

% Handle both:
%    (1) an input without any attributes and
%    (2) an input in which every attribute contains
%        an unsupported data class.
if ~exist('dbfspec','var')
    dbfspec = struct([]);
end

%--------------------------------------------------------------------------

function maxFieldLength = calculateMaxFieldLength(values)
% Calculate a safe upper bound on the number of bytes per field required to
% contain the characters in the cell array, VALUES.

% Convert cell to a char array. Dynamic vectors are validated to contain
% only string values in cell arrays.
 charValues = char(values);
            
% Determine a safe upper bound for the number of bytes per field required
% to contain the number of characters. For efficiency, use charValues to
% determine if the input, VALUES, is a cell array containing all ASCII
% characters. 
if isASCII(charValues)
    % charValues contains all ASCII characters. A safe upper bound is the
    % size of the rows.
    maxFieldLength = size(charValues, 2);
else
    % The array contains non-ASCII unicode characters. Calculate
    % maxFieldLength as the maximum number of bytes required to hold any
    % element in VALUES. For each element of the cell array, convert the
    % element to native representation and count the resultant number of
    % bytes. Set maxFieldLength as the maximum number of bytes of any
    % element in the cell array.
    numNativeBytesFcn = @(x)numel(unicode2native(x));
    numelCell = cellfun(numNativeBytesFcn, values, 'UniformOutput', false);
    maxFieldLength = max(cell2mat(numelCell));
end

%--------------------------------------------------------------------------

function tf = isASCII(c)
% Return true if the character array, C, contains all ASCII characters.

tf = isequal(char(uint8(c)), c);
