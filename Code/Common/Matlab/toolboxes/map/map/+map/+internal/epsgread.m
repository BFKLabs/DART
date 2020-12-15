function result = epsgread(table, code)
%epsgread Read table or record from EPSG Geodetic Parameter Dataset
%
%   RESULT = EPSGREAD(TABLE) reads all records and fields from the
%   designated table, returning the results in a 2-D cell array of strings,
%   with the field names in its top row. TABLE is a string containing the
%   name of the EPSG table to be read, minus the '.csv' file extension. The
%   result can be viewed in tabular form using the workspace browser.
%
%   RECORD = EPSGREAD(TABLE,CODE) reads the record that matches the
%   specified numeric code and returns its contents in a scalar structure
%   in which the field names match the strings in the table header. RECORD
%   is [] if no match for the code is found.
%
%   CODES = EPSGREAD(TABLE,'codes') returns a numeric column vector
%   listing the integer codes from the first column of the table.
%
%   Limitations
%   -----------
%   The function assumes that the only newline characters are record
%   delimiters.  But the files 'coordinate_operation_method.csv' and
%   'change.csv' have rows with embedded newlines, so they cannot be read.
%
%   The function does not handle empty files gracefully, and hence cannot
%   read the 'codes' table.
%
%   Examples
%   --------
%   % Read the entire ellipsoid table into a 2-D cell array 
%   % and view it in the variable editor.
%   result = map.internal.epsgread('ellipsoid'); openvar result
%
%   % Read a single record from the ellipsoid table into a scalar struct.
%   result = map.internal.epsgread('ellipsoid',7019)
%
%   % Read a single record from the unit of measure table into a
%   % scalar struct.
%   result = map.internal.epsgread('unit_of_measure',9001)
%
%   % Read the numeric codes from the unit of measure table
%   % into a column vector.
%   codes = map.internal.epsgread('unit_of_measure','codes')
%
%   The EPSG Geodetic Parameter Dataset is owned by the International
%   Association of Oil and Gas Producers (OGP). See http://www.epsg.org/
%   for additional information.

% Copyright 2011-2012 The MathWorks, Inc.

% Locate toolbox/map/mapproj.
if isdeployed
    mapproj = fileparts(which('mapproj/vgrint1.m'));
else
    mapproj = fullfile(matlabroot,'toolbox','map','mapproj');
end

% Construct and validate full name and path for the EPSG CSV file.
validateattributes(table, {'char'}, {'nonempty','row'})
filename = fullfile(mapproj,'projdata','epsg_csv',[table '.csv']);

% Check existence.
if exist(filename,'file') ~= 2
    error(message('map:fileio:fileNotFound', filename))
end

% Open the file and construct a clean-up object to ensure it gets closed.
% In the call to fopen, the ENCODING argument is specified as 'ISO-8859-1',
% because to the best of our knowledge that is the encoding used in each of
% the EPSG CSV files.  (Of course, a general CSV reader should accept an
% optional input to allow the default encoding to be more generally
% overridden; but epsgread is not intended to be such a function.)
fid = fopen(filename,'r','native','ISO-8859-1');
if fid == -1
    error(message('map:fileio:unableToOpenFile', filename))
end
clean = onCleanup(@() fclose(fid));

if nargin < 2
    % Read the entire file and return its contents in a 2-D cell array.
    
    % Scan the header strings from the first line in the file into a cell
    % vector of strings.
    header = csvReadHeader(fid);
    
    % Scan the data lines into a cell vector with one line per cell.
    data = scanData(fid);
    
    % Construct a cell array with the same number of rows and columns as the
    % CSV table.
    result = cell(1 + numel(data),numel(header));
    
    % Copy the header into the top row.
    result(1,:) = header;
    
    % Parse each data row and store the results in the cell array.
    for k = 1:numel(data)
        result(k+1,:) = csvParseDataLine(data{k});
    end
else
    if strcmp(code,'codes')
        % Read the entire file and return a vector containing the numeric
        % codes from the first column.
        result = readCodes(fid);
    else
        % Read a single record and return a scalar structure, using the
        % header strings as field names.
        validateattributes(code,{'double'}, ...
            {'real','finite','positive','integer'},'','CODE',2)
        result = readRecord(fid, code);
    end
end

%--------------------------------------------------------------------------

function codes = readCodes(fid)
% Assuming the file identifier FID is positioned at the beginning of a CSV
% file, skip the header line, then read the rest of the file and extract
% the code from the beginning of each line. Return the results in a
% numerical column vector.

% Skip the header line.
fgetl(fid);

% Scan the data lines into a cell vector with one line per cell.
data = scanData(fid);

% Scan the integer code from the beginning of each line.
codes = cellfun(@(d) sscanf(d,'%d'), data);

%--------------------------------------------------------------------------

function data = scanData(fid)
% Assuming that fid is positioned just after the header line,
% read the rest of the file into a cell vector with one line per cell,
% filtering out any lines that begin with the '#' character.

% Special character
newline = char(10);

% Read the rest of the file into a cell vector with one line per cell.
data = textscan(fid,'%s',-1,'Delimiter',newline,'BufSize',10000,'Whitespace','');
data = data{1};

% Filter out comment lines, if any.
isComment = cellfun(@(d) strcmp(d(1),'#'), data);
data(isComment) = [];

%--------------------------------------------------------------------------

function result = readRecord(fid, code)
% Assuming the file identifier FID is positioned at the beginning of a CSV
% file, read the file line by line until a line is found that matches the
% specified integer code is found, or to the end of the file, whichever
% comes first.

% Read the header strings into a cell array.
header = csvReadHeader(fid);

done = false;
while ~done
    tline = fgetl(fid);
    if ischar(tline)
        if sscanf(tline,'%d') == code
            % Found a match
            done = true;
        end
    else
        % End of file
        done = true;
    end
