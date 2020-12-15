function addLayer(this,layer)
%ADDLAYER Add a layer to the viewer
%
%   ADDLAYER(LAYER) adds the MapModel.layer object to the MapView.

%   Copyright 1996-2003 The MathWorks, Inc.

scribefiglisten(this.Figure,'off');
this.Map.addLayer(layer);
scribefiglisten(this.Figure,'on');
