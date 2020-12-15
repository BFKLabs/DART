function imaqtool( varargin )
% IMAQTOOL Launch the Image Acquisition Tool
%
%   IMAQTOOL will launch an interactive GUI to allow you to explore,
%   configure, and acquire data from your installed and supported image
%   acquisition devices.
%
%   IMAQTOOL(FILE) starts the GUI and then immediately reads an Image
%   Acquisition Tool configuration IAT-file.

% DT 9/2006
% Copyright 2006-2010 The MathWorks, Inc.

desk=iatbrowser.getDesktop();
if ~isempty(desk.getMainFrame())
    % If already visible, pop to front.
    desk.getMainFrame().toFront();
    % TODO: consider whether to allow loading of files.
    return;
end

com.mathworks.toolbox.imaq.browser.IATBrowserDesktop.openDesktop();

browser = iatbrowser.Browser;

if nargin==1
    browser.treePanel.loadConfigurationFile(varargin{1});
elseif nargin > 1
    error(message('imaq:imaqtool:tooManyArguments'));
end
