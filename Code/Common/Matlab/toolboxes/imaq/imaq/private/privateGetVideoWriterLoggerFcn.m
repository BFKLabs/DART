function fcnHandle = privateGetVideoWriterLoggerFcn
% PRIVATEGETVIDEOWRITERLOGGERFCN Callback to handle disk logging to a VideoWriter object.
%
%    This function returns a function handle that can be used as a callback
%    to handle disk logging when the user is logging data to disk using a
%    VideoWriter object.  It handles opening and closing the file as well
%    as converting the received data to a uint8, if necessary, before
%    writing the file to disk.
%
%    This function is for internal use only and is not intended for use by
%    customers.

% Copyright 2010-2012 The MathWorks, Inc.

fcnHandle = @internalLoggerFcn;

    function internalLoggerFcn(obj, eventData)
        try
            diskLogger = obj.DiskLogger;
            
            if strcmp(eventData.Data.Type, 'StopLogging')
                % If the event type is to stop logging, close the file.  Note
                % that close flushes any writeVideo commands that are in the
                % queue.
                drawnow;
                diskLogger.close();
                return;
            end
            
            if (~diskLogger.IsOpen)
                if strcmpi(diskLogger.FileFormat, 'mj2')
                    % If we're logging to a Motion JPEG 2000 file, set the bit
                    % depth if the user hasn't already set it.
                    if isempty(diskLogger.MJ2BitDepth)
                        diskLogger.MJ2BitDepth = eventData.Data.BitDepth;
                    end
                end
                
                diskLogger.open();
            end
            
            % Most profiles will error if passed non-uint8 data.  Since we know
            % the bit depth, convert the data so that we can attempt to log it.
            if ~strcmpi(diskLogger.FileFormat, 'mj2') && ...
                    (eventData.Data.BitDepth > 8)
                data = uint8(bitshift(eventData.Data.Data, 8 - eventData.Data.BitDepth));
            else
                data = eventData.Data.Data;
            end
            
            
            diskLogger.writeVideo(data);
        catch exp
            if diskLogger.IsOpen
                diskLogger.close();
            end
            uddObj = imaqgate('privateGetField', obj, 'uddobject');
            uddObj.acquisitionerror('imaq:disklogging:VideoWriterError', ...
                sprintf('Unexpected error logging to disk:\n%s', exp.message));
            % Unset the logging function so that the error gets thrown only
            % once
            set(uddObj, 'ZZZVideoWriterLoggingFcn', []);
            return;
        end
    end
end