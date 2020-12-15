%KMLDocument Construct KML document object
%
%       FOR INTERNAL USE ONLY -- This class is intentionally undocumented
%       and is intended for use only within other toolbox classes and
%       functions. Its behavior may change, or the class itself may be
%       removed in a future release.
%
%   The KMLDocument class constructs an object to represent and write KML
%   elements to a file. The documentation for KML may be found at
%   https://developers.google.com/kml/documentation/kmlreference
%
%   KMLDocument properties:
%      DocumentName - Name of document
%      Description  - Description for feature
%      Name         - Label for feature
%      Icon         - Icon filename for feature
%      IconScale    - Scale of icon
%      Color        - Color of icon and line
%      Width        - Width of line
%      Camera       - Virtual camera for scene
%      LookAt       - Virtual camera for feature
%      AltitudeMode - Altitude interpretation
%
%   KMLDocument methods:
%      KMLDocument   - Construct KML document object
%      addAddress    - Add address or addresses to KML document
%      addFeature    - Add feature or features to KML document
%      addMultiPartFeature - Add multi-part feature(s) to KML document
%      write         - Write KML document to disk

% Copyright 2012-2013 The MathWorks, Inc.

classdef KMLDocument < handle
    
    properties (GetAccess = 'public', SetAccess = 'public', Dependent)
        %DocumentName Name of document
        %
        %   DocumentName is a string indicating the name of the document.
        %   The name appears as a text string in the viewer as the label
        %   for the document.
        DocumentName
        
        %FolderName Name of folder
        %
        %   FolderName is a string indicating the name of the folder
        %   containing the features. If unspecified, the folder is the
        %   document.
        FolderName
    end
    
    properties (Access = 'public')   
        %Description Description for feature
        %
        %   Description is a string or cell array of strings that specifies
        %   the contents to be displayed in the feature's description
        %   tag(s). The description appears in the description balloon when
        %   the user clicks on either the feature name in the Google Earth
        %   Places panel or clicks the placemark icon in the viewer window.
        Description 
        
        %Name Label for feature
        %
        %   Name is a string or cell array of strings which specifies a
        %   name displayed in the viewer as the label for the feature.
        Name
        
        %Icon Icon filename for feature
        %
        %   Icon is a string or cell array of strings which specifies a
        %   custom icon filename.  If the icon filename is not in the
        %   current folder, or in a folder on the MATLAB path, specify a
        %   full or relative pathname. The string may be an Internet URL.
        %   The URL must include the protocol type.
        Icon
        
        %IconScale Scale of icon
        %
        %   IconScale is a positive numeric scalar or vector which
        %   specifies a scaling factor for the icon.
        IconScale
        
        %Color Color of feature
        %
        %   Color is a string or cell array of strings that specify the
        %   alpha, red, green, blue color value of the icon or line. The
        %   color string is a KML color value: [alpha blue green red] in
        %   lower case hex. Color and opacity (alpha) values are expressed
        %   in hexadecimal notation. The range of values for any one color
        %   is 0 to 255 (00 to ff).
        Color
        
        %Width Width of line
        %
        %   Width is a positive numeric scalar or vector that specifies the
        %   width of the line in pixels. If unspecified, the width is 1.
        Width
        
        %LookAt Virtual camera for feature
        %
        %   A geopoint vector that defines the virtual camera that views
        %   the points or lines. The value specifies the view in terms of
        %   the point of interest that is being viewed. The view is defined
        %   by the fields of the geopoint vector, outlined in the table
        %   below. LookAt is limited to looking down at a feature, you can
        %   not tilt the virtual camera to look above the horizon into the
        %   sky.
        % 
        %   Property     
        %   Name       Description                     Data Type
        %   ---------  ---------------------------     ---------
        %   Latitude   Latitude of the point the       Scalar double
        %              camera is looking at in degrees
        % 
        %   Longitude  Longitude of the point the      Scalar double
        %              camera is looking at in degrees 
        % 
        %   Altitude   Altitude of the point the       Scalar numeric
        %              camera is looking at in meters  default: 0
        %              (optional)   
        % 
        %   Heading    Camera direction (azimuth)      Scalar numeric
        %              in degrees (optional)           [0 360], default: 0
        % 
        %   Tilt       Angle between the direction of  Scalar numeric
        %              the LookAt position and the     [0 90], default: 0
        %              normal to the surface of the
        %              Earth (optional)               
        % 
        %   Range      Distance in meters from the     Scalar numeric
        %              point to the LookAt position    
        % 
        %   AltitudeMode 
        %              Specifies how the altitude is   String with value:
        %              interpreted for the LookAt      'absolute',
        %              point (optional)                'clampToGround', 
        %                                   (default) 'relativeToGround'
        LookAt
        
        %Camera Virtual camera for scene
        %
        %   Camera is a geopoint vector that defines the virtual camera
        %   that views the scene. The value defines the position of the
        %   camera relative to the Earth's surface as well as the viewing
        %   direction of the camera. The camera position is defined by the
        %   fields of the geopoint vector, outlined in the table below. The
        %   camera value provides full six-degrees-of-freedom control over
        %   the view, so you can position the camera in space and then
        %   rotate it around the X, Y, and Z axes. Most importantly, you
        %   can tilt the camera view so that you're looking above the
        %   horizon into the sky.
        %
        %   Property     
        %   Name       Description                     Data Type
        %   ---------  ---------------------------     ---------
        %   Latitude   Latitude of the eye point       Scalar double
        %              (virtual camera) in degrees
        % 
        %   Longitude  Longitude of the eye point      Scalar double
        %              (virtual camera) in degrees 
        % 
        %   Altitude   Distance of the camera from     Scalar numeric
        %              the Earth's surface, in meters 
        % 
        %   Heading    Camera direction (azimuth)      Scalar numeric
        %              in degrees (optional)           [0 360], default 0
        % 
        %   Tilt       Camera rotation in degrees      Scalar numeric
        %              around the X axis (optional)    [0 180] default: 0
        % 
        %   Roll       Camera rotation in degrees      Scalar numeric
        %              around the Z axis (optional)    default: 0
        % 
        %   AltitudeMode 
        %              Specifies how camera altitude   String with value:
        %              is interpreted. (optional)      'absolute',
        %                                              'clampToGround',
        %                                    (default) 'relativeToGround'
        Camera
        
        %AltitudeMode Altitude interpretation
        %
        %   AltitudeMode is string or cell array of strings that specify
        %   how altitude values are interpreted. Permissible values are
        %   'absolute', 'clampToGround', and 'relativeToGround'.
        AltitudeMode
    end
        
    properties(SetAccess='private', GetAccess='private')
        DOM = []
        DocumentElement = []
        FolderElement = []
        pDocumentName = ''
        pFolderName = ''
        UseLineStyle = false
        UseDefaultName = false
    end
    
    methods

        function kml = KMLDocument(name)
        %KMLDocument Construct KML document object
        %
        %   kml = map.internal.KMLDocument() constructs a default KML
        %   document object.
        %
        %   kml = map.internal.KMLDocument(name) constructs a KML object
        %   and sets the DocumentName to name.

            % Create the XML DOM and the XML DocumentElement.
            [kml.DOM, kml.DocumentElement] = createDocument;
            
            % Assign documentName to input if supplied.
            if exist('name', 'var')
                documentName = name;
            else
                documentName = '';
            end
                       
            % Add documentName to DocumentElement.
            tagName = 'name';
            kml.appendTextToFeature( ...
                kml.DocumentElement, tagName, documentName);
            
            % Set the DocumentName.
            kml.pDocumentName = documentName;            
        end
        
        %----------------------- set/get ----------------------------------
       
        function set.DocumentName(kml, name)
        % Set DocumentName property.
            
            if ~ischar(name) || (~isvector(name) && ~isempty(name))
                validateattributes(name, {'char'}, {'vector'}, ...
                    mfilename, 'DocumentName');
            end
            kml.pDocumentName = name;
            
            % Re-assign the Document name.
            item = kml.DocumentElement.getElementsByTagName('name').item(0);
            item.setTextContent(name);
        end
        
        %------------------------------------------------------------------
        
        function name = get.DocumentName(kml)
        % Get DocumentName property.
        
            name = kml.pDocumentName;
        end
        
        %------------------------------------------------------------------
        
        function set.FolderName(kml, name)
        % Set FolderName property.
        
           kml.pFolderName = name;
           kml.FolderElement = kml.createElement('Folder');
           kml.appendTextToFeature(kml.FolderElement, 'name', name);
        end
        
        %------------------------------------------------------------------
        
        function name = get.FolderName(kml)
        % Get FolderName property.
        
            name = kml.pFolderName;
        end
        
        %------------------------------------------------------------------
        
        function addAddress(kml, address)
        % Add address to KML document
            
            kml.UseLineStyle = false;
            kml.UseDefaultName = kml.usingDefaultName();
            
            try                               
                % Append the addresses to the KML document.
                for k = 1:length(address)
                    setNameDefaultValue(kml, 'Address', k)
                    appendAddress(kml, address{k}, k);
                end
            catch e
                throwAsCaller(e)
            end
        end
                     
        %------------------------------------------------------------------
        
        function addFeature(kml, S)
        % Add feature(s) stored in dynamic vector S to the KML document.
            
            kml.UseDefaultName = kml.usingDefaultName();
            try                
                % Determine altitude field.
                altitudeName = determineAltitudeName(S);
                                
                % Add dynamic vector to document.
                if isa(S, 'geopoint')
                    % Add point data to the document.
                    lat = S.Latitude;
                    lon = S.Longitude;
                    alt = S.(altitudeName);
                    for k = 1:length(S)
                        setNameDefaultValue(kml, 'Point', k)
                        appendPoint(kml, lat(k), lon(k), alt(k), k);
                    end
                else
                    % Add dynamic shape to document.
                    addMultiPartFeature(kml, S);
                end
            catch e
                throwAsCaller(e)
            end
        end
        
        %------------------------------------------------------------------
        
        function addMultiPartFeature(kml, S, useFolder)
        % addMultiPartFeature Add multi-part feature(s) to KML document
        %
        %   addMultiPartFeature(kml, S) adds the multi-part feature stored
        %   in S to the KML document, KML. S must be a geoshape vector.
        %
        %   addMultiPartFeature(kml, S, useFolder) sets the folder name
        %   for multi-part features if useFolder is true.
            
            kml.UseDefaultName = kml.usingDefaultName();
            if ~exist('useFolder', 'var')
                useFolder = true;
            end
            try
                % Determine altitude field.
                altitudeName = determineAltitudeName(S);
                
                if strcmp(S.Geometry, 'point')
                    % Add multi-point data to the document.
                    for k = 1:length(S)
                        lat = S(k).Latitude;
                        lon = S(k).Longitude;
                        alt = S(k).(altitudeName);
                        if useFolder
                           kml.FolderName = sprintf('Multipoint %d', k);
                        end
                        appendMultiPoint(kml, lat, lon, alt, k);
                    end
                    kml.FolderName = '';
                else
                    % Adding line.
                    kml.UseLineStyle = true;
                    
                    % Add line data to the document.
                    for k = 1:length(S)
                        lat = S(k).Latitude;
                        lon = S(k).Longitude;
                        alt = S(k).(altitudeName);
                        
                        % Create a Folder and assign FolderName to Name
                        % if coordinates contain NaN values.
                        if any(isnan(lat))
                            % Set the default value if needed.
                            setNameDefaultValue(kml, 'Line', k);
                            
                            if useFolder
                                % Assign the folder name to the name of the
                                % line.
                                kml.FolderName = getProperty(kml, 'Name', k);
                            end
                        end
                        
                        % Append the line segments.
                        appendMultiLineSegment(kml, lat, lon, alt, k);
                        kml.FolderName = '';
                    end
                end
            catch e
                throwAsCaller(e)
            end
        end
        
        %------------------------------------------------------------------
        
        function write(kml, filename)
        % write Write KML document to disk
        %
        %   write(kml, filename) writes the KML document object, kml, to
        %   disk.
        
            try
                validateattributes(filename, {'char'}, {'vector'}, ...
                    mfilename, 'FILENAME')
            catch e
                throwAsCaller(e)
            end
            
            % Set DocumentName if it is empty.
            if isempty(kml.DocumentName)
                % Use the basename of the file for the name of the KML
                % document.
                [~, docName] = fileparts(filename);
                kml.DocumentName = docName;
            end
            
            % Write the DOM to an XML file.
            try
                xmlwrite(filename, kml.DOM);
            catch e
                % XMLWRITE error stack contains a long Java traceback for
                % cases in which the file can not be opened. Verify that
                % case and error with a succinct message.
                fid = fopen(filename,'w');
                if fid < 0
                    error(message('map:fileio:unableToOpenWriteFile', filename));
                else
                    % XMLWRITE failed for other reasons.
                    % Close the newly opened file and error with a general
                    % error message.
                    fclose(fid);
                    if exist(filename, 'file')
                        try
                            delete(filename);
                        catch e %#ok<NASGU>
                            % No action required.
                        end
                    end
                    error(message('map:fileio:unableToWriteFile', obj.Filename));
                end
            end
        end        
    end
    
    methods  (Access = 'protected')
        
        %------------------------------------------------------------------

        function DOM = getDOM(kml)
        % getDOM  Return XML Document Object Model (DOM) object
        %
        %   DOM = getDom(kml) returns the object's XML Document Object
        %   Model (DOM) object.
        
            DOM = kml.DOM;
        end
                
        %------------------------------------------------------------------
        
        function value = getProperty(kml, name, index)
        % Return the NAME property at INDEX location.
            
            default = ' ';
            if isprop(kml, name)               
                value = kml.(name);
                if any(strcmp(name, {'Camera', 'LookAt'}));
                    if iscell(value)
                        value = value{1};
                    end
                end
                if index > length(value) && ~isscalar(value)
                    % Unable to determine which value to return so set to
                    % the empty string.
                    value = default;
                elseif ~isscalar(value)
                    % Obtain value at index.
                    if ~iscell(value)
                        value = value(index);
                    else
                        value = value{index};
                    end
                elseif iscell(value)
                    % Value is scalar, return contents of cell.
                    value = value{1};
                end
                % Have already obtained value. Value is scalar and not a cell.
            else
                % name is not a property.
                value = default;
            end
        end
        
        %------------------------------------------------------------------
        
        function setNameDefaultValue(kml, value, index)
        % Set the Name property default value.
        
            if kml.UseDefaultName
                kml.Name{1} = sprintf('%s %d', value, index);
            end        
        end
        
        %------------------------------------------------------------------
        
        function appendPoint(kml, lat, lon, alt, index)
        % appendPoint Append a point or points to document model
        %
        %   appendPoint(kml, lat, lon, alt) appends a point or points to a
        %   KML Placemark element at the coordinates specified by lat, lon,
        %   alt. The coordinate arrays are numeric and may contain NaN
        %   values which are ignored. It is assumed that the coordinate
        %   arrays are validated prior to invoking the appendPoint method.
            
            nonNan = find(~isnan(lat) & ~isnan(lon));
            lon = wrapTo180(lon);
            for k = nonNan                
                coordinates = convertCoordinatesToString(lat(k), lon(k), alt(k));
                kml.appendCoordinatePlacemark('Point', coordinates,  index);
            end
        end
        %------------------------------------------------------------------
        
        function appendLine(kml, lat, lon, alt, index)
        % appendLine Append a line or lines to document model
        %
        %   appendLine(kml, lat, lon, alt) appends a line or lines to a KML
        %   Placemark element at the coordinates specified by lat, lon,
        %   alt. The coordinate arrays are numeric and may contain NaN
        %   values which are ignored. It is assumed that the coordinate
        %   arrays are validated prior to invoking the appendPoint method.
             
            lon = wrapTo180(lon);
            coordinates = convertCoordinatesToString(lat, lon, alt);
            kml.appendCoordinatePlacemark('LineString', coordinates,  index);
        end
        
        %------------------------------------------------------------------
        
        function appendMultiLineSegment(kml, lat, lon, alt, index)
        %appendMultiLineSegment Append line segments to document model
        %
        %   appendMultiLineSegment(kml, lat, lon, alt, index) appends line
        %   segments (separated by Nans) to the document. If index is not
        %   empty, then index is used for the line number, otherwise the
        %   index of the kth line segment is used.
                    
            % Split the coordinates.
            [latCells, lonCells, altCells] = splitCoordinate(lat, lon, alt);
                                  
            % Append the lines to the KML document.
            for k = 1:length(latCells)
                lat = latCells{k};
                lon = lonCells{k};
                alt = altCells{k};
                if ~isempty(index)
                    lineNumber = index;
                else
                    lineNumber = k;
                end
                if ~isempty(kml.FolderName)
                    kml.Name{lineNumber} = sprintf('Segment %d', k);
                else
                   setNameDefaultValue(kml, 'Line', lineNumber);
                end
                appendLine(kml, lat, lon, alt, lineNumber);
            end     
            
            % Append the folder to the document if the name has been set.
            if ~isempty(kml.FolderName)
                kml.appendChild(kml.FolderElement);
            end
        end
        
        %------------------------------------------------------------------
        
        function appendMultiPoint(kml, lat, lon, alt, index)
        %appendMultiPoint Append multi-point data to document model
        %
        %   appendMultiPoint(kml, lat, lon, alt) appends multi-point data
        %   to KML Placemark elements at the coordinates specified by lat,
        %   lon, alt. It is assumed that the coordinate arrays are
        %   validated prior to invoking the appendMultiPoint method.
                                        
            % Append each point to the document. The NaN values are
            % filtered out and the longitude wrapping is handled by the
            % appendPoint method.
            for k = 1:length(lat)
                setNameDefaultValue(kml, 'Point', k)
                kml.appendPoint(lat(k), lon(k), alt(k), index);
            end
            
            % Append the folder to the document if the name has been set.
            if ~isempty(kml.FolderName)
                kml.appendChild(kml.FolderElement);
            end

        end
        
        %------------------------------------------------------------------
        
        function appendAddress(kml, address, index)
        %appendAddress Append address to document model
        %
        %   appendAddress(kml, address) appends address data to a KML
        %   Placemark element. The cell array address contains string
        %   address data. The address is a single string per point. It is
        %   assumed that the address cell array is validated prior to
        %   invoking the appendAddress method.

            kml.appendAddressPlacemark(address, index);
        end
        
        %------------------------------------------------------------------

        function element = createElement(kml, name)
        % Create a new KML element with specified name.
        
            element = kml.DOM.createElement(name);
        end
        
        %------------------------------------------------------------------

        function placemarkElement = createPlacemarkElement(kml, index)
        % Create a new Placemark element.
            
            % Create an element with a Placemark tag name.
            placemarkElement  = createElement(kml, 'Placemark');
            
            % Add Snippet tag to prevent description lines from being
            % displayed in the control panel.
            tagName = 'Snippet';
            attributes = {'maxLines', '0'};
            textData = ' ';
            kml.appendAttributeElementToFeature( ...
                placemarkElement, tagName, attributes, textData);
            
            % Append all the options to the Placemark element.
            kml.appendOptionsToFeature(placemarkElement, index);
        end

        %------------------------------------------------------------------

        function appendChild(kml, child)
        % Append a child element to the document. The child element
        % contains a new KML element.
        
            kml.DocumentElement.appendChild(child);
        end

        %------------------------------------------------------------------
        
         function appendCoordinatePlacemark(kml, elementName, coordinates, index)        
        % Append a Placemark element to the document. The Placemark element
        % contains a new KML element with name elementName. The new
        % featureElement contains a KML coordinates element containing the
        % specified coordinates.
        
            % Create an element with a Placemark tag name and append the
            % properties to the placemark element.
            placemarkElement = kml.createPlacemarkElement(index);
            
            % Create the featureElement ('Point' or 'LineString')
            featureElement = kml.createElement(elementName);
            
            % Add altitudeMode.
            mode = getProperty(kml, 'AltitudeMode', index);
            if ~isequal(mode, ' ')
                kml.appendTextToFeature( featureElement, 'altitudeMode', mode);
            end
            
            % Add the specific feature element with coordinates to the
            % Placemark element.
            tagName = 'coordinates';
            kml.appendTextToFeature(featureElement, tagName, coordinates);
            placemarkElement.appendChild(featureElement);
            if isempty(kml.FolderName)
                kml.appendChild(placemarkElement);
            else
                kml.FolderElement.appendChild(placemarkElement);
            end
        end
        
        %------------------------------------------------------------------
        
        function appendAddressPlacemark(kml, address, index)
        % Append a Placemark element to the document that contains a new
        % address KML element.  The new address element contains the
        % specified address.
                    
            % Create an element with a Placemark tag name and append the
            % data from the properties to the placemark element.
            placemarkElement  = kml.createPlacemarkElement(index);
            
            % Add the address element with the address to the Placemark
            % element.
            tagName = 'address';           
            kml.appendTextToFeature(placemarkElement, tagName, address);          
            kml.appendChild(placemarkElement);
        end

        %------------------------------------------------------------------
        
        function appendOptionsToFeature(kml, featureElement,  index)
         % Append the properties to the KML element, featureElement.
            
            % Append text options to feature.
            kml.appendTextOptionsToFeature(featureElement, index);
            
            % Append any icon style options to feature.
            kml.appendStyleOptionsToFeature(featureElement, index);
            
            % Append any view point options to feature.
            kml.appendViewPointOptionsToFeature(featureElement, index);
        end
        
        %------------------------------------------------------------------
        
        function appendTextOptionsToFeature(kml, featureElement, index)
        % Append text properties to a KML element.
        %
        % Text options are simple text strings that are inserted between
        % KML tags. For example:
        %  <kmlTag> text </kmlTag>
        %
        % The property name is matched regardless of case from a list
        % of supported kmlTagNames. If found, the value in the kmlTagNames
        % is the kmlTag element.  The value of the property is the
        % text inserted between the beginning and ending kmlTags.
        
            % Supported KML element names.
            kmlTagNames = {'description','name','address'};
            
            % Corresponding KMLDocument properties. 
            documentProperties = {'Description', 'Name', 'Address'};
            
            % Is the tag name required.
            isRequired = {true, true, false};

            % Add the tag if requested.
            for k=1:numel(documentProperties)

                currentOption = documentProperties{k};
                currentValue = getProperty(kml, currentOption, index);
                tagIndex = strcmpi(currentOption, kmlTagNames);
                tagName = kmlTagNames(tagIndex);

                if isRequired{tagIndex} || ~isequal(currentValue, ' ')
                    kml.appendTextToFeature(...
                        featureElement, tagName, currentValue);
                end
            end
        end
        
        %------------------------------------------------------------------
        
        function appendStyleOptionsToFeature(kml, featureElement,  index)
        % Append style options to a KML element. Both IconStyle and
        % LineStyle are supported elements.
        %
        % Icon options are properties that contain the partial string
        % 'Icon'. These options are inserted into a IconStyle kmlTag. Two
        % 'Icon' fields are supported:
        %    IconScale and Icon.
        %
        % The KML IconStyle element is composed of the following:
        % <IconStyle>
        %   <scale>1</scale>                   <!-- float -->
        %   <Icon>
        %     <href>...</href>
        %   </Icon>
        % </IconStyle>
        %
        % If an 'IconScale' field is set in properties, then the
        % KML tag <scale> is set to the field value.
        %
        % If an 'Icon' field is set in the properties, then the
        % value of the field is inserted into a <href> KML element. This
        % element is then inserted into a <Icon> KML element.
        %
        % If either 'Icon' or 'IconScale' is set in the properties,
        % then the resulting KML element is inserted into the <IconStyle>
        % element.
        %
        % If both 'Icon' and 'IconScale' are set to empty or ' ', then an
        % IconStyle element is not created.
        %
        % The IconStyle element must be inserted into the KML Style
        % element. For example:
        %
        % <Style>
        %    <IconStyle>
        %       <scale> 2 </scale>
        %    </IconStyle>
        % </Style>
        %
        % Line style properties modify the color or width of a line. These
        % properties are inserted into a LineStyle kmlTag. Two fields are
        % supported:
        %    color and width
        %
        % The KML LineStyle element is composed of the following:
        % <LineStyle>
        %   <width>value</with>       <!-- float  -->
        %   <color>value</color>      <!-- string -->
        % </LineStyle>
        %
        % If either 'Color' or 'Width' is set in the properties, and
        % UseLineStyle is true then the KML element is inserted into the
        % <LineStyle> element.
        %
        % If both are set to empty or ' ' or UseLineStyle is false, then a
        % LineStyle element is not created.
        %
        % The LineStyle element must be inserted into the KML Style
        % element. For example:
        %
        % <Style>
        %    <LineStyle>
        %       <width>2</width>
        %       <color>ff0000ff</color>
        %    </LineStyle>
        % </Style>
            
            % Supported KML element names.
            kmlTagNames = {'Icon','IconScale', 'LineStyle', 'color', 'width'};
            
            % Corresponding KMLDocument properties.
            documentProperties = ...
                {'Icon','IconScale', 'LineStyle', 'Color', 'Width'};
            
            % Setup a logical array to determine if the Icon fields need to
            % be added to the document.
            needToAddElements = false(1,numel(kmlTagNames));
                        
            % Create the Style and IconStyle elements.
            styleElement = kml.createElement('Style');
            iconStyleElement = kml.createElement('IconStyle');
            lineStyleElement = kml.createElement('LineStyle');
            
            useIconStyle = false;
            useLineStyle = kml.UseLineStyle;
            
            % Add the tag if requested.
            for k=1:numel(documentProperties)
                
                currentOption = documentProperties{k};
                currentValue = getProperty(kml, currentOption, index);
                
                tagIndex = strcmpi(currentOption, kmlTagNames);
                tagName = kmlTagNames{tagIndex};
                
                % Determine if the field value contains valid data to add
                % to the document.
                containsData = ...
                    ~isempty(currentValue) && ~isequal(currentValue, ' ');
                needToAddElements(k) = containsData;
                
                if containsData
                    switch tagName
                        case 'Icon'
                            % Icon field creates KML tags:
                            % <Icon>
                            %    <href> currentValue </href>
                            % </Icon>
                            
                            useIconStyle = true;
                            href = 'href';
                            iconElement = kml.createElement(tagName);
                            hrefElement = kml.appendTextToFeature( ...
                                iconStyleElement, href, currentValue);
                            
                            iconElement.appendChild(hrefElement);
                            iconStyleElement.appendChild(iconElement);
                            
                        case 'IconScale'
                            % IconScale field creates KML tags:
                            % <scale> currentValue </scale>
                            
                            useIconStyle = true;
                            scaleName = 'scale';
                            value = num2strd(currentValue);
                            iconScaleElement = kml.appendTextToFeature( ...
                                iconStyleElement, scaleName, value);
                            iconStyleElement.appendChild(iconScaleElement);
                            
                        case 'color'
                            % Color field creates KML tag:
                            % <color>value</color>
                            
                            tagName = 'color';
                            useIconStyle = true;
                            colorElement = kml.appendTextToFeature( ...
                                iconStyleElement, tagName, currentValue);
                            iconStyleElement.appendChild(colorElement);
                            if useLineStyle
                                colorElement = kml.appendTextToFeature( ...
                                    lineStyleElement, tagName, currentValue);
                                lineStyleElement.appendChild(colorElement);
                            end
                            
                        case 'width'
                            % width field creates KML tag:
                            % <width>value</width>
                            
                            if useLineStyle
                                tagName = 'width';
                                currentValue = num2strd(currentValue);
                                widthElement = kml.appendTextToFeature( ...
                                    lineStyleElement, tagName, currentValue);
                                lineStyleElement.appendChild(widthElement);
                            end
                    end
                end
            end
            
            % Only append the IconStyle, LineStyle, amd Style elements to
            % the document if any fields are set.
            if any(needToAddElements)
                if useIconStyle
                    styleElement.appendChild(iconStyleElement);
                end
                if useLineStyle
                    styleElement.appendChild(lineStyleElement);
                end
                featureElement.appendChild(styleElement);
            end
        end

       %------------------------------------------------------------------
        
       function appendViewPointOptionsToFeature(kml, featureElement, index)
       % Append view point options to a KML element.
       %
       % Camera and LookAt options are supported.
       %
       % Camera options are properties that contain
       % the string 'Camera'. These options are inserted into a Camera
       % kmlTag.
       %
       % The KML Camera element is composed of the following:
       % <Camera>
       %   <longitude>value</longitude>  <angle180>
       %   <latitude>value</latitude>    <angle90>
       %   <altitude>value</altitude>    <double>
       %   <heading>value</heading>      <angle360>
       %   <tilt>value</tilt>            <anglepos180>
       %   <roll>value</roll>            <angle180>
       %   <altitudeMode>value</altitudeMode>  <string>
       % </Camera>
       %
       % If a 'Camera' field is set properties, then the KML
       % tag <Camera> is set to the field values.
       %
       % The Camera or LookAt element are inserted into the KML Placemark
       % element, but they both cannot be inserted into the same one.
       % For example:
       %
       % <Placemark>
       %    <Camera>
       %    </Camera>
       % </Placemark>
           
           % Supported KML element names.
           kmlTagNames = {'Camera','LookAt'};
           
           % Corresponding KMLDocument properties.
           documentProperties = kmlTagNames;
                     
           % Add the tag if requested.
           for k=1:numel(documentProperties)
               
               currentOption = documentProperties{k};
               currentValue = getProperty(kml, currentOption, index);
               
               % Determine if the field value contains valid data to add
               % to the document.
               containsData = ~isempty(currentValue) ...
                   && isa(currentValue, 'geopoint');
               
               if containsData
                   % Validate that the coordinate values do not contain
                   % NaNs since they have not been validated to be
                   % NaN-coincident with the coordinates.
                   lat = currentValue.Latitude;
                   str = [currentOption '.Latitude'];
                   validateattributes(lat, {'numeric'}, {'finite'}, mfilename, str);
                   
                   lon = currentValue.Longitude;
                   str = [currentOption '.Longitude'];
                   validateattributes(lon, {'numeric'}, {'finite'}, mfilename, str);

                   tagIndex = strcmpi(currentOption, kmlTagNames);
                   tagName = kmlTagNames{tagIndex};
                   
                   topElement = kml.createElement(tagName);
                   elementNames = ...
                       ['Longitude'; 'Latitude'; fieldnames(currentValue)];
                   elementNames(strcmp('AltitudeMode', elementNames)) = [];
                   for n = 1:numel(elementNames)
                       elementName = elementNames{n};
                       value = num2strd(currentValue.(elementName));
                       kml.appendTextToFeature( ...
                           topElement, lower(elementName), value);
                   end
                   kml.appendTextToFeature( ...
                       topElement, 'altitudeMode', currentValue.AltitudeMode);
                   featureElement.appendChild(topElement);
               end
           end
       end
        
       %------------------------------------------------------------------
       
       function element = appendTextToFeature(kml, ...
               featureElement, elementName, textData)
       % Append text to a feature element.
       %
       % Create and append a new text element to a new KML element with
       % name elementName. The elementName node is appended to
       % featureElement.  The text element contains the text from the
       % string textData. The featureElement contains the new elementName
       % KML element.

           element = kml.createElement(elementName);
           textNode = kml.DOM.createTextNode(textData);
           element.appendChild(textNode);
           featureElement.appendChild(element);
       end
        
       %------------------------------------------------------------------
       
       function appendAttributeElementToFeature(kml, ...
               featureElement, elementName, elementAttributes, textData)
       % Append attribute element to a feature element.
       %
       % Create and append a new text element to a new KML element with
       % name elementName. The elementName node is appended to
       % featureElement.  The text element contains the text from the
       % string textData. The elementName node's attribute is set with the
       % values in the string cell array elementAttributes. The
       % featureElement contains the new elementName KML element.
           
           element = kml.appendTextToFeature( ...
               featureElement, elementName, textData);
           element.setAttribute(elementAttributes{:});
       end
    end
    
    methods (Access = 'private')
        
        function tf = usingDefaultName(kml)
        % Determine if the Name property is the default value.
        
           name = getProperty(kml, 'Name', 1);
           tf = isequal(name, ' ') ...
               && (isscalar(kml.Name) || isempty(kml.Name));
        end
    end
