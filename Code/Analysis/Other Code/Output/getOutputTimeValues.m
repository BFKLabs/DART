% --- sets the independent variable string/multiplier from the popupmenu
function [timeStr,tMlt,tRnd] = getOutputTimeValues(hPopup)

% if there is no valid metric units to be set, then exit with NaN values
if (strcmp(get(hPopup,'visible'),'off'))
    [timeStr,tMlt,tRnd] = deal(NaN);
    return
end

% initialisations
[lStr,iSel] = deal(get(hPopup,'string'),get(hPopup,'value'));

% sets the values based on the dependent variable type and selection
switch get(hPopup,'userdata')
    case 'Time' % case is the independent variable is time
        switch lStr{iSel}
            case 'Seconds' % case is time is in seconds
                [timeStr,tMlt] = deal('(secs)',1);
                tRnd = 0.01/(1 + 999*(length(lStr) < 4));
            case 'Minutes' % case is time is in minutes
                [timeStr,tMlt] = deal('(mins)',1/60);
                tRnd = 0.1/(1 + 9*(length(lStr) < 4));
            case 'Hours' % case is time is in hours   
                [timeStr,tMlt,tRnd] = deal('(hrs)',1/(60*60),0.001);
            case 'Days' % case is time is in days
                [timeStr,tMlt,tRnd] = deal('(days)',1/(24*60*60),0.0001);
        end
    case 'Dist' % case is the independent variable is distance
        switch lStr{iSel}
            case 'Millimetres' % case is distance is in millimetres
                [timeStr,tMlt,tRnd] = deal('(mm)',1,1);
            case 'Centimetres' % case is distance is in centimetres
                [timeStr,tMlt,tRnd] = deal('(cm)',1/10,0.1);
            case 'Metres' % case is distance is in metres
                [timeStr,tMlt,tRnd] = deal('(m)',1/1000,0.001);
        end    
end
