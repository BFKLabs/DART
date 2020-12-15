classdef PluginManager < handle
    %PLUGINMANAGER Manage audio file plugins and plugin paths
    %   PluginManager manages a set of audio file I/O 
    %   asyncio device, converter, and filter plugins
    %   and their capabilities.
    %
 
    %   Authors: NH, DT
    %   Copyright 2012-2013 The MathWorks, Inc.
 
    %   IMPLEMENTATION NOTES
    %   PluginManager is a singleton who's lifetime manages the lifetime
    %   of a mex file (mexPluginManager). This mex file holds an instance
    %   of a C++ audio::File::PluginManager.
    %
    %   Note that the use of ~ for the obj parameter in most of the methods
    %   is done on purpose. Most of the methods in this class defer
    %   directly to a mex file without using obj.  These methods could
    %   be static, but we want to bind the lifetime of the mex's data with
    %   to the lifetime of this class, so the Singleton pattern was chosen.
    
    properties (Constant, GetAccess='public')
        ErrorPrefix = 'multimedia:audiofile:';
    end
    
    properties (GetAccess='public', SetAccess='private')
        PluginPath       % Full Path to the audio file I/O device plugins
        MLConverter      % Fully qualified path to the MATLAB converter 
        SLConverter      % Fully qualified path to the Simulink converter
        TransformFilter  % FUlly qualified path to the Audio Transform filter
    end
    
    properties (Dependent, GetAccess='public', SetAccess='private')
        ReadableFileTypes   % Cell array of file extensions readable by the plugins
        WriteableFileTypes  % Cell array of file extensions writable by the plugins
    end
    
    
    methods (Access='public')
        function pluginPath = getPluginForRead(~, fileToRead)
            % Given a path to an audio file, return the audio file I/O
            % asyncio device plugin to use for reading this file.
            pluginPath = mexPluginManager('getPluginForRead',fileToRead);
            
            import multimedia.internal.audio.file.PluginManager;
            PluginManager.handlePluginError(pluginPath);
        end
        
        function pluginPath = getPluginForWrite(~,fileToWrite)
            % Given a path to an audio file to write  return the audio file I/O
            % asyncio device plugin to use for writing this type file.
            pluginPath = mexPluginManager('getPluginForWrite',fileToWrite);

            import multimedia.internal.audio.file.PluginManager;
            PluginManager.handlePluginError(pluginPath);
        end
    end
    
    methods (Static)
        function exception = convertPluginException( exception, identifierBase )
            % Given an exception with an identifier that begins with 
            % PluginManager.ErrorPrefix, convert the identifier of that 
            % exception to an identifier beginning with IdentifierBase.  
            % This is useful for translating exceptions thrown from the 
            % PluginManager into exceptions with an identifier for your 
            % product.
            % 
            % For example:
            %
            %   import multimedia.internal.audio.file.PluginManager;
            %   try 
            %      PluginManager.Instance.getPluginForRead('myfile.wav')
            %   catch exception
            %      % Translate exception for use in audiovideo
            %      exception = PluginManager.convertPluginException(exception, ...
            %          'MATLAB:audiovideo:audioread');
            %      throw(exception);
            %   end
            %
            % NOTE: Exceptions thrown by PluginManager are fully 
            % translated, so clients of this code do NOT need to add 
            % error IDs in their own message catalogs.
            %

            import multimedia.internal.audio.file.PluginManager;

            if isempty(strfind(exception.identifier, ...
                    PluginManager.ErrorPrefix))
                
                % Exception is not a 'PluginException' 
                % just pass it back.
                return;
            end
            
            if isempty(exception.message)
                % This 'PluginException' exception has no 'message' and 
                % was most likely thrown via the asyncio chaneel. 
                % Insert the message now.
                exception = MException(...
                    message(exception.identifier));
            end
            
            idpartindices = strfind(exception.identifier,':');
            
            lastpart = exception.identifier(idpartindices(end)+1:end);
            newid = [identifierBase ':' lastpart];
            exception = MException(newid,exception.message);
        end
    end
    
    methods % Custom get methods for properties
        
        function fileTypes = get.ReadableFileTypes(~)
            fileTypes = mexPluginManager('getReadableFileTypes');
            
            import multimedia.internal.audio.file.PluginManager;
            PluginManager.handlePluginError(fileTypes);
        end
        
        function fileTypes = get.WriteableFileTypes(~)
            fileTypes = mexPluginManager('getWriteableFileTypes');

            import multimedia.internal.audio.file.PluginManager;
            PluginManager.handlePluginError(fileTypes);
        end
        
        function delete(~)
            mexPluginManager('destroyPluginManager');
        end
    end
    
    methods (Access = 'private')
        function obj = PluginManager
            basePath = fullfile( ...
                matlabroot,...
                'toolbox','shared','multimedia',...
                'bin',computer('arch'));
            
            % Initialize plugin paths
            obj.PluginPath = fullfile(basePath,'audio');
            obj.MLConverter = fullfile(basePath,'audiomlconverter');
            obj.SLConverter = fullfile(basePath,'audioslconverter');
            obj.TransformFilter = fullfile(basePath,'audiotransformfilter');
            
            %initialize the underlying plugin manager
            mexPluginManager('initializePluginManager',obj.PluginPath, obj.MLConverter, obj.TransformFilter);
        end

    end
    
    methods(Static, Access='private')
        
        function handlePluginError(err)
            if ~isstruct(err)
                return;
            end
            
            import multimedia.internal.audio.file.PluginManager;
            
            errID = [PluginManager.ErrorPrefix err.Name];
            messageArgs = {errID};
            if (~isempty(err.What))
                messageArgs{end+1} = err.What;
            end
            
            msgObj = message(messageArgs{:});
            
            % An error occurred, throw this as an MException
            throwAsCaller(MException(errID, msgObj.getString)); 
        end
    end
    
    methods(Static, Access='public')
        function instance = getInstance(~)
            % Revert back to using a constant property once g911313 is
            % fixed
            persistent localInstance;
            if isempty(localInstance)
                localInstance = multimedia.internal.audio.file.PluginManager();
            end
            instance = localInstance;
        end
    end
    
   
end

