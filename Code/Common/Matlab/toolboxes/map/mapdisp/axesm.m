function [h,msg] = axesm(varargin)
%AXESM Define map axes and set map properties
%
%  AXESM activates a GUI to define a map projection for the current axes.
%
%  AXESM(PROPERTYNAME, PROPERTYVALUE,...) uses the map properties in the
%  input list to define a map projection for the current axes. For a list
%  of map projection properties, execute GETM AXES.  All standard
%  (non-mapping) axes properties are controlled using the axes command. For
%  a list of available projections, execute MAPS.
%
%  AXESM(PROJID,...) uses the string PROJID to designate which map
%  projection to use. PROJID should match one of the entries in the last
%  column of the table displayed by the MAPS function.
%
%  See also AXES, GETM, MAPLIST, MAPS, MFWDTRAN, MINVTRAN, PROJFWD,
%  PROJINV, PROJLIST, SETM

% Copyright 1996-2013 The MathWorks, Inc.

% The following syntax is invoked from within Mapping Toolbox(TM)
% function SETM, but is not intended for general use.
%
%    AXESM(MSTRUCT,...) uses the map structure specified by MSTRUCT to
%                       initialize the map projection.

% Obsolete syntax
% ---------------
% [h,msg] = AXESM(...) returns a string indicating any error encountered.
if nargout > 1
    warnObsoleteMSGSyntax(mfilename)
    msg = '';
end

%  Initialize output variables
if nargout ~= 0
    h = [];
end

%  Initialize default map structure.
%  Save each of the field names to compare with passed in properties

mstruct = initmstruct;            %  AXESM algorithm requires mfields to
mfields = fieldnames(mstruct);    %  always remain a cell array.

%  Test input arguments

if (nargin > 0) && any(ishghandle(varargin{1}))
    error(message('map:axesm:invalidFirstParameter','AXESM'))
end

if nargin == 0
    % AXESM
    if ~ismap(gca)
        [~,defproj] = maplist; % get the default projection
        mstruct.mapprojection = defproj;
        mstruct = feval(mstruct.mapprojection,mstruct);
        mstruct = resetmstruct(mstruct);
        set(gca,...
            'NextPlot','Add', ...
            'UserData',mstruct, ...
            'DataAspectRatio',[1 1 1], ...
            'Box','on',...
            'ButtonDownFcn',@uimaptbx)
        %  May not hit mapprojection case with non-map axes
        set(gca,'XLimMode','auto','YLimMode','auto')
        showaxes off
    end
    cancelflag = axesmui;
    if nargout ~= 0
        h = cancelflag;
    end
elseif nargin == 1 && ~ischar(varargin{1}) && ~isstruct(varargin{1})
    gcm(varargin{1})
    axes(varargin{1}); %#ok<MAXES>
else
    if rem(nargin,2)
        if isstruct(varargin{1})
            % AXESM(MSTRUCT,...)
            mstruct   = varargin{1};
            startpt   = 2;
            newfields  = sortrows(char(fieldnames(mstruct)));
            testfields = sortrows(char(mfields));
            if any(size(testfields) ~= size(newfields)) ...
                    || any(any(testfields ~= newfields))
                error(message('map:axesm:invalidMap'))
            end
        else
            % AXESM(PROJFCN,...)
            startpt = 2;
            try
                mstruct.mapprojection = maps(varargin{1});
                mstruct = feval(mstruct.mapprojection,mstruct);
            catch %#ok<CTCH>
                if exist(varargin{1},'file') == 2
                    mstruct = feval(varargin{1},mstruct);
                else
                    error(message('map:axesm:undefinedMapAxis'))
                end
            end
        end
    else
        % AXESM(PROPERTYNAME, PROPERTYVALUE,...)
        startpt = 1;
    end

    %  Permute the property list so that 'angleunits' (if supplied) is first
    %  and 'mapprojection' is second.  'angleunits' must be processed first
    %  so that all defaults end up in the proper units.  'mappprojection'
    %  must be processed second so that any supplied parameter, such as
    %  'parallels', is not overwritten by the defaults in the projection
    %  function.
    varargin(1:(startpt-1)) = [];
    varargin = reorderprops(varargin);

    % Assign variables to test if a reset property is being set to 'reset'.
    resetFrameGrat = false;
    resetProperties = {'grid', 'meridianlabel', 'parallellabel' ,'frame'};
    
    %  Cycle through the property name-value pairs.
    for j = 1 : 2 : numel(varargin)
        % Allow 'spheroid' as a synonym for 'geoid'
        [propname, propvalue] = validateprop(varargin, [{'spheroid'}; mfields], j);
        if strcmp(propname,'spheroid')
            propname = 'geoid';
        end
        if isequal(propvalue, 'reset') && ...
                any(strncmp(propname, resetProperties, numel(propname)))
             resetFrameGrat = true;
        end
        mstruct = setprop(mstruct, propname, propvalue);
    end

    %  Remove possible NaN left by setMapLatLimit.
    mstruct.origin(isnan(mstruct.origin)) = 0;
    
    %  Check for defaults to be computed.
    mstruct = resetmstruct(mstruct);
    
    if resetFrameGrat
        % Update the axes with the new mstruct.
        set(gca, 'UserData', mstruct);
    else
        % Set GCA to be a map axes
        setgca(mstruct)
    end

    %  Display map frame, lat-lon graticule, and meridian and parallel
    %  labels, if necessary
    setframegrat(mstruct)

    %  Set output variable if necessary
    if nargout >= 1
        h = gca;
    end
