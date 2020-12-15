function [filename, S, options] = kmlparse(fcnName, type, varargin)
%KMLPARSE Parse input for KML functions
%
%   [filename, S, kml] = KMLPARSE(fcnName, type, varargin) parses varargin
%   input and returns validated and parsed output. See KMLWRITE for a
%   description of inputs for varargin.
%
%   Input Arguments
%   ----------------
%   fcnName          - Name of calling function for use in error messages
%
%   type             - Type of elements to parse. The type is either
%                      'line', 'point', or 'any'.
%
%   varargin         - Cell array of inputs to parse
%
%
%   Output Arguments
%   ----------------
%   filename         - String indicating name of KML file
%
%   S                - A geopoint or geoshape vector
% 
%   options          - Scalar structure containing parsed options
%
%   See also KMLWRITE, KMLWRITELINE, KMLWRITEPOINT

% Copyright 2012-2013 The MathWorks, Inc.

% Verify the filename.
filename = verifyFilename(varargin{1}, fcnName);
varargin(1) = [];

% Parse the input.
[dataArgs, options, userSupplied] = parseInput(type, varargin{:});

% Validate dataArgs.
S = dataArgs{1};
if numel(dataArgs) == 1 && (isstruct(S) || isobject(S))
    % Using (filename, S) syntax
    % Check the coordinates and altitude values of S.
    % Create a description table if requested
    [S, options] = checkFeatures(S, options, userSupplied);
      
elseif length(dataArgs) > 1
    % Using (filename, lat, lon) or (filename, lat, lon, alt) syntax
    % Validate the arrays and convert them to a dynamic vector or dynamic
    % shape object.
    [S, options] = arraysToDynamicVector(dataArgs, options, type);
    
else
    % Using (filename, address) syntax
    S = validateAddress(S, fcnName);
end

% Spec field is not needed anymore.
options = rmfield(options, 'Spec');

%--------------------------------------------------------------------------

function [dataArgs, options, userSupplied] = parseInput(type, varargin)
% Parse the data from varargin.

% Get the list of parameter names based on type.
parameterNames = getParameterNames(type);

% Verify the number of data arguments.
numDataArgs = verifyNumberOfDataArgs(parameterNames, varargin);

% Define dataArgs.
dataArgs = varargin(1:numDataArgs);

% Remove the data arguments from varargin to obtain the pvpairs.
varargin(1:numDataArgs) = [];

% Set the number of required elements for the options structure. If a
% single character address is specified, then the number of elements is 1;
% otherwise, the number of elements is equal to the numel of the first data
% argument.
numElements = numberOfFeatures(dataArgs{1}, type);

% Get the list of function handles to validate the input.
validateFcns = getValidators(type, numElements);

