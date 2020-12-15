classdef (Hidden) UserDeleteDisabled < handle
    %UserDeleteDisabled BaseClass that prevents end user deletion
    %   DAQ objects derived from this class cannot be deleted by the delete
    %   command.  All subclasses of this are required to define their
    %   delete methods protected.  This allows normal garbage collection,
    %   but prevents users from explicitly deleting an object,
    %
    %    This undocumented class may be removed in a future release.
    
    % Copyright 2009-2010 The MathWorks, Inc.
    % $Revision: 1.1.6.2 $  $Date: 2010/08/07 07:25:54 $
    
    methods (Access=protected)
        function delete(~)
        end
    end
    
end

