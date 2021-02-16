% --- creates a simplified file name (for long file names) --- %
function simpName = simpFileName(fName,iPos)

% sets the simplified file name start/finish index positions
if (nargin == 1)
    iPos = 10;
end

% sets the simplified file-name (if it is longer than the specified)
if (length(fName) > (2*iPos+1))
    simpName = [fName(1:iPos),'~~',fName((-iPos:0)+end)];
else
    simpName = fName;
end