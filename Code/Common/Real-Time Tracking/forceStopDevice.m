% --- force stops any continuously running devices
function forceStopDevice(hGUI)

% retrieves the parameter/data struct
[rtD,rtP] = deal(getappdata(hGUI,'rtD'),getappdata(hGUI,'rtP'));

% determines if any devices are on. if they are, then turn them off
if (~isempty(rtP.Stim)) && (~isempty(rtD))
    if (strcmp(rtP.Stim.sType,'Cont'))
        % initialisations
        iStim = getappdata(hGUI,'iStim');
        dInfo = getappdata(hGUI,'objDACInfo');
        isDAC = any(strcmp(dInfo.dType,'DAC'));

        % turns off any devices that are on
        if (isfield(dInfo,'Control'))
            hS = dInfo.Control;
            for i = 1:size(rtD.sStatus,1)
                if (rtD.sStatus(i,2) == 1)
                    % stops the device based on the type
                    if (isDAC)
                        % case is for a DAC device
                        iChG = find(iStim.ID(:,1) == iStim.ID(i,1));
                        updateStimChannels(hS{iStim.ID(i,1)},0,1,rtD,iChG) 
                    else
                        % case is for a serial controller
                        switch (dInfo.sType{iStim.ID(i,1)})
                            case ('Opto') % case is for the optogenetics
                                N = 4;
                            otherwise % case is for the other devices
                                N = 1;
                        end
                        
                        % sets zero values for all the channels
                        updateStimChannels(hS{iStim.ID(i,1)},zeros(1,N),0,iStim.ID(i,2))
                    end
                end
            end
        end
    end
end    