end

%-----------------------------------------------------------------------

function props = reorderprops(props)
% Permute the property list, moving the following properties (when
% present) to the start and ordering them as listed here: angleunits,
% mapprojection, zone, origin, flatlimit, flonlimit, maplatlimit,
% maplonlimit.  Also, convert all the property names to lower case.

% Reshape to a 2-by-N: Property names are in row 1, values in row 2.
props = reshape(props,[2,numel(props)/2]);

% Convert all property names to lower case.
props(1,:) = lower(props(1,:));

% Index properties: 101, 102, 103, ...
indx = 100 + (1:size(props,2));

% Determine which columns contain 'angleunits', 'mapprojection', etc.
indx(strmatch('an',    props(1,:))) = 1;  % 'angleunits'
indx(strmatch('mappr', props(1,:))) = 2;  % 'mapprojection'
indx(strmatch('z',     props(1,:))) = 3;  % 'zone'
indx(strmatch('o',     props(1,:))) = 4;  % 'origin'
indx(strmatch('fla',   props(1,:))) = 5;  % 'flatlimit'
indx(strmatch('flo',   props(1,:))) = 6;  % 'flonlimit'
indx(strmatch('mapla', props(1,:))) = 7;  % 'maplatlimit'
indx(strmatch('maplo', props(1,:))) = 8;  % 'maplonlimit'

% Sort indx and save the required permutations in indexsort.
[~, indexsort] = sort(indx);

% Permute the columns of props.
props = props(:,indexsort);

% Turn props back into a row vector.
props = props(:)';

%-----------------------------------------------------------------------

function [propname, propvalu] = validateprop(props, mfields, j)

%  Get the property name and test for validity.
try
    propname = validatestring(props{j}, mfields, 'axesm');
catch e
    if mnemonicMatches(e.identifier, {'unrecognizedStringChoice'})
        error(message('map:axesm:unrecognizedProperty',props{j}))
    elseif mnemonicMatches(e.identifier, {'ambiguousStringChoice'})
        error(message('map:axesm:ambiguousPropertyName',props{j}))
    else
        e.rethrow();
    end
    
end

%  Get the property value, ensure that it's a row vector and convert
%  string-valued property values to lower case.
propvalu = props{j+1};
propvalu = propvalu(:)';
if ischar(propvalu)
    propvalu = lower(propvalu);
end

%-----------------------------------------------------------------------

function mstruct = setprop(mstruct, propname, propvalu)

