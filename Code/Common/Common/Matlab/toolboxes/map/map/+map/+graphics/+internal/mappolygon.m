function h = mappolygon(x, y, varargin)
%MAPPOLYGON Display polygon in projected map coordinate system
%
%   map.graphics.internal.MAPPOLYGON(X, Y, Name, Value) constructs a patch
%   and an "edge line", in order to display a polygon in map (x-y)
%   coordinates.  The polygon is drawn in the Z == 0 plane.
%
%   map.graphics.internal.MAPPOLYGON(X, Y, Z, Name, Value) displays the
%   polygon in the horizontal plane indicated by the scalar Z.
%
%   H = map.graphics.internal.MAPPOLYGON(___) returns a handle to a patch
%   object, that may be used to reset various properties (or empty, if X
%   and Y are empty).
%
%   Inputs
%   ------
%   X and Y contain the polygon vertices, and may include NaN values to
%   delimit multiple parts, including inner rings.  X and Y must match in
%   size and the locations of NaN delimiters.
%
%   Z is a scalar defining the horizontal plane in which to display the
%   polygon.
%
%   Name and Value indicate optional name-value pairs, corresponding to
%   graphics properties of patch.  An optional 'EdgeLine' parameter may
%   also be specified, with a scalar logical value.  If true (the default),
%   an "edge line" object is created and used to display the polygon edges.
%   If false, the edge line is omitted and the polygon edges are not
%   shown.  Another optional parameter, 'FaceVertexForm', allows test code
%   to dictate the way in which patch is used, overriding default behavior
%   (which depends on MATLAB graphics).
%
%   If the EdgeAlpha, EdgeColor, LineWidth, or LineStyle properties (or any
%   marker properties) are set during construction, or via set(h,...),
%   their values may be applied to an "edge line" object, not the patch
%   itself.
%
%   Example
%   -------
%   coast = load('coast.mat');
%   [y, x] = maptrimp(coast.lat, coast.long, [-90 90], [-180 180]);
%   figure('Color','white')
%   h = map.graphics.internal.mappolygon(x,y,'FaceColor',[0.7 0.7 0.4]);
%   axis equal; axis off
%   set(h,'FaceAlpha',0.5)
%   get(h)
%
%   See also map.graphics.internal.GLOBEPOLYGON

% Copyright 2012-2013 The MathWorks, Inc.

defaultFaceColor = [1 1 0.5];   % Pale yellow

% Extract Z from the input, if provided. Otherwise set Z to [] and omit
% ZData when constructing graphics objects.
if numel(varargin) >= 1 && ~ischar(varargin{1})
    z = varargin{1};
    varargin(1) = [];
else
    z = [];
end

% Separate out any 'Parent' properties from varargin
qParent = strncmpi(varargin,'pa',2);
qParent = qParent | circshift(qParent,[0 1]);
parents = varargin(qParent);
varargin(qParent) = [];

% Check the 'EdgeLine' flag, which is true by default.
[edgeLine, varargin] ...
    = internal.map.findNameValuePair('EdgeLine',true,varargin{:});

% Check the FaceVertexForm flag; default value depends on MATLAB graphics.
[faceVertexForm, varargin] = internal.map.findNameValuePair( ...
    'FaceVertexForm', ~matlab.graphics.internal.isGraphicsVersion1, varargin{:});

if ~isempty(x) || ~isempty(y)
    if any(~isnan(x(:))) || any(~isnan(y(:)))
        % The polygon has at least one part.
        
        % Clean up data, making sure that the edge-line closes.
        [x, y] = closePolygonParts(x, y);
        
        if isShapeMultipart(x,y)
            % The polygon has multiple parts.
            if faceVertexForm
                hPatch = faceVertexPolygon( ...
                    x, y, z, defaultFaceColor, edgeLine, parents);
            else
                hPatch = multiPatchPolygon( ...
                    x, y, z, defaultFaceColor, edgeLine, parents);
            end
        else
            % The polygon has only one part. Construct a single patch,
            % using the vertices provided, taking care not to include any
            % NaNs in the vertex list.
            n = isnan(x);
            x(n) = [];
            y(n) = [];
            if isempty(z)
                hPatch = patch('XData', x,'YData', y, ...
                    parents{:}, 'FaceColor', defaultFaceColor);
            else
                hPatch = patch('XData', x,'YData', y, ...
                    'ZData', z + zeros(size(x)), ...
                    parents{:}, 'FaceColor', defaultFaceColor);
            end
        end
    else
        % Construct a patch with no data when X and Y contain only NaN.
        hPatch = patch('XData', NaN, 'YData', NaN, 'ZData', NaN, ...
            parents{:}, 'FaceColor', defaultFaceColor);
    end
    
    % Apply user-supplied properties, if any, and make patch visible.
    set(hPatch,'Visible','on',varargin{:})
else
    % Return empty when X and Y are both empty.
    hPatch = reshape(gobjects(0),[0 1]);
end

% Suppress output if called with no return value and no semicolon.
if nargout > 0
    h = hPatch;
end

end

%--------------------------------------------------------------------------