% Parse the parameter/value pair input. Use try/catch since the stack for
% when an error message is thrown is not very useful.
try
    [options, userSupplied, unmatched] = ...
        internal.map.parsepv(parameterNames, validateFcns, varargin{:});
    
    % Check if varargin contained unmatched parameters.
    if ~isempty(unmatched)
        permissibleParams =  ...
            [sprintf('''%s'', ', parameterNames{1:end-1}), ...
            'or ' '''' parameterNames{end} ''''];
        error(message('map:validate:invalidParameterName', ...
            unmatched{1}, permissibleParams));
    end
catch e
    throwAsCaller(e)
end

% Determine if an attribSpec is provided as a structure.
if userSupplied.Description && isstruct(options.Description{1})
    % An attribSpec is supplied in the options structure. Assign the Spec
    % field to it. Set the userSupplied.Description field to
    % false, since the Description will be created using the supplied
    % attribSpec. Modify the Description field to contain an empty space
    % for all elements.
    options.Spec = options.Description{1};
    userSupplied.Description = false;
    options.Description = {' '}; 
else
    % An attribSpec is not provided, set the Spec field to [].
    options(1).Spec = [];
end

if isa(options.Camera{1}, 'geopoint') && isa(options.LookAt{1}, 'geopoint')
    % Specifying both Camera and LookAt at the same time is not allowed.
    error(message('map:kml:expectedOneViewParameter'));
end

%--------------------------------------------------------------------------

function parameterNames =  getParameterNames(type)
% Return cell arrays of the parameter names and validation functions.

% parameterNames is a cell array of valid parameter names.
parameterNames = {'Description', 'Name', 'Icon', 'IconScale', ...
    'Camera', 'LookAt', 'AltitudeMode', 'Color', 'Width'};

% Remove those that do not belong to a particular type.
parameterNames(getNonParameterNameIndex(type, parameterNames)) = [];

%--------------------------------------------------------------------------

function index = getNonParameterNameIndex(type, parameterNames)
% Return index of parameter names that are not specific to a particular
% type.

if strcmp(type, 'point')
    index = strcmp('Width', parameterNames);
elseif strcmp(type, 'line')
    index = ismember(parameterNames, {'Icon', 'IconScale'});
else
    index = false(1, length(parameterNames));
end

%--------------------------------------------------------------------------

function validateFcns =  getValidators(type, numElements)
% Return cell array of function handles that validate input.

% Get all parameter names.
parameterNames = getParameterNames('any');

% validateFcns is a cell array of a validation functions for each
% parameterName.
defaultAltitudeMode = 'clampToGround';
validateFcns = { ...
    @(x)validateCellWrapper(x, @validateDescription, ...
       parameterNames{1}, numElements), ...
    @(x)validateCellWrapper(x, @validateStringCell, ...
       parameterNames{2}, numElements), ...
    @(x)validateCellWrapper(x, @validateFilenameCell, ...
       parameterNames{3}, numElements), ...
    @(x)validateNumericWrapper(x, @validatePositiveNumericArray, ...
       parameterNames{4}, numElements), ...
    @(x)validateViewPointWrapper(x, @validateViewParameters, ...
       parameterNames{5}, numElements), ...
    @(x)validateViewPointWrapper(x, @validateViewParameters, ...
       parameterNames{6}, numElements), ...
    @(x)validateCellWrapper(x, ...
       @(x, y) validateAltitudeMode(x, y, defaultAltitudeMode), ...
       parameterNames{7}, numElements), ...
    @(x)validateColorWrapper(x, @validateColor, ...
       parameterNames{8}, numElements), ...
    @(x)validateNumericWrapper(x, @validatePositiveNumericArray, ...
       parameterNames{9}, numElements)};
   
% Remove those functions that are not part of this type.
validateFcns(getNonParameterNameIndex(type, parameterNames)) = [];

%--------------------------------------------------------------------------

function numFeatures = numberOfFeatures(arg1, type)
% Determine number of features.

if ischar(arg1)
    numFeatures = 1;
elseif isobject(arg1)
    numFeatures = length(arg1);
elseif ~strcmp('line', type)
    % point or feature
    numFeatures = numel(arg1);
else
    % A line feature may be mult-part (separated by NaNs). However, it is 
    % considered a single feature. 
    numFeatures = 1;
end

%--------------------------------------------------------------------------

function filename = verifyFilename(filename, fcnName)
% Verify and validate the filename input.

filenamePos = 1;
validateattributes(filename, {'char'}, {'vector','nonempty'}, 'kmlparse', ...
    'FILENAME', filenamePos);

% Add .kml extension to filename if necessary.
kmlExt = '.kml';
[pathname, basename, ext] = fileparts(filename);
map.internal.assert(isequal(lower(ext), kmlExt) || isempty(ext), ...
    'map:fileio:invalidExtension', upper(fcnName), filename, kmlExt);
filename = fullfile(pathname,[basename,kmlExt]);

%--------------------------------------------------------------------------

function numDataArgs = verifyNumberOfDataArgs(parameterNames, inputs)
% Verify the number of required data arguments.
%
% The command line is composed of two sets of parameters:
%    the required arguments, followed by parameter-value pairs.
%
% For the case of KMLWRITE, the number of required arguments is either one,
% for S or ADDRESS input, or two for LAT and LON input, or three for LAT,
% LON, ALTITUDE input. A single required argument may be of the following
% type:
%   struct: geostruct input
%   dynamic vector
%   char  : address data 
%   cell  : address data
%   
% For the case of two or more required arguments (lat and lon input), the
% type of argument is numeric.
%
% verifyNumberOfDataArgs calculates the number of required data arguments
% and verifies the command line syntax. INPUTS is expected to contain at
% least one element. The FILENAME argument from the command line is
% expected to be removed prior to calling.

% Assign a logical row vector that has one more element than INPUTS,
% which contains true when the corresponding element of INPUTS is a
% string, false otherwise, and which ends in true which will help in the
% case where INPUTS contains no strings.
stringPattern = [cellfun(@ischar, inputs) true];

% Determine the number of data arguments:
%
% Define a working row vector that looks like this: [1 1 2 3 ...
% numel(inputs)], and call it numDataArgKey.  Then index into it with the
% stringPattern row vector (both have length 1 + numel(inputs)) and keep
% the first element that results (because there may be more than one
% string) to define numDataArgs.  The following three cases cover all the
% possibilities:
%
% (1) inputs{1} is a string, which means it must contain an address,
% which is the one and only data argument.  The first element of
% stringPattern is true, and the first element returned by the logical
% indexing step is the first element of numDataArgKey, which is 1.
%
% (2) inputs contains at least one string, but it is not inputs{1}. In
% this case, the number of data arguments is one less than the position of
% the first string in INPUTS. Due to the offset in the definition of
% numDataArgKey (the 2nd value is 1, the 3rd value is 2, etc.) the first
% element of the array returned by the indexing step will be the required
% value.
%
% (3) inputs contains no strings, so only the last element in
% stringPattern is true, which indexes the last element of numDataArgKey,
% which is numel(inputs). All the arguments are data arguments in this
% case.
numDataArgKey = [1, 1:numel(inputs)];
numDataArgs = numDataArgKey(stringPattern);
numDataArgs = numDataArgs(1);

% Set logicals for the conditions of one, two, or three data arguments. For
% one data argument, the char case is previously defined. 
% For the error condition: kmlwrite(filename, object / struct, number) 
% if you also include the check below in haveOneDataArg:
%  || isstruct(inputs{1}) || isobject(inputs{1});
% the code will issue an error from validatestring (below), which is not 
% very helpful. By not including the check, the code issues an error when
% validating latitude and longitude inputs.
haveOneDataArg = numDataArgs == 1 || iscell(inputs{1});
haveThreeDataArgs = ~haveOneDataArg && numDataArgs == 3;
haveTwoDataArgs = ~haveOneDataArg && ~haveThreeDataArgs;

% The paramPos is the expected position of the first parameter-value pair.
% The function expects one, two, or thee data arguments, so the paramPos is
% one plus the expected values.
paramPos = [2,3,4];
paramPos = paramPos([haveOneDataArg haveTwoDataArgs haveThreeDataArgs]);

% If the paramPos variable is not a string, then error.
if ~stringPattern(paramPos)
    % argPos is the position in the command line arguments for the paramPos
    % variable. Since FILENAME is removed from INPUTS, it is one plus
    % paramPos. 
     argPos = paramPos+1;
     validatestring(inputs{paramPos}, parameterNames, mfilename, ...
         'NAME', argPos)
end
    
%--------------------------------------------------------------------------

function c = validateCellWrapper(c, validateFcn, parameter, numElements)
% Validate cell wrapper function provides a common interface to validate
% inputs that are required to be cell array.

% c needs to be a cell array.
if ~iscell(c)
    c = {c};
end

% c needs to be a row vector.
c = {c{:}}; %#ok<CCAT1>

% Validate the number of elements in c.
validateNumberOfCellElements(c, parameter, numElements);

% Execute the validation function.
c = validateFcn(c, parameter);

% Map any empty characters to space characters.
c = mapEmptyToSpaceChar(c);

%--------------------------------------------------------------------------

function c = validateNumericWrapper(c, validateFcn, parameter, numElements)
% Validate numeric wrapper function provides a common interface to validate
% inputs that are required to be numeric array.

if iscell(c)
    c = cell2mat(c);
end

% Execute the validation function.
c = validateFcn(c, parameter);

% All parameter values must be converted to a cell array.
c = num2cell(c(:)');

% Validate the number of elements in c.
validateNumberOfCellElements(c, parameter, numElements);

% Map any empty characters to space characters.
c = mapEmptyToSpaceChar(c);

%--------------------------------------------------------------------------

function c = validateViewPointWrapper(c, validateFcn, parameter, numElements)
% validateViewPointWrapper provides a common interface to validate inputs
% for view point parameters (Camera and LookAt) that are required to be
% geopoint vectors.

% Validate input as a geopoint vector.
validateattributes(c, {'geopoint'}, {}, mfilename, parameter)

% Make sure required field names are present and setup Camera and LookAt
% specific data.
names = fieldnames(c);

if strcmp(parameter, 'Camera')
    % Camera
    required = 'Altitude'; 
    
    attributeNames = {'Altitude', 'Heading', 'Tilt', 'Roll',  'AltitudeMode'};
    viewParameters = {'Heading', 'Tilt', 'Roll'};
    viewRanges = { ...
        {'>=', 0, '<=', 360}, ...
        {'>=', 0, '<=', 180}, ...
        {'>=', -180, '<=', 180}};
else
    % LookAt
    
    % Check required parameter, Range.
    required = 'Range';
    
    % Check Altitude since it is required for Camera but not for LookAt.
    if ~any(strcmp('Altitude', names))
        c.Altitude = 0;
    end
    
    attributeNames = {'Altitude', 'Heading', 'Tilt', 'Range', 'AltitudeMode'};
    viewParameters = {'Heading', 'Tilt', 'Range'};
    viewRanges = { ...
        {'>=', 0, '<=', 360}, ...
        {'>=', 0, '<=', 90}, ...
        {'>=', 0}};
end

% Make sure required fields are present.
if isempty(names) || ~any(strcmp(required, names))
    error(message('map:kml:expectedField', parameter, required))
end

% Validate Altitude.
validateattributes(c.Altitude, {'numeric'}, {'real','finite'}, ...
    'kmlparse', [parameter '.Altitude']);

% Validate coordinates.
% NaN locations must be identical and values cannot be infinite.
% Clients need to validate that NaN locations coincide with feature 
% coordinates.
lat = c.Latitude;
lon = c.Longitude;
nanLat = isnan(lat);
nanLon = isnan(lon);
latStr = [parameter '.Latitude'];
lonStr = [parameter '.Longitude'];
if ~isequal(nanLat, nanLon) || all(nanLat) || any(isinf(lat)) || any(isinf(lon))
    validateattributes(lat, {'numeric'}, {'finite'}, mfilename, latStr);
    validateattributes(lon, {'numeric'}, {'finite'}, mfilename, lonStr);
else
    validateCoordinates(lat, lon, latStr, lonStr);
end
c.Longitude = wrapTo180(lon);

% Warn and remove unnecessary names.
nonAttributeNames = setdiff(names, attributeNames);
if ~isempty(nonAttributeNames)
    removedNames = sprintf('''%s'', ', nonAttributeNames{:});
    warning(message('map:kml:ignoringFieldnames', removedNames, parameter))
    for k = 1:numel(nonAttributeNames)
        c.(nonAttributeNames{k}) = [];
    end
end

% Execute the validation function.
c = validateFcn(c, parameter, viewParameters, viewRanges);

% Validate the number of elements in c.
validateNumberOfCellElements(c, parameter, numElements);
    
% Return in a cell array.
c = {c};

%--------------------------------------------------------------------------

function c = validateViewParameters(c, parameter, viewParameters, viewRanges)

names = fieldnames(c);
n = length(c);

commonAttributes = {'real', 'finite'};
for k = 1:numel(viewParameters);
    name = viewParameters{k};
    attributes = [commonAttributes, viewRanges{k}];
    if any(strcmp(name, names))
        validateattributes(c.(name), {'numeric'}, attributes, ...
            'kmlparse', [parameter '.' name]);
    else
        c.(name) = zeros(1, n);
    end
end

default = 'relativeToGround';
if any(strcmp('AltitudeMode', names))
    name = [parameter '.AltitudeMode'];
    c.AltitudeMode = validateAltitudeMode(c.AltitudeMode, name, default);
else
    c(1:length(c)).AltitudeMode = default;
end

%--------------------------------------------------------------------------

function mode = validateAltitudeMode(mode, parameterName, default)
% Validate AltitudeMode to be a valid string or cell array of strings.

if ~iscell(mode)
    mode = {mode};
end

% Change any '' values (used by geopoint to expand vector) to default.
index = cellfun(@isempty, mode);
mode(index) = {default};

% Validate mode as a cell array of strings.
mode = validateStringCell(mode, parameterName);

% Validate values
validModes = {'relativeToGround', 'relativeToSeaLevel', 'clampToGround'};
for k = 1:numel(mode)
    mode{k} = validatestring(mode{k}, validModes, 'kmlparse', parameterName);
end

% The KML format expects 'absolute' rather than 'relativeToSeaLevel'.
mode = strrep(mode, 'relativeToSeaLevel', 'absolute');

%--------------------------------------------------------------------------

function c = validateDescription(c, parameter)
% Validate description input. c is a cell array that is validated to
% contain strings or struct input.

% Permit char, or struct or numeric empty.
validInput = @(x)(ischar(x) || isstruct(x) || (isnumeric(x) && isempty(x)));
cIsCellArrayOfStringsOrStruct = cellfun(validInput, c);
if ~all(cIsCellArrayOfStringsOrStruct)
    value = c(~cIsCellArrayOfStringsOrStruct);
    value = value{1};
    validateattributes(value, {'char','struct'},{},'kmlparse', parameter)
end

%--------------------------------------------------------------------------

function c = validateColorWrapper(c, validateFcn, parameter, numElements)
% validateColorWrapper validates a 'Color' value.

% Execute the validation function.
c = validateFcn(c, parameter, numElements);

% Validate the number of elements in c.
validateNumberOfCellElements(c, parameter, numElements);
    
%--------------------------------------------------------------------------

function c = validateColor(c, parameter, numElements)
% Validate color input. The input c may be either a numeric array (1-by-3
% or numElements-by-3) containing RGB color values, a color string, or a
% cell array of color strings of length 1 or numElements. The output c is a
% cell array that contains KML color strings. A KML color string is valued:
% [alpha blue green red] in lower case hex. Color and opacity (alpha)
% values are expressed in hexadecimal notation. The range of values for any
% one color is 0 to 255 (00 to ff). Use the default ff for opacity.
% numElements is the number of features.

if ischar(c)
    c = {c};
end

if iscell(c)
    % c is a cell array, validate that it is a cell array of strings.
    index = cellfun(@(x) (ischar(x) && isvector(x)), c);
    if ~all(index)
        % The values in c are not all strings. Find the first non-string
        % value and issue an error using validateattributes.
        value = c{find(~index,1)};
        validateattributes(value, {'char'}, {'vector'}, 'kmlparse', parameter)
    end
    
    % c is a cell array of strings.
    % Convert colorSpec strings to RGB values.
    rgb = zeros(numel(c), 3);
    for k = 1:numel(c)
        rgb(k,:) = map.internal.colorSpecToRGB(c{k});
    end
    c = rgb;    
else
    % c is expected to be a numeric color array with size 1-by-3 or
    % numElements-by-3 and with values between 0 and 1.
    if size(c, 1) == 1
        % Allow the number of colors to be 1. If c contains a single color
        % (1-by-3) the numeric color value is converted to a single color
        % string and it will be propagated to all features (in the same
        % manner as a single string specification).
        numberOfRows = 1;
    else
        % Otherwise require one color for each element.
        numberOfRows = numElements;
    end
    validateattributes(c, {'double'}, ...
        {'nonempty', '>=', 0, '<=', 1, 'size', [numberOfRows 3]}, ...
        'kmlparse', parameter)
end

% Convert valid RGB values to KML color string: ffHexBlueHexGreenHexRed
numColors = size(c, 1);
kmlColors = cell(1, numColors);
for k = 1:numColors
    kmlColors{k} = sprintf('%02x', round(255 * [1 c(k,[3 2 1])]));
end

% Return c as a cell array of KML color strings.
c = kmlColors;

%--------------------------------------------------------------------------

function  c = validateStringCell(c, parameter)
% Validate c to be a cell array of strings. The strings must be row
% vectors.

if ~iscell(c)
    c = {c};
end

index = cellfun(@(x) (isempty(x) || (isvector(x) && ischar(x))), c);
if ~all(index)
    value = c(~index);
    value = value{1};
    validateattributes(value, {'char'}, {'vector'}, 'kmlparse', parameter)
end

%--------------------------------------------------------------------------

function  c = validatePositiveNumericArray(c, parameter)
% Validate c to be an array containing positive numeric values. 

cIsPositiveNumericArray = ...
    isnumeric(c) && all(~isinf(c(:))) && all(c(:) > 0);
if ~cIsPositiveNumericArray
    validateattributes(c, {'numeric'}, {'finite', 'positive'}, ...
        'kmlparse', parameter);
end

%--------------------------------------------------------------------------

function  c = validateFilenameCell(c, parameter)
% Validate c to be a cell array containing filenames. The filenames are
% validated to be strings and to exist. A filename may contain a URL
% string containing ftp:// http:// or file://.

% Validate the input as all string.
c = validateStringCell(c, parameter);

% Verify that all files exist. Some files may be a URL string, in which
% case filesExist is set to false.
filesExist = logical(cellfun(@(x)exist(x,'file'), c));

% urlEntries is a logical array that is true for entries that contain a
% URL string.
urlEntries = isURL(c);

% filesAreValid is a logical array set to true for all entries that are
% valid.
filesAreValid = urlEntries | filesExist;

if ~all(filesAreValid)
    % invalidEntries is a cell array of entries that are invalid.
    invalidEntries = c(~filesAreValid);
    fileNotFound = invalidEntries{1};
    error(message('map:fileio:fileNotFound', fileNotFound));
end

% The files may be partial pathnames. Set all filenames to absolute path.
c = getAbsolutePath(c, filesExist);

%--------------------------------------------------------------------------

function filenames = getAbsolutePath(filenames, filesExist)
% Return the absolute path of each element in filenames. filesExist is a
% cell array that is true for each file that exists.

for k=1:numel(filenames)
    if filesExist(k)
        
        try 
           fid = fopen(filenames{k},'r');
           fullfilename = fopen(fid);
           fclose(fid);
        catch e
            error(message('map:fileio:unableToOpenFile', filenames{k}));
        end
                
        if exist(fullfile(pwd,fullfilename),'file')
           fullfilename = fullfile(pwd, fullfilename);
        end
        filenames{k} = fullfilename;
    end
end
    
%--------------------------------------------------------------------------

function tf = isURL(filenames)
% Determine if a cell array of filenames contain a URL string. Return a
% logical array that is true for each element in filenames that contains a
% URL string.

urlFiles = strfind(filenames, '://');
tf = cellfun(@isempty, urlFiles);
tf = ~tf;

%--------------------------------------------------------------------------

function validateNumberOfCellElements(c, parameter, maxNumElements)
% Validate the number of elements in the c cell array.

validNumberOfCellElements = length(c) == [0, 1, maxNumElements];
if ~any(validNumberOfCellElements)
    if maxNumElements == 1
        % Use an error message from validateattributes to indicate that the
        % value needs to be a scalar.
        validateattributes(c, {class(c)}, {'scalar'}, mfilename, parameter);
    else
        error(message('map:validate:mismatchNumberOfElements', ...
            parameter, maxNumElements));
    end
end

%--------------------------------------------------------------------------

function c = mapEmptyToSpaceChar(c)
% Map empty values to a single space character. c is a cell array. empty
% values in the cell array are changed to ' '.
%
% XMLWRITE will not output empty tags correctly. For example, a value of ''
% for a tag name of 'description' will output as:
% <description/> 
% rather than:
% <description></description>

spaceChar = ' ';
c(isempty(c)) = {spaceChar};
emptyIndex = cellfun(@isempty, c);
c(emptyIndex) = {spaceChar};

%--------------------------------------------------------------------------

function [S, options] = checkFeatures(S, options, userSupplied)
% Validate the coordinate and altitude arrays in S. Add a description table
% to options.Description if userSupplied.Description is false.

% Validate the input S.
[S, options] = validateS(S, options);

% A table needs to be created if the user did not supply a description or
% an attribute spec is supplied in the Spec field of options.  If an
% attribute spec is supplied, then userSupplied.Description is previously
% set to false.
if ~userSupplied.Description
    options = makeDefaultTable(S, options);
end

% Determine altitude field.
[S, altitudeName, altitudeIsSpecified] = determineAltitudeName(S);

% Set AltitudeMode, if not supplied, and if altitude values have been
% specified in S. The default value used by KML functions is
% 'relativeToSeaLevel' but KML uses 'absolute'.
if all(strcmp(' ', options.AltitudeMode)) && altitudeIsSpecified
    options.AltitudeMode = {'absolute'};
end

% Validate altitude.
issueWarning = true;
warningName = ['altitude (''' altitudeName ''')'];
needTable = false;
if isa(S, 'geopoint')
    % S is a geopoint vector.
    % Validate altitude and verify NaN locations.
    lat = S.Latitude;
    alt = S.(altitudeName);
    alt = validateAltitude(alt, lat);
    [S.(altitudeName), needTable] = checkAltitudeNans( ...
        alt, lat, warningName, issueWarning);
else
    % S is a geoshape vector.
    % Since the altitude values may be set, loop through each element,
    % validate the altitude values and issue a warning once if NaN values in
    % altitudeName do not correspond to NaN values in Latitude and set them
    % to 0.
    altCell = cell(1, length(S));
    for k = 1:length(S)
        lat = S(k).Latitude;
        alt = S(k).(altitudeName);
        alt = validateAltitude(alt, lat);
        [altCell{k}, warningIssued] = ...
            checkAltitudeNans(alt, lat, warningName, issueWarning);
        if warningIssued
            issueWarning = false;
            needTable = true;
        end
    end
    S.(altitudeName) = altCell;
end

% A table needs to be re-created if a warning has been issued since the
% values of S have changed from NaN to 0.
if ~userSupplied.Description && needTable
    options = makeDefaultTable(S, options);
end
    
%--------------------------------------------------------------------------

function [S, options] = arraysToDynamicVector(dataArgs, options, type)
% Validate the latitude and longitude coordinate arrays in dataArgs 
% and the altitude (if present). If type is 'line', return S as a geoshape
% vector with 'line' Geometry; otherwise return S as a geopoint vector.

% Verify the coordinates.
lat = dataArgs{1};
lon = dataArgs{2};
[lat, lon] = validateCoordinates(lat, lon);

if length(dataArgs) == 3
    % Using (filename, lat, lon, alt) syntax
    % Validate altitude.
    alt = dataArgs{3};
    alt = validateAltitude(alt, lat);
    
    % Set AltitudeMode, if not supplied.
    % The default value used by
    % KMLWRITE is 'relativeToSeaLevel' but KML uses 'absolute'
    if all(strcmp(' ', options.AltitudeMode))
        options.AltitudeMode = {'absolute'};
    end
    
    % Check NaN locations of altitude.
    issueWarning = true;
    alt = checkAltitudeNans(alt, lat, 'altitude', issueWarning);
else
    % Assign alt values of 0.
    alt = zeros(1, numel(lat));
end

% Create a geoshape vector if type is 'line' otherwise create a geopoint
% vector.
if strcmp(type, 'line')
    S = geoshape(lat, lon, 'Altitude', {alt}, 'Geometry', 'line');
else
    S = geopoint(lat, lon, 'Altitude', alt);
end

%--------------------------------------------------------------------------

function address = validateAddress(address, fcnName)
% Validate address as a string or a cell array of strings.

validTypes = {'cell', 'char'};
validateattributes(address, validTypes, {'nonempty'}, fcnName, 'ADDRESS', 2);

% address must be a cell array.
if ~iscell(address)
    address = {address};
end

% Verify that address is a cell array of strings.
index = cellfun(@(x)(isempty(x) || (isvector(x) && ischar(x))), address);
if ~all(index)
    value = address{find(~index, 1)};
    validateattributes(value, {'char'}, {'vector'}, fcnName, 'ADDRESS')
end
    
%--------------------------------------------------------------------------

function [S, options] = validateS(S, options)
% Validate input S.

validTypes = {'struct', 'geopoint', 'geoshape'};
validateattributes(S, validTypes, {'vector', 'nonempty'}, mfilename, 'S', 2);

if isstruct(S)
    % Verify the geostruct and convert to a dynamic vector.
    S = checkgeostruct(S);
end

% Allow point or line geometry.
map.internal.assert(any(strcmpi(S.Geometry, {'point', 'line'})), ...
    'map:geostruct:expectedSpecificGeometry', ...
    '''point'' or ''line''', ['''', S.Geometry, '''']);

% Verify the coordinates.
validateCoordinates(S.Latitude, S.Longitude);

%--------------------------------------------------------------------------

function options = makeDefaultTable(S, options)
% Create a default HTML table based on S and the attribSpec. The attribSpec
% is supplied in options.Spec and may be empty. The options Description
% field contains the output HTML table.

attribSpec = options.Spec;

% Create an attribSpec if it is empty.
if isempty(attribSpec)
    attribSpec = makeattribspec(S);
else
    % Validate the attribute spec.
    attribSpec = validateAttributeSpec(attribSpec, S);
end

% Convert the attribute fields of the dynamic vector to a cell array
% containing HTML. The table is the description field of a KML
% Placemark element which is located at the specified coordinates.
options.Description = attributeFieldsToHTML(S, attribSpec);

%--------------------------------------------------------------------------

function S = checkgeostruct(S)

% Verify the input is a non-empty structure.
validateattributes(S, {'struct'}, {'vector','nonempty'}, ...
     mfilename, 'S', 2);

 % Support version1 geostruct.
if isfield(S,'lat') && isfield(S,'long')
   S = updategeostruct(S);
end

% Validate S.
p = map.internal.struct2DynamicVector(S);

% Verify the geostruct coordinate field names.
map.internal.assert(isa(p, 'geopoint') || isa(p, 'geoshape'), ...
    'map:geostruct:expectedGeostruct');

% Point, MultiPoint, Line geometry is supported.
map.internal.assert(any(strcmpi(p.Geometry, {'point', 'line'})), ...
    'map:geostruct:expectedSpecificGeometry', ...
    '''Point'' or ''MultiPoint''', ['''', S(1).Geometry, '''']);

S = p;

%--------------------------------------------------------------------------

function html = attributeFieldsToHTML(S, attribSpec)
% Convert attribute fields to HTML. Create an HTML table as a string value
% in the cell array HTML for each element in the dynamic vector S by
% applying the attribute specification, attribSpec. HTML is the same length
% as S.

% Obtain the field names of the attribute structure to be used in the
% table.
rowHeaderNames = getAttributeLabelsFromSpec(attribSpec);

% Convert the fields to a string cell array.
c = attributeFieldsToStringCell(S, attribSpec);

% Convert each element of S to an HTML table. 
html = cell(1,length(S));
for k=1:length(S)
    % Convert the cell array to an HTML table.
    html{k} = makeTable(rowHeaderNames, c(:,k));
end

%--------------------------------------------------------------------------

function attributeLabels = getAttributeLabelsFromSpec(attribSpec)
% Obtain the table names from the attribute spec.  attributeLabels is a
% cell array containing the string names for each attribute.

% Assign the field names of the desired attributes.
specFieldNames = fieldnames(attribSpec);

% Assign the number of desired attributes.
numSpecFields = numel(specFieldNames);

% Allocate space for the attribute labels.
attributeLabels = cell(1,numSpecFields);

% Obtain the names from the spec.
for m=1:numSpecFields
    specFieldName = specFieldNames{m};
    attributeLabels{m} = attribSpec.(specFieldName).AttributeLabel;   
end

%--------------------------------------------------------------------------

function c = attributeFieldsToStringCell(S, attribSpec)
% Convert the dynamic vector S to a string cell array by applying the 
% format in the structure attribSpec.

% Get the field names of the attribute structure and initialize a cell
% array.
attributeNames = fieldnames(attribSpec);
c = cell(length(attributeNames), length(S));

% Apply the specification to S.
% Loop through each of the attributeNames and convert each value  of the
% dynamic vector to a string. Apply the attribute specification to the
% numeric values. A cell array in a geopoint or geoshape vector is always
% a cellstr.
for k=1:numel(attributeNames)
    fieldName = attributeNames{k};
    value = S.(fieldName);
    if ischar(value)
        c(k,:) = {value};
    elseif iscell(value)
        c(k,:) = value;
    else
        for n = 1:length(value)
            v = value(n);
            c{k, n} = num2str(v, attribSpec.(fieldName).Format);
        end
    end
end

%--------------------------------------------------------------------------

function attribSpec = validateAttributeSpec(attribSpec, S)
% Validate attribute specification.

% If attribSpec is empty, make sure it's an empty struct.
if isempty(attribSpec)
    % No need to check anything else, including the attribute fields of S.
    attribSpec = struct([]);
else
    % Make sure that attribSpec is a scalar structure.
    validateattributes(attribSpec, {'struct'}, {'scalar'}, ...
        'kmlwrite', 'Description')
    
    % Validates attribute values in S and make sure attribSpec and S are
    % mutually consistent.
    defaultspec = makeattribspec(S);  
    attributeNamesInS = fields(defaultspec);
    attributeNamesInattribSpec = fields(attribSpec);
    
    % Check 1:  Every attribute in attribSpec must be present in S.
    missingAttributes = setdiff(attributeNamesInattribSpec,attributeNamesInS);
    map.internal.assert(isempty(missingAttributes), ...
        'map:geostruct:missingAttributes');
    
    % Check 2:  Field types in attribSpec must be consistent with S. While
    % in this loop, use the default to fill in any fields missing from
    % attribSpec.
    for k = 1:numel(attributeNamesInattribSpec)
        attributeName = attributeNamesInattribSpec{k};
        fSpec = attribSpec.(attributeName);
        fDefault = defaultspec.(attributeName);
        
        if ~isfield(fSpec,'AttributeLabel')
            attribSpec.(attributeName).AttributeLabel = fDefault.AttributeLabel;
        end
        
        if ~isfield(fSpec,'Format')
            attribSpec.(attributeName).Format = fDefault.Format;
        end
    end
end

%--------------------------------------------------------------------------

function  html = makeTable(names, values)
% Create a cell array containing HTML embedded tags representing a table.
% The table is two-column with name, value pairs. 

% NAMES is a string cell array containing the names for the first column in
% the table. VALUES is a string cell array containing the values for the
% second column in the table.  HTML is a char array containing embedded
% HTML tags defining a table. 

if ~isempty(names)
    numRows = numel(names);
    html = cell(numRows+2,1);

    html{1} = sprintf('<html><table border="1">\n');
    rowFmt = '<tr><td>%s</td><td>%s</td></tr>\n';
    for k = 1:numRows
        html{k+1} = sprintf(rowFmt, names{k}, values{k});
    end
    html{numRows+2} = sprintf('</table><br></br></html>\n');
    html = char([html{:}]);
else
    html = ' ';
end

%--------------------------------------------------------------------------

function [lat, lon] = validateCoordinates(lat, lon, latStr, lonStr)
% Validate the latitude, longitude coordinates.

if ~exist('latStr', 'var')
    latStr = 'latitude coordinates';
end

if ~exist('lonStr', 'var')
    lonStr = 'longitude coordinates';
end

% Make sure the lat and lon arrays are numeric to prevent issues with using
% isnan.
if ~isnumeric(lat) || ~isnumeric(lon)
    validateattributes(lat, {'numeric'}, {}, mfilename, latStr);
    validateattributes(lon, {'numeric'}, {}, mfilename, lonStr);
end
     
% The shape of the arrays do not matter.
lat = lat(:)';
lon = lon(:)';

% Validate numeric data.
% NaN values cause validateattributes to throw an error in the 'finite'
% case, but are permitted.
latNaNIndices = isnan(lat);
lonNaNIndices = isnan(lon);

if ~all(~isinf(lat)) || all(latNaNIndices)
    attributes = {'real', 'nonempty', 'finite'};
else
    attributes = {'real', 'nonempty'};
end
validateattributes(lat, {'numeric'}, attributes, mfilename, latStr);

if ~all(~isinf(lon)) || all(lonNaNIndices)
    attributes = {'real', 'nonempty', 'finite'};
else
    attributes = {'real', 'nonempty'  'size', size(lat)};
end
validateattributes(lon, {'numeric'}, attributes, mfilename, lonStr);

% Validate NaN locations.
if ~isequal(latNaNIndices, lonNaNIndices)
    error('map:kml:mismatchedNaNsInCoordinatePairs', ...
    'Expected latitude and longitude coordinates to have NaN-delimiters in corresponding locations.');
end

% Validate latitudes are in range.
validateattributes(lat(~latNaNIndices), {'numeric'}, {'>=', -90, '<=', 90},...
    mfilename, latStr);

%--------------------------------------------------------------------------

function alt = validateAltitude(alt, lat)
% Validate altitude.

% Ensure row vector for consistency with lat and lon.
% validateCoordinates ensures that lat and lon are row vectors.
alt = alt(:)';

% Ensure length matches if alt is a scalar.
if isscalar(alt)
    alt = alt * ones(1, numel(lat));
end

% Validate altitude. Ensure size matches coordinates.
name = 'altitude';
attributes = {'real', 'nonempty', 'size', size(lat)};
validateattributes(alt, {'numeric'}, attributes, mfilename, name);

% Allow NaN values but altitude cannot be infinite.
if any(isinf(alt))
    validateattributes(alt, {'numeric'}, {'finite'}, mfilename, name);
end

%--------------------------------------------------------------------------

function [alt, warningIssued] = checkAltitudeNans( ...
    alt, lat, warningName, issueWarning)
% If ALT and LAT have matching lengths, then check that the NaN locations
% of ALT match the NaN locations of LAT. If not, then set those ALT values
% to 0 and warn if issueWarning is true.

warningIssued = false;
% If lengths are not equal, there is no need to issue an error here because
% validation of altitude values will fail elsewhere.
if length(alt) == length(lat)
    altNans = isnan(alt);
    latNans = isnan(lat);
    altOrLatNans = latNans | altNans;
    if ~isequal(latNans, altOrLatNans)
        if issueWarning
            warning('map:kml:settingAltitudeToZero', ...
                'Setting %s NaN values to 0.', warningName)
            warningIssued = true;
        end
        alt(altNans) = 0;
    end
end

%--------------------------------------------------------------------------

function [S, altitudeName, altitudeIsSpecified] = determineAltitudeName(S)
% Determine the altitude name from the input dynamic vector, S.

% Assign default values.
defaultName = 'Altitude';
isVertexProperty = isa(S, 'geoshape');
if isVertexProperty
   defaultValue = {0};
else
    defaultValue = 0;
end

% Find altitude names in S.
altitudeNames = {'Altitude', 'Elevation', 'Height'};
names = fieldnames(S);
index = ismember(altitudeNames, names);

% Validate altitude.
if any(index)
    if length(find(index)) > 1
        warning(message('map:kml:tooManyAltitudeFields'))
        altitudeName = defaultName;
        S = rmfield(S, altitudeNames(index));
        S = assignAltitude(S, isVertexProperty, altitudeName, defaultValue);
        altitudeIsSpecified = false;
    else
        altitudeName = altitudeNames{index};
        altitudeIsSpecified = true;
    end
else
    altitudeName = defaultName;
    S = assignAltitude(S, isVertexProperty, altitudeName, defaultValue);
    altitudeIsSpecified = false;
end

%--------------------------------------------------------------------------

function S = assignAltitude(S, isVertexProperty, altitudeName, value)
% Assign altitudeName property to S. S is a geopoint or geoshape vector.

if ~isVertexProperty
    S.(altitudeName) = value;
else
    for k = 1:length(S)
        % Determine NaN locations.
        nanLocations = isnan(S(k).Latitude);
        
        % Expand to match in length.
        S(k).(altitudeName) = value;
        
        % Set NaN locations.
        S(k).(altitudeName)(nanLocations) = NaN;
    end
end

