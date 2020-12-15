function propLists = privateConvertVideoSourcePropinfoToList(videoSourceObject)
% PRIVATECONVERTVIDEOSOURCEPROPINFOTOLIST Converts propinfo structure of a
% video source object to a list(java.util.List) of Property (testmeas.property.editor.Property)
% objects. Only device specific properties are returned to the user.
%
% This function is used by the property editor to convert propinfo structure
% of the video source object list of propeties.

% Copyright 2008-2013 The MathWorks, Inc.

pInfoStruct = propinfo(videoSourceObject);
fieldNames = fieldnames(pInfoStruct);

import com.mathworks.toolbox.testmeas.propertyeditor.*;
import java.util.*;

% create the output array of properties
propLists = ArrayList();

for index = 1:length(fieldNames)
    afieldName = fieldNames{index};
    field = pInfoStruct.(afieldName);
    
    % we are only intereseted in device specific properties.
    if(field.DeviceSpecific == 0)
        continue;
    end
    
    aProp = Property;
    aProp.setName(afieldName);
    
    % Set property type
    type = field.Type;
    switch(lower(type))
        case 'string'
            aProp.setType(PropertyType.STRING);
        case 'double'
            aProp.setType(PropertyType.DOUBLE);
        case 'integer'
            aProp.setType(PropertyType.INTEGER);
    end
    
    % Moving setValue, setDefaultValue & setMatrix below setType() - g909619
    aProp.setValue(get(videoSourceObject, afieldName));
    aProp.setDefaultValue(field.DefaultValue);
    aProp.setMatrix(videoSourceObject.isArrayProperty(afieldName));
    
    % Set constraint and constraint value
    constraint = field.Constraint;
    propinfoConstraintValues = field.ConstraintValue;
    switch(lower(constraint))
        case 'bounded'
            % do not show empty properties. see g456131
            if(propinfoConstraintValues(1) == propinfoConstraintValues(2))
                continue;
            end
            
            aProp.setConstraint(Constraint.BOUND);
            
            if(aProp.getType() == PropertyType.DOUBLE)
                boundedConstraintValue = BoundedConstraintValues.createDoubleBoundedConstraintValue...
                    (propinfoConstraintValues(1), propinfoConstraintValues(2));
            elseif(aProp.getType() == PropertyType.INTEGER)
                boundedConstraintValue = BoundedConstraintValues.createLongBoundedConstraintValue...
                    (propinfoConstraintValues(1), propinfoConstraintValues(2));
            end
            
            aProp.setConstraintValues(boundedConstraintValue);
            
            if(any(isinf(propinfoConstraintValues)))
                aProp.setIsInfinityValid(true);
            end
        case 'enum'
            aProp.setConstraint(Constraint.ENUM);
            
            enumConstValues = EnumConstraintValues;
            enumConstValues.setAllConstants(field.ConstraintValue);
            
            aProp.setConstraintValues(enumConstValues);
        case 'none'
            aProp.setConstraint(Constraint.NONE);
            aProp.setConstraintValues(ConstraintValues);
        otherwise
            assert(false, 'unexpected constraint');
    end
    
    % Set read only status
    readOnly = field.ReadOnly;
    switch(lower(readOnly))
        case 'always'
            aProp.setReadStatus(ReadStatus.READ_ONLY);
        case 'whileRunning'
            aProp.setReadStatus(ReadStatus.WHILE_RUNNING);
        case 'never'
            aProp.setReadStatus(ReadStatus.WRITABLE);
    end
    
    % Set help
    try
        vidObj = videoSourceObject.Parent;
        actualSource = getSource(vidObj.Source, videoSourceObject.SourceName);
        help = imaqhelp(actualSource, afieldName);
        aProp.setHelp(help);
    catch exc %#ok<NASGU>
        assert(false, sprintf('imaqhelp failed for property %s, source %s of video input %s', afieldName, videoSourceObject.SourceName, videoSourceObject.Parent.Name));
    end
    
    propLists.add(aProp);
end

    function actualSource = getSource(sources, name)
        % returns source with SourceName 'name' contained in sources
        for srcIdx = 1 : length(sources)
            if(strcmpi(sources(srcIdx).SourceName, name))
                actualSource = sources(srcIdx);
                break;
            end
        end
    end
end

