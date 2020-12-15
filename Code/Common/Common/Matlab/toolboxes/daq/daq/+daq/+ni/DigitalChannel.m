classdef (Hidden) DigitalChannel < daq.DigitalChannel & daq.ni.NICommonChannelAttrib
    %DigitalChannel All settings & operations for an NI digital channel.
    
    % Copyright 2012 The MathWorks, Inc.
    %
    
    %Disable warnings about accessing properties from a property set
    %function -- this class cannot be saved.
    %#ok<*MCSUP>
    
    %% -- Protected and private members of the class --
    % Non public-constructor
    methods(Hidden)
        function obj = DigitalChannel(session,deviceInfo,channelID)
            %DigitalChannel All settings & operations for a digital channel
            %added to a session.
            %    DigitalChannel(SESSION,DEVICEINFO,ID) Create a digital
            %    channel with SESSION, DEVICEINFO, and ID (see daq.Channel)
            
            % Create the channel to get appropriate defaults
            obj@daq.DigitalChannel(session,deviceInfo,channelID);
        end
    end
    
    methods(Hidden, Static)
        function [result] = parseChannelsHook(channelID)
            result = {};
            
            if ~iscell(channelID)
                channelID = {channelID};
            end
                
            for ch = 1:numel(channelID)
                channels = channelID{ch};
                
                if ~ischar(channels)
                    daq.internal.BaseClass.getLocalizedException('daq:channel:invalidChannelFormat').throwAsCaller;
                end
                
                [regexMatches, regexSplits, regexTokens] = regexp(channels,...
                    'port(\d+)(\\|/)line(\d+)(:\d+){0,1}',...
                    'match', 'split', 'tokens', 'ignorecase' , 'freespacing');
                
                if isempty(regexMatches) || isempty(regexTokens)
                    daq.internal.BaseClass.getLocalizedException('daq:channel:invalidChannelFormat').throwAsCaller;
                end
                
                % check separators
                for i = 1:numel(regexSplits)
                    if ~isempty(regexSplits{i})
                        validSeparator = regexp(regexSplits{i}, ',', 'match', 'freespacing');
                        if (numel(regexMatches) == 1 && ~strcmp(regexSplits{i},'')) ||...
                           isempty(validSeparator) ||...
                           (numel(regexMatches) > 1 && ~strcmp(validSeparator, ','))
                            daq.internal.BaseClass.getLocalizedException('daq:channel:invalidChannelFormat').throwAsCaller;
                        end
                    end
                end
                
                for i = 1:numel(regexTokens)
                    port = str2double(regexTokens{i}{1});
                    lineStart = str2double(regexTokens{i}{3});
                    
                    if isempty(regexTokens{i}{4})
                        result{end+1} = sprintf('port%d/line%d', port, lineStart); %#ok<AGROW>
                    else
                        tmp = regexp(regexTokens{i}{4}, ':(\d+)', 'tokens');
                        lineEnd = str2double(tmp{1});
                        increment = 1;
                        if lineEnd < lineStart
                            increment = -1;
                        end
                        for line = lineStart:increment:lineEnd
                            result{end+1} = sprintf('port%d/line%d', port, line); %#ok<AGROW>
                        end
                    end
                end
            end
        end
    end
end