end

% If line is found that starts with the specified code, parse the line and
% construct the return structure. Otherwise return [].
if ischar(tline)
    % Found a match.
    data = csvParseDataLine(tline);
    
    % Code the data for the matching line into a scalar structure
    % with one field for each string in the cell array HEADER.
    fieldValuePairs = [header; data];
    result = struct(fieldValuePairs{:});
else
    % Failed to find a match.
    result = [];
end

%--------------------------------------------------------------------------

function header = csvReadHeader(fid)
%csvReadHeader Read header from CSV file into cell vector
%
%   HEADER = csvReadHeader(FID) scans the header strings from the first
%   line in a comma-separated-value (CSV) file, strips off quotation marks
%   if they are present, and replaces spaces, if present, with underscores.
%   FID is a file descriptor position at the beginning of a CSV file. The
%   result, HEADER, is a cell vector of strings.

% Special characters
quote = char(34);
space = char(32);
underscore = char(95);

% Read and parse the first single line.
tline1 = fgetl(fid);
tline1(tline1 == quote) = [];
tline1(tline1 == space) = underscore;
header = textscan(tline1,'%s',-1,'Delimiter',',');

% Function textscan returns a column cell vector within a scalar cell;
% convert that to a row cell vector.
header = header{1}';

%--------------------------------------------------------------------------

function data = csvParseDataLine(tline)
%parseCSV Parse a data line from a comma-separate-value (CSV) file
%
%   DATA = csvParseDataLine(TLINE) parses the string TLINE into a cell
%   vector of strings, DATA, with one element for each comma-separated
%   field/data element found in TLINE.
%
%   Remarks
%   -------
%   (1) Even though the TLINE should have come from a "CSV" file, not all
%       commas are separators. Some fields begin and end with a quotation
%       mark, and these fields may contain commas that are just part of the
%       text.
%
%   (2) True quoted text, as in the name of a source work such as
%       "Geodetic Reference System 1980", is enclosed in pairs of doubled
%       quotation marks, like this: ""Geodetic Reference System 1980"".
%
%   (3) It's important to remove the quotation marks of the sort mentioned
%       in remark (1), and to eliminate the extra quotation marks in the
%       case of remark (2); parseCSV performs both these operations.

% Special characters
comma = char(44);
quote = char(34);
newline = char(10);

% Append a comma-separator to the end of the line.
tline(end+1) = comma;

% For comma-quotation and quotation-comma pairs that might begin and end
% fields, identify the location of the comma in each pair.
sQuote = strfind(tline,[comma quote]) + 1;
eQuote = strfind(tline,[quote comma]);

if ~isempty(sQuote) && ~isempty(eQuote)
    % Eliminate false positives in sQuote and eQuote by ensuring that they
    % occur in alternating pairs. Start by combining them, then sorting.
    % Apply the sort index to a vector of 0s and 1s in which 0 indicates
    % the occurrence of a comma-quotation pair and 1 indicates the
    % occurrence of a quotation-comma pair. Use diff to identify the places
    % where runs of multiple comma-quotation pairs start and where runs of
    % multiple quotation-comma pairs end. All other elements in such runs
    % are false positives and will be removed.
    aQuote = [sQuote eQuote];
    [aQuote, ix] = sort(aQuote);
    r = [zeros(size(sQuote)) ones(size(eQuote))];
    r = r(1,ix);         % Logical index to ending elements within aQuote
    q = ~r(1,end:-1:1);  % Logical index to starting elements within aQuote, flipped LR
    q = diff([q 0]);
    q = q(1,end:-1:1) == -1;  % Index to starting elements minus false positives
    r = diff([r 0])   == -1;  % Index to ending elements minus false positives
    sQuote = aQuote(q);  % sQuote with false positives removed
    eQuote = aQuote(r);  % eQuote with false positives removed
    
    % Identify the elements of TLINE that are bounded by comma-quotation /
    % quotation-comma pairs (after excluding false positives). Construct
    % vectors s and e that are zero except where the commas in such pairs
    % are located. The cumulative sums of s and e, when added together,
    % will be even for sections of TLINE that are not so bounded, and odd
    % for sections of TLINE that are.
    s = zeros(size(tline));
    e = zeros(size(tline));
    s(sQuote + 1) = 1;
    e(eQuote) = 1;
    boundedByCommaQuoteQuoteComma = (mod(cumsum(s) + cumsum(e),2) == 1);
else
    boundedByCommaQuoteQuoteComma = false(size(tline));
end

% A logical vector that indexes all the commas
isComma = (tline == comma);

% A separating comma is any element of TLINE that is a comma and (a) is not
% bounded by comma-quotation / quotation-comma pairs or (b) is indexed by
% sQuote and eQuote. Construct a logical vector that indexes all the
% separating commas.
separator = false(size(tline));
separator(isComma & ~boundedByCommaQuoteQuoteComma) = true;
separator([sQuote - 1, eQuote + 1]) = true;

% Because it's inconvenient having some commas that are separators and
% others that are not, convert all the separating commas to newlines. (We
% don't expect TLINE to contain any newline characters prior to this step.)
tline(separator) = newline;

% Remove, from TLINE, the quotation marks that immediately follow or
% precede the commas identified sQuote and eQuote.
tline([sQuote, eQuote]) = [];

% Convert all double quotation marks within TLINE to single quotation marks.
tline(strfind(tline,[quote quote])) = [];

% Use textscan to break TLINE into substrings delimited by tab characters.
data = textscan(tline,'%s',-1,'Delimiter',newline,'Whitespace','');

% Convert the result to a row cell vector (starting from a scalar cell
% containing a column cell vector).
data = data{1}';
