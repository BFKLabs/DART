function writeSerialString(hS,sStr)

% initialisations
tw = 5;
hasDev = ~isempty(hS) && ~isa(hS,'DummyDevice');

% prints the string to the device       
if iscell(sStr)
    % case is a multi-string array (opto or light-cycle)
    j = 1;
    while j <= length(sStr)
        try
            % sends the signal to the device
            if hasDev
                if isa(hS,'serial')
                    fprintf(hS,sStr{j},'async');
                elseif isa(hS,'internal.Serialport')                    
                    hS.writeline(sStr{j})
                end
            else
                fprintf('%s\n',sStr{j});
            end                        

            % increments the counter
            java.lang.Thread.sleep(tw);
            j = j + 1;
        catch 
            % if there was an error, then pause for a short time   
            java.lang.Thread.sleep(tw);
        end
    end
else
    % case is a single-string (motor device)
    if hasDev
        if isa(hS,'serial')
            fprintf(hS,sStr,'async');
        elseif isa(hS,'internal.Serialport')
            hS.writeline(sStr)
        end
    else
        fprintf('%s\n',sStr); 
    end                     
end
