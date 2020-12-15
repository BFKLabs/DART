function out = triggerconfig(obj, varargin)
%TRIGGERCONFIG Configure video input object trigger settings.
%
%    TRIGGERCONFIG(OBJ, TYPE) 
%    TRIGGERCONFIG(OBJ, TYPE, CONDITION) 
%    TRIGGERCONFIG(OBJ, TYPE, CONDITION, SOURCE) configures the 
%    TriggerType, TriggerCondition, and TriggerSource properties of 
%    video input object OBJ to the value specified by TYPE, CONDITION, 
%    and SOURCE, respectively. 
%
%    OBJ can be a single video input object or an array of video input 
%    objects. If an error occurs, any video input objects in the array 
%    that have already been configured are returned to their original 
%    configuration.
%
%    TYPE, CONDITION, and SOURCE are text strings. For a list of valid 
%    trigger configurations, use TRIGGERINFO(OBJ). CONDITION and SOURCE 
%    are optional parameters as long as a unique trigger configuration 
%    can be determined from the parameters provided.
%
%    TRIGGERCONFIG(OBJ, CONFIG) configures the TriggerType, TriggerCondition,
%    and TriggerSource property values for video input object OBJ using CONFIG, 
%    a MATLAB structure with fieldnames TriggerType, TriggerCondition, and 
%    TriggerSource, each with the desired property value. 
%
%    CONFIG = TRIGGERCONFIG(OBJ) returns a MATLAB structure, CONFIG,
%    containing OBJ's current trigger configuration. The fieldnames of CONFIG 
%    are TriggerType, TriggerCondition, and TriggerSource, each containing 
%    OBJ's current property value. OBJ must be a 1x1 object.
%
%    Example:
%       % Construct a video input object.
%       obj = videoinput('winvideo', 1);
%
%       % Configure the trigger settings.
%       triggerconfig(obj, 'manual')
%
%       % Trigger the acquisition.
%       start(obj)
%       trigger(obj)
%
%       % Remove video input object from memory.
%       delete(obj);
%
%    See also IMAQDEVICE/TRIGGERINFO, IMAQHELP. 
%

%    CP 10-07-02
%    Copyright 2001-2012 The MathWorks, Inc.

% Error checking.
if ~isa(obj, 'imaqdevice')
    error(message('imaq:triggerconfig:invalidType'));
elseif ~all(isvalid(obj))
    error(message('imaq:triggerconfig:invalidOBJ'));
end

uddobj = imaqgate('privateGetField', obj, 'uddobject');
% If nargin > 1, verify OBJ is not running,
if (nargin > 1) && any(strcmp(get(uddobj, 'Running'), 'on'))
    error(message('imaq:triggerconfig:objRunning'));
end

% Define configuration order.
trigfields = {'TriggerType', 'TriggerCondition', 'TriggerSource'};

% Only allow arrays when configuring.
nObjects = length(uddobj);
if (nargin==1) && (nObjects > 1)
    error(message('imaq:triggerconfig:OBJ1x1'));
elseif nargin==1,
    % S = TRIGGERCONFIG(OBJ)
    out = cell2struct(get(uddobj, trigfields), trigfields, 2);
    return;
end

% Configure each object provided. 
prevConfig = cell(length(uddobj), 1);
for i=1:nObjects,
    try
        % Make sure to cache the previous configurations
        % before configuring the new one.
        prevConfig{i} = get(uddobj(i), trigfields);
        localConfig(trigfields, uddobj(i), varargin{:});
    catch exception
        % Attempt to configure back to previous settings.
        for p = 1:length(prevConfig),
            triggerconfig(uddobj(p), prevConfig{p}{:});
        end
        throw(exception);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localConfig(trigfields, uddobj, varargin)

% Parameter parsing.
userSettings = {};
switch nargin
    case 3,
        userInput = varargin{1};
        if (~isstruct(userInput) && ~ischar(userInput)) || ...
                (isstruct(userInput) && length(userInput)~=1),
            % Invalid input type.
            error(message('imaq:triggerconfig:invalidParamType'));
            
        elseif isstruct(userInput)
            % TRIGGERCONFIG(OBJ, S)
            validStruct = true;
            usersFields = fieldnames(userInput);
            if ( length(usersFields)~=length(trigfields) )
                validStruct = false;
            else
                for i=1:length(trigfields)
                    if ~isfield(userInput, trigfields{i})
                        validStruct = false;
                    else
                        userSettings{i} = userInput.(trigfields{i});  %#ok<AGROW>
                    end
                end
            end
            
            % Check if the MATLAB structure was correct.
            if ~validStruct
                error(message('imaq:triggerconfig:invalidStruct'));
            end            
        else
            userSettings{1} = varargin{1};
        end
        
    case 4,
        % TRIGGERCONFIG(OBJ, TYPE, CONDITION)
        if ~ischar(varargin{1}) || ~ischar(varargin{2}),
            % Invalid data type.
            error(message('imaq:triggerconfig:invalidString'));
        end
        userSettings{1} = varargin{1};
        userSettings{2} = varargin{2};
        
    case 5,
        % TRIGGERCONFIG(OBJ, TYPE, CONDITION, SOURCE)
        if ~ischar(varargin{1}) || ~ischar(varargin{2}) || ~ischar(varargin{3}),
            % Invalid data type.
            error(message('imaq:triggerconfig:invalidString'));
        end
        userSettings{1} = varargin{1};
        userSettings{2} = varargin{2};
        userSettings{3} = varargin{3};
        
    otherwise,
        error(message('imaq:triggerconfig:tooManyInputs'));
