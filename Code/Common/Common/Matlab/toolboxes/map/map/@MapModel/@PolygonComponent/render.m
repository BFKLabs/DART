function render(this,layerName,legend,ax,visibility)
%RENDER Render the polygon component.
%
%   RENDER(LAYERNAME, LEGEND, AX, VISIBILITY) renders all features
%   of the polygon component into the axes AX using the symbolization
%   defined in the legend, LEGEND, for the layer defined by LAYERNAME.
%   The polygon visibility is defined by VISIBILITY.

% Copyright 1996-2012 The MathWorks, Inc.

features = this.Features;
for k = 1:numel(features)
    % Polygon vertex arrays.
    xdata = features(k).xdata;
    ydata = features(k).ydata;
    
    % Graphics properties from symbolization rules.
    properties = legend.getGraphicsProperties(features(k));
    
    % Convert from struct to name-value form.
    properties = [fieldnames(properties)'; struct2cell(properties)'];
    properties = properties(:)';
    
    % Construct the k-th polygon --
    % a patch that may have an associated "edge line".
    h = map.graphics.internal.mappolygon(xdata, ydata, ...
        'Tag', layerName, ...
        'Parent', ax, ...
        'Visible', visibility, ...
        'HitTest', 'off', ...
        properties{:});
    
    % Set 'HitTest' on the edge line.
    hEdgeLine = getappdata(h,'EdgeLine');
    set(hEdgeLine,'HitTest','off')
    
    % Store the Attributes structure in the appdata of the patch.
    setappdata(h,'Attributes',features(k).Attributes)
end
