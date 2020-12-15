function taggedString = addLink(linkedText,linkDestination,toolboxName)
%

%ADDLINK add a hyperlink to a string for display in the MATLAB Command
%Window.
%
%   taggedString = addLink(linkedText,linkDestination) takes an input
%   string (linkedText) and wraps it in html tags that execute a MATLAB
%   command to open the documentation browser to a specified location
%   (linkDestination) in the Optimization Toolbox documentation. The result
%   (taggedString) can be inserted in any text printed to the MATLAB
%   Command Window (e.g. error, MException, warning, fprintf).
%
%   taggedString = addLink(linkedText,linkDestination,toolboxName) directs
%   the MATLAB command to open the documentation for the specified toolbox.

%   Copyright 2009-2011 The MathWorks, Inc.

% If only two inputs are supplied, assume that the link is to the
% Optimization Toolbox documentation.
if nargin < 3
    toolboxName = 'optim';
end

if feature('hotlinks') && ~isdeployed;
    % Create explicit char array so as to avoid translation
    openTag = sprintf('<a href = "matlab: helpview([docroot ''/toolbox/%s/helptargets.map''],''%s'');">',...
        toolboxName,linkDestination);
    closeTag = '</a>';
    taggedString = [openTag linkedText closeTag];
else
    taggedString = linkedText;
end