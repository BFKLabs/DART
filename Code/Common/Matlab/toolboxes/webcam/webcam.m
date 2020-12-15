classdef (Sealed, CaseInsensitiveProperties=true, TruncatedProperties=true) webcam < hgsetget & dynamicprops
%WEBCAM Creates webcam object to acquire frames from your Webcam.
%    CAMOBJ = WEBCAM returns a webcam object, CAMOBJ, that acquires images
%    from the specified Webcam. By default, this selects the first
%    available Webcam returned by WEBCAMLIST.
% 
%    CAMOBJ = WEBCAM(DEVICENAME) returns a webcam object, CAMOBJ, for
%    Webcam with the specified name, DEVICENAME. The Webcam name can be 
%    found using the function WEBCAMLIST.
%
%    CAMOBJ = WEBCAM(DEVICEINDEX) returns a webcam object, CAMOBJ, for
%    Webcam with the specified device index, DEVICEINDEX. The Webcam device
%    index is the index into the cell array returned by WEBCAMLIST.
%
%    CAMOBJ = WEBCAM(..., P1, V1, P2, V2,...) constructs the webcam object,
%    CAMOBJ, with the specified property values. If an invalid property
%    name or property value is specified, the webcam object is not created.
%
%    Creating WEBCAM object obtains exclusive access to the Webcam. 
%
%    SNAPSHOT method syntax:
%
%    IMG = snapshot(CAMOBJ) acquires a single frame from the Webcam.
%
%    [IMG, TIMESTAMP] = snapshot(CAMOBJ) returns the frame, IMG, and the 
%    acquisition timestamp, TIMESTAMP. 
%
%    WEBCAM methods:
%
%    snapshot     - Acquire a single frame from the Webcam.
%    preview      - Activate a live image preview window.
%    closePreview - Close live image preview window.
%
%    WEBCAM properties:    
%
%    Name                 - Name of the Webcam.
%    Resolution           - Resolution of the acquired frame.
%    AvailableResolutions - Cell array of list of available resolutions.
%
%    The WEBCAM interface also exposes the dynamic properties of the Webcam
%    that we can access programmatically. Some of these dynamic properties
%    are Brightness, Contrast, Hue, Exposure etc. The presence of these
%    properties in the WEBCAM object depends on the Webcam that you connect
%    to.
%
%    Example:
%       % Construct a webcam object
%       camObj = webcam;
%       
%       % Preview a stream of image frames.
%       preview(camObj);
%
%       % Acquire and display a single image frame.
%       img = snapshot(camObj);
%       image(img);
%
%    See also WEBCAMLIST
    
