% --- Checks to see that an input value from an edit box is valid. The ----
%     input value is valid if it is numerical and within the defined limits
function [ok,eStr] = chkEditValue(nwVal,valLim,chkInt,varargin)
% ok         indicates if the new value is valid (1 = valid, 0 otherwise)
% nwVal      new values from the edit box
% valLim     limits of that the new value can take
% chkInt     boolean variable to check whether the new value is an integer

% initialises the boolean variable
ok = 1;
eStr = [];
del = 1e-6;
isIntLim = mod(valLim,1)==0;

% checks to see if the input value is valid. if it is not, then return a
% value of ok = 0 (i.e., an error has occured)
if isnan(nwVal)
    % the new value is not a numerical value
    ok = 0;
    eStr = 'Input value must be numeric.';
    
elseif valLim(1) == valLim(2)
    if nwVal ~= valLim(1)
        ok = 0;
        eStr = sprintf('Input value must equal %i.',valLim(1));
    end
    
elseif nwVal < (valLim(1)-del)
    % input value is less than lower bound
    ok = 0;
    
    % check the other limit so as to set the error string
    if isinf(valLim(2))
        if chkInt || isIntLim(1)
            eStr = sprintf(['Input value must be greater than ',...
                            'or equal to %i.'],valLim(1));
        else
            eStr = sprintf(['Input value must be greater than ',...
                            'or equal to %.3f.'],valLim(1));
        end
    else
        if chkInt || all(isIntLim)
            eStr = sprintf('Input value must be between %i and %i.',...
                                            valLim(1),valLim(2));        
        else
            eStr = sprintf('Input value must be between %.3f and %.3f.',...
                                            valLim(1),valLim(2));        
        end
    end
    
elseif nwVal > (valLim(2)+del)
    % input value is greater than upper bound
    ok = 0;
    
    % check the other limit so as to set the error string
    if isinf(valLim(1))
        if chkInt || isIntLim(1)
            eStr = sprintf(['Input value must be less than or ',...
                            'equal to %i.'],valLim(2));
        else
            eStr = sprintf(['Input value must be less than or ',...
                            'equal to %.3f.'],valLim(2));
        end
    else
        if chkInt || (all(isIntLim))
            eStr = sprintf('Input value must be between %i and %i.',...
                                            valLim(1),valLim(2));        
        else        
            eStr = sprintf('Input value must be between %.3f and %.3f.',...
                                            valLim(1),valLim(2));        
        end
    end

elseif (mod(nwVal,1) ~= 0) && chkInt
    % the input value is not an integer
    ok = 0;
    eStr = 'Input value must be an integer.';
    
elseif nargin > 3
    % parses the input argument
    p = inputParser;
    addParameter(p,'exactVal',[],@isnumeric);
    addParameter(p,'exactMlt',[],@isnumeric);
    parse(p,varargin{:});
    
    % determines if the input value matches any of the value in the exact
    % value array (if provided)
    if ~isempty(p.Results.exactVal)
        if ~any(nwVal == p.Results.exactVal)
            % if not, then flag that an error has occurred
            [ok,eVal] = deal(0,p.Results.exactVal);
            
            % sets up the error string based on the number of exact values
            switch length(eVal)
                case 1
                    % case is there is only one exact value
                    eStr = sprintf('The input value can only be %i.',eVal);
                    
                case 2
                    % case is there are 2 exact values
                    eStr = sprintf(['The input value must be either ',...
                                    '%i or %i.'],eVal(1),eVal(2));
                                
                otherwise
                    % case is there is more than 2 exact values
                    vStr = join(arrayfun(@num2str,eVal(1:end-1),'un',0),', ');
                    eStr = sprintf(['The input value must take a value ',...
                                    'of %s, or %i.'],vStr{1},eVal(end));            
            end
        end
    end  
    
    % determines if the input value is a multiple of the pMlt (if provided)
    if ~isempty(p.Results.exactMlt)
        if mod(nwVal,p.Results.exactMlt) ~= 0
            % if not, then flag that an error has occurred
            [ok,pMlt] = deal(0,p.Results.exactMlt);
            
            % case is there is only one exact value
            eStr = sprintf(['The input value must be a ',...
                            'multiple of %i.'],pMlt);            
        end
    end
end

% if an error has occured, then show the error dialog box
if ~ok && (nargout == 1)
    eStrF = sprintf('Error! %s',eStr);
    waitfor(errordlg(eStrF,'Input Value Error','modal'));
end