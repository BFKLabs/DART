% --- determines the DAC type based on the Matlab version and device type
function [i1,i2] = getDACType(objDAC)

% memory allocation
[i1,i2] = deal(false(length(objDAC),1));

% sets the device types based on A) the version of Matlab, and B) whether
% the device has an interal clock
for i = 1:length(i1)
    if (verLessThan('matlab','9.2'))
        % using older Matlab version
        dName = get(objDAC{i},'Name');
        if (strContains(dName,'nidaq'))
            % device doesn't use internal clock
            i2(i) = true;
        else
            % device does use internal clock
            i1(i) = true;
        end
    else
        % newer Matlab version, so can't use internal clock to store the
        % output signal
        i2(i) = true;
    end
end