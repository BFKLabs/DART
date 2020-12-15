classdef (Hidden) DisplayFormatter
    % DISPLAYFORMATTER Utility class to format the display of VideoWriter
    % and HMI components objects.
    %
    % DisplayFormatter is a general purpose utility class used to format
    % the disp and getdisp of objects.  It is currently being used by
    % Visual Components and VideoWriter objects.  It attempts to mimic the
    % default display of MATLAB classes.
    %
    % This is an internal class and is not intended for use in customer
    % code.
    %
    % DisplayFormatter methods:
    %     getDisplayHeader - Return the display header for an object
    %     getDisplayCategories - Return the display categories and the
    %                            property names and property values
    %                            associated with that category for an object.
    %
    %     getDisplayTable - Return the display of Table for an object
    %     getDisplayFooter - Return the display footer for an object
    %     getPropertiesString - Return the string for the property display.
    %     getTableString - Return the string for the Table display.
    %
    %
    % Example:
    %   To display the categories
    %   fprintf(internal.DisplayFormatter.getDisplayCategories(obj,...
    %            'CategoryOne',{'PropertyAlpha', 'PropertyBeta', 'PropertyGaama'},...
    %            'CategoryTwo',{'PropertyAlpha'},...
    %            'CategoryThree',{'PropertyAlpha','PropertyBeta'}));
    %
    %  To display the Table
    %    fprintf(internal.DisplayFormatter.getDisplayTable(obj,...
    %                                            {'ColumnName', 'ColumnName'},...
    %                                            {'PropertyAlpha', 'PropertyBeta'}));
    
    % Copyright 2009-2012 The MathWorks, Inc.
    
    properties(Constant)
        
        %All category names are indented 4 spaces
        CategoryIndent = blanks(4);
        
        % All property names are indented 3 spaces underneath the category
        % names.
        CategoryPropertyNameIndent = blanks(7);
        
        %Property value are indented 3 spaces from the longest property
        %name.
        CategoryIndentPropertyNamesAndValues = blanks(3);
        
        %All column properties are indented 2 spaces underneath the column
        %name
        TableColumnPropertiesIndent = blanks(2);
        
        %Columns in a table are indented 5 spaces
        TableColumnSpacing = blanks(5);
        
        %Table is indented 4 spaces
        TableIndent = 4;
        
        %Indent for the state color column
        StateColorsIndent = blanks(3);
    end
    
    
    methods (Static)
        
        function header = getDisplayHeader(displayObject)
            % HEADER = GETDISPLAYHEADER(OBJ) Return the display header for an object.
            %
            % HEADER =  returns the header string
            % for the object obj.  The header string is designed to
            % reflect the appearance of the default MATLAB Class object
            % display except that subclasses are not displayed.
            
            hotlinks = feature('hotlinks');
            myclass = class(displayObject);
            
            if hotlinks
                header = sprintf('  <a href="matlab:help %s">%s</a>\n\n', myclass, myclass);
            else
                header = sprintf('  %s\n\n', myclass);
            end
        end
        
        function categoryHeader = getDisplayCategories(displayObject, varargin)
            % CATEGORYHEADER = GETDISPLAYCATEGORIES(DISPLAYOBJECT, VARARGIN)
            % returns the String containing the display of category and the
            % group of property names and values associated with that category.
            
            % Example :
            %
            % CategoryName
            %
            %    PropertyAlpha:   value
            %    PropertyBeta:    value
            %
            % DISPLAYOBJECT = The object of the component class
            %
            % VARARGIN = cell array containing the category names and the
            % property names.
            
            % Checking the condition that for each category name there
            % should at least be one property name associated with it.
            if mod((length(varargin)),2) > 0
                error(message('testmeaslib:DisplayFormatter:WrongArgumentsMustBeNameValuePairs'))
            end
            
            categoryHeader = '';
            
            %Getting all the Category Names
            categoryNames = varargin(1:2:end);
            
            %Getting all the Property Names
            propertyNames = varargin(2:2:end);
            
            %calculating the length of the longest property name.
            maxPropertyLength = max(cellfun(@length, [varargin{2:2:end}]));
            
            % For each category names get the values of all the property
            % names associated with that particular category and then
            % append it to the displayCategoryString
            for ii = 1:length(categoryNames)
                % Each category name start with 4 indent spaces followed by
                % extra line break, followed by property names and values.
                % Example:
                %     <4 Indent Spaces>CategoryName <\n\n>
                %
                categoryHeader = sprintf('%s%s%s\n\n',categoryHeader,...
                    internal.DisplayFormatter.CategoryIndent,...
                    categoryNames{ii});
                
                % rendering the values of property names and then
                % concatenating property names and property values text
                % to category header string.
                categoryHeader =  [categoryHeader internal.DisplayFormatter. ...
                    getPropertiesString(displayObject, propertyNames{ii}, maxPropertyLength)];
            end
        end
        
        function displayTable = getDisplayTable(displayObject, columnNames, columnProperties)
            % DISPLAYTABLE = GETDISPLAYTABLE(DISPLAYOBJECT, COLUMNNAMES,
            % COLUMNPROPERTIES) returns
            % the String containing the display of property names and its
            % values in a table format .
            %
            % DISPLAYOBJECT = the object of the component class
            %
            % COLUMNNAMES = cell array containing the column names
            %
            % COLUMNPROPERTIES =  cell array containing properties names.
            
            
            % cell array to store the property values corresponding to
            % property names.
            columnPropertiesValues = cell(1, 2);
            
            % getting property value for each column properties
            for ii = 1:length(columnProperties)
                columnPropertiesValues{ii} =  internal.DisplayFormatter.convertToCellArrayOfString(displayObject.(columnProperties{ii}));
                
            end
            
            % Creating whole table display using DispTable class and
            % getting it in text format.
            displayTable =  internal.DisplayFormatter...
                .getTableString(columnNames, columnPropertiesValues);
            
        end
        
        function footer = getDisplayFooter(displayObject)
            %  FOOTER = GETDISPLAYFOOTER(OBJ) Return the display footer for an object.
            %
            %  FOOTER = Returns the footer string for the object obj.
            %  The footer string is designed to reflect the appearance of
            %  the default MATLAB Class object display.
            
            hotlinks = feature('hotlinks');
            myclass = class(displayObject);
            
            if hotlinks
                methodsString = getString(message('testmeaslib:DisplayFormatter:Methods'));
                footer = sprintf('  <a href="matlab:methods(''%s'')">%s</a>\n\n', myclass, methodsString);
            else
                footer = sprintf('\n');
            end
            
        end
        
        function  displayTableObj = createDisplayTable(columnNames)
            %DISPLAYTABLEOBJ = CREATEDISPLAYTABLE(COLUMNNAMES) returns a
            %DispTable object and set the table indentation and the spacing
            %among the table columns
            %
            %COLUMNNAMES = cell array of columns names.
            
            displayTableObj = internal.DispTable();
            % Indent the table 4 blank spaces
            displayTableObj.Indent = internal.DisplayFormatter.TableIndent;
            
            % Indent the columns by 5 blank spaces
            displayTableObj.ColumnSeparator = internal.DisplayFormatter.TableColumnSpacing;
            
            % adding the name of the columns to the table.
            for ii =1:length(columnNames)
                displayTableObj.addColumn(columnNames{ii});
            end
            
        end
        
        function propsname = convertToCellArrayOfString(currProp)
            % PROPSNAME = CONVERTTOCELLARRAY(CURRPROP) covert every data
            % type in to cell array.
            %
            % PROPSNAME = cell array containing the formatted elements
            % depending upon the class of the property value.
            %
            % Example:
            % if cell array of strings
            % propsname = {''a'', ''b'', ''c''}
            %
            % else
            % propsname = {'0', '1', '2'}
            %
            % CURRPROP = Property values of the object.
            propsname = {};
            switch(lower(class(currProp)))
                case 'cell'
                    for ii=1:length(currProp)
                        if (ischar( currProp{ii}) == 1)
                            % This is done to enclosed each string
                            % element with an additional single quotes
                            str = sprintf('''%s''',currProp{ii});
                            propsname = [propsname str];
                        else
                            str = sprintf('%d',currProp{ii});
                            propsname = [propsname str];
                        end
                        
                    end
                case 'char'
                    propsname = {currProp};
                otherwise
                    % value is assumed to be numeric array                    
                    
                    % Turn entire thing into padded matrix
                    paddedStringMatrix = num2str(currProp);
                    
                    % Take the text from each row in the char matrix
                    % and put them as individual elements in a cell
                    % to make a cell array of strings
                    numRows = size(currProp, 1);
                    propsname = cell(1, numRows);
                    
                    for idx = 1:numRows
                        propsname{idx} = paddedStringMatrix(idx, :);
                    end                                                                
                    
            end
        end
    end
    
    methods (Static, Access = 'private')
        
        function propertiesString = getPropertiesString(displayObject , propertyNames, maxPropertyLength, propPretext)
            % PROPERTIESSTRING = GETPROPERTIESSTRING(OBJ , PROPERTYNAMES, PROPPRETEXT,LARGESTPROPLEN)
            % Return the string for the property display.
            %
            % PROPERTIESSTRING  String which mimics the default
            % property display for the displayObject specified by obj.
            %
            % PROPERTYNAMES Cell array containing the properties names to
            % be displayed.This argument also determines the order in which
            % properties are displayed.
            %
            % PROPPRETEXT String argument will insert a string before the
            % display of the property name for each property.  This is
            % useful when displaying the properties of a sub-object.
            %
            % MAXPROPERTYLENGTH Double containing the length of the
            % longest property name.
            
            if(nargin == 3)
                propPretext = '';
            end
            
            propertiesString = '';
            
            for ii = 1:length(propertyNames)
                propertyName = propertyNames{ii};
                %Getting the property values for each property name
                propertyValue =  internal.DisplayFormatter.propertyValueToString(displayObject.(propertyName));
                
                %calculating the additional blank spaces equal to the difference between
                %the length of the current property name and the longest
                %property name.
                spaces = blanks((maxPropertyLength - length(propertyName)));
                
                % Creating the property names display string
                % <7 indent spaces> <propPreText> <propertyName> : <spaces> <3 indent spaces> <propertyValue>
                % Example:
                % propertiesString =
                %        PropertyAlpha:   value
                %        PropertyBeta:    value
                propertiesString = sprintf('%s%s%s%s:%s%s%s\n', propertiesString,...
                    internal.DisplayFormatter.CategoryPropertyNameIndent,...
                    propPretext,...
                    propertyName,...
                    spaces,...
                    internal.DisplayFormatter.CategoryIndentPropertyNamesAndValues,...
                    propertyValue);
            end
            %One line break after the last property in the category and
            %the next category.
            propertiesString = sprintf('%s\n', propertiesString);
            
            %Replaces the '\' and '%' with escape characters within the
            %propertiesString
            propertiesString = strrep(propertiesString, '\', '\\');
            propertiesString = strrep(propertiesString, '%', '%%');
        end
        
        
        function displayTableString = getTableString(columnNames, columnProperties)
            % DISPLAYTABLESTRING = GETTABLESTRING(COLUMNPROPERTIES,COLUMNNAME)
            % returns the string which holds the formatted table display.
            %
            % COLUMNPROPERTIES = A cell array containing the column
            % properties values for each column
            %
            % COLUMNNAME = A cell array containing the names of the
            % headings of the columns.
            
            
            columnPropertiesValues = {};
            
            for ii=1:length(columnProperties)
                columnPropertiesValues = [columnPropertiesValues columnProperties{ii}'];
            end
            
            %Creating the disp table object and setting the indentation and
            %the header of the table
            displayTable = internal.DisplayFormatter.createDisplayTable(columnNames);
            
            %Adding a 3 space indent before each column properties values
            currentRowData = cellfun(@(val) [internal.DisplayFormatter.TableColumnPropertiesIndent val],...
                columnPropertiesValues, 'UniformOutput', false);
            
            % Adding row in the table
            for ii = 1:size(currentRowData, 1)
                displayTable.addRow(currentRowData(ii,:));
            end
            
            displayTableString = displayTable.getDisplayText();
            
            %One line break at the end of the table
            displayTableString = sprintf('%s\n', displayTableString);
            
            %Replaces the '\' and '%' with escape characters within the
            %displayTableString
            displayTableString = strrep(displayTableString, '\', '\\');
            displayTableString = strrep(displayTableString, '%', '%%');
        end
        
        
        function str = propertyValueToString( val )
			% STR = PROPVALTOSTRING( VAL ) returns the formatted string
			%
			% STR = String depending upon the class of value passed , the
			% string is formatted i.e.
			%
			% if char
			% str = 'abc'
			%
			% if cell array of strings
			% str ={ 'a' 'b' 'c'}
			%
			% if double
			% str = 1 
			%
			% if array of double 
			% str = [1 2 3 4]
			%
			% if array of logical 
			% str = [0 1 1 0]
			%
			% if function handle
			% str = @foo
			%
			% if cell array defining a callback, e.g. {@foo, arg1, arg2}
			% str = {m x n cell}
			%
			% if empty
			% str =[]
			%
			% However if the length of the array or cells exceed the length
			% of the Command Window , then they will be abbreviated by
			% showing the size and the class, e.g [m x n classOfArray]
			%
			% VAL = The Property value

			%Storing the size of the command window.
			commandWindowLength = get(0, 'CommandWindowSize');

			if(isobject(val))
				if(isscalar(val))
					% Ex: an HG handle
					str = class(val);
				else
					% Ex: an array of HG handles
					str = sprintf('[%d x %d %s]', size(val, 1), size(val, 2), class(val));
				end
				return;
			end

			switch lower(class(val))
				case 'cell'

					if( ~isempty(val) && isa(val{1},'function_handle') )
						% handles the case of a callback with arguments 
						% e.g. {@foo, arg1, arg2, ...}
						str = ['{' num2str(size(val,1)) ' x ' num2str(size(val,2)) ' ' class(val) '}'];

					else
						str = '';
						for ii=1:length(val)
							if(ii == 1)
							   str = '{'; 
							end
							if ischar(val{ii})
								str = sprintf('%s''%s'' ', str, val{ii});
							elseif isnumeric(val{ii}) || islogical(val{ii})
								str = sprintf('%s%d ', str, val{ii});
							else
								str = sprintf('%s%s ', str, strtrim(evalc('disp(val{ii})')));
							end
							if (ii == length(val))
								str = deblank(str);
								str = sprintf('%s}', str);
							end
						end

						% Handle the case when its empty
						if(isempty(str))
							str = '{}';
						end

						%Abbreviating the string to show only the
						%size and the name of the class
						if(length(str) >= commandWindowLength)
							str = ['{' num2str(size(val,1)) ' x ' num2str(size(val,2)) ' ' class(val) '}'];
						end
					end

				case 'char'
					str = sprintf('''%s''', val);

				case 'function_handle'
					str = strtrim(evalc('disp(val)'));

				otherwise
					if(~isempty(val))
						%if the value is double array
						value = arrayfun(@num2str, val , 'UniformOutput', false);
						if(length(value) > 1)
							str = '';
							for ii=1:length(value)
								if(ii == 1)
									str = '[';
								end
								str = sprintf('%s%s ', str, value{ii});
								if (ii == length(value))
									str = deblank(str);
									str = sprintf('%s]', str);
								end
							end
						else
							%If the val is double
							str = value{1};
						end
						%Abbreviating the string to show only the
						%size and the name of the class
						if(length(str) >= commandWindowLength)
							str ='';
							str = [str '[' num2str(size(val,1)) ' x ' num2str(size(val,2)) ' ' class(val) ']'];
						end
					else
						%if the val is empty
						str = sprintf('[]');
					end
			end
			
		end
		
    end
    
end
