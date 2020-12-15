classdef (Hidden) ConversionUtility < daq.internal.BaseClass
    %ConversionUtility This class is used by utility functions provided for
    %DigitalIO
    
    %Copyright 2012-2013 The MathWorks, Inc.
    
    properties (Constant = true)
        MAX_BITS_DOUBLE2INT = 52;
    end
    
    properties (Constant = true, Access = private)
        
        % Store as properties: faster lookup

        % There may be some (marginal) benefit to storing the most common
        % hex-values first (e.g. 0 and F).
        nibble_keys = '0123456789ABCDEF';

        lkeys = 16; % numel(nibble_keys);
        
        % Each nibble is length 4; each nibble describes 16 values
        nibble_values = logical(...
               [0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1;...
                0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1;...
                0 0 1 1 0 0 1 1 0 0 1 1 0 0 1 1;...
                0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1]'...
               );
        
    end
    
    methods (Hidden)
        function out = binaryVectorToDecimal(obj,binaryVector,varargin)
            % Handle optional arguments like BitOrder
            obj.handleBitOrderInput(varargin{:});
            
            obj.BinaryVectorArray = obj.flipIfNeeded(binaryVector);
            
            numRows = size(obj.BinaryVectorArray, 1);
            numCols = size(obj.BinaryVectorArray, 2);
            
            if numCols > obj.MAX_BITS_DOUBLE2INT
                out = uint64(zeros(numRows, 1));
            else
                out = zeros(numRows, 1);
            end
            
            for rowIndex = 1:numRows
                rowData = obj.BinaryVectorArray(rowIndex,:);
                out(rowIndex) = obj.rowBinaryVectorToDecimal(rowData,varargin{:});
            end
        end
        
        function out = binaryVectorToHex(obj,binaryVector,varargin)
            % Handle optional arguments like BitOrder
            obj.handleBitOrderInput(varargin{:});
            
            obj.BinaryVectorArray = obj.flipIfNeeded(binaryVector);

            numRows = size(obj.BinaryVectorArray, 1);

            out = cell(numRows, 1);
            
            % Handle optional arguments like BitOrder
            obj.handleBitOrderInput(varargin{:});
            
            for rowIndex = 1:numRows
                rowData = obj.BinaryVectorArray(rowIndex,:);
                out{rowIndex} = obj.rowBinaryVectorToHex(rowData,varargin{:});
            end
        end
        
        function out = decimalToBinaryVector(obj,decimalNumber,varargin)
            % Accept row or column based vectors
            if size(decimalNumber, 2) ~= 1
                decimalNumber = decimalNumber';
            end
            
            % decimalToBinaryVector works on integer datatypes also and
            % log2 does not work on them. Calculate minimum no.of bits
            % needed by finding the first one in the vector.
            %
            obj.DecimalNumber = decimalNumber;
            out = logical(bitget(max(obj.DecimalNumber),64:-1:1));
            obj.MinimumNumberOfBits = 64 - find(out,1,'first') + 1;
            
            % Compare to requested number of bits
            if nargin > 2
                obj.NumberOfBits = varargin{1};
            else
                obj.NumberOfBits = obj.MinimumNumberOfBits;
            end
            
            % Handle optional arguments like BitOrder
            obj.handleNumBitsAndBitOrderInput(obj.NumberOfBits, varargin{2:end});
            
            % Prepare output array
            numRows = size(decimalNumber, 1);
            out = zeros(numRows, obj.NumberOfBits);
            
            for rowIndex = 1:numRows
                rowData = decimalNumber(rowIndex,:);
                out(rowIndex,:) = obj.rowDecimalToBinaryVector(rowData,obj.NumberOfBits,varargin{2:end});
            end
            
            out = obj.flipIfNeeded(out);
        end
        
        % Uses a look-up table to create a correspondence between string
        % representations of hexadecimal (input) and binary (output)
        % numbers.
        function out = hexToBinaryVector(obj, hexString, varargin)
            obj.HexCellArray = hexString;
            numRows = size(obj.HexCellArray, 1);
            initialNumBits = max(cellfun(@length, obj.HexCellArray)) * 4;
            
            obj.MinimumNumberOfBits = initialNumBits;
            if nargin > 2
                obj.NumberOfBits = varargin{1};
            end
            
            if nargin > 3
                obj.BitOrder = varargin{2};
            end
            
            if ~isempty(obj.NumberOfBits)
                maxNumBits = max(initialNumBits, obj.NumberOfBits);
            else
                maxNumBits = initialNumBits;
            end
            
            % Use cellfun instead of a for-loop
            % Note: if function is not nested, it will require multiple
            % inputs. One possible way to maintain the existing form is to
            % use an anonymous function & currying.
            binaryCell = cellfun(@rowHexToBinaryVector_nested, obj.HexCellArray, 'UniformOutput', false);
            binaryVector = [binaryCell{:}]';
            
            % Adjust number of bits
            isFlipped = false;
            if nargin > 3
                isFlipped = strcmpi(varargin{2}, 'lsbfirst');
            end
            
            obj.MinimumNumberOfBits = maxNumBits - find(any(binaryVector,1), 1, 'first') + 1;
            
            % Force a new validation against the re-calculated minimum
            % number of bits
            numBits = obj.MinimumNumberOfBits;
            if nargin > 2
                if ~isempty(varargin{1})
                    numBits = varargin{1};
                end
           end
           
           % Return flipped data (LSBFirst)
           if ~isFlipped
               out = binaryVector( : , maxNumBits - numBits + 1:end);
           else
               out = binaryVector( : , maxNumBits:-1:maxNumBits-numBits+1);
           end
           
           % Nested helper function: converts a string of hexadecimal
           % characters into a string of binary characters using look-up
           % table.
           % Uses the following outer-function vars: obj, maxNumBits
           function out = rowHexToBinaryVector_nested(hexCharacters)

               % This operation is now performed in set.HexArray
               % Using upper eliminates checking for 'a'-'f'
               % hexCharacters = upper(hexCharacters);
               numCharacters = numel(hexCharacters);
               indices = zeros(1, numCharacters);
               
               % Possible improvement: use arrayfun or bsxfun to
               % avoid coding a loop at all (might permit JIT opt.)
               for i=1:obj.lkeys,
                   % strfind is slightly faster than find
                   indices(strfind(hexCharacters, obj.nibble_keys(i))) = i;
                   % indices(hexCharacters == obj.nibble_keys(i)) = i;
               end

               % A non-zero entry indicates that one of the characters is
               % not hexadecimal.
               if all(indices)
                    out = (obj.nibble_values(indices, :))';
                    out = out(:);
                    out_len = length(out);
                    % Return only the bits the user requested
                    if (maxNumBits <= out_len)
                        out = out((end-maxNumBits+1):end);
                    else
                        out = [false(maxNumBits-out_len, 1); out];
                    end
               else
                   obj.localizedError('daq:general:invalidHexCharacters');
               end
           end
        end
        
    end
    
    methods (Access = private)
        function out = rowBinaryVectorToDecimal(obj,varargin)
            
            %Flip binary vector if needed
            binaryVector = varargin{1};
            numBits = numel(binaryVector);
            
            if numBits > obj.MAX_BITS_DOUBLE2INT
                daq.internal.ClassManager.getInstance.warnOnBinaryVectorGreaterThan52bits();
                out = uint64(0);
                % When the number is greater than 52-bits, double
                % operations like pow2 and sum will not work. Need to use
                % bit logic operations to get the weighted sum of the
                % binary vector.
                %
                for i = 1:numBits
                    out = bitset(out,i,binaryVector(numBits - i + 1));
                end
            else
                % Calculate the decimal equivalent by multiplying binary
                % vector with correct decimal weights and adding them up.
                out = sum(binaryVector .* pow2(size(binaryVector,2)-1:-1:0));
            end
            
        end
        
        function out = rowBinaryVectorToHex(obj,varargin)
            
            %Flip binary vector if needed
            binaryVector = varargin{1};
            
            % Calculate the number of hex characters needed for the
            % conversion.
            nOut = ceil(numel(binaryVector)/4);
            
            % If the binary vector is not provided as sets of 4, pad extra
            % zeros
            corr = rem(numel(binaryVector),4);
            if corr
                correctBinaryVector = [ zeros(1,4-corr) binaryVector];
            else
                correctBinaryVector = binaryVector;
            end
            
            % Get decimal equivalent of each nibble for the binary vector
            nibble = getNibble(1:nOut);
            
            % Convert each nibble to it's equivalent hexadecimal number's
            % ASCII representation. Number 0 to 9 can be converted to '0'
            % and '9' in ASCII by adding 48. Whereas number 10 to 16 can be
            % converted to 'A' and 'F' in ASCII by adding 55. So if the
            % number is greater than 9, add 55 else add 48. Add these two
            % and then get the character representation of ASCII.
            % For Ex for [0 0 0 1 1 0 1 0]
            % nibbles = [ 1 10]
            % out = char([48+1 55+10]) = '1A'
            out = char((( nibble + 55) .* double(nibble>9) ) ... % Add 55 for 10-16
                + ((nibble + 48) .* double(nibble<=9)));  % Add 48 for 0-9
            
            % Return the decimal number for the specified starting
            % hexadecimal position.
            function result = getNibble(iHexCharacters)
                result = zeros(1,numel(iHexCharacters));
                for loop = 1:numel(iHexCharacters)
                    endIndex = iHexCharacters(loop) * 4;
                    result(loop) = sum(correctBinaryVector(endIndex-3:endIndex) .* pow2(3:-1:0));
                end
            end
        end
        
        function out = rowDecimalToBinaryVector(obj,varargin)
            
            decimalNumber = uint64(varargin{1});
            
            % Convert to binary vector by getting each bit in correct order.
            out = logical(bitget(decimalNumber,64:-1:1));
            
            % Pad or cut according to the number of bits needed
            if obj.NumberOfBits < 64
                out = out((end-obj.NumberOfBits+1):end);
            else
                out = [zeros(1,obj.NumberOfBits-64) out];
            end
        end
        
    end
    
    methods ( Access = private )
        function result = flipIfNeeded(obj,input)
            
            if obj.Flip
                result = fliplr(input);
            else
                result = input;
            end
        end
        
        function handleNumBitsAndBitOrderInput(obj,varargin)
            % Set the defaults
            obj.NumberOfBits = [];
            obj.BitOrder = daq.BitOrder.MSBFirst;
            
            if nargin >= 2
                obj.NumberOfBits = varargin{1};
            end
            
            if nargin >= 3
                obj.BitOrder = varargin{2};
            end
        end
        
        function handleBitOrderInput(obj,varargin)
            % Set the defaults
            obj.BitOrder = daq.BitOrder.MSBFirst;
            
            if nargin >= 2
                obj.BitOrder = varargin{1};
            end
        end
        
    end
    
    properties( Access = private )
        
        %MinimumNumberOfBits A double representing the minimum number of bits
        %required for conversion. Used in *ToBinaryVector functions.
        MinimumNumberOfBits
        
        %MaximumNumberOfBits A double representing the maximum number of bits
        %required for conversion. Used in *ToBinaryVector functions.
        MaximumNumberOfBits
        
        %DecimalNumber A uint64 representing the decimal number input
        DecimalNumber
        
        %NumberOfBits A double representing the number of bits specified by the
        %user
        NumberOfBits
        
        %BitOrder A string enumeration represents the order specified by the
        %user. It can be 'MSBFirst' or 'LSBFirst'
        BitOrder
        
        %Flip Boolean, BitOrder == LSBFirst
        Flip
        
        %BinaryVector A validated binary vector array
        BinaryVectorArray
    end
    
    properties (Access = private, Transient)
        %HexCellArray A character string representing the hexadecimal number input
        HexCellArray
    end
    
    methods
        
        function set.MinimumNumberOfBits(obj,newValue)
            
            % If the input is 0, change the number of bits needed to
            % represent as 1
            if isempty(newValue)
                obj.MinimumNumberOfBits = 1;
            else
                obj.MinimumNumberOfBits = newValue;
            end
            
        end
        
        function set.HexCellArray(obj,newValue)
            % Accept regular and cell arrays
            if ~iscell(newValue)
                try
                    newValue = cellstr(newValue);
                catch e %#ok<NASGU>
                    obj.localizedError('daq:general:invalidHexCharacters');
                end
            end
            
            % Accept row or column based vectors
            numRows = size(newValue, 1);
            numCols = size(newValue, 2);
            if numCols ~= 1
                if numRows == 1
                    newValue = newValue';
                    numRows = size(newValue, 1);
                    numCols = size(newValue, 2);
                else
                    MException(message('daq:general:needColumnBasedVector')).throwAsCaller;
                end
            end
            
            % Eliminate future checking for lower-case entries.
            newValue = upper(newValue);
            
            % strfind is fast, but strncmp is faster
            % check first 2 characters

            idx_prefixed = strncmp(newValue, '0X', 2);
                        
            % Remove '0X' or '0x' as prefixes _only_.
            if ~isempty(idx_prefixed)
                % Using strrep by itself is inadequate: an invalid input
                % such as '00xabcdef' will become a valid one.
                % Only correct for prefixed entries:
                idx_valid = 1:numel(newValue);
                % Prefixed entries are a subset of _all_ valid entries
                % Select/Isolate these entries
                entries_fix = newValue(idx_valid(idx_prefixed));
                % Remove the prefix characters in these entries only and 
                % then recopy the entries into the locations they were
                % obtained from
                newValue(idx_valid(idx_prefixed)) = strrep(entries_fix, '0X', '');
                
            end
           
            obj.HexCellArray = newValue;
        end
        
        function set.BinaryVectorArray(obj,newValue)
            % Check for valid binary vector
            if ~(isnumeric(newValue) || islogical(newValue))  || ...
                    any(any((newValue ~= 0 & newValue ~= 1)))
                obj.localizedError('daq:general:invalidBinaryVector');
            end
            
            obj.BinaryVectorArray = newValue;
        end
        
        function set.BitOrder(obj,newValue)
            
            % Check for valid bit order.
            if ~ischar(newValue) && ~isa(newValue,'daq.BitOrder')
                obj.localizedError('daq:general:invalidOrder');
            end
            
            newValue = char(newValue);
            
            % Convert to lower to make it case correcting
            switch lower(newValue)
                case 'lsbfirst'
                    obj.BitOrder = daq.BitOrder.setValue('LSBFirst');
                case 'msbfirst'
                    obj.BitOrder = daq.BitOrder.setValue('MSBFirst');
                otherwise
                    obj.BitOrder = daq.BitOrder.setValue(newValue);
            end
            
            obj.Flip = (obj.BitOrder == daq.BitOrder.LSBFirst);
        end
        
        function set.DecimalNumber(obj,newValue)
            if isempty(newValue)
                obj.localizedError('daq:general:invalidDecimalNumber');
            end
            
            if size(newValue, 2) ~= 1
                obj.localizedError('daq:general:needColumnBasedVector');
            end
            
            if iscell(newValue)
                obj.localizedError('daq:general:invalidDecimalNumber');
            end
            
            % Decimal number should be positive integer scalar.
            if ~(any(daq.internal.isNumericNum(newValue))) || ~(any(isreal(newValue))) ||...
                    any(newValue < 0)  || ~any(isequal(floor(newValue),newValue))
                obj.localizedError('daq:general:invalidDecimalNumber');
            end
            
            % decimalToBinaryVector accepts all data types -
            % doubles,uint8,uint64 etc. Convert to a uint64 number to unify
            % code execution later.
            obj.DecimalNumber = uint64(newValue);
        end
        
        function set.NumberOfBits(obj,newValue)
            
            % If number of bits is specified as empty, use minimum number
            % of bits needed for conversion.
            if isempty(newValue)
                obj.NumberOfBits = obj.MinimumNumberOfBits;
                return;
            end
            
            % Number of bits should be positive non-zero integer scalar.
            if ~(daq.internal.isNumericNum(newValue)) || ~isscalar(newValue) ...
                    || (newValue <= 0) || ~isequal(floor(newValue),newValue)
                obj.localizedError('daq:general:invalidNumberOfBits');
            end
            
            % Error out if number of bits specified is less than the minimum number
            % of bits needed to represent the converted value
            if newValue < obj.MinimumNumberOfBits %#ok<*MCSUP>
                obj.localizedError('daq:general:insufficientBitsToRepresentNumber');
            end
            
            obj.NumberOfBits = newValue;
        end
    end
    
    methods(Access=protected)
        function resetImpl(obj) %#ok<MANU>
            %We are inheriting from daq.internal.BaseClass to use its methods
            %so need to define this function, however since we do not need
            %any special destruction code for the utility functions, this is
            %an empty implementation
        end
    end
    
end