function hPatch = faceVertexPolygon(x, y, z, faceColor, edgeLine, parents)
% Use face-vertex form to construct a "fill patch" in which the edges are
% turned off.  Construct an edge line if the edgeLine flag is true.

[f,v] = map.internal.polygonToFaceVertex(x,y);
if ~isempty(z)
    v = [v, z + zeros(size(v,1),1)];
end
hPatch = patch('Faces', f, 'Vertices', v, parents{:}, ...
    'FaceColor', faceColor, 'EdgeColor','none', 'Visible','off');

if edgeLine
    % Construct an "edge line," with HandleVisibility off.
    if isempty(z)
        map.graphics.internal.constructEdgeLine(hPatch, x, y);
    else
        map.graphics.internal.constructEdgeLine( ...
            hPatch, x, y, z + zeros(size(x)));
    end   
end
end

%--------------------------------------------------------------------------

function hPatch = multiPatchPolygon(x, y, z, faceColor, edgeLine, parents)
% Use vertex-list (XData, YData) form to construct multiple patch that fill
% the area occupied by a polygon.  Construct an "edge patch" to display the
% polygon edges if edgeLine is true.  Otherwise, construct it anyway, but
% make it a "null patch," without the actual vertices.

% Ensure terminating NaNs, to avoid an edge that connects the
% first and last vertices.
if ~isnan(x(end))
    x(end+1) = NaN;
    y(end+1) = NaN;
end

% Construct two or more "fill patches" as needed to fill in the
% interior of the polygon, gathered together in an hggroup.
% Set EdgeColor last, to ensure that it is 'none'.
% Handle visibility is off for both group and patches.
[xSimple, ySimple] = polygonToSimpleCurves(x(:), y(:));
hFillPatchGroup = hggroup(parents{:}, ...
    'Visible','off','HandleVisibility','off');
[first, last] = internal.map.findFirstLastNonNan(xSimple);
for k = 1:numel(first)
    s = first(k);
    e = last(k);
    xdata = xSimple(s:e);
    ydata = ySimple(s:e);
    if isempty(z)
        patch('Parent',hFillPatchGroup,'XData',xdata,'YData',ydata)
    else
        patch('Parent',hFillPatchGroup,...
            'XData',xdata,'YData',ydata,'ZData',z + zeros(size(xdata)))
    end
end
set(allchild(hFillPatchGroup),'FaceColor',faceColor, ...
    'EdgeColor','none','HandleVisibility','off');

% Construct an "edge patch" object in which only the edges are visible.
% This is the object whose handle will be visible, and which will be
% returned if requested. If edgeLine is false, then this object should not
% display anything -- and need not contain any actual coordinates, in fact,
% but still needs to be constructed, in order to provide the "master"
% handle that is returned.
if edgeLine
    if isempty(z)
        hPatch = patch('XData',x,'YData',y,parents{:},'FaceColor',faceColor);
    else
        hPatch = patch('XData',x,'YData',y,'ZData',z + zeros(size(x)), ...
            parents{:},'FaceColor',faceColor);
    end
else
    hPatch = patch('XData', NaN, 'YData', NaN, 'ZData', NaN, parents{:});
end

% Provide access to the fill patch group.
setappdata(hPatch, 'FillPatchGroup', hFillPatchGroup)

% Set DeleteFcn and CreateFcn callbacks.
set(hPatch, 'DeleteFcn', @deleteFillPatchGroup)
set(hPatch, 'CreateFcn', @copyFillPatchGroup)

% Set up listeners such that the fill patch group responds to
% set(h,'FaceColor',...) and set(h,'FaceAlpha',...), and to
% ensure that it gets deleted appropriately.
addListeners(hPatch, hFillPatchGroup)

% Make the fill patches visible.
set(hFillPatchGroup,'Visible','on')

end

%--------------------------------------------------------------------------

function deleteFillPatchGroup(hPatch, ~)
% Delete the fill patch.
% if ishghandle(hFillPatchGroup)
%     delete(hFillPatchGroup);
% end

if ishghandle(hPatch, 'patch') && isappdata(hPatch, 'FillPatchGroup')
    hFillPatchGroup = getappdata(hPatch, 'FillPatchGroup');
    if ishghandle(hFillPatchGroup, 'hggroup') ...
            && isequal(ancestor(hFillPatchGroup, 'axes'), ancestor(hPatch,'axes'))
        delete(hFillPatchGroup)
        rmappdata(hPatch, 'FillPatchGroup')
    end
end
end
    
%--------------------------------------------------------------------------

function copyFillPatchGroup(hPatch, ~)
% If the hgroup in the hPatch appdata is in a different axes than hPatch,
% copy it into the axes ancestor of hPatch and set the appdata and
% listeners. These actions will be performed when copyobj is called but not
% when openfig is called.

