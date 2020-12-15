function resourceString = privateGetJavaResourceString(bundleName, resourceKey)
% PRIVATEGETJAVARESOURCESTRING Get a resource string from a resource bundle.
%
%   PRIVATEGETJAVARESOURCESTRING(BUNDLENAME, KEY) returns the resource
%   string associate with the key KEY from the resource bundle
%   BUNDLENAME.
%
%   Example:
%
%      myString = privateGetJavaResourceString('com.mathworks.toolbox.imaq.browser.resources.RES_TABPANE', 'GeneralPanel.roiPanelTitle');

% Copyright 2006, The MathWorks, Inc.
%  $Keyword: $

% These need to be passed to java explicitly since this getBundle is not
% called from within the context of a java object.
defaultLocale = java.util.Locale.getDefault();
classLoader = java.lang.ClassLoader.getSystemClassLoader();

% Get the resource bundle
resourceBundle = java.util.ResourceBundle.getBundle(bundleName, defaultLocale, classLoader);

resourceString = char(resourceBundle.getString(resourceKey));