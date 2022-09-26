function simulateKeyPress(keyStr)

% see following link for missing key codes
% => https://docs.oracle.com/javase/8/docs/api/constant-values.html#java.awt.event.KeyEvent.VK_HOME

% java imports
import java.awt.Robot
import java.awt.event.*

% initialisations
keys = Robot;
iChar = double(keyStr);

% sets the key press index value
if length(iChar) == 1
    % case is there is a single character for the key string
    indKey = iChar;    
else
    switch lower(keyStr)
        case 'alt'
            % case is the alt key
            indKey = 18;
            
        case {'ctrl','control'}
            % case is the control key
            indKey = 17;            
            
        case {'esc','escape'}
            % case is the escape key
            indKey = 27;            
            
        case 'enter'
            % case is the enter key
            indKey = 10;            
            
        case 'space'
            % case is the space key
            indKey = 32;
            
        case 'shift'
            % case is the shift key
            indKey = 16;
            
        case 'tab'
            % case is the tab key
            indKey = 9;                        
            
    end
        
end

% simulates the key press
keys.keyPress(indKey);