end

% Get trigger information.
try
    configurations = triggerinfo(uddobj, userSettings{1});
catch exception
    throw(exception);
end

% Perform the configuration.
try
    if length(userSettings)==length(trigfields),
        % TRIGGERCONFIG(OBJ, TYPE, CONDITION, SOURCE)
        userSettings = localFixGigeForNonStandardFeatures(uddobj, userSettings);
        triggerconfig(uddobj, userSettings{:});
        
    elseif (nargin==3),        
        % TRIGGERCONFIG(OBJ, TYPE)
        if (length(configurations)==1),
            % Configuration was unique
            configSettings = struct2cell(configurations);
            triggerconfig(uddobj, configSettings{:});
        else
            % Configuration is not unique
            error(message('imaq:triggerconfig:notUnique'));
        end
        
    else
        % TRIGGERCONFIG(OBJ, TYPE, CONDITION)
        % Need to make sure configuration is unique
        %
        % If there is only 1 configuration with the given 
        % condition, it's unique.
        validConditions = {configurations.(trigfields{2})};
        conditionMatch = strmatch(lower(userSettings{2}), lower(validConditions));
        if length(conditionMatch)==1,
            configMatch = struct2cell(configurations(conditionMatch));
            triggerconfig(uddobj, configMatch{:});
        elseif isempty(conditionMatch)
            error(message('imaq:triggerconfig:notValid'));
        else
            error(message('imaq:triggerconfig:notUnique'));
        end
    end
catch exception
    throw(exception);
end

function [userSettingsOut] = localFixGigeForNonStandardFeatures(uddobj, userSettings)

hwinfo = imaqhwinfo(uddobj);
if ~strcmp(hwinfo.AdaptorName, 'gige') || ~strcmp(userSettings{1}, 'hardware')
    userSettingsOut = userSettings;
    return;
end

% is gige and is a hardware trigger setting
if strcmp(userSettings{2}, 'DeviceSpecific') && strcmp(userSettings{3}, 'DeviceSpecific')
    userSettingsOut = userSettings;
    return;
end

% either an erroneous setting or else an old setting

% assume correct old setting of something like
%     triggerconfig(vid, 'hardware', 'FallingEdge', 'Line1-AcquisitionStart')
% convert to:
%     triggerconfig(vid, 'hardware', 'DeviceSpecific', 'DeviceSpecific')
% and set:
%     AcquisitionStartTriggerActivation = FallingEdge
%     AcquisitionStartTriggerMode = On
%     AcquisitionStartTriggerSource = Line2

condition = userSettings{2}; % 'FallingEdge'
source = userSettings{3}; % 'Line1-AcquisitionStart'
hyphenIdx = strfind(source, '-');
if isempty(hyphenIdx)
    % not an old configuration, pass it on and let it error if need be
    userSettingsOut = userSettings;
    return;
end
hyphenIdx = hyphenIdx(end); % use last one
triggerSelector = source((hyphenIdx + 1): end); % 'AcquisitionStart'
triggerSource = source(1:(hyphenIdx - 1)); % 'Line1'
warning(message('imaq:triggerconfig:gige:obsoleteTriggerConfig'));
try
    set(uddobj.Source, [triggerSelector 'TriggerMode'], 'On');
catch %#ok<CTCH>
    error(message('imaq:triggerconfig:gige:errorSettingTriggerMode', triggerSelector));
end

try
    set(uddobj.Source, [triggerSelector 'TriggerActivation'], condition);
catch %#ok<CTCH>
    error(message('imaq:triggerconfig:gige:errorSettingTriggerActivation', triggerSelector, condition));
end

try
set(uddobj.Source, [triggerSelector 'TriggerSource'], triggerSource);
catch %#ok<CTCH>
    error(message('imaq:triggerconfig:gige:errorSettingTriggerSource', triggerSelector, triggerSelector));
end

userSettingsOut{1} = userSettings{1};
userSettingsOut{2} = 'DeviceSpecific';
userSettingsOut{3} = 'DeviceSpecific';
