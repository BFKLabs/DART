function value = iptgetpref(prefName)
%IPTGETPREF Get value of Image Processing Toolbox preference.
%   PREFS = IPTGETPREF without an input argument returns a structure
%   containing all the Image Processing Toolbox preferences with their
%   current values.  Each field in the structure has the name of an Image
%   Processing Toolbox preference.  See IPTSETPREF for a list.
%
%   VALUE = IPTGETPREF(PREFNAME) returns the value of the Image
%   Processing Toolbox preference specified by the string PREFNAME.  See
%   IPTSETPREF for a complete list of valid preference names.  Preference
%   names are not case-sensitive and can be abbreviated.
%
%   Example
%   -------
%       value = iptgetpref('ImshowAxesVisible')
%
%   See also IMSHOW, IPTSETPREF.

%   Copyright 1993-2011 The MathWorks, Inc.

% migrate preferences to settings if necessary
s = Settings;
if ~s.images.PreferencesMigrated
    migratePreferences();
end

error(nargchk(0,1,nargin,'struct'));

% Get IPT factory preference settings
factoryPrefs = iptprefsinfo;
allNames = factoryPrefs(:,1);

if nargin == 0
    % Display all current preference settings
    value = [];
    for k = 1:length(allNames)
        thisField = allNames{k}{1};
        value.(thisField) = iptgetpref(thisField);
    end
    
else
    % Return specified preferences
    validateattributes(prefName,{'char'},{},mfilename,'PREFNAME')
    
    validPrefs = [allNames{:}];
    preference = validatestring(prefName,validPrefs,mfilename,'PREFNAME');    
        
    % Handle the mixed-data-type magnification preferences first
    if ~isempty(strfind(preference,'Magnification'))
        
        % helper function sets both related settings appropriately
        if strcmpi(preference,'ImshowInitialMagnification')
            value = getInitialMag(s,'imshow');
        else
            value = getInitialMag(s,'imtool');
        end
        
    else
        
        % Handle single-data-type preferences (each one individually)
        if strcmpi(preference,'ImtoolStartWithOverview')
            value = s.images.imtool.OpenOverview;
            
        elseif strcmpi(preference,'UseIPPL')
            value = s.images.UseIPPL;
            
        elseif strcmpi(preference,'ImshowAxesVisible')
            if s.images.imshow.ShowAxes
                value = 'on';
            else
                value = 'off';
            end
            
        elseif strcmpi(preference,'ImshowBorder')
            value = s.images.imshow.BorderStyle;
            
        end
    end
    
end


function mag = getInitialMag(s,fun)
% Helper function to simplify the mixed type preferences

style = s.images.(fun).InitialMagnificationStyle;
if strcmp(style,'numeric')
    mag = s.images.(fun).InitialMagnification;
else
    mag = style;
end
