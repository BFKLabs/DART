% --- sets up the title/label font data structs --- %
function Font = setupFontStruct(varargin)

% initialises the default font struct fields
Font = struct('FontName', 'Helvetica', ...
              'FontWeight', 'bold', ...
              'FontAngle', 'normal', ...
              'FontUnits', 'points', ...
              'Color', 'k', ...
              'FontSize', 20);

% check to see the valid number of arguments have been input%
if (nargin == 0)
    % no inputs, so exit
    return
elseif (mod(nargin,2) == 0)
    % if there are an even number of input arguments, then set the fields
    % of the font struct
    nField = nargin/2;
    for i = 1:nField
        % retrieves the field/value indices within the input argument array
        [fStr,fVal] = deal(varargin{(i-1)+1},varargin{2*i});
        if (isfield(Font,fStr))
            if (isnumeric(fVal))
                % if the field is valid, then update it
                eval(sprintf('Font.%s = %i;',fStr,fVal))                
            else
                % if the field is valid, then update it
                eval(sprintf('Font.%s = %s;',fStr,fVal))
            end
        end
    end
else
    % otherwise output an error
    eStr = 'Error! Must have an even number of input arguments.';
    waitfor(errordlg(eStr,'Font Struct Setup Error','modal'))
end
          