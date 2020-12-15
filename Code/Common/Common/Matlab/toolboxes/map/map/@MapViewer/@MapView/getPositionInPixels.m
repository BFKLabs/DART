function p = getPositionInPixels(this)

% Copyright 1996-2008 The MathWorks, Inc.

oldUnits = get(this.Figure,'Units');
set(this.Figure,'Units','pixels')
p = get(this.Figure,'Position');
set(this.Figure,'Units',oldUnits)
