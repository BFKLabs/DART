classdef (Hidden,Sealed) ClassManager < handle & daq.internal.UserDeleteDisabled
    %ClassManager Coordinate general toolbox object behaviors.
    %    In order to assure that the save warning is only
    %issued once per MATLAB session (or per daq.reset
    %operation), all classes maintain a reference to the
    %ClassManager singleton, which retains information about
    %whether a save operation has occurred, issuing the warning,
    %if needed.
    %
    %    This undocumented class may be removed in a future release.
    
    %    Copyright 2009-2013 The MathWorks, Inc.
    
    %% -- Public methods, properties, and events --
    % Methods
    methods
        function warnOnSaveAttempt(obj)
            %warnOnSaveAttempt The first time it is called, it warns.
            %warnOnSaveAttempt() Throws a warning
            %indicating that a save was attempted on a data acquisition
            %object.  If called again, simply returns.
            
            error(nargchk(1,1,nargin,'struct')) %#ok<NCHKN>
            
            if obj.HasSaveWarningBeenIssued
                return
            end
            obj.HasSaveWarningBeenIssued = true;
            
            sWarningBacktrace = warning('off','backtrace');
            warning(message('daq:general:nosave'));
            warning(sWarningBacktrace);
        end
        
        function warnOnBinaryVectorGreaterThan52bits(obj)
            %warnOnBinaryVectorGreaterThan52bits The first time it is
            %called, it warns. warnOnBinaryVectorGreaterThan52bits() Throws
            %a warning indicating that the binary vector provided is
            %greater than 52-bits and decimal data will be returned in
            %uint64. If called again, simply returns.
            
            error(nargchk(1,1,nargin,'struct')) %#ok<NCHKN>
            
            if obj.HasBinaryVectorWarningBeenIssued
                return
            end
            obj.HasBinaryVectorWarningBeenIssued = true;
            
            sWarningBacktrace = warning('off','backtrace');
            warning(message('daq:general:greaterthan52'));
            warning(sWarningBacktrace);
        end
    end
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods(Access=private)
        function obj = ClassManager()
            obj.HasSaveWarningBeenIssued = false;
        end
    end
    
    % Hidden static methods, which are typically used as friend methods
    methods(Hidden,Static)
        function value = getInstance()
            persistent Instance;
            if isempty(Instance) || ~isvalid(Instance)
                Instance = daq.internal.ClassManager();
            end
            value = Instance;
        end
        
        function releaseInstance()
            try
                delete(daq.internal.ClassManager.getInstance);
            catch e %#ok<NASGU>
                % Ignore all errors that occur during deletes
            end
        end
    end
    
    % Private properties
    properties (GetAccess = private,SetAccess = private)
        %HasSaveWarningBeenIssued True if the
        %warnOnSaveAttempt method has been called.
        HasSaveWarningBeenIssued
        
        %HasBinaryVectorWarningBeenIssued True if the
        %warnOnBinaryVectorGreaterThan52bits method has been called.        
        HasBinaryVectorWarningBeenIssued
    end
    
end
