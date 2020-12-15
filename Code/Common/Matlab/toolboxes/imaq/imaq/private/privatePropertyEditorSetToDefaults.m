function [ ] = privatePropertyEditorSetToDefaults( srcUDD, propNames, propValues, forIMAQTOOL )
%PRIVATEPROPERTYEDITORSETTODEFAULTS Used by property editor to set values of properties to their defaults.
%
%    [ERRORMSG PROPVALUES] = privatePropertyEditorSetToDefaults(SOURCEOBJ,
%    PROPERTYNAMES, PROPERTYVALUES) sets properties in PROPERTYNAMES of
%    object SOURCEOBJ to PROPERTYVALUES.
%
%    Copyright 2011-2012 The MathWorks, Inc.

if forIMAQTOOL
    % store current ROI
    vidObj = iatbrowser.Browser().currentVideoinputObject;
    roiBeforePropSet = vidObj.ROIPosition;
    wasPreviewing = iatbrowser.Browser().prevPanelController.isPreviewing();
end

set(srcUDD, propNames, propValues);

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
end

end