%   Copyright 2013 The MathWorks, Inc.
    
    properties(GetAccess = public, SetAccess = private)
        %Name Specifies the name of the Webcam. 
        %   The Name property cannot be modified once the object is created 
        %   and is read only.
        Name
    end
    
    
    properties(Access = public)
        %Resolution Video Resolution to be used while acquiring an image.
        %   Specify the resolution of the acquired frame. The default value
        %   of resolution is the default resolution returned by the camera.
        %   You can change the resolution to any supported value. The list
        %   of available resolutions can be found by accessing the
        %   AvailableResolutions property.
        Resolution
    end

    properties(Access = private, Hidden)
        CamController
        CamPreviewController
        UniqueID
        CurrentWidth
        CurrentHeight
        IsPreviewing
    end
    
    properties(GetAccess = public, SetAccess = private)
        %Available Resolutions List of all available resolutions.
        %   List of all available resolutions supported by the Webcam. This 
        %   property is read only.   
        AvailableResolutions
    end
    
    properties (Access = private, Hidden)
        % Maintain a map of created objects to gain exclusive access.
        ConnectionMap = containers.Map()
    end
    
    methods(Access = public)
        function obj = webcam(varargin)
            % webcam - Construct a WEBCAM object.
            
            try
                % Check if the support package is installed.
                fullpathToUtility = which('matlab.webcam.internal.Utility');
                if isempty(fullpathToUtility) 
                    % Support package not installed - Error.
                    if feature('hotlinks')
                        error('MATLAB:webcam:supportPkgNotInstalled', message('MATLAB:webcam:webcam:supportPkgNotInstalled').getString);
                    end
                end

                % Choose the camera enumeration MEX file based on the platform
                [~, deviceNames, uniqueIDs] = matlab.webcam.internal.Utility.enumerateWebcams;

                if(isempty(deviceNames))
                    % No devices were found.
                    error('MATLAB:webcam:noWebcams', message('MATLAB:webcam:webcam:noWebcams').getString);
                end

                if(isempty(varargin))% empty arguments
                    devID = uniqueIDs{1};
                    devName = deviceNames{1};
                else
                    if (ischar(varargin{1})) % If the input argument is a string - Device name is passed in.
                        devName = validateName(varargin{1}, deviceNames);
                        index = ismember(deviceNames, devName);
                        devID = uniqueIDs{index};
                    elseif (isnumeric(varargin{1})) % If the input argument is numeric - device index is passed in.

                        % Specified index is larger than number of webcams
                        % found
                        devIndex = varargin{1};
                        validateattributes(devIndex, {'numeric'}, {'scalar', '>=', 1, '<=', length(uniqueIDs), 'nonnan', 'finite'}, 'webcam', 'INDEX', 1);

                        devName = deviceNames{devIndex};
                        devID = uniqueIDs{devIndex};                
                    else
                        % The first argument provided was invalid. 
                        error('MATLAB:webcam:invalidArg', message('MATLAB:webcam:webcam:invalidArg').getString);
                    end
                end

                % Check if connection exists.
                if isKey(obj.ConnectionMap, devName)
                    storedDevID = obj.ConnectionMap(devName);
                    if storedDevID == devID
                        error('MATLAB:webcam:connectionExists', message('MATLAB:webcam:webcam:connectionExists', devName).getString);
                    end
                end

                % Update the webcam Name and ID property
                obj.Name = devName;
                obj.UniqueID = devID;

                % Create the controller object
                obj.CamController = ...
                    matlab.webcam.internal.WebcamController(devName, devID);

                % Parse resolution for frame width and height
                [obj.CurrentWidth, obj.CurrentHeight] = obj.CamController.getCurrentFrameSize;

                % Add dynamic properties map from the Channel
                dynamicProps = obj.CamController.getDynamicProperties();
                dynPropKeys = dynamicProps.keys;
                dynPropValues = dynamicProps.values;

                for i=1:dynamicProps.size()
                    prop = addprop(obj,dynPropKeys{i});
                    obj.(dynPropKeys{i}) = dynPropValues{i};
                    prop.SetAccess = 'public';
                    prop.Dependent = true;
                    prop.AbortSet = true; % Is this ok? 
                    prop.SetMethod = @(obj, value) obj.setDynamicProperty(prop.Name, value);
                    prop.GetMethod = @(obj) obj.getDynamicProperty(prop.Name);
                end

                % Set PV pairs if provided.
                if (nargin>1)

                    if ~mod(nargin,2) % If number of arguments is even
                        error('MATLAB:webcam:unmatchedPVPairs', message('MATLAB:webcam:webcam:unmatchedPVPairs').getString);
                    end

                    for i = 2:2:length(varargin)
                        pName = varargin{i};
                        if(strcmpi(pName,'Name')||strcmpi(pName,'AvailableResolutions'))
                            error('MATLAB:webcam:setReadOnly', message('MATLAB:webcam:webcam:setReadOnly', varargin{i}).getString);
                        end

                        % Validate the property for case-insensitive matching.
                        actualPropName = validatestring(pName, fieldnames(set(obj)), 'webcam', upper(pName), i);

                        % Set the value.
                        obj.(actualPropName) = varargin{i+1};
                    end
                end

                obj.CamController.open();

                % Add current Webcam to connectionMap
                obj.ConnectionMap(devName) = devID;

                % Initialize Preview Controller
                obj.CamPreviewController = matlab.webcam.internal.PreviewController(obj.Name, obj.CamController);
            catch excep
                throwAsCaller(excep);
            end
        end
        
        function [image, timestamp] = snapshot(obj)
            %SNAPSHOT - Acquires a single frame from the webcam.
            %
            % IMAGE = SNAPSHOT(obj) returns the most recent image from the
            % webcam associated with the WEBCAM object, obj.
            % 
            % [IMAGE, TIMESTAMP] = SNAPSHOT(obj), returns the timestamp
            % of the acquired image frame.

            % Error checking for object.
            if ~isvalid(obj)
                error('MATLAB:webcam:invalidObject', message('MATLAB:webcam:webcam:invalidObject').getString);
            end            
            [image, timestamp] = obj.CamController.getCurrentFrame();
        end
        
                
        function hImage = preview(obj)
            %PREVIEW Display preview of live video data.
            %
            % PREVIEW(OBJ) creates a Video Preview window that displays 
            % live video for webcam object OBJ. The window also displays 
            % the webcam name, timestamp, video resolution and frame rate.
            % The Video Preview window displays the video data at 100% 
            % magnification (one screen pixel represents one image pixel). 
            % 
            % The Video Preview window remains active until it is closed 
            % using closePreview. If you clear the WEBCAM object, the Video 
            % Preview window stops previewing and closes automatically.
            %
            % HIMAGE = preview(OBJ) returns HIMAGE, a handle to the image 
            % object containing the previewed data. To obtain a handle to 
            % the figure window containing the image object, use ANCESTOR. 
            % For more information about using image objects, see IMAGE.            
            %
            % See also closePreview
            
            
            % Error checking for object.
            if ~isvalid(obj)
                error('MATLAB:webcam:invalidObject', message('MATLAB:webcam:webcam:invalidObject').getString);
            end

            % Call controller preview.
            imHandle = obj.CamPreviewController.preview();
                                   
            % Assign output only if requested.
            if(nargout > 0)
                hImage = imHandle;
            end
        end
        
        function closePreview(obj)
            % CLOSEPREVIEW(OBJ) closes the live preview window for Webcam 
            % object, OBJ.  
            %
            % See also preview                
            
            
            % Error checking for object.
            if ~isvalid(obj)
                error('MATLAB:webcam:invalidObject', message('MATLAB:webcam:webcam:invalidObject').getString);
            end
            
            obj.CamPreviewController.closePreview();
        end
        
        
        function varargout = set(obj, varargin)
          %SET    Set webcam object property values
          %   H,'PropertyName',PropertyValue) sets the value of the specified
          %   property for the webcam object, H.
          %
          %   SET(H,'PropertyName1',Value1,'PropertyName2',Value2,...) sets
          %   multiple property values with a single statement.
          %
          %   Given a structure S, whose field names are object property names,
          %   SET(H,S) sets the properties identified by each field name of S with
          %   the values contained in the structure.
          %
          %   A = SET(H, 'PropertyName') returns the possible values for the
          %   specified property of the webcam object, H. The returned array is a
          %   cell array of possible value strings or an empty cell array if the
          %   property does not have a finite set of possible string values.
          %
          %   A = SET(H) returns all property names and their possible values for
          %   the webcam object, H. The return value is a structure whose field
          %   names are the property names of H, and whose values are cell arrays
          %   of possible property value strings or empty cell arrays.
          %
          %   See also get.

          % Error checking for object.
          if ~isvalid(obj)
              error('MATLAB:webcam:invalidObject', message('MATLAB:webcam:webcam:invalidObject').getString);
          end          
          
          settableFields = fieldnames(set@hgsetget(obj));
          switch(nargin)
            case 1
                % S = set(obj)
                fn = fieldnames(obj);
                % Filter out the read-only props - the only one being
                % DeviceProperties.
                for ii = 1:length(fn)
                    dPropInfo = obj.findprop(fn{ii});
                    if ~strcmp(dPropInfo.SetAccess, 'public')
                        continue;
                    end
                    val = {set(obj,fn{ii})};
                    if isempty(val{1})
                        st.(fn{ii}) = {};
                    else
                        st.(fn{ii}) = val;
                    end
                end
                varargout = {st};
            case 2
              % Second argument is a structure.
              if isstruct(varargin{1})
                  % set(obj, struct)
                  st = varargin{1};
                  stfn = fieldnames(st);
                  for ii = 1:length(stfn)
                      prop = stfn{ii};
                      prop = validatestring(prop, settableFields, 'webcam', upper(prop));
                      try
                          set@hgsetget(obj,prop,st.(prop));
                      catch ME
                          throwAsCaller(ME);
                      end
                  end
              else % This returns the required property enumerations for tab completion.
                  % info = set(obj, prop)
                  propName = varargin{1};
                  
                  propName = validatestring(propName, settableFields);
                  
                  dPropInfo = obj.findprop(propName);
                  if ~strcmp(dPropInfo.SetAccess, 'public')
                      error('MATLAB:webcam:devicePropReadOnly', message('MATLAB:webcam:webcam:devicePropReadOnly', propName).getString);
                  end
                  
                  if strcmpi(propName, 'Resolution')
                      propEnum = get(obj, 'AvailableResolutions');
                      varargout = {propEnum};
                      return;
                  end
                  
                  % Initialize varargount
                  varargout = {{}};
                  val = get(obj, propName);
                  if isnumeric(val) % Not an enumeration
                      return;
                  end
                  
                  % TODO: To change this once channel has a ENUM property
                  % associated with each property that is an enumeration.
                  if ismember(val, {'on', 'off'})
                      propEnum = {'on', 'off'};
                  else
                      propEnum = {'auto', 'manual'};
                  end
                  varargout = {propEnum}; % Returns the list of values.
                  return;
              end
            otherwise
               % set(obj, <PV Pairs>)
               if mod(length(varargin),2)
                    error('MATLAB:webcam:unmatchedPVPairs', message('MATLAB:webcam:webcam:unmatchedPVPairs').getString);
               end
               
               for ii = 1:2:length(varargin)
                  try
                      pName = validatestring(varargin{ii}, settableFields, 'webcam', upper(varargin{ii}));
                      
                      dPropInfo = obj.findprop(pName);
                      if ~strcmp(dPropInfo.SetAccess, 'public')
                          error('MATLAB:webcam:devicePropReadOnly', message('MATLAB:webcam:webcam:devicePropReadOnly', pName).getString);
                      end
                                            
                      set@hgsetget(obj, pName, varargin{ii+1});
                  catch ME
                      throwAsCaller(ME);
                  end
               end
               varargout = {};
          end
        end
        
    end
    
    methods (Access = public, Hidden)
        function delete(obj)
            %DELETE - Delete the webcam object and free resources.
            try
                if (~isempty(obj.CamController)&& isvalid(obj.CamController))
                      obj.CamController.delete();
                      obj.CamController = [];
                end

                if (~isempty(obj.CamPreviewController)&& isvalid(obj.CamPreviewController))
                      obj.CamPreviewController.delete();
                      obj.CamPreviewController = [];
                end

                if isKey(obj.ConnectionMap, obj.Name)
                    remove(obj.ConnectionMap, obj.Name);
                end
            catch excep
                throwAsCaller(excep);
            end
            
        end
        
        function obj = saveobj(obj)
        % saveobj Saves the Webcam information to file.
        %
        %   OBJ = saveobj(OBJ) saves the Webcam for future loading. 

            % Set object properties into a structure for saving. Turn the
            % warning off to so that it does not show to the user.
            warnState = warning('OFF', 'MATLAB:structOnObject');
            saveInfo = struct(obj);
            warning(warnState);

            % Remove fields that should not be saved.
            saveInfo = rmfield(saveInfo, 'CamController');
            saveInfo = rmfield(saveInfo, 'CamPreviewController');
            saveInfo = rmfield(saveInfo, 'CurrentWidth');
            saveInfo = rmfield(saveInfo, 'CurrentHeight');
            saveInfo = rmfield(saveInfo, 'IsPreviewing');
            saveInfo = rmfield(saveInfo, 'AvailableResolutions');
            saveInfo = rmfield(saveInfo, 'ConnectionMap');
            saveInfo = rmfield(saveInfo, 'UniqueID');

            % Set the output to save.
            obj = saveInfo;
        end        
        
        function closepreview(~)
            error('MATLAB:webcam:invalidClosePreview', message('MATLAB:webcam:webcam:invalidClosePreview').getString);
        end
                
        function value = getDynamicProperty (obj, propName)
            % Get the actual property name before passing through.
            propName = validatestring(propName, properties(obj), 'webcam', propName);
            
            value = obj.CamController.getDynamicProp(propName);
        end
        
        function setDynamicProperty(obj, propName, value)
            try
                % Get the actual property name before passing through.
                propName = validatestring(propName, properties(obj), 'webcam', propName);

                obj.CamController.setDynamicProp(propName, value);
            catch excep
                throwAsCaller(excep);
            end
        end
    end
    
    methods (Access = public, Hidden)
        % Disable and hide these methods.
        function c = horzcat(varargin)
            %HORZCAT Horizontal concatenation of Webcam objects.
            
            if (nargin == 1)
                c = varargin{1};
            else
                error('MATLAB:webcam:noconcatenation', message('MATLAB:webcam:webcam:noconcatenation').getString);
            end
        end
        function c = vertcat(varargin)
            %VERTCAT Vertical concatenation of Webcam objects.
            
            if (nargin == 1)
                c = varargin{1};
            else
                error('MATLAB:webcam:noconcatenation', message('MATLAB:webcam:webcam:noconcatenation').getString);
            end
        end
        function c = cat(varargin)
            %CAT Concatenation of Webcam objects.
            if (nargin > 2)
                error('MATLAB:webcam:noconcatenation', message('MATLAB:webcam:webcam:noconcatenation').getString);
            else
                c = varargin{2};
            end
        end

        % Hidden methods from the hgsetget super class.
        function res = eq(obj, varargin)
            res = eq@hgsetget(obj, varargin{:});
        end
        function res =  fieldnames(obj, varargin)
            res = fieldnames@hgsetget(obj,varargin{:});
        end
        function res = ge(obj, varargin)
            res = ge@hgsetget(obj, varargin{:});
        end
        function res = gt(obj, varargin)
            res = gt@hgsetget(obj, varargin{:});
        end
        function res = le(obj, varargin)
            res = le@hgsetget(obj, varargin{:});
        end
        function res = lt(obj, varargin)
            res = lt@hgsetget(obj, varargin{:});
        end
        function res = ne(obj, varargin)
            res = ne@hgsetget(obj, varargin{:});
        end
        function res = findobj(obj, varargin)
            res = findobj@hgsetget(obj, varargin{:});
        end
        function res = findprop(obj, varargin)
            res = findprop@hgsetget(obj, varargin{:});
        end
        function res = addlistener(obj, varargin)
            res = addlistener@hgsetget(obj, varargin{:});
        end
        function res = notify(obj, varargin)
            res = notify@hgsetget(obj, varargin{:});
        end
        
        % Hidden methods from the dynamic proper superclass
        function res = addprop(obj, varargin)
            res = addprop@dynamicprops(obj, varargin{:});
        end
    end
    
    methods
        function value = get.Name(obj)
            value = obj.Name;
        end
        
        function value = get.Resolution(obj)
            value = obj.CamController.getResolution();
        end
        
        function set.Resolution(obj, value)
            try
                obj.CamController.setResolution(value); %#ok<MCSUP>
            catch excep
                throwAsCaller(excep);
            end
        end
        
        function values = get.AvailableResolutions(obj)
            values = obj.CamController.getAvailableResolutions;
        end
    end
    
    methods (Static, Hidden)
        function supportPackageInstaller
        % Wrapper function to start support package installer for Webcams

            % Launch the installer.
            hwconnectinstaller.launchInstaller('SupportPackageFor', 'USB Webcams', 'StartAtStep', 'SelectPackage');
        end
        
        function obj = loadobj(inStruct)
        % LOADOBJ Load webcam object from memory.
        %
        
            try
                % Try creating the object. 
                obj = webcam(inStruct.Name, 'Resolution', inStruct.Resolution);
            catch
                warning('MATLAB:webcam:cannotCreateObject', message('MATLAB:webcam:webcam:cannotCreateObject').getString);
                obj = webcam.empty();
            end
            
            % Restore properties.
            inStruct = rmfield(inStruct, 'Name');
            inStruct = rmfield(inStruct, 'Resolution');
            
            if ~isempty(fieldnames(inStruct))
                try
                    % Set the property values. 
                    set(obj, inStruct);
                catch
                    % Unable to restore property for webcam object. 
                    warning('MATLAB:webcam:cannotRestoreProperties', message('MATLAB:webcam:webcam:cannotRestoreProperties').getString);
                end
            end
        end
    end
end

function resolvedName = validateName(deviceName,deviceList)
    partials = deviceList(strncmpi(deviceName,deviceList,numel(deviceName)));
    exacts = 1;
    % Generate a string of Webcam names
    listStr = deviceList{1};
    for i = 2:numel(deviceList)
        listStr = [listStr ', ' deviceList{i}]; %#ok<AGROW>
    end
    
    if numel(partials) == 0
        error('MATLAB:webcam:invalidName', message('MATLAB:webcam:webcam:invalidName', listStr).getString);
    elseif numel(partials) > 1  
        exacts = find(strcmp(deviceName,partials), 1);
        if isempty(exacts)
            error('MATLAB:webcam:invalidName', message('MATLAB:webcam:webcam:invalidName', listStr).getString);
        end
    end
    resolvedName = partials{exacts};
end