switch propname

    %*************************************
    %  Properties That Get Processed First
    %*************************************

    case 'angleunits'
        mstruct = setAngleUnits(mstruct,propvalu);

    case 'mapprojection'
        mstruct = setMapProjection(mstruct, propvalu);
        
    case 'zone'
        mstruct = setZone(mstruct, propvalu);

    case 'origin'
        mstruct = setOrigin(mstruct, propvalu);

    case 'flatlimit'
        mstruct = setflatlimit(mstruct, propvalu);

    case 'flonlimit'
        mstruct = setflonlimit(mstruct, propvalu);

    case 'maplatlimit'
        if isempty(propvalu)
            mstruct.maplatlimit = [];
        else
            mstruct = setMapLatLimit(mstruct, propvalu);
        end

    case 'maplonlimit'
        if isempty(propvalu)
            mstruct.maplonlimit = [];
        else
            mstruct = setMapLonLimit(mstruct, propvalu);
        end

    %************************
    %  General Map Properties
    %************************

    case 'aspect'
        mstruct.aspect = validateStringValue(propvalu, ...
            {'normal','transverse'}, propname);

    case 'geoid'
        if isa(propvalu,'oblateSpheroid') || isa(propvalu,'referenceSphere')
            mstruct.geoid = propvalu;
        else
            mstruct.geoid = checkellipsoid(propvalu,'AXESM','ELLIPSOID');
        end
        
    case 'mapparallels'
        if ischar(propvalu) || length(propvalu) > 2
            invalidPropertyValue(propname)
        elseif mstruct.nparallels == 0
            error(message('map:axesm:unsupportedProperty', ...
                upper('mapparallels')))
        elseif numel(propvalu) > mstruct.nparallels
            error(message('map:axesm:tooManyElements', ...
                upper('mapparallels')))
        else
            mstruct.mapparallels = propvalu;
        end

    case 'scalefactor'
        if ~isnumeric(propvalu) || length(propvalu) > 1 ||  propvalu == 0
            invalidPropertyValue(propname)
        else
            if any(strcmp(mstruct.mapprojection,{'utm','ups'}))
                error(message('map:axesm:unsupportedProperty', ...
                    upper('scalefactor')))
            else
                mstruct.scalefactor = propvalu;
            end
        end

    case 'falseeasting'
        if ~isnumeric(propvalu) || length(propvalu) > 1
            invalidPropertyValue(propname)
        else
            if any(strcmp(mstruct.mapprojection,{'utm','ups'}))
                error(message('map:axesm:unsupportedProperty', ...
                    upper('falseeasting')))
            else
                mstruct.falseeasting = propvalu;
            end
        end

    case 'falsenorthing'
        if ~isnumeric(propvalu) || length(propvalu) > 1
            invalidPropertyValue(propname)
        else
            if any(strcmp(mstruct.mapprojection,{'utm','ups'}))
                error(message('map:axesm:unsupportedProperty', ...
                    upper('falsenorthing')))
            else
                mstruct.falsenorthing = propvalu;
            end
        end


    %******************
    %  Frame Properties
    %******************

    case 'frame'
        value = validateStringValue(propvalu, {'on','off','reset'}, propname);        
        if strcmp(value,'reset')
            value = 'on';
        end       
        mstruct.frame = value;

    case 'fedgecolor'
        if ischar(propvalu) || ...
                (length(propvalu) == 3 && all(propvalu <= 1 & propvalu >= 0))
            mstruct.fedgecolor = propvalu;
        else
            invalidPropertyValue(propname)
        end

    case 'ffacecolor'
        if ischar(propvalu) || ...
                (length(propvalu) == 3 && all(propvalu <= 1 & propvalu >= 0))
            mstruct.ffacecolor = propvalu;
        else
            invalidPropertyValue(propname)
        end

    case 'ffill'
        if ~ischar(propvalu)
            mstruct.ffill = max([propvalu,2]);
        else
            invalidPropertyValue(propname)
        end

    case 'flinewidth'
        if ~ischar(propvalu)
            mstruct.flinewidth = max([propvalu(:),0]);
        else
            invalidPropertyValue(propname)
        end

    %*************************
    %  General Grid Properties
    %*************************

    case 'grid'
       
        value = validateStringValue(propvalu, {'on','off','reset'}, propname);        
        if strcmp(value,'reset')
            value = 'on';
        end        
        mstruct.grid = value;

    case 'galtitude'
        if ~ischar(propvalu)
            mstruct.galtitude = propvalu(1);
        else
            invalidPropertyValue(propname)
        end

    case 'gcolor'
        if ischar(propvalu) || ...
                (length(propvalu) == 3 && all(propvalu <= 1 & propvalu >= 0))
            mstruct.gcolor = propvalu;
        else
            invalidPropertyValue(propname)
        end

    case 'glinestyle'
        lstyle = internal.map.parseLineSpec(propvalu);
        mstruct.glinestyle = lstyle;
        if isempty(lstyle)
            warning(message('map:axesm:missingGridLineStyle'))
        end

    case 'glinewidth'
        if ~ischar(propvalu)
            mstruct.glinewidth = max([propvalu(:),0]);
        else
            invalidPropertyValue(propname)
        end


    %**************************
    %  Meridian Grid Properties
    %**************************

    case 'mlineexception'
        if ischar(propvalu)
            invalidPropertyValue(propname)
        else
            mstruct.mlineexception = propvalu;
        end

    case 'mlinefill'
        if ~ischar(propvalu)
            mstruct.mlinefill = max([propvalu, 2]);
        else
            invalidPropertyValue(propname)
        end

    case 'mlinelimit'
        if ischar(propvalu) || length(propvalu) ~= 2
           invalidPropertyValue(propname)
        else
            mstruct.mlinelimit = propvalu;
        end

    case 'mlinelocation'
        if ischar(propvalu)
            invalidPropertyValue(propname)
        elseif length(propvalu) == 1
            mstruct.mlinelocation = abs(propvalu);
        else
            mstruct.mlinelocation = propvalu;
        end

    case 'mlinevisible'
        mstruct.mlinevisible = validateStringValue( ...
            propvalu, {'on','off'}, propname);

    %**************************
    %  Parallel Grid Properties
    %**************************

    case 'plineexception'
        if ischar(propvalu)
            invalidPropertyValue(propname)
        else
            mstruct.plineexception = propvalu;
        end

    case 'plinefill'
        if ~ischar(propvalu)
            mstruct.plinefill = max([propvalu, 2]);
        else
            invalidPropertyValue(propname)
        end

    case 'plinelimit'
        if ischar(propvalu) || length(propvalu) ~= 2
            invalidPropertyValue(propname)
        else
            mstruct.plinelimit = propvalu;
        end

    case 'plinelocation'
        if ischar(propvalu)
            invalidPropertyValue(propname)
        elseif length(propvalu) == 1
            mstruct.plinelocation = abs(propvalu);
        else
            mstruct.plinelocation = propvalu;
        end

    case 'plinevisible'
        mstruct.plinevisible = validateStringValue( ...
            propvalu, {'on','off'}, propname);

    %**************************
    %  General Label Properties
    %**************************

    case 'fontangle'
        mstruct.fontangle = validateStringValue( ...
            propvalu, {'normal','italic','oblique'}, propname);

    case 'fontcolor'
        if ischar(propvalu) || ...
                (length(propvalu) == 3 && all(propvalu <= 1 & propvalu >= 0))
            mstruct.fontcolor = propvalu;
        else
            invalidPropertyValue(propname)
        end

    case 'fontname'
        if ischar(propvalu)
            mstruct.fontname = propvalu;
        else
            invalidPropertyValue(propname)
        end

    case 'fontsize'
        if ischar(propvalu) || length(propvalu) ~= 1
            invalidPropertyValue(propname)
        else
            mstruct.fontsize = propvalu;
        end

    case 'fontunits'
        mstruct.fontunits = validateStringValue(propvalu, ...
             {'points','normalized', 'inches','centimeters','pixels'}, ...
             propname);

    case 'fontweight'
        mstruct.fontweight = validateStringValue( ...
            propvalu, {'normal','bold'}, propname);
        
    case 'labelformat'
        mstruct.labelformat = validateStringValue( ...
            propvalu, {'compass','signed','none'}, propname);

    case 'labelunits'
        if strncmpi(propvalu, 'dms', numel(propvalu))
            mstruct.labelunits = lower(propvalu);
        else
            mstruct.labelunits = checkangleunits(propvalu);
        end
        
    case 'labelrotation'
        mstruct.labelrotation = validateStringValue( ...
            propvalu, {'on','off'}, propname);
        
        %***************************
    %  Meridian Label Properties
    %***************************

    case 'meridianlabel'
        value =  validateStringValue( ...
            propvalu, {'on','off','reset'}, propname);
        if strcmp(value,'reset')
            value = 'on';
        end
        mstruct.meridianlabel = value;

    case 'mlabellocation'
        if ischar(propvalu)
            invalidPropertyValue(propname)
        elseif length(propvalu) == 1
            mstruct.mlabellocation = abs(propvalu);
        else
            mstruct.mlabellocation = propvalu;
        end

    case 'mlabelparallel'
        if ischar(propvalu)
            mstruct.mlabelparallel = validateStringValue( ...
                propvalu, {'north','south','equator'}, propname);
        elseif length(propvalu) == 1
            mstruct.mlabelparallel = propvalu;
        else
            invalidPropertyValue(propname)
        end

    case 'mlabelround'
        if ischar(propvalu) || length(propvalu) ~= 1
            invalidPropertyValue(propname)
        else
            mstruct.mlabelround = round(propvalu);
        end


    %***************************
    %  Parallel Label Properties
    %***************************

    case 'parallellabel'
        value = validateStringValue( ...
            propvalu, {'on','off','reset'}, propname);
        if strcmp(value,'reset')
            value = 'on';
        end
        mstruct.parallellabel = value;

    case 'plabellocation'
        if ischar(propvalu)
            invalidPropertyValue(propname)
        elseif length(propvalu) == 1
            mstruct.plabellocation = abs(propvalu);
        else
            mstruct.plabellocation = propvalu;
        end

    case 'plabelmeridian'
        if ischar(propvalu)
            mstruct.plabelmeridian = validateStringValue( ...
                propvalu, {'east','west','prime'}, propname);
        elseif length(propvalu) == 1
            mstruct.plabelmeridian = propvalu;
        else
            invalidPropertyValue(propname)
        end

    case 'plabelround'
        if ischar(propvalu) || length(propvalu) ~= 1
            invalidPropertyValue(propname)
        else
            mstruct.plabelround = round(propvalu);
        end

    otherwise
        error(message('map:axesm:readOnlyProperty', upper(propname)))
