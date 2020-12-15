function out = vertcat(varargin)
%VERTCAT Vertical concatenation of image acquisition objects.
%
%    See also IMAQHELP.
%

%    CP 9-01-01
%    Copyright 2001-2010 The MathWorks, Inc.

% Initialize variables.
c=[];

% Loop through each UDD object and concatenate.
for i = 1:nargin
    if ~isempty(varargin{i}),
        % Make sure we are only concatenating image acquisition objects.
        if ~isa(varargin{i},'imaqdevice'),
            error(message('imaq:vertcat:parentMixedTypes'));
        end
        
        if isempty(c),
            c = varargin{i};
        else
            % Concatenate the UDD object for each.
            try
                % May error with "All rows in the bracketed expression must
                % have the same number of columns."
	            c.uddobject = [c.uddobject; imaqgate('privateGetField', varargin{i}, 'uddobject')];
            catch exception
                throw(exception);
            end            
            
            % Concatenate the type for each object.
            appendType = imaqgate('privateGetField', varargin{i}, 'type');
            c.type = [c.type; appendType];
        end 
    end
end

% Verify that a matrix of objects was not created.
if (length(c.uddobject) ~= numel(c.uddobject))
    error(message('imaq:vertcat:noMatrix'));
end

% Output the array of objects.
out = c;
