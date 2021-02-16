% --- outputs the real-time tracking data to file
function rtOut = outputRTTrackData(rtD,varargin)

% initialisations
rtOut = [];
if (~isfield(rtD,'rtP'))
    return
else
    rtP = rtD.rtP;
end

% determines if the stimuli connections have been made
if (isempty(rtP.Stim))
    % no stimuli, so exit
    return
else
    Stim = rtP.Stim;
    switch (Stim.cType)
        case ('Ch2App') % case is connecting a channel to a apparatus
            % determines if any connections were set
            if (all(isnan(Stim.C2A)))
                % no connections are made, so exit
                return
            else
                % otherwise, set the boolean flags
                isC2A = true;
            end
        case ('Ch2Tube') % case is connecting a channel to a tube
            if (all(all(isnan(Stim.C2T),2)))
                % no connections are made, so exit
                return
            else
                % otherwise, set the boolean flags
                isC2A = false;
            end
    end
end

if (nargin == 1)
    % prompts the user if they want to put the tracking data
    uChoice = questdlg('Do you want to output the Real-Time Tracking data',...
                       'Output Tracking Data?','Yes','No','Yes');
                   
    if (strcmp(uChoice,'Yes'))     
        % case is outputting the data to file
        ppDef = getappdata(findall(0,'tag','figDART'),'ProgDef');
        [fName,fDir,fIndex] = uiputfile({'*.mat','Matlab File (*.mat)'},...
                                 'Save Data File',ppDef.Analysis.OutData);

        % if the user cancelled, then exit the function
        if (~fIndex); return; end
    else
        % if the user declined then exit the function
        return
    end
end

% sets the key cell array
Key = {'sData = Stimuli Event Data';...
       'rtP = Real-Time Tracking Parameters';...
       'iDev = Device ID#';...
       'iCh = Channel Index';...
       'iApp = Region Index';...
       'iFly = Fly Index'};

% retrieves the output data arrays
[sData,ID] = deal(rtD.sData,rtD.iStim.ID);

% sets the device indices
if (isC2A)
    % connection is the channel to apparatus
    indD = Stim.C2A;
    [iApp,Key] = deal(indD(:,1),Key(1:end-1));
else
    % connection is the channel to individual tube
    indD = Stim.C2T;
    [iApp,iFly] = deal(indD(:,1),indD(:,2));
end

% removes any of the non-connections
ii = ~any(isnan(indD),2);
[sData,iDev,iCh,iApp] = deal(sData(ii),ID(ii,1),ID(ii,2),iApp(ii));

% outputs the data based on the output type
if (nargin == 1)
    % case is outputting the data to file
    if (isC2A)
        save(fullfile(fDir,fName),'Key','sData','rtP','iDev','iCh','iApp')
    else
        iFly = iFly(ii);
        save(fullfile(fDir,fName),'Key','sData','rtP','iDev','iCh','iApp','iFly')
    end
else
    % case is outputting the data to a struct
    rtOut = struct('Key',[],'sData',[],'rtP',rtP,'iDev',iDev,...
                   'iCh',iCh,'iApp',iApp);
               
    % sets the other fields
    [rtOut.Key,rtOut.sData] = deal(Key,sData);                   
    if (~isC2A); rtOut.iFly = iFly(ii); end
end
