function setParaObjValue(obj,hObj,varargin)

% retrieves the parameter value corresponding to the object parameter
pVal = obj.(hObj.UserData);

switch hObj.Style
    case 'checkbox'
        % case is a checkbox object
        if length(pVal) == 3
            hObj.Value = pVal(3) < 0;
        else
            hObj.Value = pVal;
        end
    
    case 'edit'
        % case is an editbox object
        
        % sets the editbox string (based on parameter value type)
        if length(pVal) > 1
            % case is random value
            if (length(pVal) == 2) || (pVal(end) < 0)
                hObj.String = num2str(pVal(varargin{1}));
            else
                hObj.String = num2str(pVal(end));                
            end
            
        else
            % case is deterministic values
            if isnumeric(pVal)
                % case is numeric value
                hObj.String = num2str(pVal);
            elseif ischar(pVal)
                % case is string value
                hObj.String = pVal;
            end
        end
           
    
    case 'popupmenu'
        % case is a popupmenu object
        hObj.Value = find(strcmp(hObj.String,pVal));

end