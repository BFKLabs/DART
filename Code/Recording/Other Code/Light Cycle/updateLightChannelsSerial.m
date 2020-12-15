% --- updates the serial controller output channels
function updateLightChannelsSerial(hS,wAmp,iAmp,dwAmp,diAmp,dT)

% global variables
global Ywl Yir white_scl

% retrieves the controller type and other initialisations
[tw0,tw1] = deal(50,0);
sType = get(hS,'UserData');

% loops through all of the changes updating the channel amplitudes
while (1)
    try 
        % attempts to update the serial device
        if sType == 0
            if (nargin == 3)
                sStr = sprintf('2,%f,%f,%f,%f,%f',wAmp,iAmp,0,0,0);
            else
                sStr = sprintf('3,%f,%f,%f,%f,%f',wAmp,iAmp,dwAmp,diAmp,dT); 
            end
        elseif sType == 2
            % case is the V2 serial devices
            Y = roundP([wAmp, iAmp]*100);
            [Ywl,Yir] = deal(roundP(white_scl*(Y(1)/100)),Y(2));
            sStr = {sprintf('2,%i,%i,%i',Ywl,Ywl,Ywl), ...
                    sprintf('3,0,%i\n',Yir)};  
        end
        
        % increments the counter
        if iscell(sStr)
            for i = 1:length(sStr)
                try
                    fprintf(hS,sStr{i},'async');
                    java.lang.Thread.sleep(roundP(tw0/2+rand*tw1));
                catch
                    % if there was an error, then pause for a short time         
                    java.lang.Thread.sleep(roundP(tw0+rand*tw1));
                end
            end
        else
            fprintf(hS,sStr,'async');
        end
                
        % sets the signal to the device
        break;
    catch 
        % if there was an error, then pause for a short time         
        java.lang.Thread.sleep(roundP(tw0+rand*tw1));
    end
end