function openSerialDevice(hS,sType)

if strcmp(get(hS,'Status'),'closed')
    % opens the serial port
    fopen(hS);

    % special case - must write 1 to HT3 to start loop
    switch sType
        case {5, 'HTControllerV3'}
            % case is the HTControllerV3 devices
            fscanf(hS);
            fprintf(hS,'1 \n');
    end
end