if ishghandle(hPatch, 'patch') && isappdata(hPatch, 'FillPatchGroup')
    hFillPatchGroup = getappdata(hPatch, 'FillPatchGroup');
    if ishghandle(hFillPatchGroup, 'hggroup')
        ax = ancestor(hPatch, 'axes');
        if ~isequal(ax, ancestor(hFillPatchGroup, 'axes'))
            hCopy = copyobj(hFillPatchGroup, ax);
            setappdata(hPatch, 'FillPatchGroup', hCopy);
            addListeners(hPatch, hCopy)
            uistack(hCopy, 'down')
        end
    end
end
end

%--------------------------------------------------------------------------

function addListeners(hPatch, hFillPatchGroup)

% Set up listeners that transfer face property settings from edge patch
% to the fill patches.
addlistener(hPatch,'FaceColor','PostSet',@setFaceProps);
addlistener(hPatch,'FaceAlpha','PostSet',@setFaceProps);
addlistener(hPatch,'Visible',  'PostSet',@setFaceProps);
addlistener(hPatch,'EdgeColor','PostSet',@setEdgeColor);

% Keep some state information to help the listener callbacks work.
updateFaceProps = true;
updateEdgeColor = true;
edgeColor = get(hPatch,'EdgeColor');

%------------------- nested callback functions ------------------

    function setFaceProps(hSrc,evnt)
        % Apply 'FaceColor' and 'FaceAlpha' values to the fill patches
        % rather than to the edge patch. Use allchild because the fill
        % patches have hidden handles.
        if updateFaceProps
            hEdgePatch = evnt.AffectedObject;
            set(allchild(hFillPatchGroup), ...
                hSrc.Name, get(hEdgePatch, hSrc.Name))
            updateFaceProps = false;
        end
        updateFaceProps = true;
    end

    function setEdgeColor(~,evnt)
        % If EdgeColor is set to 'flat' or 'interp', quietly restore it to
        % its previous setting.
        if updateEdgeColor
            hEdgePatch = evnt.AffectedObject;
            value = get(hEdgePatch,'EdgeColor');
            if any(strcmpi(value,{'flat','interp'}))
                % Filter out values that match 'flat' or 'interp'.
                updateEdgeColor = false;
                set(hEdgePatch,'EdgeColor',edgeColor)
                updateEdgeColor = true;
            end
        end
        edgeColor = get(hPatch,'EdgeColor');
    end
end

%--------------------------------------------------------------------------

function [x, y] = polygonToSimpleCurves(x, y)
% Cut polygon into simple closed curves
%
%   Repeatedly cut a multipart polygon on vertical lines until there are no
%   remaining holes -- only a collection of simple, closed curves separated
%   by NaNs. This function is recursive. The recursion terminates when the
%   input polygon (x,y) includes only clockwise curves.
%
%   X -- Column vector containing X-coordinates of polygon vertices
%   Y -- Column vector containing Y-coordinates of polygon vertices
%
%   Multiple parts are separated by NaN values embedded at corresponding
%   locations with X and Y.
%
%   To prevent invalid input from causing infinite recursion, it's verified
%   that the input polygon includes at least one clockwise part.

ccw = ~ispolycw(x, y);
if all(ccw)
    error('map:polygons:noClockwiseParts', ...
        'Expected at least one polygon part to be clockwise.')
elseif any(ccw)
    % At this point, there's at least one counterclockwise curve, and hence
    % at least one hole to be eliminated.
    
    % Choose the cut location, c, to be centered between the left-most and
    % right-most extremities of the first hole.
    k = find(ccw,1);
    [first, last] = internal.map.findFirstLastNonNan(x);
    xHole = x(first(k):last(k));
    v = (min(xHole) + max(xHole))/2;
    
    % Make the cut.
    [xL, yL] = cutOnVerticalLeft( x, y, v);
    [xR, yR] = cutOnVerticalRight(x, y, v);
    
    % Recurse on both sides of the cut.
    [xL, yL] = polygonToSimpleCurves(xL, yL);
    [xR, yR] = polygonToSimpleCurves(xR, yR);
    
    % Combine results.
    x = [xL; NaN; xR];
    y = [yL; NaN; yR];
end

end

%--------------------------------------------------------------------------

function [x, y] = cutOnVerticalLeft(x, y, v)
% Cut a polygon along the vertical line x == v, keeping only the part to
% the left of the line.
%
%   X -- Column vector containing X-coordinates of polygon vertices
%   Y -- Column vector containing Y-coordinates of polygon vertices
%   V -- X-coordinate of vertical line

ymin = min(y);
ymax = max(y);
xmin = min(x);
xb = [xmin xmin    v    v xmin];
yb = [ymin ymax ymax ymin ymin];
[x, y] = polybool('intersection', x, y, xb, yb);
end

%--------------------------------------------------------------------------

function [x, y] = cutOnVerticalRight(x, y, v)
% Cut a polygon along the vertical line x == v, keeping only the part to
% the right of the line.
%
%   X -- Column vector containing X-coordinates of polygon vertices
%   Y -- Column vector containing Y-coordinates of polygon vertices
%   V -- X-coordinate of vertical line

ymin = min(y);
ymax = max(y);
xmax = max(x);
xb = [xmax xmax    v    v xmax];
yb = [ymax ymin ymin ymax ymax];
[x, y] = polybool('intersection', x, y, xb, yb);
end
