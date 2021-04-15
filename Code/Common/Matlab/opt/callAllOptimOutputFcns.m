function stop = callAllOptimOutputFcns(OutputFcn,xOutputfcn,optimValues,state,varargin)
%CALLALLOPTIMOUTPUTFCNS Helper function that manages the output functions.
%
%   Private to optimization functions.

%   Copyright 2005-2006 The MathWorks, Inc.
%   $Revision: 1.1.6.3 $  $Date: 2006/12/15 19:27:38 $

% call each output function
stop = false(length(OutputFcn),1);
for i = 1:length(OutputFcn)
    stop(i) = feval(OutputFcn{i},xOutputfcn,optimValues,state,varargin{:});
end
% If any stop(i) is true we set the stop to true
stop = any(stop);