end

%-----------------------------------------------------------------------

function mstruct = setflatlimit(mstruct, flatlimit)

if ischar(flatlimit) || length(flatlimit) > 2
    invalidPropertyValue(propname)
elseif strcmp(mstruct.mapprojection,'globe')
    warning(message('map:axesm:flatlimitGlobe','FLatLimit','globe'))
else
    mstruct.flatlimit = flatlimit;
end

%-----------------------------------------------------------------------

function mstruct = setflonlimit(mstruct, flonlimit)

if ischar(flonlimit) || (length(flonlimit) ~= 2 && ~isempty(flonlimit))
    invalidPropertyValue(propname)
elseif strcmp(mstruct.mapprojection,'globe')
    warning(message('map:axesm:flonlimitGlobe','FLonLimit','globe'))
else
    mstruct.flonlimit = flonlimit;
end

%-----------------------------------------------------------------------

function setgca(mstruct)

%  Set GCA to be map axes.
set(gca, ...
    'NextPlot','Add',...
    'UserData',mstruct,...
    'DataAspectRatio',[1 1 1],...
    'Box','on', ...
    'ButtonDownFcn',@uimaptbx)

%  Show the axes background but not the axes labels.
showaxes('off');

%-----------------------------------------------------------------------

function setframegrat(mstruct)

