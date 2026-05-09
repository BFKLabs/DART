function sStr = setupArduinoString(dType,pVal)

switch dType
    case 'all'
        % case is all devices
        xiF = 1:6;
        sStrF = arrayfun(@(x)(setupArduinoString(x,pVal)),xiF(:),'un',0);
        sStr = cell2cell(sStrF);

        return

    case {'motor', 'ir', 1, 6}
        % case is the motors/infra-red lights
        xi = 0:7;
        % xi = 1:8;

    case {'hl', 5}
        % case is the house (white) lights
        xi = 1:2;

    case {'red', 'green', 'blue', 2, 3, 4}
        % case is the opto lights
        switch dType
            case {'red', 2}
                % case is the red channel
                xi = 1:2;

            case {'green', 3}
                % case is the green channel
                xi = 3:4;      

            case {'blue', 4}
                % case is the blue channel
                xi = 5:6;
        end

        % resets device flag
        dType = 'opto';
end

% convert numerical device flags to strings
switch dType
    case 1
        dType = 'motor';
    case 5
        dType = 'hl';    
    case 6
        dType = 'ir';
end

% sets up the device stimuli strings
sStr = arrayfun(@(x)(sprintf('set %s %i %i \n',dType,x,pVal)),xi(:),'un',0);