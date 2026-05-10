function sStr = setupArduinoString(dType,pVal)

switch dType
    case 'all'
        % case is all devices
        xiF = 1:6;
        sStr = arrayfun(@(x)(setupArduinoString(x,pVal)),xiF(:),'un',0);
        return

    case {'motor', 1}
        % case is the motors/infra-red lights
        xiCh = 1;

    case {'red', 'green', 'blue', 2, 3, 4}
        % case is the opto lights
        switch dType
            case {'red', 2}
                % case is the red channel
                xiCh = 2;

            case {'green', 3}
                % case is the green channel
                xiCh = 3;      

            case {'blue', 4}
                % case is the blue channel
                xiCh = 4;
        end

        % resets device flag
        dType = 'opto';
        
    case {'hl', 5}
        % case is the house (white) lights
        xiCh = 5;
        
    case {'ir', 6}
        % case is the ir lights
        xiCh = 6;        
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
sStr = sprintf('set %s %i %i \n',dType,100*xiCh,pVal);