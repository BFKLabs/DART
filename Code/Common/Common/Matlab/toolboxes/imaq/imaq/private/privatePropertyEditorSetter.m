function [errorMsg] = privatePropertyEditorSetter(sourceObj, property, newPropertyValue, forIMAQTOOL)
%PRIVATEPROPERTYEDITORSETTER Used by property editor to set values of properties.
%
%    [ERRORMSG PROPVALUES] = PRIVATEPROPERTYEDITORSETTER(SOURCEOBJ,
%    PROPERTY, NEWPROPERTYVALUE) sets PROPERTY of object SOURCEOBJ to
%    NEWPROPERTYVALUE. If the set fails, then ERRORMSG contains the error
%    message.
%
%    Copyright 2009-2013 The MathWorks, Inc.

import com.mathworks.toolbox.testmeas.propertyeditor.Constraint
try
    % Contains error string if set errors, empty otherwise.
    errorMsg = '';
    if forIMAQTOOL
        vidObj = iatbrowser.Browser().currentVideoinputObject;
        
        if (isempty(vidObj) || ~isvalid(vidObj))
            % Listener probably called during cleanup.
            return;
        end
        
        % store current ROI
        roiBeforePropSet = vidObj.ROIPosition;
    else
        if (isempty(sourceObj) || ~isvalid(sourceObj))
            % Listener probably called during cleanup.
            return;
        end
    end
    
    numericValue = newPropertyValue;
    
    % newValue of the property is coming from a Widget. In some cases this
    % property needs to be processed before it can be send to set of the MATLAB
    % object.
    if property.isNumeric() && ischar(newPropertyValue)
        [numericValue success] = str2num(newPropertyValue); %#ok<ST2NM>
        
        if (~success)
            % there was an exception converting from string to number. clearly
            % the user entered an invalid value. create a generic error
            % message.
            errorMsg = getString(message('imaq:propertyeditor:invalidSet', char(property.getName)));
        end
    end
    if forIMAQTOOL
        try
            b = iatbrowser.Browser();
            wasPreviewing = b.prevPanelController.isPreviewing();
        catch %#ok<CTCH>
            wasPreviewing = false;
        end
    end    
    % do not set if there was an error before this.
    if isempty(errorMsg)
        try
            set(sourceObj, char(property.getName), numericValue);
        catch exc
            errorMsg = exc.message;
        end
    end
    
    if forIMAQTOOL
        roiAfterPropSet = vidObj.ROIPosition;
        
        if ~isequal(roiBeforePropSet, roiAfterPropSet)
            b=iatbrowser.Browser();
            b.acqParamPanel.updateROIPanel();
            if wasPreviewing
                b.prevPanelController.stopPreview(false);
                b.prevPanelController.startPreview(false);
            end
        end
        
        acqPanel = com.mathworks.toolbox.imaq.browser.acquisitionParameters.AcquisitionParametersPanel.getInstance;
        propertyEditor = acqPanel.getFormatNodePanel.getPropertyEditor;
    else
        inspector = com.mathworks.toolbox.imaq.SourceInspector.getInstance();
        propertyEditor = inspector.getPropertyEditor();
    end
    
    % If the property editor is closed, simply return
    if isempty(propertyEditor)
        return
    end
        
    props = propertyEditor.getProperties();
    
    
    % Get the actual value of the properties and update the property editor.
    % The actual value of the property might not be the same as the value we
    % just set even when set is successful. It is therefore important to get
    % the actual value of the property regardless of whether set passed or
    % failed.
    for idx = 0 : props.size - 1
        aprop = props.get(idx);
        propname = char(aprop.getName);
        curValue = get(sourceObj, propname);
        constraint = aprop.getConstraint();
        
        % Properties with custom getters can return current values that are
        % outside of the range of allowable values for the property.  Until we
        % provide instance properties for adaptors, we'll need to just skip
        % these updates.
        if constraint == Constraint.ENUM
            constraintValues = aprop.getConstraintValues().getAllConstants();
            if ~constraintValues.contains(curValue)
                continue;
            end
        elseif constraint == Constraint.BOUND
            constraintValues = aprop.getConstraintValues();
            lowerBound = double(constraintValues.getLowerBound());
            upperBound = double(constraintValues.getUpperBound());
            if ( any(curValue < lowerBound) || any(curValue > upperBound) )
                continue;
            end
        end
        aprop.setValue(curValue);
        drawnow;
    end
catch globalExcp
    errorMsg = globalExcp.message;
end