%  Display grid and frame if necessary
if strcmp(mstruct.frame,'on')
    framem('reset');
end

if strcmp(mstruct.grid,'on')
    gridm('reset');
end

if strcmp(mstruct.meridianlabel,'on')
    mlabel('reset');
end

if strcmp(mstruct.parallellabel,'on')
    plabel('reset');
end

%-----------------------------------------------------------------------

function value = validateStringValue(value, options, propname)
% If VALUE is a string that uniquely matches an element in the string
% cell OPTIONS, return that element. Otherwise throw an error announcing an
% invalid property value.

try
    value = validatestring(value, options, 'axesm');
catch e
    if mnemonicMatches(e.identifier, ...
            {'ambiguousStringChoice','unrecognizedStringChoice'})
        invalidPropertyValue(propname)
    else
        e.rethrow();
    end
end

%-----------------------------------------------------------------------

function tf = mnemonicMatches(identifier, options)
% Return true if the last part of the colon-delimited string IDENTIFIER,
% typically called the mnemonic, is an exact match for any of the strings
% in the cell string OPTIONS.

parts = textscan(identifier,'%s','Delimiter',':');
mnemonic = parts{1}{end};
tf = any(strcmp(mnemonic,options));

%-----------------------------------------------------------------------

function invalidPropertyValue(propname)
% Throw error to indicate that the value provided for property
% PROPNAME is not value.

throwAsCaller(MException('map:validate:invalidPropertyValue', ...
    'AXESM', upper(propname)))
