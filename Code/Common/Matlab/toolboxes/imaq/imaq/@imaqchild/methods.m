function varargout = methods(obj, full)
%METHODS Display class method names.
%   METHODS CLASSNAME displays the names of the methods for the
%   class with the name CLASSNAME.
%
%   METHODS(OBJ) displays all of the methods available for the object
%   OBJ.
%
%   M = METHODS(OBJ)
%   M = METHODS('CLASSNAME') returns the methods in a cell array of
%   strings.
%
%   METHODS differs from WHAT in that the methods from all method
%   directories are reported together, and METHODS removes all
%   duplicate method names from the result list.  METHODS will also
%   return the methods for a Java class.
%
%   METHODS(OBJ, '-full')
%   METHODS CLASSNAME -full  displays a full description of the
%   methods in the class, including inheritance information and,
%   for Java methods, also attributes and signatures.  Duplicate
%   method names with different signatures are not removed.
%   If class_name represents a MATLAB class, then inheritance 
%   information is returned only if that class has been instantiated. 
%
%   M = METHODS(OBJ, '-full')
%   M = METHODS('CLASSNAME', '-full') returns the full method
%   descriptions in a cell array of strings.
%   
%   See also METHODSVIEW, WHAT, WHICH, HELP.

%   DT 6/2004
%   Copyright 2004-2013 The MathWorks, Inc.

% Validate that the input arguments are correct.
narginchk(1, 2)

% Validate that the output arguments are correct.
nargoutchk(0, 1)

% Validate that the object is of the correct type.
if (~isa(obj, 'imaqchild') || (length(obj) ~= 1))
    error(message('imaq:methods:invalidType'));
end

if ~isvalid(obj)
    error(message('imaq:methods:invalidOBJ'));
end

% If the second argument is specified, it must be exactly -full
if (nargin == 2)
    if ~strcmp(full, '-full')
        error(message('imaq:methods:badopt'));
    end
end

methodsToRemove = {'Contents', 'loadobj', 'saveobj'};

if (nargin == 1)
    objMethods = methods(class(obj));
    imaqdeviceMethods = methods('imaqchild');

    methodNames = unique(sort({objMethods{:} imaqdeviceMethods{:}})); %#ok<CCAT>

    % Remove unwanted methods names from the display
    methodNames = setdiff(methodNames, methodsToRemove)';

    if (nargout == 0)
        localPrettyPrint(methodNames, class(obj));
    else
        varargout(1) = {methodNames};
    end
    
else
    if (nargout == 0)
        outDisp = evalc('builtin(''methods'', obj, ''-full'');');
        
        % Remove the functions that should not be displayed from the list
        % of functions displayed.
        
        % Create a regular expression that will find the correct line.  Use
        % \n to indicate line breaks since ^ and & don't seem to work on
        % the result of evalc.
        replaceStrings = regexprep(methodsToRemove, '(.*)', '\n($0.*?)\n');
        
        % Remove the lines from the display.
        outDisp = regexprep(outDisp, replaceStrings, '\n');
        
        % Show the display without any extra carriage returns.
        fprintf('%s', outDisp);
    else
        methodNames = builtin('methods', obj, '-full');
        for i = 1:length(methodsToRemove)
            methodNames(strmatch(methodsToRemove{i}, methodNames)) = [];
        end
        varargout{1} = methodNames;
    end
end


function localPrettyPrint(methodNames, className)
% Prints the methods to the command window nicely formatted and with a
% header.  The display is formatted to take up the width of the command
% window.

% Get the size of the command window, and therefor the max line width.
commandWindowSize = matlab.desktop.commandwindow.size;
maxLineLength = commandWindowSize(1);

% Determine the longest method name.  This is used to calculate the padding
% so that the method names are properly justified.
maxMethodLength = max(cellfun('length', methodNames));

% Print out the heading
headingSpace = '\n\n';
headingText = sprintf('%sMethods for class %s:\n%s',headingSpace,className,headingSpace);
fprintf(headingText);

% Calculate spacing information.
maxSpacing = 2;
maxColumns = floor(maxLineLength/(maxMethodLength + maxSpacing));
numOfRows = ceil(length(methodNames)/maxColumns);

% Reshape the methods into a numOfRows-by-maxColumns matrix.
numToPad = (maxColumns * numOfRows) - length(methodNames);
for i = 1:numToPad
    methodNames = {methodNames{:} ' '}; %#ok<CCAT>
end
methodNames = reshape(methodNames, numOfRows, maxColumns);

% Print out the methods.

% Loop through the methods and print them out.
for i = 1:numOfRows
    out = '';
    for j = 1:maxColumns
        m = methodNames{i,j};
        
        % Only add the padding blanks if this is not the last column.
        if (j == maxColumns)
            out = [out m]; %#ok<AGROW>
        else
            out = [out sprintf('%s%s', m, blanks(maxMethodLength + maxSpacing - length(m)))]; %#ok<AGROW> 
        end
    end    
    fprintf([out '\n']);
end

fprintf('\n');