end

%---------------------- Utility Functions ---------------------------------

function  [DOM, documentElement] = createDocument()
% Create the XML DOM and Document element.

DOM = com.mathworks.xml.XMLUtils.createDocument('kml');

rootNode = DOM.getDocumentElement;
namespace = 'http://www.opengis.net/kml/2.2';
rootNode.setAttribute('xmlns', namespace);

documentElement = DOM.createElement('Document');
rootNode.appendChild(documentElement);

end

%--------------------------------------------------------------------------

function coordinates = convertCoordinatesToString(lat, lon, alt)
% Convert coordinates to a string.

if isscalar(lat)
    latStr = num2strd(lat);
    lonStr = num2strd(lon);
    altStr = num2strd(alt);
    coordinates = [lonStr, ',', latStr, ',', altStr];
else
    coordinates = [];
    for k = 1:length(lat)
        coordStr = convertCoordinatesToString(lat(k), lon(k), alt(k));
        coordinates = sprintf('%s %s', coordinates, coordStr);
    end
end
end

%--------------------------------------------------------------------------

function altitudeName = determineAltitudeName(S)
% Determine the altitude name from the input dynamic vector, S.

% Find altitude names in S.
altitudeNames = {'Altitude', 'Elevation', 'Height'};
names = fieldnames(S);
index = ismember(altitudeNames, names);
altitudeName = altitudeNames{index};
if isempty(altitudeName)
    % This condition cannot be met unless the class is constructed outside
    % of the KML functions. The class expects an altitude name. Since it is
    % an internal class and this condition cannot be met, rather than error
    % here, let the code error when attempting to access the data.
    altitudeName = altitudeNames{1};
end
end

%--------------------------------------------------------------------------

function [latCells, lonCells, altCells] = splitCoordinate(lat, lon, alt)
% Split latitude, longitude, and altitude coordinates into cells.

% Split latitude and longitude coordinates.
[latCells, lonCells] = polysplit(lat,lon);

% Split altitude.
alt(isnan(lat)) = NaN;
altCells = polysplit(alt, lat);
end
       
%--------------------------------------------------------------------------

function str = num2strd(value)
% Convert a scalar number to a string representation with a maximum of 15
% digits of precision.

% Use sprintf to convert a number to a string representation with 15 digits
% of precision. (You can use num2str(value, 15) but sprintf is more
% efficient).
if isscalar(value)
    str = sprintf('%.15g', value);
else
    validateattributes(value, {'numeric'}, {'scalar', 'nonempty'});
end
end

